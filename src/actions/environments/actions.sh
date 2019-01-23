requirements-environments() {
  requireCatalystfile
  requirePackage
}

# TODO: move this def
STD_ENV_PUPRPOSES='dev test pre-production production'

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

environments-add() {
  local ENV_NAME="${1:-}"
  # TODO: echo "Adding environment for project $CURR_PROJECT"
  if [ -z "${ENV_NAME}" ]; then
    requireAnswer 'Local environment name: ' ENV_NAME
  fi

  if [[ -z "${CURR_ENV_PURPOSE:-}" ]]; then
    echo "Select purpose:"
    select CURR_ENV_PURPOSE in $STD_ENV_PUPRPOSES '<other>'; do break; done
    if [[ "$CURR_ENV_PURPOSE" == '<other>' ]]; then
      requireAnswer 'Purpose label: ' CURR_ENV_PURPOSE
    fi
  fi

  local REQ_SERVICES=`project-required-services`
  local REQ_SERVICE
  CURR_ENV_SERVICES=()
  for REQ_SERVICE in $REQ_SERVICES; do
    local ANSWER
    findProvidersFor "$REQ_SERVICE" ANSWER
    CURR_ENV_SERVICES+=("$ANSWER")
    local REQ_PARAM
    for REQ_PARAM in `getRequiredParameters "$ANSWER"`; do
      local PARAM_VAL=''
      requireAnswer "Value for required parameter '$REQ_PARAM': " PARAM_VAL
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

environments-list() {
  local RESULT="$(doEnvironmentList)"
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

environments-deselect() {
  test -L $CURR_ENV_FILE && rm $CURR_ENV_FILE
  loadCurrEnv
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