doEnvironmentList() {
  local TMP
  TMP=$(setSimpleOptions LIST_ONLY -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ ! -d "${LIQ_ENV_DB}/${PACKAGE_NAME}" ]]; then
    return
  fi
  local CURR_ENV
  if [[ -L "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ]]; then
    CURR_ENV=`readlink "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" | xargs basename`
  fi
  local ENV
  for ENV in `find "${LIQ_ENV_DB}/${PACKAGE_NAME}" -mindepth 1 -maxdepth 1 -type f -not -name "*~" -exec basename '{}' \; | sort`; do
    ( ( test -z "$LIST_ONLY" && test "$ENV" == "${CURR_ENV:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ENV"
  done
}

environmentsServiceDescription() {
  local VAR_NAME="$1"
  local SERVICE="$2"
  local PACKAGE_NAME="$3"

  eval "$VAR_NAME='${SERVICE} from ${PACKAGE_NAME}'"
}

environmentsFigureFqnService() {
  local VAR_NAME="$1"
  local REQ_SERVICE="$2"
  local SERVICE_DESC="$3"

  local SELECTED_PROVIDER=$(echo "$SERVICE_DESC" | sed -E -e 's/[^ ]+ from (.+)/\1/')
  local SELECTED_SERVICE=$(echo "$SERVICE_DESC" | sed -E -e 's/ from .+//')

  eval "$VAR_NAME='${REQ_SERVICE}:${SELECTED_PROVIDER}:${SELECTED_SERVICE}'"
}

environmentsFindProvidersFor() {
  local REQ_SERVICE="${1}"
  # TODO: put var name first for consistency
  local RESULT_VAR_NAME="${2}"
  local DEFAULT="${3:-}"

  local CAT_PACKAGE_PATHS=`getCatPackagePaths`
  local SERVICES SERVICE_PACKAGES PROVIDER_OPTIONS CAT_PACKAGE_PATH
  for CAT_PACKAGE_PATH in "${BASE_DIR}" $CAT_PACKAGE_PATHS; do
    local NPM_PACKAGE=$(cat "${CAT_PACKAGE_PATH}/package.json")
    local PACKAGE_NAME=$(echo "$NPM_PACKAGE" | jq --raw-output ".name")
    local SERVICE
    for SERVICE in $((echo "$NPM_PACKAGE" | jq --raw-output ".catalyst.provides | .[] | select((.\"interface-classes\" | .[] | select(. == \"$REQ_SERVICE\")) | length > 0) | .name | @sh" 2>/dev/null || echo '') | tr -d "'"); do
      SERVICES=$((test -n "$SERVICE" && echo "$SERVICES '$SERVICE'") || echo "'$SERVICE'")
      SERVICE_PACKAGES=$((test -n "$SERVICE_PACKAGES" && echo "$SERVICE_PACKAGES '$PACKAGE_NAME'") || echo "'$PACKAGE_NAME'")
      local SERV_DESC
      environmentsServiceDescription SERV_DESC "$SERVICE" "$PACKAGE_NAME"
      list-add-item PROVIDER_OPTIONS "$SERV_DESC"
    done
  done

  if test -z "$SERVICES"; then
    echoerrandexit "Could not find any providers for '$REQ_SERVICE'."
  fi

  PS3="Select provider for required service '$REQ_SERVICE': "
  local PROVIDER
  if [[ -z "${SELECT_DEFAULT:-}" ]]; then
    # TODO: is there a better way to preserve the word boundries? We can use the '${ARRAY[@]@Q}' construct in bash 4.4
    # We 'eval' because 'PROVIDER_OPTIONS' may have quoted words, but if we just
    # expanded it directly, we could options like:
    # 1) 'foo
    # 2) bar'
    # 3) 'baz'
    # instead of:
    # 1) foo bar
    # 2) baz
    eval "selectOneCancel PROVIDER PROVIDER_OPTIONS"
  else
    eval "selectOneCancelDefault PROVIDER PROVIDER_OPTIONS"
  fi

  environmentsFigureFqnService "$RESULT_VAR_NAME" "$REQ_SERVICE" "$PROVIDER"
}

environmentsGetDefaultFromScripts() {
  local VAR_NAME="$1"
  local FQ_SERVICE="$2"
  local REQ_PARAM="$3"

  local SERV_SCRIPT
  for SERV_SCRIPT in `getCtrlScripts "$FQ_SERVICE"`; do
    DEFAULT_VAL=`runServiceCtrlScript --no-env "$SERV_SCRIPT" param-default "$CURR_ENV_PURPOSE" "$REQ_PARAM"` \
      || echoerrandexit "Service script '$SERV_SCRIPT' does not support 'param-default'. Perhaps the package is out of date?"
    if [[ -n "$DEFAULT_VAL" ]]; then
      eval "$VAR_NAME='$DEFAULT_VAL'"
      break
    fi
  done
}
