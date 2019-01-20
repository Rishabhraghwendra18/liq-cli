usage-services() {
  local PREFIX="${1:-}"

  cat <<EOF
${PREFIX}${cyan_u}services${reset} :"
  list [-s|--show-status] [<service spec>...] : Lists all or named runtime
    services for the current environment and their status.
  start [<service spec>...] : Starts all or named services for the current
    environment.
  stop [<service spec>...] : Stops all or named services for the current
    environment.
  log [<service spec>...] : Displays logs for all or named services for the
    current environment.
  err-log [<service spec>...] : Displays error logs for all or named services
    for the current environment.
  connect [-c|--capabilities] <service spec> : Connects to the named service, if
    possible. The '--capabilities' option will print 'interactive', and/or
    'pipe', separated by newlines, to indicate the capabilities of the specified
    connection.

Where '${cyan}service spec${reset}' is either a service interface class or
<service iface>.<service name>. A service may be selected by it's major type, so
'sql' woud select environment services 'sql' and 'sql-mysql' (etc.). Thus,
'catalyst runtime services connect sql' may be used to connect to both MySQL,
Postgres, etc. DBs.
EOF
}
