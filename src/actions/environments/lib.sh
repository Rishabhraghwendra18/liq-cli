doEnvironmentList() {
  if [[ ! -d "${_CATALYST_ENVS}/${PACKAGE_NAME}" ]]; then
    return
  fi
  local CURR_ENV
  if [[ -L "${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env" ]]; then
    CURR_ENV=`readlink "${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env" | xargs basename`
  fi
  local ENV
  for ENV in `find "${_CATALYST_ENVS}/${PACKAGE_NAME}" -mindepth 1 -maxdepth 1 -type f -not -name "*~" -exec basename '{}' \; | sort`; do
    ( ( test "$ENV" == "${CURR_ENV:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ENV"
  done
}

updateEnvironment() {
  local ENV_PATH="$_CATALYST_ENVS/${PACKAGE_NAME}/${ENV_NAME}"
  mkdir -p "`dirname "$ENV_PATH"`"

  # TODO: use '${CURR_ENV_SERVICES[@]@Q}' once upgraded to bash 4.4
  cat <<EOF > "$ENV_PATH"
CURR_ENV_SERVICES=(${CURR_ENV_SERVICES[@]})
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

environmentsFindProvidersFor() {
  local REQ_SERVICE="${1}"
  local RESULT_VAR_NAME="${2}"
  local DEFAULT="${3:-}"

  local CAT_PACKAGE_PATHS=`getCatPackagePaths`
  declare -a SERVICES
  declare -a SERVICE_PACKAGES
  local CAT_PACKAGE_PATH
  for CAT_PACKAGE_PATH in $CAT_PACKAGE_PATHS; do
    local NPM_PACKAGE=`cat "${CAT_PACKAGE_PATH}/package.json"`
    local PACKAGE_NAME=`cat "${CAT_PACKAGE_PATH}/package.json" | jq --raw-output ".name"`
    for SERVICE in `echo "$NPM_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select((.\"interface-classes\" | .[] | select(. == \"$REQ_SERVICE\")) | length > 0) | .name | @sh" | tr -d "'"`; do
      SERVICES+=("$SERVICE")
      SERVICE_PACKAGES+=("$PACKAGE_NAME")
    done
  done

  declare -a PROVIDER_OPTIONS
  local I=0
  while (($I < ${#SERVICES[@]})); do
    PROVIDER_OPTIONS+="${SERVICES[$I]} (from ${SERVICE_PACKAGES[$I]})"
    I=$(($I + 1))
  done
  if (( $I == 0 )); then
    echoerrandexit "Could not find any providers for '$REQ_SERVICE'."
  fi

  echo "Select provider for required service '$REQ_SERVICE':"
  local PROVIDER
  # TODO: is there a better way to preserve the word boundries? We can use the '${ARRAY[@]@Q}' construct in bash 4.4
  eval 'select PROVIDER in "<cancel>" '$(printf "'%s' " "${PROVIDER_OPTIONS[@]}")'; do
    case "$PROVIDER" in
      "<cancel>")
        exit;;
      *)
        break;;
    esac
  done'

  local SELECTED_PROVIDER=`echo "$PROVIDER" | sed -E -e 's/[^(]+\(from ([^)]+)\)/\1/'`
  local SELECTED_SERVICE=`echo "$PROVIDER" | sed -E -e 's/ \(from .+//'`

  eval "$RESULT_VAR_NAME='${REQ_SERVICE}:${SELECTED_PROVIDER}:${SELECTED_SERVICE}'"
}
