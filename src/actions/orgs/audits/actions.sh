# TODO: add check that 'meta keys' command group is available. Post install func, I think.

orgs-audits() {
  local ACTION="${1}"; shift

  if [[ $(type -t "orgs-audits-${ACTION}" || echo '') == 'function' ]]; then
    orgs-audits-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" policies audits
  fi
}

orgs-audits-process() {
  echoerrandexit "Audit processing not yet implemented."
}

orgs-audits-start() {
  eval "$(setSimpleOptions SCOPE= NO_CONFIRM:C -- "$@")"

  local TIME OWNER AUDIT_PATH FILES
  policy-audit-start-prep "$@"
  orgs-audits-setup-work
  policy-audit-initialize-records

  echofmt reset "Would you like to begin processing the audit now? If not, the session will and your previous work will be resumed."
  if yes-no "Begin processing? (y/N)" N; then
    orgs-audits-process
  else
    orgs-audits-finalize-session "${AUDIT_PATH}" "${TIME}" "$(orgs-audits-describe)"
  fi
}
