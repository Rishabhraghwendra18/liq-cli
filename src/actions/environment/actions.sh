source ./actionlib/gcpHelpers.sh

environment-show() {
  if [ -n "$CURR_ENV" ]; then
    echo "Current environment:"
    echo "$CURR_ENV"
    echo
    cat "$_CATALYST_ENVS/${CURR_ENV}"
  else
    echoerrandexit "Environment is not set. Try 'catalyst environment set'."
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
      eval "$SET_HELPER"
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
    select CURR_ENV_PURPOSE in test pre-production production <other>; do break; done
    if [[ "$CURR_ENV_PURPOSE" == '<other>' ]]; then
      requireAnswer 'Purpose label: ' CURR_ENV_PURPOSE
  fi

  if [[ "$CURR_ENV_TYPE" == 'gcp' ]]; then
    gatherGcpData
  fi
}

doEnvironmentList() {
  find "$_CATALYST_ENVS" -mindepth 1 -maxdepth 1 -type f -exec basename '{}' \;
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
  if [ -f "$_CATALYST_ENVS/${ENV_NAME}" ]; then
    echo "CURR_ENV='${ENV_NAME}'" > "$_CURR_ENV_FILE"
  else
    echoerrandexit "No such environment '$ENV_NAME' defined."
  fi
}

environment-delete() {
  local ENV_NAME="${1:-}"

  onConfirm() {
    rm ${_CATALYST_ENVS}/${ENV_NAME} && echo "Local '${ENV_NAME}' entry deleted."
  }

  onCancel() {
    return 0 # noop
  }

  if [[ -z "$ENV_NAME" ]]; then
    if [[ -z "$CURR_ENV" ]]; then
      echoerrandexit "No current environment defined. Try 'catalyst environment delete <env name>'."
    fi
    # else

    yesno \
      "Confirm deletion of local records for current environment '${$CURR_ENV}': (y/N)" \
      N \
      onDeleteConfirm \
      onDeleteCancel
  elif [[ -f "${_CATALYST_ENVS}/${ENV_NAME}" ]]; then
    yesno \
      "Confirm deletion of local records for environment '${$CURR_ENV}': (y/N)" \
      N \
      onDeleteConfirm \
      onDeleteCancel
  else
    echoerrandexit "No such environment '${ENV_NAME}' found. Try 'catalyst environment list'."
  fi
}
