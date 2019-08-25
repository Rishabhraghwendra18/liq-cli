help-services() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}services${reset} <action>: Manages active runtime services." || cat <<EOF
${PREFIX}${cyan_u}services${reset} :
  ${underline}list${reset} [-s|--show-status] [<service spec>...] : Lists all or named runtime
    services for the current environment and their status.
  ${underline}start${reset} [<service spec>...] : Starts all or named services for the current
    environment.
  ${underline}stop${reset} [<service spec>...] : Stops all or named services for the current
    environment.
  ${underline}log${reset} [<service spec>...] : Displays logs for all or named services for the
    current environment.
  ${underline}err-log${reset} [<service spec>...] : Displays error logs for all or named services
    for the current environment.
  ${underline}connect${reset} [-c|--capabilities] <service spec> : Connects to the named service, if
    possible. The '--capabilities' option will print 'interactive', and/or
    'pipe', separated by newlines, to indicate the capabilities of the specified
    connection.

Where '${cyan}service spec${reset}' is either a service interface class or
<service iface>.<service name>. A service may be selected by it's major type, so
'sql' woud select environment services 'sql' and 'sql-mysql' (etc.). Thus,
'catalyst services connect sql' may be used to connect to both MySQL,
Postgres, etc. DBs.
EOF
}
