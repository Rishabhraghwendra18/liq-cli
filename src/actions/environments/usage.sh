usage-environments() {
  local PREFIX="${1:-}"

  cat<<EOF
${PREFIX}${cyan_u}environments${reset}:
  list: List available environments for the current project.
  show [<name>]: Display the named or current environment.
  add [<name>]: Interactively adds a new environment definition to the current
    project.
  delete <name>: Deletes named environment for the current project.
  select [<name>]: Selects one of the available environment.
  deselect: Unsets the current environment.
  set [<key> <value>] | [<env name> <key> <value>]: Updates environment
    settings.
EOF
}
