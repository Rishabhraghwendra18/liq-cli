requirements-environments() {
  requireCatalystfile
  requirePackage
}

source ./actionslib/common.sh
source ./actionslib/query.sh
source ./actionslib/update.sh
source ./gcplib/iam.sh
source ./gcplib/organizations.sh
source ./gcplib/projects.sh
source ./gcplib/services.sh
source ./gcplib/sql.sh
source ./gcplib/utils.sh

environments-add() {
  local ENV_NAME REQ_PARAMS DEFAULT_SETTINGS
  CURR_ENV_SERVICES=()
  environmentsGatherEnvironmentSettings "$@"

  if [[ -n "$REQ_PARAMS" ]]; then
    local REQ_PARAM
    for REQ_PARAM in $REQ_PARAMS; do
      if [[ -z "${!REQ_PARAM:-}" ]]; then
        local PARAM_VAL=''
        local DEFAULT_VAR_NAME="${REQ_PARAM}_DEFAULT_VAL"
        if declare -F environmentsGet-$REQ_PARAM >/dev/null; then
          environmentsGet-$REQ_PARAM $REQ_PARAM
        fi
        if [[ -z ${!REQ_PARAM:-} ]]; then
          require-answer "Value for required parameter '$REQ_PARAM': " PARAM_VAL "${!DEFAULT_VAR_NAME:-}"
          eval "$REQ_PARAM='$PARAM_VAL'"
        fi
      fi
    done
  fi
  # else, there are no required service interfaces and we're done.

  updateEnvironment
  environmentsAskIfSelect
}

environments-delete() {
  local ENV_NAME="${1:-}"
  test -n "$ENV_NAME" || echoerrandexit "Must specify enviromnent for deletion."

  if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    echoerrandexit "No such environment '$ENV_NAME'."
  fi

  onDeleteConfirm() {
    rm "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" && echo "Local '${ENV_NAME}' entry deleted."
  }

  onDeleteCurrent() {
    onDeleteConfirm
    environments-select 'none'
  }

  onDeleteCancel() {
    return 0 # noop
  }

  if [[ "$ENV_NAME" == "$CURR_ENV" ]]; then
    yesno \
      "Confirm deletion of current environment '${CURR_ENV}': (y/N) " \
      N \
      onDeleteCurrent \
      onDeleteCancel
  elif [[ -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    yesno \
      "Confirm deletion of environment '${ENV_NAME}': (y/N) " \
      N \
      onDeleteConfirm \
      onDeleteCancel
  else
    echoerrandexit "No such environment '${ENV_NAME}' found. Try 'catalyst environment list'."
  fi
}

environments-deselect() {
  ( test -L "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" \
    && rm "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ) \
    || echoerrandexit "No environment currently selected."
  loadCurrEnv
}

environments-list() {
  local RESULT="$(doEnvironmentList "$@")"
  if test -n "$RESULT"; then
    echo "$RESULT"
  else
    echo "No environments defined for '${PACKAGE_NAME}'. Use 'catalyst environment add'."
  fi
}

environments-select() {
  local ENV_NAME="${1:-}"
  if [[ -z "$ENV_NAME" ]]; then
    if test -z "$(doEnvironmentList)"; then
      echoerrandexit "No environments defined. Try 'catalyst environment add'."
    fi
    echo "Select environment:"
    select ENV_NAME in `doEnvironmentList`; do break; done
  fi
  local CURR_ENV_FILE="${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env"
  if [[ -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    test -L $CURR_ENV_FILE && rm $CURR_ENV_FILE
    cd "${LIQ_ENV_DB}/${PACKAGE_NAME}/" && ln -s "./${ENV_NAME}" curr_env
  else
    echoerrandexit "No such environment '$ENV_NAME' defined."
  fi
  # if not error and exit
  loadCurrEnv
}

environments-set() {
  echoerr "TODO: sorry, 'set' implementation is outdated"
  exit
  local ENV_NAME KEY VALUE
  if [[ $# -eq 3 ]]; then
    ENV_NAME="$1"
    KEY="$2"
    VALUE="$3"
  elif [[ $# -eq 2 ]]; then
    ENV_NAME="$CURR_ENV"
    KEY="$1"
    VALUE="$2"
  elif [[ $# -eq 0 ]]; then
    ENV_NAME="$CURR_ENV"
    echo "Select parameter to update"
    # TODO: add 'selectOrOther' function; we use this pattern in a few places
    select KEY in `getEnvTypeKeys` '<other>'; do break; done
    if [[ "$KEY" == '<other>' ]]; then
      require-answer 'Parameter key: ' KEY
    fi
    require-answer 'Parameter value: ' VALUE
    updateEnvParam "$KEY" "$VALUE"
  else
    echoerrandexit "Unexpected number of arguments to 'catalyst environment set'."
    # TODO: print action specific help would be nice
  fi

  updateEnvironment
}

environments-show() {
  local ENV_NAME="${1:-}"

  if [[ -n "$ENV_NAME" ]]; then
    if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
      echoerrandexit "No such environment '$ENV_NAME' found for '$PACKAGE_NAME'."
    fi
  else
    if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ]]; then
      echoerrandexit "No environment selected for '$PACKAGE_NAME'. Try 'catalyst environment select' or 'catalyst environment show <name>'."
    fi
    ENV_NAME='curr_env'
  fi
  cat "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}"

  # if [[ -n "$CURR_ENV" ]] && [[ "$CURR_ENV" == "$ENV_NAME" ]]; then
  #  echo "Current environment:"
  #  echo "$CURR_ENV"
  #  echo
  #fi
  #local ENV_DB="${LIQ_ENV_DB}/${ENV_NAME}"
  #if [[ -f "$ENV_DB" ]]; then
  #  cat "$ENV_DB"
  #else
  #  echoerrandexit "No such environment '${ENV_NAME}'."
  #fi
}

# TODO: this shares a lot of code with environments-add
environments-update() {
  local TMP
  TMP=$(setSimpleOptions NEW_ONLY -- "$@") \
    || ( help-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  local ENV_NAME="${1:-}"

  if [[ -z "${ENV_NAME}" ]]; then
    if [[ -L "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ]]; then
      requireEnvironment
      ENV_NAME="$CURR_ENV"
    else
      local ENV_LIST
      ENV_LIST=$(environments-list --list-only)
      selectOneCancel ENV_NAME ENV_LIST
    fi
  fi

  if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    contextHelp
    echoerrandexit "Unknown environment name '${ENV_NAME}'."
  else
    source "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}"
  fi

  # Handle the purpose
  if [[ -z "$NEW_ONLY" ]]; then
    local SELECT_DEFAULT="$CURR_ENV_PURPOSE"
    unset CURR_ENV_PURPOSE
    PS3="Select purpose: "
    selectOneCancelOtherDefault CURR_ENV_PURPOSE STD_ENV_PURPOSES
  fi

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  local PRIOR_ENV_SERVICES="${CURR_ENV_SERVICES[@]:-}"
  CURR_ENV_SERVICES=()
  for REQ_SERV_IFACE in $REQ_SERV_IFACES; do
    local PRIOR_MATCH="$(echo "$PRIOR_ENV_SERVICES" | sed -Ee 's/(^|.* +)('$REQ_SERV_IFACE':[^ ]+)( +|$).*/\2/')"
    if echo "$PRIOR_ENV_SERVICES" | grep -qE '(^|.* +)('$REQ_SERV_IFACE':[^ ]+)( +|$).*'; then
      local PRIOR_SERVICE=$(echo "$PRIOR_MATCH" | cut -d: -f3)
      local PRIOR_PACKAGE=$(echo "$PRIOR_MATCH" | cut -d: -f2)
      environmentsServiceDescription SELECT_DEFAULT "$PRIOR_SERVICE" "$PRIOR_PACKAGE"
      SELECT_DEFAULT="'${SELECT_DEFAULT}'"
    else
      SELECT_DEFAULT=''
    fi
    local FQN_SERVICE
    if [[ -z "$NEW_ONLY" ]] || [[ -z "$SELECT_DEFAULT" ]]; then
      environmentsFindProvidersFor "$REQ_SERV_IFACE" FQN_SERVICE
    else
      environmentsFigureFqnService FQN_SERVICE "$REQ_SERV_IFACE" "$(echo "$SELECT_DEFAULT" | tr -d "'")"
    fi
    CURR_ENV_SERVICES+=("$FQN_SERVICE")

    local REQ_PARAMS=$(getRequiredParameters "$FQN_SERVICE")
    local ADD_REQ_PARAMS=$((echo "$PACKAGE" | jq -e --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"params-req\" | @sh" 2> /dev/null || echo '') | tr -d "'")
    if [[ -n "$ADD_REQ_PARAMS" ]]; then
      if [[ -n "$REQ_PARAMS" ]]; then
        REQ_PARAMS="$REQ_PARAMS $ADD_REQ_PARAMS"
      else
        REQ_PARAMS="$ADD_REQ_PARAMS"
      fi
    fi
    local REQ_PARAM
    for REQ_PARAM in $REQ_PARAMS; do
      local DEFAULT_VAL=${!REQ_PARAM:-}
      if [[ -z "$NEW_ONLY" ]] || [[ -z "$DEFAULT_VAL" ]]; then
        if [[ -n "${!REQ_PARAM:-}" ]]; then # it's set in the prior env def
          eval "$REQ_PARAM=''"
        else
          # check the scripts for defaults for new values
          environmentsGetDefaultFromScripts DEFAULT_VAL "$FQN_SERVICE" "$REQ_PARAM"
        fi

        local PARAM_VAL=''
        require-answer "Value for required parameter '$REQ_PARAM': " PARAM_VAL "$DEFAULT_VAL"
        eval "$REQ_PARAM='$PARAM_VAL'"
      fi
    done

    # update configuration constants
    for REQ_PARAM in $(echo $PACKAGE | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\" | keys | @sh" | tr -d "'"); do
      local CONFIG_VAL=$(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\".\"$REQ_PARAM\" | @sh" | tr -d "'")
      eval "$REQ_PARAM='$CONFIG_VAL'"
    done
  done

  updateEnvironment
}
