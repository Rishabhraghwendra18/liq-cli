help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles catalyst self-config and meta operations." \
   || cat <<EOF
${PREFIX}${cyan_u}meta${reset} <action>:
   ${underline}bash-config${reset}: Prints bash configuration. Try: eval \`catalyst meta bash-config\`
EOF
}
