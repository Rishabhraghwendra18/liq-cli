usageHelperServiceSpec() {
  local TAB="${1:-}"
  echo
  echo "${TAB}Where '${cyan}<service spec>${reset}' is either a service interface class or <service iface>.<service name>. A service may"
  echo "${TAB}be selected by it's major type, so 'sql' woud select environment services 'sql' and 'sql-mysql' (etc.)."
  echo "${TAB}Thus, 'catalyst runtime services connect sql' may be used to connect to both MySQL, Postgres, etc. DBs."
}

usage-runtime-environments() {
  local TAB="${1:-}"
  local PREFIX
  if [[ -z "$TAB" ]]; then PREFIX="catalyst runtime "; fi

  echo "${TAB}${PREFIX}${cyan_u}environments${reset} :"
  echo "${TAB}  list : List available environments for the current project."
  echo "${TAB}  show [<name>] : Display the named or current environment."
  echo "${TAB}  add [<name>] : Interactively adds a new environment definition to the current project."
  echo "${TAB}  delete <name> : Deletes named environment for the current project."
  echo "${TAB}  select [<name>] : Selects one of the available environment."
  echo "${TAB}  deselect : Unsets the current environment."
  echo "${TAB}  set [<key> <value>] | [<env name> <key> <value>]: Updates environment settings."
}

usage-runtime-services() {
  local TAB="${1:-}"
  local PREFIX
  if [[ -z "$TAB" ]]; then PREFIX="catalyst runtime "; fi

  echo "${TAB}${PREFIX}${cyan_u}services${reset} :"
  echo "${TAB}  list [-s|--show-status] [<service spec>...] : Lists all or named runtime services for the current environment and their status."
  echo "${TAB}  start [<service spec>...] : Starts all or named services for the current environment."
  echo "${TAB}  stop [<service spec>...] : Stops all or named services for the current environment."
  echo "${TAB}  log [<service spec>...] : Displays logs for all or named services for the current environment."
  echo "${TAB}  err-log [<service spec>...] : Displays error logs for all or named services for the current environment."
  echo "${TAB}  connect <service spec> : Connects to the named service, if possible."

  if [[ -z "$TAB" ]]; then
    usageHelperServiceSpec; fi
}

print_runtime_usage() {
  local TAB="${1:-}"
  echo "${TAB}catalyst ${cyan_u}runtime${reset} <sub-group> :"
  echo
  usage-runtime-environments "${TAB}  "
  echo
  usage-runtime-services "${TAB}  "
  usageHelperServiceSpec "${TAB}  "
}
