print_environment_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid environment actions are:\n"
  fi
  echo "${PREFIX}show [<name>]: Display the named or current environment."
  echo "${PREFIX}add : Add a new environment definition."
  echo "${PREFIX}list : List available environments."
  echo "${PREFIX}select [<name>|none]: Selects one of the available environment."
  echo "${PREFIX}set [<key> <value>] | [<env name> <key> <value>]: Updates environment settings."
  echo "${PREFIX}delete [<name>]: Deletes the current or named environment."
}
