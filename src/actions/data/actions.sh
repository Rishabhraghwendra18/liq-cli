source "`dirname ${BASH_SOURCE[0]}`/lib.sh"

source "`dirname ${BASH_SOURCE[0]}`/actionslib/sql.sh"

requirements-data() {
  requireEnvironment
}

usage-data-build() {
  cat <<EOF | indent
$(usageActionPrefix data)${underline}build${reset} [<iface>...]: Loads the project schema into all or
each named data service.
EOF
}

data-build() {
  local MAIN='data-build-${IFACE}'
  dataRunner "$@"
}

data-load() {
  echoerrandexit "The 'load' action has not yet been implemented."
}

data-reset() {
  local MAIN='data-reset-${IFACE}'
  dataRunner "$@"
}

data-rebuild() {
  local MAIN='data-rebuild-${IFACE}'
  dataRunner "$@"
}

dataRunner() {
  local SERVICE_STATUSES=`services-list -sp`

  local IFACE
  for IFACE in "$@"; do
    # Check all the parameters are good.
    if [[ "$IFACE" == *'-'* ]]; then
      usage-data "catalyst "
      echoerrandexit "The 'data' commands work with primary interfaces. See usage above"
    else
      local SERV
      SERV=`echo "$SERVICE_STATUSES" | grep -sE "^${IFACE}(-[^ ]*)?:"` || \
        echoerrandexit "Could not find a service to handle interface class '${IFACE}'. Check package configuration and command typos."
      echo "${SERV}" | cut -d':' -f2 | grep -s 'running' || \
        echoerrandexit "Service handling iface '$IFACE' is currently stopped. Try 'catalyst services start ${IFACE}'"
    fi
  done

  for IFACE in "$@"; do
    eval "$MAIN"
  done
}
