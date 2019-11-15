help-policies() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}policies${reset} <action>: Manages organization policies." || cat <<EOF
${PREFIX}${cyan_u}policies${reset} <action>:
  ${underline}update${reset}: Updates organization policies.

Policies defines all manner of organizational operations. They are "organizational code".
EOF
}
