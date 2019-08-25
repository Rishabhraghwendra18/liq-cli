print_local_help() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid local actions are:\n"
  fi
  echo "${PREFIX}start : Starts all local development services."
  echo "${PREFIX}stop : Stops all local development services."
  echo "${PREFIX}restart : Stops then starts all local development services."
  echo "${PREFIX}clear-logs : Deletes all local development service logs."
}
