source "`dirname ${BASH_SOURCE[0]}`/actionslib/gcpHelpers.sh"
source "`dirname ${BASH_SOURCE[0]}`/actionslib/helpers.sh"

environment-show() {
  local ENV_NAME=`getEnv "${1:-}"`
  test -n "$ENV_NAME" || exit 1

  if [[ -n "$CURR_ENV" ]] && [[ "$CURR_ENV" == "$ENV_NAME" ]]; then
    echo "Current environment:"
    echo "$CURR_ENV"
    echo
  fi
  local ENV_DB="${_CATALYST_ENVS}/${ENV_NAME}"
  if [[ -f "$ENV_DB" ]]; then
    cat "$ENV_DB"
  else
    echoerrandexit "No such environment '${ENV_NAME}'."
  fi
}

environment-set() {
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
    local SET_HELPER=`setHelperFunctionName "$KEY"`
    if [[ -n "$SET_HELPER" ]]; then
      eval "$SET_HELPER '$ENV_NAME'"
    else
      requireAnswer 'Parameter value: ' VALUE
      updateEnvParam "$KEY" "$VALUE"
    fi
  else
    echoerrandexit "Unexpected number of arguments to 'catalyst environment set'."
    # TODO: print action specific usage would be nice
  fi

  updateEnvironment
}

environment-add() {
  local ENV_NAME="${1:-}"
  if [ -z "${1}" ]; then
    requireAnswer 'Local environment name: ' ENV_NAME
  fi

  if [[ -z "$CURR_ENV_TYPE" ]]; then
    echo "Select type:"
    select CURR_ENV_TYPE in local gcp; do break; done
  fi

  if [[ -z "$CURR_ENV_PURPOSE" ]]; then
    echo "Select purpose:"
    select CURR_ENV_PURPOSE in dev test pre-production production '<other>'; do break; done
    if [[ "$CURR_ENV_PURPOSE" == '<other>' ]]; then
      requireAnswer 'Purpose label: ' CURR_ENV_PURPOSE
    fi
  fi

  if [[ "$CURR_ENV_TYPE" == 'gcp' ]]; then
    gatherGcpData
  fi

  function selectNewEnv() {
    environment-select "${ENV_NAME}"
  }

  yesno "Would you like to select the newly added '${ENV_NAME}'? (Y\n) " \
    Y \
    selectNewEnv
}

environment-list() {
  if test -n "$(doEnvironmentList)"; then
    doEnvironmentList
  else
    echo "No environments defined. Use 'catalyst environment add'."
  fi
}

environment-select() {
  local ENV_NAME="${1:-}"
  if [[ -z "$ENV_NAME" ]]; then
    if test -z "$(doEnvironmentList)"; then
      echoerrandexit "No environments defined. Try 'catalyst environment add'."
    fi
    echo "Select environment:"
    select ENV_NAME in `doEnvironmentList`; do break; done
  fi
  if [[ "${ENV_NAME}" == 'none' ]]; then
    rm "$_CURR_ENV_FILE"
  elif [[ -f "$_CATALYST_ENVS/${ENV_NAME}" ]]; then
    echo "CURR_ENV='${ENV_NAME}'" > "$_CURR_ENV_FILE"
  else
    echoerrandexit "No such environment '$ENV_NAME' defined."
  fi
  # if not error and exit
  loadCurrEnv
}

environment-delete() {
  local ENV_NAME=`getEnv "${1:-}"`
  test -n "$ENV_NAME" || die

  onDeleteConfirm() {
    rm ${_CATALYST_ENVS}/${ENV_NAME} && echo "Local '${ENV_NAME}' entry deleted."
  }

  onDeleteCurrent() {
    onDeleteConfirm
    environment-select 'none'
  }

  onDeleteCancel() {
    return 0 # noop
  }

  if [[ -z "$ENV_NAME" ]] || [[ "$ENV_NAME" == "$CURR_ENV" ]]; then
    if [[ -z "$CURR_ENV" ]]; then
      echoerrandexit "No current environment defined. Try 'catalyst environment delete <env name>'."
    fi
    # else
    ENV_NAME="$CURR_ENV"
    yesno \
      "Confirm deletion of local records for current environment '${CURR_ENV}': (y/N) " \
      N \
      onDeleteCurrent \
      onDeleteCancel
  elif [[ -f "${_CATALYST_ENVS}/${ENV_NAME}" ]]; then
    yesno \
      "Confirm deletion of local records for environment '${ENV_NAME}': (y/N) " \
      N \
      onDeleteConfirm \
      onDeleteCancel
  else
    echoerrandexit "No such environment '${ENV_NAME}' found. Try 'catalyst environment list'."
  fi
}
