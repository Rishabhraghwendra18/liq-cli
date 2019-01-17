usageHelperServiceSpec() {
  echo
  echo "Where '${cyan}<service spec>${reset}' is either a service interface class or <service iface>.<service name>."
}

usage-runtime-environments() {
  local TAB="${1:-}"
  local PREFIX
  if [[ -z "$TAB" ]]; then PREFIX="catalyst runtime "; fi

  echo "${TAB}${PREFIX}${cyan_u}environments${reset} [<name>|-a [<name>]|-d [<name>...]] :"
  echo "${TAB}  no args : Lists environments for the current project."
  echo "${TAB}  <name>... : Gives detailed info for each named environment."
  echo "${TAB}  -a [<name>] : Interactively adds a new environment definition."
  echo "${TAB}  -d <name>... : Deletes the named environments associated to the current project."
}

usage-runtime-services() {
  local TAB="${1:-}"
  local PREFIX
  if [[ -z "$TAB" ]]; then PREFIX="catalyst runtime "; fi

  echo "${TAB}${PREFIX}${cyan_u}services${reset} :"
  echo "${TAB}  list [<service spec>...] : Lists all or named runtime services for the current environment and their status."
  echo "${TAB}  start [<service spec>...] : Starts all or named services for the current environment."
  echo "${TAB}  stop [<service spec>...] : Stops all or named services for the current environment."
  echo "${TAB}  log [<service spec>...] : Displays logs for all or named services for the current environment."
  echo "${TAB}  err-log [<service spec>...] : Displays error logs for all or named services for the current environment."
  echo "${TAB}  connect <service spec> : Connects to the named service, if possible."

  if [[ -z "$TAB" ]]; then usageHelperServiceSpec; fi
}

print_runtime_usage() {
  local TAB="${1:-}"
  echo "${TAB}catalyst ${cyan_u}runtime${reset} <sub-group> :"
  echo
  usage-runtime-environments "${TAB}  "
  echo
  usage-runtime-services "${TAB}  "
  usageHelperServiceSpec
}
