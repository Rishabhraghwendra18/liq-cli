runtime-services() {
  if [[ $# -eq 0 ]]; then
    runtime-services-list
  elif [[ "$1" == "-s" ]]; then
    shift
    runtime-services-start "$@"
  elif [[ "$1" == "-S" ]]; then
    shift
    runtime-services-stop "$@"
  elif [[ "$1" == "-r" ]]; then
    shift
    runtime-services-restart "$@"
  else
    runtime-services-detail "$@"
  fi
}

runtime-services-list() {
  source "${CURR_ENV_FILE}"
  local SERVICE
  for SERVICE in ${CURR_ENV_SERVICES[@]}; do
    local SERV_IFACE=`echo "$SERVICE" | cut -d: -f1`
    local SERV_PACKAGE_NAME=`echo "$SERVICE" | cut -d: -f2`
    local SERV_NAME=`echo "$SERVICE" | cut -d: -f3`
    local SERV_PACKAGE=`npm explore "$SERV_PACKAGE_NAME" -- cat package.json`
    local SERV_SCRIPT=`echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-script\" | @sh" | tr -d "'"`

    echo "$SERV_IFACE ($(npx $SERV_SCRIPT status))"
  done
}

runtime-services-start() {
  echo "TODO"
}

runtime-services-stop() {
  echo "TODO"
}

runtime-services-restart() {
  echo "TODO"
}

runtime-services-detail() {
  echo "TODO"
}
