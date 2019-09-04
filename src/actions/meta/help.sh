help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles catalyst self-config and meta operations." \
   || cat <<EOF
${PREFIX}${cyan_u}meta${reset} <action>:
   ${underline}init${reset} [--silent|-s] [--playground|-p <absolute path>]: Creates the Liquid
     Development DB (a local directory) and playground.
   ${underline}bash-config${reset}: Prints bash configuration. Try: eval \`catalyst meta bash-config\`
EOF
}
