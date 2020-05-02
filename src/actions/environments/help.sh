help-environments() {
  local PREFIX="${1:-}"

  local SUMMARY="Runtime environment configurations."

  handleSummary "${PREFIX}${cyan_u}environments${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}environments${reset}:
  ${SUMMARY}
$(_help-actions-list environments add delete deselect list select set show update | indent)
EOF
}

help-environments-add() {
  cat <<EOF | _help-func-summary add "[<name>]"
Interactively adds a new environment definition to the current project.
EOF
}

help-environments-delete() {
  cat <<EOF | _help-func-summary delete "<name>"
Deletes named environment for the current project.
EOF
}

help-environments-deselect() {
  cat <<EOF | _help-func-summary deselect
Unsets the current environment.
EOF
}

help-environments-list() {
  cat <<EOF | _help-func-summary list
List available environments for the current project.
EOF
}

help-environments-select() {
  cat <<EOF | _help-func-summary select "[<name>]"
Display the named or current environment.
EOF
}

help-environments-set() {
  cat <<EOF | _help-func-summary set "[<key> <value>] | [<env name> <key> <value>]"
Updates environment settings.
EOF
}

help-environments-show() {
  cat <<EOF | _help-func-summary show "[<name>]"
Selects one of the available environment.
EOF
}

help-environments-update() {
  cat <<EOF | _help-func-summary update "[-n|--new-only]"
Interactively update the current environment.
EOF
}
