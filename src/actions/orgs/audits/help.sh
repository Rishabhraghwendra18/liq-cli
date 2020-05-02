help-orgs-audits() {
  local PREFIX="${1:-}"

  local SUMMARY="Audit management."

  handleSummary "${cyan_u}orgs audits${reset} <action>: ${SUMMARY}" || cat <<EOF
${cyan_u}orgs audits${reset} <action>:
  ${SUMMARY}
$(_help-actions-list orgs-audits start | indent)
EOF
}

help-orgs-audits-start() {
  cat <<EOF | _help-func-summary start "[--scope|-s <scope>] [--no-confirm|-C] [<domain>]"
Initiates an audit. An audit scope is either 'change' (default), 'process' or 'full'.

Currently supported domains are 'code' and 'network'. If domain isn't specified, then the user will be given an interactive list.

By default, a summary of the audit will be displayed to the user for confirmation. This can be supressed with the '--no-confirm' option.
EOF
}
