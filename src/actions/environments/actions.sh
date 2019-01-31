requirements-environments() {
  requireCatalystfile
  requirePackage
}

# TODO: move this def
STD_ENV_PUPRPOSES='dev test pre-production production'

environments-add() {
  local ENV_NAME="${1:-}"
  # TODO: echo "Adding environment for project $CURR_PROJECT"
  if [ -z "${ENV_NAME}" ]; then
    requireAnswer 'Local environment name: ' ENV_NAME
  fi

  if [[ -z "${CURR_ENV_PURPOSE:-}" ]]; then
    PS3="Select purpose: "
    selectDoneCancelAllOther CURR_ENV_PURPOSE $STD_ENV_PUPRPOSES
  fi

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  CURR_ENV_SERVICES=()
  for REQ_SERV_IFACE in $REQ_SERV_IFACES; do
    # select the service provider
    local ANSWER
    environmentsFindProvidersFor "$REQ_SERV_IFACE" ANSWER
    CURR_ENV_SERVICES+=("$ANSWER")

    # define required params
    local REQ_PARAM
    for REQ_PARAM in `getRequiredParameters "$ANSWER"`; do
      local DEFAULT_VAL
      environmentsGetDefaultFromScripts DEFAULT_VAL "$ANSWER" "$REQ_PARAM"

      local PARAM_VAL=''
      requireAnswer "Value for required parameter '$REQ_PARAM': " PARAM_VAL "$DEFAULT_VAL"
      eval "$REQ_PARAM='$PARAM_VAL'"
    done
  done

  updateEnvironment

  function selectNewEnv() {
    environments-select "${ENV_NAME}"
  }

  yesno "Would you like to select the newly added '${ENV_NAME}'? (Y\n) " \
    Y \
    selectNewEnv
}

environments-delete() {
  local ENV_NAME="${1:-}"
  test -n "$ENV_NAME" || echoerrandexit "Must specify enviromnent for deletion."

  onDeleteConfirm() {
    rm ${_CATALYST_ENVS}/${PACKAGE_NAME}/${ENV_NAME} && echo "Local '${ENV_NAME}' entry deleted."
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
  elif [[ -f "${_CATALYST_ENVS}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
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
  test -L $CURR_ENV_FILE && rm $CURR_ENV_FILE
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
  local CURR_ENV_FILE="${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env"
  if [[ -f "${_CATALYST_ENVS}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    test -L $CURR_ENV_FILE && rm $CURR_ENV_FILE
    cd "${_CATALYST_ENVS}/${PACKAGE_NAME}/" && ln -s "./${ENV_NAME}" curr_env
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
      requireAnswer 'Parameter key: ' KEY
    fi
    requireAnswer 'Parameter value: ' VALUE
    updateEnvParam "$KEY" "$VALUE"
  else
    echoerrandexit "Unexpected number of arguments to 'catalyst environment set'."
    # TODO: print action specific usage would be nice
  fi

  updateEnvironment
}

environments-show() {
  local ENV_NAME="${1:-}"

  if [[ -n "$ENV_NAME" ]]; then
    if [[ ! -f "${_CATALYST_ENVS}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
      echoerrandexit "No such environment '$ENV_NAME' found for '$PACKAGE_NAME'."
    fi
  else
    if [[ ! -f "${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env" ]]; then
      echoerrandexit "No environment selected for '$PACKAGE_NAME'. Try 'catalyst environment select' or 'catalyst environment show <name>'."
    fi
    ENV_NAME='curr_env'
  fi
  cat "${_CATALYST_ENVS}/${PACKAGE_NAME}/${ENV_NAME}"

  # if [[ -n "$CURR_ENV" ]] && [[ "$CURR_ENV" == "$ENV_NAME" ]]; then
  #  echo "Current environment:"
  #  echo "$CURR_ENV"
  #  echo
  #fi
  #local ENV_DB="${_CATALYST_ENVS}/${ENV_NAME}"
  #if [[ -f "$ENV_DB" ]]; then
  #  cat "$ENV_DB"
  #else
  #  echoerrandexit "No such environment '${ENV_NAME}'."
  #fi
}

# TODO: this shares a lot of code with environments-add
environments-update() {
  local ENV_NAME="${1:-}"

  if [[ -z "${ENV_NAME}" ]]; then
    if [[ -L "${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env" ]]; then
      requireEnvironment
      ENV_NAME="$CURR_ENV"
    else
      selectOneCancel ENV_NAME $(environments-list --list-only)
    fi
  fi

  if [[ ! -f "${_CATALYST_ENVS}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    contextHelp
    echoerrandexit "Unknown environment name '${ENV_NAME}'."
  else
    source "${_CATALYST_ENVS}/${PACKAGE_NAME}/${ENV_NAME}"
  fi

  local SELECT_DEFAULT="$CURR_ENV_PURPOSE"
  unset CURR_ENV_PURPOSE
  PS3="Select purpose: "
  selectDoneCancelOtherDefault CURR_ENV_PURPOSE $STD_ENV_PUPRPOSES

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  local PRIOR_ENV_SERVICES="${CURR_ENV_SERVICES[@]}"
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
    local ANSWER
    environmentsFindProvidersFor "$REQ_SERV_IFACE" ANSWER
    CURR_ENV_SERVICES+=("$ANSWER")

    for REQ_PARAM in `getRequiredParameters "$ANSWER"`; do
      local DEFAULT_VAL=${!REQ_PARAM:-}
      if [[ -n "${!REQ_PARAM:-}" ]]; then # it's set in the prior env def
        eval "$REQ_PARAM=''"
      else
        # check the scripts for defaults for new values
        environmentsGetDefaultFromScripts DEFAULT_VAL "$ANSWER" "$REQ_PARAM"
      fi

      local PARAM_VAL=''
      requireAnswer "Value for required parameter '$REQ_PARAM': " PARAM_VAL "$DEFAULT_VAL"
      eval "$REQ_PARAM='$PARAM_VAL'"
    done
  done

  updateEnvironment
}
