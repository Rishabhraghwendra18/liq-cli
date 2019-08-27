# ctrlScriptEnv generates the environment settings and required parameters list
# for control scripts.
#
# The method will set 'EXPORT_PARAMS', which should be declared local by the
# caller.
#
# The method will normally echo an error and force an exit
# if a required parameter is not found. If '_SKIP_CURR_ENV_FILE' is set to any
# value, this check will be skipped and the variable will be set to blank. This
# is in support of internal flows which may which may define a subset of the
# required parameters in order to initiate an operation that only requires that
# subset.
ctrlScriptEnv() {
  check-param-err() {
    local REQ_PARAM="${1}"; shift
    local DESC="${1}"; shift

    if [[ -z "${!REQ_PARAM:-}" ]] && [[ -z "${_SKIP_CURR_ENV_FILE:-}" ]]; then
      echoerrandexit "No value for ${DESC} '$REQ_PARAM'. Try updating the environment:\ncatalyst environment update -n"
    fi
  }

  EXPORT_PARAMS=PACKAGE_NAME$'\n'BASE_DIR$'\n'LIQ_ENV_LOGS$'\n'SERV_NAME$'\n'SERV_IFACE$'\n'PROCESS_NAME$'\n'SERV_LOG$'\n'SERV_ERR$'\n'PID_FILE$'\n'REQ_PARAMS

  local REQ_PARAM
  for REQ_PARAM in $REQ_PARAMS; do
    check-param-err "$REQ_PARAM" "service-source parameter"
    list-add-item EXPORT_PARAMS "${REQ_PARAM}"
  done

  local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
  local ADD_REQ_PARAMS=$((echo "$PACKAGE" | jq -e --raw-output ".catalyst.requires | .[] | select(.iface==\"$SERV_IFACE\") | .\"params-req\" | @sh" 2> /dev/null || echo '') | tr -d "'")
  for REQ_PARAM in $ADD_REQ_PARAMS; do
    check-param-err "$REQ_PARAM" "service-local parameter"
    list-add-item EXPORT_PARAMS "${REQ_PARAM}"
  done

  for REQ_PARAM in $(getConfigConstants "${SERV_IFACE}"); do
    # TODO: ideally we'd load constants from the package.json, not environment.
    check-param-err "$REQ_PARAM" "config const"
    list-add-item EXPORT_PARAMS "${REQ_PARAM}"
  done
}

runServiceCtrlScript() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions NO_ENV -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  local SERV_SCRIPT="$1"; shift

  if [[ -z $NO_ENV ]]; then
    local EXPORT_PARAMS
    local REQ_PARAMS
    REQ_PARAMS=$(getRequiredParameters "$SERVICE_KEY")
    ctrlScriptEnv

    # The script might be our own or an installed dependency.
    if [[ -e "${BASE_DIR}/bin/${SERV_SCRIPT}" ]]; then
      ( export $EXPORT_PARAMS; "${BASE_DIR}/bin/${SERV_SCRIPT}" "$@" )
    else
      ( export $EXPORT_PARAMS; cd "${BASE_DIR}"; npx --no-install $SERV_SCRIPT "$@" )
    fi
  else
    if [[ -e "${BASE_DIR}/bin/${SERV_SCRIPT}" ]]; then
      "${BASE_DIR}/bin/${SERV_SCRIPT}" "$@"
    else
      ( cd "${BASE_DIR}"; npx --no-install $SERV_SCRIPT "$@" )
    fi
  fi
}

testServMatch() {
  local KEY="$1"; shift
  if [[ -z "${1:-}" ]]; then
    # if there's nothing to match, then everything matches
    return 0
  fi
  local CANDIDATE
  for CANDIDATE in "$@"; do
    # Match on the interface class only; trim the script name.
    CANDIDATE=`echo $CANDIDATE | sed -Ee 's/\..+//'`
    # Unlike the 'provides' matching, we match only on major-interface types.
    KEY=`echo $KEY | sed -Ee 's/-.+//'`
    CANDIDATE=`echo $CANDIDATE | sed -Ee 's/-.+//'`
    if [[ "$KEY" ==  "$CANDIDATE" ]]; then
      return 0
    fi
  done
  return 1
}

testScriptMatch() {
  local KEY="$1"; shift
  if [[ -z "${1:-}" ]]; then
    # if there's nothing to match, then everything matches
    return 0
  fi
  local CANDIDATE
  for CANDIDATE in "$@"; do
    # If script bound and match or not script bound
    if [[ "$CANDIDATE" != *"."* ]] || [[ "$KEY" == `echo $CANDIDATE | sed -Ee 's/^[^.]+\.//'` ]]; then
      return 0
    fi
  done
  return 1
}

runtimeServiceRunner() {
  local _MAIN="$1"; shift
  local _ALWAYS_RUN="$1"; shift

  if [[ -z ${_SKIP_CURR_ENV_FILE:-} ]]; then
    source "${CURR_ENV_FILE}"
  fi
  declare -a ENV_SERVICES
  if [[ -n "${CURR_ENV_SERVICES:-}" ]]; then
    if [[ -z "${REVERSE_ORDER:-}" ]]; then
      ENV_SERVICES=("${CURR_ENV_SERVICES[@]}")
    else
      local I=$(( ${#CURR_ENV_SERVICES[@]} - 1 ))
      while (( $I >= 0 )); do
        ENV_SERVICES+=("${CURR_ENV_SERVICES[$I]}")
        I=$(( $I - 1 ))
      done
    fi
  fi
  local UNMATCHED_SERV_SPECS="$@"

  # TODO: Might be worth tweaking interactive-CLI by passing in vars indicating whether working on single or multiple, 'item' number and total, and whether current item is first, middle or last.
  local SERVICE_KEY
  for SERVICE_KEY in ${ENV_SERVICES[@]:-}; do
    local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
    local MAJOR_SERV_IFACE=`echo "$SERV_IFACE" | cut -d- -f1`
    local MINOR_SERV_IFACE=`echo "$SERV_IFACE" | cut -d- -f2`
    if testServMatch "$SERV_IFACE" "$@"; then
      local SERV_PACKAGE_NAME=`echo "$SERVICE_KEY" | cut -d: -f2`
      local SERV_NAME=`echo "$SERVICE_KEY" | cut -d: -f3`
      local SERV_PACKAGE
      getPackageDef SERV_PACKAGE "$SERV_PACKAGE_NAME"
      local SERV_SCRIPT
      local SERV_SCRIPTS=`echo "$SERV_PACKAGE" | jq --raw-output ".catalyst.provides | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-scripts\" | @sh" 2> /dev/null | tr -d "'"`
      [[ -n $SERV_SCRIPTS ]] || echoerrandexit "$SERV_PACKAGE_NAME package.json does not properly define 'catalyst.provides.$SERV_NAME.ctrl-scripts'."
      local SERV_SCRIPT_ARRAY=( $SERV_SCRIPTS )
      local SERV_SCRIPT_COUNT=${#SERV_SCRIPT_ARRAY[@]}
      # give the process scripts their proper, self-declared order
      if (( $SERV_SCRIPT_COUNT > 1 )); then
        for SERV_SCRIPT in $SERV_SCRIPTS; do
          local SCRIPT_ORDER # see https://unix.stackexchange.com/a/88338/84520
          SCRIPT_ORDER=$(runServiceCtrlScript --no-env $SERV_SCRIPT myorder)
          [[ -n $SCRIPT_ORDER ]] || echoerrandexit "Could not determine script run order."
          SERV_SCRIPT_ARRAY[$SCRIPT_ORDER]="$SERV_SCRIPT"
        done
      fi

      local SERV_SCRIPT_INDEX=0
      local SERV_SCRIPTS_COOKIE=''
      for SERV_SCRIPT in ${SERV_SCRIPT_ARRAY[@]}; do
        local SCRIPT_NAME # see https://unix.stackexchange.com/a/88338/84520
        SCRIPT_NAME=$(runServiceCtrlScript --no-env $SERV_SCRIPT name)
        local PROCESS_NAME="${SERV_IFACE}"
        if (( $SERV_SCRIPT_COUNT > 1 )); then
          PROCESS_NAME="${SERV_IFACE}.${SCRIPT_NAME}"
        fi
        local CURR_SERV_SPECS=''
        local SPEC_CANDIDATE
        for SPEC_CANDIDATE in "$@"; do
          if testServMatch "$SERV_IFACE" "$SPEC_CANDIDATE"; then
            list-add-item CURR_SERV_SPECS "$SPEC_CANDIDATE"
          fi
          # else it's a spec for another service interface
        done
        if testScriptMatch "$SCRIPT_NAME" "$CURR_SERV_SPECS"; then
          local SERV_OUT_BASE="${LIQ_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}"
          local SERV_LOG="${SERV_OUT_BASE}.log"
          local SERV_ERR="${SERV_OUT_BASE}.err"
          local PID_FILE="${SERV_OUT_BASE}.pid"
          eval "$_MAIN" || return $?

          # Again, notice that the service match is only on the major interface class.
          UNMATCHED_SERV_SPECS=`echo $UNMATCHED_SERV_SPECS | sed -Ee 's/(^| +)'${MAJOR_SERV_IFACE}'(-[^ ]+)?\.'${SCRIPT_NAME}'( +|$)//'`
        fi
        if [[ -n "${_ALWAYS_RUN:-}" ]]; then
          eval "$_ALWAYS_RUN"
        fi
        SERV_SCRIPT_INDEX=$(( $SERV_SCRIPT_INDEX + 1))
      done
      UNMATCHED_SERV_SPECS=`echo $UNMATCHED_SERV_SPECS | sed -Ee 's/(^| +)'$MAJOR_SERV_IFACE'(-[^ ]+)?( +|$)//'`
    fi
  done

  local UNMATCHED_SERV_SPEC
  for UNMATCHED_SERV_SPEC in $UNMATCHED_SERV_SPECS; do
    echoerr "Did not match service spec '$UNMATCHED_SERV_SPEC'."
  done
}
