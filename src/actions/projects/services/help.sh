help-projects-services() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages package service configuration."

  handleSummary "${PREFIX}${cyan_u}projects services${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}projects services${reset} <action>:
  ${SUMMARY}
$(_help-actions-list projects-services add delete list show | indent)
EOF
}

help-projects-services-add() {
  cat <<EOF | _help-func-summary add "[<service name>]"
Add a provided service to the current project.
EOF
}

help-projects-services-list() {
  cat <<EOF | _help-func-summary list "[<service name>...]"
Lists the services provided by the current or named projects.
EOF
}

help-projects-services-delete() {
  cat <<EOF | _help-func-summary delete "<project name> [<service name>]"
Deletes a provided service.
EOF
}

help-projects-services-show() {
  cat <<EOF | _help-func-summary show "[<service name>...]"
Show service details.
EOF
}
