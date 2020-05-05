help-services() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages active runtime services."

  handleSummary "${PREFIX}${cyan_u}services${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}services${reset} :
$(echo "${SUMMARY}

Here, 'service spec' is either a service interface class or <service iface>.<service name>. A service may be selected by it's major type, so 'sql' woud select environment services 'sql' and 'sql-mysql' (etc.). Thus, 'liq services connect sql' may be used to connect to both MySQL, Postgres, etc. DBs." | fold -sw 82 | indent)
$(_help-actions-list services connect err-log list log restart start stop | indent)
EOF
}

help-services-connect() {
  cat <<EOF | _help-func-summary connect "[-c|--capabilities] <service spec>"
Connects to the named service, if possible. The '--capabilities' option will print 'interactive', and/or 'pipe', separated by newlines, to indicate the capabilities of the specified connection.
EOF
}

help-services-err-log() {
  cat <<EOF | _help-func-summary err-log "[<service spec>...]"
Displays error logs for all or named services for the current environment.
EOF
}

help-services-list() {
  cat <<EOF | _help-func-summary list "[-s|--show-status] [<service spec>...]"
Lists all or named runtime services for the current environment and their status.
EOF
}

help-services-log() {
  cat <<EOF | _help-func-summary log "[<service spec>...]"
Displays logs for all or named services for the current environment.
EOF
}

help-services-restart() {
  cat <<EOF | _help-func-summary restart "[<service spec>...]"
Effectively starts and stops the service. Restart may take advantage of specific 'restart' capabilities in the underlying service which, when available, are presumable more efficient and quicker than a stop-start.
EOF
}

help-services-start() {
  cat <<EOF | _help-func-summary start "[<service spec>...]"
Starts all or named services for the current environment.
EOF
}

help-services-stop() {
  cat <<EOF | _help-func-summary stop "[<service spec>...]"
Stops all or named services for the current environment.
EOF
}
