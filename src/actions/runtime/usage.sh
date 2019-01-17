usage-runtime-environments() {
  local TAB="${1:-}"
  local PREFIX
  if [[ -z "$TAB" ]]; then PREFIX='catalyst runtime '; fi

  echo "${TAB}${PREFIX}environments [<name>|-a [<name>]|-d [<name>...]] :"
  echo "${TAB}  no args : Lists environments for the current project."
  echo "${TAB}  <name>... : Gives detailed info for each named environment."
  echo "${TAB}  -a [<name>] : Interactively adds a new environment definition."
  echo "${TAB}  -d <name>... : Deletes the named environments associated to the current project."
}

usage-runtime-services() {
  local TAB="${1:-}"
  local PREFIX
  if [[ -z "$TAB" ]]; then PREFIX='catalyst runtime '; fi

  echo "${TAB}${PREFIX}services [<iface class>|-a [<iface class>]|-d [<iface class>...]] :"
  echo "${TAB}  no args : Lists runtime services for the current environment and their status."
  echo "${TAB}  <iface class>... : Gives detailed info for service of the named interface class."
  echo "${TAB}  -s [<iface class>] : Starts the service by interface class or all services (no args)."
  echo "${TAB}  -S [<iface class>] : Stops the service by interface class or all services (no args)."
  echo "${TAB}  -r [<iface class>] : Restarts the service by interface class or all services (no args)."
}

print_runtime_usage() {
  local TAB="${1:-}"
  echo -e "${TAB}catalyst runtime <sub-module>:"
  usage-runtime-environments "${TAB}  "
  usage-runtime-services "${TAB}  "
}
