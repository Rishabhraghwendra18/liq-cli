# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-orgs-audits() {
  handleSummary "${cyan_u}audits${reset} <action>: Manage audits." || cat <<EOF
${cyan_u}policies audits${reset} <action>:
$(help-orgs-audits-start | sed -e 's/^/  /')
EOF
} #$'' HACK to reset Atom Beutifier

help-orgs-audits-start() {
  cat <<EOF
${underline}start${reset} [--scope|-s <scope>] [--no-confirm|-C] [<domain>] :
  Initiates an audit. An audit scope is either 'change' (default), 'process' or 'full'.

  Currently supported domains are 'code' and 'network'. If domain isn't specified, then the user will be given an
  interactive list.

  By default, a summary of the audit will be displayed to the user for confirmation. This can be supressed with
  the '--no-confirm' option.
EOF
}
