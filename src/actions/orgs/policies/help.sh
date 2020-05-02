help-orgs-policies() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages organization policies."

  handleSummary "${PREFIX}${cyan_u}orgs policies${reset} <action>: ${SUMMARY}" || cat <<EOF
$(echo "${SUMMARY} Policies defines all manner of organizational operations. They are \"organizational code\"." | fold -sw 80 | indent)
$(_help-actions-list orgs-policies document update | indent)
EOF
}

help-orgs-policies-document() {
  cat <<EOF | _help-func-summary document
Refreshes (or generates) org policy documentation based on current data.
EOF
}

help-orgs-policies-update() {
  cat <<EOF | _help-func-summary update
Updates organization policies.
EOF
}
