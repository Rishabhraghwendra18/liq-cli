source ./actionslib/sql.sh

requirements-data() {
  requireEnvironment
}

help-data-build() {
  cat <<EOF | indent
$(helpActionPrefix data)${underline}build${reset} [<iface>...]: Loads the project schema into all or
each named data service.
EOF
}

data-build() {
  local MAIN='data-build-${IFACE}'
  dataRunner "$@"
}

data-dump() {
  local TMP
  TMP=$(setSimpleOptions OUTPUT_SET_NAME= FORCE -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  local MAIN=$(cat <<'EOF'
    local OUT_FILE
    if [[ -n "${OUTPUT_SET_NAME}" ]]; then
      OUT_FILE="${BASE_DIR}/data/${IFACE}/${OUTPUT_SET_NAME}/all.sql"
      if [[ -d "$(dirname "${OUT_FILE}")" ]] && [[ -z "$FORCE" ]]; then
        if [[ -f "$OUT_FILE" ]]; then
          function clearPrev() { rm "$OUT_FILE"; }
          function cancelDump() { echo "Bailing out..."; exit 0; }
          yesno "Found existing dump for '$OUTPUT_SET_NAME'. Would you like to replace? (y\N) " \
            N \
            clearPrev \
            cancelDump
        else
          echoerrandexit "It appears there is an existing, manually created '${OUTPUT_SET_NAME}' data set. You must remove it manually to re-use that name."
        fi
      fi
    fi
    data-dump-${IFACE}
EOF
)
  dataRunner "$@"
}

data-load() {
  if (( $# != 1 )); then
    contextHelp
    echoerrandexit "Must specify exactly one data set name."
  fi

  local MAIN='data-load-${IFACE}'
  # notice 'load' is a little different
  local SET_NAME="${1}"
  dataRunner
}

data-reset() {
  local MAIN='data-reset-${IFACE}'
  dataRunner "$@"
}

data-rebuild() {
  local MAIN='data-rebuild-${IFACE}'
  dataRunner "$@"
}

data-test() {
  local TMP
  TMP=$(setSimpleOptions SKIP_REBUILD -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  local MAIN='data-test-${IFACE}'
  dataRunner "$@"
}

dataRunner() {
  local SERVICE_STATUSES
  SERVICE_STATUSES=`services-list -sp`

  local IFACES="$@"
  if (( $# == 0 )); then
    IFACES=$(echo "$PACKAGE" | jq --raw-output '.catalyst.requires | .[] | .iface | capture("(?<iface>sql)") | .iface' | tr -d '"')
  fi

  local IFACE
  for IFACE in $IFACES; do
    # Check all the parameters are good.
    if [[ "$IFACE" == *'-'* ]]; then
      help-data "catalyst "
      echoerrandexit "The 'data' commands work with primary interfaces. See help above"
    else
      local SERV
      SERV="$(echo "$SERVICE_STATUSES" | grep -E "^${IFACE}(.[^: ]+)?:")" || \
        echoerrandexit "Could not find a service to handle interface class '${IFACE}'. Check package configuration and command typos."
      local SERV_SCRIPT NOT_RUNNING SERV_STATUS
      local SOME_RUNNING=false
      while read SERV_STATUS; do
        SERV_SCRIPT="$(echo "${SERV_STATUS}" | cut -d':' -f1)"
        echo "${SERV_STATUS}" | cut -d':' -f2 | grep -q 'running' && SOME_RUNNING=true || \
          NOT_RUNNING="${NOT_RUNNING} ${SERV_SCRIPT}"
      done <<< "${SERV}"
      if [[ -n "${NOT_RUNNING}" ]]; then
        if [[ "$SOME_RUNNING" == true ]]; then
          echoerrandexit "Some necessary processes providing the '${IFACE}' service are not running. Try:\ncatalyst services start${NOT_RUNNING}"
        else
          echoerrandexit "The '${IFACE}' service is not available. Try:\ncatalyst services start ${IFACE}"
        fi
      fi
    fi
  done

  if [[ -z "$IFACES" ]]; then
    source "${CURR_ENV_FILE}"
    IFACES=$(echo ${CURR_ENV_SERVICES[@]:-} | tr " " "\n" | sed -Ee 's/^(sql).+/\1/')
  fi

  for IFACE in $IFACES; do
    eval "$MAIN"
  done
}
