print_environment_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid environment actions are:\n"
  fi
  echo "${PREFIX}show : Display the current environment."
  echo "${PREFIX}add : Add a new environment definition."
  echo "${PREFIX}list : List available environments."
  echo "${PREFIX}select : Selects one of the available environment."
  echo "${PREFIX}set-billing [<name>]: Updates billing for the current or named environment."
  echo "${PREFIX}delete [<name>]: Deletes the current or named environment."
}
