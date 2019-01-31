doEnvironmentList() {
  local TMP
  TMP=$(setSimpleOptions LIST_ONLY -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ ! -d "${_CATALYST_ENVS}/${PACKAGE_NAME}" ]]; then
    return
  fi
  local CURR_ENV
  if [[ -L "${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env" ]]; then
    CURR_ENV=`readlink "${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env" | xargs basename`
  fi
  local ENV
  for ENV in `find "${_CATALYST_ENVS}/${PACKAGE_NAME}" -mindepth 1 -maxdepth 1 -type f -not -name "*~" -exec basename '{}' \; | sort`; do
    ( ( test -z "$LIST_ONLY" && test "$ENV" == "${CURR_ENV:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ENV"
  done
}

updateEnvironment() {
  local ENV_PATH="$_CATALYST_ENVS/${PACKAGE_NAME}/${ENV_NAME}"
  mkdir -p "`dirname "$ENV_PATH"`"

  # TODO: use '${CURR_ENV_SERVICES[@]@Q}' once upgraded to bash 4.4
  cat <<EOF > "$ENV_PATH"
CURR_ENV_SERVICES=(${CURR_ENV_SERVICES[@]})
CURR_ENV_PURPOSE='${CURR_ENV_PURPOSE}'
EOF

  local SERV_KEY
  # TODO: again, @Q when available
  for SERV_KEY in ${CURR_ENV_SERVICES[@]}; do
    for REQ_PARAM in `getRequiredParameters "$SERV_KEY"`; do
      cat <<EOF >> "$ENV_PATH"
$REQ_PARAM='${!REQ_PARAM}'
EOF
    done
  done
}

updateEnvParam() {
  local KEY="$1"
  local VALUE="$2"

  local VAR_NAME=${KEY//:/_}
  VAR_NAME=${VAR_NAME}// /_}
  VAR_NAME="CURR_ENV_${VAR_NAME^^}"

  declare "$VAR_NAME"="$VALUE"
}

environmentsServiceDescription() {
  local VAR_NAME="$1"
  local SERVICE="$2"
  local PACKAGE_NAME="$3"

  eval "$VAR_NAME='${SERVICE} from ${PACKAGE_NAME}'"
}

environmentsFindProvidersFor() {
  local REQ_SERVICE="${1}"
  local RESULT_VAR_NAME="${2}"
  local DEFAULT="${3:-}"

  local CAT_PACKAGE_PATHS=`getCatPackagePaths`
  local SERVICES SERVICE_PACKAGES PROVIDER_OPTIONS CAT_PACKAGE_PATH
  for CAT_PACKAGE_PATH in "${BASE_DIR}" $CAT_PACKAGE_PATHS; do
    local NPM_PACKAGE=`cat "${CAT_PACKAGE_PATH}/package.json"`
    local PACKAGE_NAME=`cat "${CAT_PACKAGE_PATH}/package.json" | jq --raw-output ".name"`
    local SERVICE
    for SERVICE in `echo "$NPM_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select((.\"interface-classes\" | .[] | select(. == \"$REQ_SERVICE\")) | length > 0) | .name | @sh" | tr -d "'"`; do
      SERVICES=$((test -n "$SERVICE" && echo "$SERVICES '$SERVICE'") || echo "'$SERVICE'")
      SERVICE_PACKAGES=$((test -n "$SERVICE_PACKAGES" && echo "$SERVICE_PACKAGES '$PACKAGE_NAME'") || echo "'$PACKAGE_NAME'")
      local SERV_DESC
      environmentsServiceDescription SERV_DESC "$SERVICE" "$PACKAGE_NAME"
      PROVIDER_OPTIONS=$((test -n "$PROVIDER_OPTIONS" && echo "$PROVIDER_OPTIONS '${SERV_DESC}'") || echo "'${SERV_DESC}'")
    done
  done

  if test -z "$SERVICES"; then
    echoerrandexit "Could not find any providers for '$REQ_SERVICE'."
  fi

  echo "Select provider for required service '$REQ_SERVICE':"
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
    eval "selectOneCancel PROVIDER $PROVIDER_OPTIONS"
  else
    eval "selectOneCancelDefault PROVIDER $PROVIDER_OPTIONS"
  fi

  local SELECTED_PROVIDER=`echo "$PROVIDER" | sed -E -e 's/[^(]+from ([^)]+)/\1/'`
  local SELECTED_SERVICE=`echo "$PROVIDER" | sed -E -e 's/ from .+//'`

  eval "$RESULT_VAR_NAME='${REQ_SERVICE}:${SELECTED_PROVIDER}:${SELECTED_SERVICE}'"
}
