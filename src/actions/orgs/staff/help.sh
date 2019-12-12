help-orgs-staff() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}orgs staff${reset} <action>: Manages organizations staff." || cat <<EOF
${PREFIX}${cyan_u}orgs staff${reset} <action>:
  ${underline}add${reset} [--email|-e <email>] [--family-name|-f <name>] [--given-name|-g <name>] [--start-date|-s <YYY-MM-DD>]:
  ${underline}list${reset}
  ${underline}remove${reset}
EOF
}
