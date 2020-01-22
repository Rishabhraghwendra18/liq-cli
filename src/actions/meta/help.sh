help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles liq self-config and meta operations." \
   || cat <<EOF
The meta group manages local liq configurations and non-liq user resources.

${PREFIX}${cyan_u}meta${reset} <action>:
   ${underline}init${reset} [--silent|-s] [--playground|-p <absolute path>]: Creates the Liquid
     Development DB (a local directory) and playground.
   ${underline}bash-config${reset}: Prints bash configuration. Try: eval \`liq meta bash-config\`

   ${bold}Sub-resources${reset}:
     * $( SUMMARY_ONLY=true; help-meta-keys )
EOF
}
