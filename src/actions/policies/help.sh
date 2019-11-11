help-policies() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}policies${reset} <action>: Manages organization policies." || cat <<EOF
${PREFIX}${cyan_u}policies${reset} <action>:
  ${underline}import${reset} [--fork|-f] <git URL>: Imports the policies into the user playground and
    registers them with the active org (if not already done). To work on the policies without
    registering them, use 'liq project import'. By default, 'policy import' does NOT create a forked
    workespace on the assumption that the policy is being imported for use/reference rather than
    for editting. If you want to register the policy AND edit it, then include the '--fork' option.

Policies defines all manner of organizational operations. They are "organizational code".
EOF
}
