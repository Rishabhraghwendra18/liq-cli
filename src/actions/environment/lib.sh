doEnvironmentList() {
  local PACKAGE_NAME=`cat $BASE_DIR/package.json | jq --raw-output ".name"`
  find "${_CATALYST_ENVS}/${PACKAGE_NAME}" -mindepth 1 -maxdepth 1 -type f -exec basename '{}' \;
}

updateEnvironment() {
  local PACKAGE_NAME=`cat $BASE_DIR/package.json | jq --raw-output ".name"`

  local ENV_PATH="$_CATALYST_ENVS/${PACKAGE_NAME}/${ENV_NAME}"
  mkdir -p "`dirname "$ENV_PATH"`"

  # the [@]@Q expands the array and puts each element in quotes
  cat <<EOF > "$ENV_PATH"
CURR_ENV_SERVICES=(${CURR_ENV_SERVICES[@]@Q})
EOF
}

updateEnvParam() {
  local KEY="$1"
  local VALUE="$2"

  local VAR_NAME=${KEY//:/_}
  VAR_NAME=${VAR_NAME}// /_}
  VAR_NAME="CURR_ENV_${VAR_NAME^^}"

  declare "$VAR_NAME"="$VALUE"
}

findProvidersFor() {
  local REQ_SERVICE="${1}"
  local RESULT_VAR_NAME="${2}"
  local NPM_ROOT=`npm root`

  local CAT_PACKAGE_PATHS=`find "$NPM_ROOT"/\@* -maxdepth 2 -name ".catalyst"`
  CAT_PACKAGE_PATHS="${CAT_PACKAGE_PATHS} "`find "$NPM_ROOT" -maxdepth 2 -name ".catalyst"`
  declare -a SERVICES
  declare -a SERVICE_PACKAGES
  local CAT_PACKAGE_PATH
  for CAT_PACKAGE_PATH in $CAT_PACKAGE_PATHS; do
    local NPM_PACKAGE=`cat $(dirname $CAT_PACKAGE_PATH)/package.json`
    local PACKAGE_NAME=`cat $(dirname $CAT_PACKAGE_PATH)/package.json | jq --raw-output ".name"`
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

  echo "Select provider for required service '$REQ_SERVICE':"
  local PROVIDER
  # TODO: is there a better way to preserve the word boundries?
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
