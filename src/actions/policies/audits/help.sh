# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-policies-audits() {
  handleSummary "${cyan_u}audits${reset} <action>: Manage audits." || cat <<EOF
${cyan_u}policies audits${reset} <action>:
$(help-policies-audits-start | sed -e 's/^/  /')
EOF
} #$'' HACK to reset Atom Beutifier

help-policies-audits-start() {
  cat <<EOF
${underline}start${reset} [--change-control|-c] [--full|-f] [--no-confirm|-C] [<domain>] :
  Initiates an audit. An audit scope is either 'change control' (default) or 'full', which may specified by the
  optional --change-control and --full parameters.

  Currently supported domains are 'code' and 'network'. If domain isn't specified, then the user will be given an
  interactive list.

  By default, a summary of the audit will be displayed to the user for confirmation. This can be supressed with
  the '--no-confirm' option.
EOF
}
