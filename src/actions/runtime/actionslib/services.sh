ctrlScriptEnv() {
  local ENV_SETTINGS="BASE_DIR='${BASE_DIR}' _CATALYST_ENV_LOGS='${_CATALYST_ENV_LOGS}' SERV_IFACE='${SERV_IFACE}'"
  local REQ_PARAM
  for REQ_PARAM in $(getRequiredParameters "$SERVICE_KEY"); do
    ENV_SETTINGS="$ENV_SETTINGS $REQ_PARAM='${!REQ_PARAM}'"
  done
  echo "$ENV_SETTINGS"
}

testServMatch() {
  local KEY="$1"; shift
  if [[ -z "${2:-}" ]]; then
    # if there's nothing to match, then everything matches
    return 0
  fi
  local TEST
  for TEST in "$@"; do
    if [[ "$TEST" == "$KEY" ]]; then
      return 0
    fi
  done
  return 1
}

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
  local SERVICE_KEY
  for SERVICE_KEY in ${CURR_ENV_SERVICES[@]}; do
    local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
    if testServMatch "$SERV_IFACE" "$@"; then
      local SERV_PACKAGE_NAME=`echo "$SERVICE_KEY" | cut -d: -f2`
      local SERV_NAME=`echo "$SERVICE_KEY" | cut -d: -f3`
      local SERV_PACKAGE=`npm explore "$SERV_PACKAGE_NAME" -- cat package.json`
      local SERV_SCRIPT=`echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-script\" | @sh" | tr -d "'"`

      local STATUS=`eval "$(ctrlScriptEnv) npx $SERV_SCRIPT status"`
      echo "$SERV_IFACE ($STATUS)"
    fi
  done
}

runtime-services-start() {
  mkdir -p "${_CATALYST_ENV_LOGS}"
  source "${CURR_ENV_FILE}"
  local SERVICE_KEY
  for SERVICE_KEY in ${CURR_ENV_SERVICES[@]}; do
    local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
    if testServMatch "$SERV_IFACE" "$@"; then
      local SERV_PACKAGE_NAME=`echo "$SERVICE_KEY" | cut -d: -f2`
      local SERV_NAME=`echo "$SERVICE_KEY" | cut -d: -f3`
      local SERV_PACKAGE=`npm explore "$SERV_PACKAGE_NAME" -- cat package.json`
      local SERV_SCRIPT=`echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-script\" | @sh" | tr -d "'"`
      rm "${_CATALYST_ENV_LOGS}/${SERV_IFACE}.log"
      rm "${_CATALYST_ENV_LOGS}/${SERV_IFACE}.err"

      echo "Starting ${SERV_IFACE}..."
      eval "$(ctrlScriptEnv) npx $SERV_SCRIPT start"
      sleep 1
      if [[ `wc -l "${_CATALYST_ENV_LOGS}/${SERV_IFACE}.err" | awk '{print $1}'` -gt 0 ]]; then
        cat "${_CATALYST_ENV_LOGS}/${SERV_IFACE}.err"
        echoerr "Possible errors while starting ${SERV_IFACE}. See error log above."
      fi
      runtime-services-list "${SERV_IFACE}"
    fi
  done
}

runtime-services-stop() {
  source "${CURR_ENV_FILE}"
  local SERVICE_KEY
  for SERVICE_KEY in ${CURR_ENV_SERVICES[@]}; do
    local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
    if testServMatch "$SERV_IFACE" "$@"; then
      local SERV_PACKAGE_NAME=`echo "$SERVICE_KEY" | cut -d: -f2`
      local SERV_NAME=`echo "$SERVICE_KEY" | cut -d: -f3`
      local SERV_PACKAGE=`npm explore "$SERV_PACKAGE_NAME" -- cat package.json`
      local SERV_SCRIPT=`echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-script\" | @sh" | tr -d "'"`

      echo "Stopping ${SERV_IFACE}..."
      eval "$(ctrlScriptEnv) npx $SERV_SCRIPT stop"
      sleep 1
      runtime-services-list "${SERV_IFACE}"
    fi
  done
}

runtime-services-restart() {
  echo "TODO"
}

runtime-services-detail() {
  echo "TODO"
}
