help-projects-issues() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}projects issues${reset} <action>: Manage organization issues." || cat <<EOF
${PREFIX}${cyan_u}projects issues${reset} <action>:
$(help-projects-issues-show | sed -e 's/^/  /')
EOF
}

help-projects-issues-show() {
  cat <<EOF
${underline}show${reset} [--mine|-m]:
  Displays the open issues for the current project. With '--mine', will attempt to get the user's GitHub name
  and show them their own issues.
EOF
}
