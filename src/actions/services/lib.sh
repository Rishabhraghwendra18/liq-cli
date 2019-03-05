ctrlScriptEnv() {
  check-param-err() {
    local REQ_PARAM="${1}"; shift
    local DESC="${1}"; shift

    if [[ -z "${!REQ_PARAM:-}" ]]; then
      echoerrandexit "No value for ${DESC} '$REQ_PARAM'. Try updating the environment:\ncatalyst environment update -n"
    fi
  }

  local ENV_SETTINGS="PACKAGE_NAME='${PACKAGE_NAME}' BASE_DIR='${BASE_DIR}' _CATALYST_ENV_LOGS='${_CATALYST_ENV_LOGS}' SERV_NAME='${SERV_NAME}' SERV_IFACE='${SERV_IFACE}' PROCESS_NAME='${PROCESS_NAME:-}' SERV_LOG='${SERV_LOG:-}' SERV_ERR='${SERV_ERR:-}' PID_FILE='${PID_FILE:-}'"
  local REQ_PARAMS=$(getRequiredParameters "$SERVICE_KEY")
  local REQ_PARAM
  for REQ_PARAM in $REQ_PARAMS; do
    check-param-err REQ_PARAM "service-source parameter"
    ENV_SETTINGS="$ENV_SETTINGS $REQ_PARAM='${!REQ_PARAM}'"
  done

  local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
  local ADD_REQ_PARAMS=$((echo "$PACKAGE" | jq -e --raw-output ".\"$CAT_REQ_SERVICES_KEY\" | .[] | select(.iface==\"$SERV_IFACE\") | .\"params-req\" | @sh" 2> /dev/null || echo '') | tr -d "'")
  for REQ_PARAM in $ADD_REQ_PARAMS; do
    check-param-err REQ_PARAM "service-local parameter"
    ENV_SETTINGS="$ENV_SETTINGS $REQ_PARAM='${!REQ_PARAM}'"
    list-add-item REQ_PARAMS "${REQ_PARAM}"
  done

  for REQ_PARAM in $(getConfigConstants "${SERV_IFACE}"); do
    # TODO: ideally we'd load constants from the package.json, not environment.
    check-param-err $REQ_PARAM "config const"
    ENV_SETTINGS="$ENV_SETTINGS $REQ_PARAM='${!REQ_PARAM}'"
    list-add-item REQ_PARAMS "${REQ_PARAM}"
  done

  echo "$ENV_SETTINGS REQ_PARAMS='$REQ_PARAMS'"
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

  source "${CURR_ENV_FILE}"
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
      local SERV_SCRIPTS=`echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-scripts\" | @sh" | tr -d "'"`
      local SERV_SCRIPT_ARRAY=( $SERV_SCRIPTS )
      local SERV_SCRIPT_COUNT=${#SERV_SCRIPT_ARRAY[@]}
      # give the process scripts their proper, self-declared order
      if (( $SERV_SCRIPT_COUNT > 1 )); then
        for SERV_SCRIPT in $SERV_SCRIPTS; do
          SERV_SCRIPT_ARRAY[$(eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT myorder")]="$SERV_SCRIPT"
        done
      fi

      local SERV_SCRIPT_INDEX=0
      local SERV_SCRIPTS_COOKIE=''
      for SERV_SCRIPT in ${SERV_SCRIPT_ARRAY[@]}; do
        local SCRIPT_NAME=$(runScript $SERV_SCRIPT name)
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
          local SERV_OUT_BASE="${_CATALYST_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}"
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
