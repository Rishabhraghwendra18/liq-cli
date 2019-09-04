updateEnvironment() {
  # expects caller to define globals, either initilized or read from env file.
  # CURR_ENV_SERVICES CURR_ENV_PURPOSE
  local ENV_PATH="$LIQ_ENV_DB/${PACKAGE_NAME}/${ENV_NAME}"
  mkdir -p "`dirname "$ENV_PATH"`"

  # TODO: use '${CURR_ENV_SERVICES[@]@Q}' once upgraded to bash 4.4
  cat <<EOF > "$ENV_PATH"
CURR_ENV_SERVICES=(${CURR_ENV_SERVICES[@]:-})
CURR_ENV_PURPOSE='${CURR_ENV_PURPOSE}'
EOF

  local SERV_KEY REQ_PARAM
  # TODO: again, @Q when available
  for SERV_KEY in ${CURR_ENV_SERVICES[@]:-}; do
    for REQ_PARAM in $(getRequiredParameters "$SERV_KEY"); do
      if [[ -z "${!REQ_PARAM:-}" ]]; then
        echoerrandexit "Did not find definition for required parameter '${REQ_PARAM}'."
      fi
      cat <<EOF >> "$ENV_PATH"
$REQ_PARAM='${!REQ_PARAM}'
EOF
    done
  done

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  for REQ_SERV_IFACE in $REQ_SERV_IFACES; do
    for REQ_PARAM in $(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"params-req\" | @sh" | tr -d "'"); do
      if [[ -z "${!REQ_PARAM:-}" ]]; then
        echoerrandexit "Did not find definition for required parameter '${REQ_PARAM}'."
      fi
      cat <<EOF >> "$ENV_PATH"
$REQ_PARAM='${!REQ_PARAM}'
EOF
    done

    for REQ_PARAM in $(getConfigConstants "$REQ_SERV_IFACE"); do
      local CONFIG_VAL=$(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\".\"$REQ_PARAM\" | @sh" | tr -d "'")
      cat <<EOF >> "$ENV_PATH"
$REQ_PARAM='$CONFIG_VAL'
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
