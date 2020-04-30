help-orgs-policies() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}orgs policies${reset} <action>: Manages organization policies." || cat <<EOF
Policies defines all manner of organizational operations. They are "organizational code".

${PREFIX}${cyan_u}policies${reset} <action>:
  ${underline}document${reset}: Refreshes (or generates) org policy documentation based on current data.
  ${underline}update${reset}: Updates organization policies.

${bold}Sub-resources${reset}:
  * $( SUMMARY_ONLY=true; help-orgs-audits )
EOF
}
