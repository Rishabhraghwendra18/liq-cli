help-environments() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}environments${reset} <action>: Runtime environment configurations." || cat <<EOF
${PREFIX}${cyan_u}environments${reset}:
  ${underline}list${reset}: List available environments for the current project.
  ${underline}show${reset} [<name>]: Display the named or current environment.
  ${underline}add${reset} [<name>]: Interactively adds a new environment definition to the current
    project.
  ${underline}delete${reset} <name>: Deletes named environment for the current project.
  ${underline}select${reset} [<name>]: Selects one of the available environment.
  ${underline}deselect${reset}: Unsets the current environment.
  ${underline}set${reset} [<key> <value>] | [<env name> <key> <value>]: Updates environment
    settings.
  ${underline}update${reset} [-n|--new-only]: Interactively update the current environment.
EOF
}
