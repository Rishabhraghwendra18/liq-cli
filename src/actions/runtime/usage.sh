print_service_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid service actions are:\n"
  fi
  echo "${PREFIX}list : List currently available services."
  echo "${PREFIX}start [all|<name>] : Started the named, all, or selected service."
  echo "${PREFIX}stop [all|<name>] : Started the named, all, or selected service."
  echo "${PREFIX}restart [all|<name>] : Started the named, all, or selected service."
}
