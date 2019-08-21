function environmentsGatherEnvironmentSettings() {
  # Expects caller to declare:
  # local ENV_NAME REQ_PARAMS
  # CURR_ENV_SERVICES as global
  environmentsCheckCloudSDK

  ENV_NAME="${1:-}"

  if [ -z "${ENV_NAME}" ]; then
    require-answer 'Local environment name: ' ENV_NAME
  fi

  if [[ -z "${CURR_ENV_PURPOSE:-}" ]]; then
    PS3="Select purpose: "
    selectOneCancelOther CURR_ENV_PURPOSE STD_ENV_PURPOSES
  fi

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  for REQ_SERV_IFACE in $REQ_SERV_IFACES; do
    # select the service provider
    local FQN_SERVICE
    environmentsFindProvidersFor "$REQ_SERV_IFACE" FQN_SERVICE
    CURR_ENV_SERVICES+=("$FQN_SERVICE")

    # define required params
    local SERV_REQ_PARAMS
    SERV_REQ_PARAMS=$(getRequiredParameters "$FQN_SERVICE")
    local ADD_REQ_PARAMS=$((echo "$PACKAGE" | jq -e --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"params-req\" | @sh" 2> /dev/null || echo '') | tr -d "'")
    if [[ -n "$ADD_REQ_PARAMS" ]]; then
      list-add-item SERV_REQ_PARAMS "$ADD_REQ_PARAMS"
    fi

    local REQ_PARAM
    for REQ_PARAM in $SERV_REQ_PARAMS; do
      local DEFAULT_VAL
      environmentsGetDefaultFromScripts DEFAULT_VAL "$FQN_SERVICE" "$REQ_PARAM"
      if [[ -n "$DEFAULT_VAL" ]]; then
        eval "${REQ_PARAM}_DEFAULT_VAL='$DEFAULT_VAL'"
      fi
    done

    # and set configuration constants
    for REQ_PARAM in $(echo $PACKAGE | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\" | keys | @sh" | tr -d "'"); do
      local CONFIG_VAL=$(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\".\"$REQ_PARAM\" | @sh" | tr -d "'")
      eval "$REQ_PARAM='$CONFIG_VAL'"
    done
    list-add-item REQ_PARAMS "$SERV_REQ_PARAMS"
  done
}

function environmentsAskIfSelect() {
  function selectNewEnv() {
    environments-select "${ENV_NAME}"
  }

  yesno "Would you like to select the newly added '${ENV_NAME}'? (Y\n) " \
    Y \
    selectNewEnv \
    || true
}
