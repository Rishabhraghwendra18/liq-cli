help-projects-issues() {
  local PREFIX="${1:-}"

  local SUMMARY="Manage projects issues."

  handleSummary "${PREFIX}${cyan_u}projects issues${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}projects issues${reset} <action>:
  ${SUMMARY}
$(_help-actions-list projects-issues show | indent)
EOF
}

help-projects-issues-show() {
  cat <<EOF | _help-func-summary show "[--mine|-m]"
Displays the open issues for the current project. With '--mine', will attempt to get the user's GitHub name and show them their own issues.
EOF
}
