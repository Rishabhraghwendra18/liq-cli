policies-audits() {
  local ACTION="${1}"; shift

  if [[ $(type -t "policies-audits-${ACTION}" || echo '') == 'function' ]]; then
    policies-audits-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" policies audits
  fi
}

policies-audits-process() {
  echoerrandexit "Audit processing not yet implemented."
}

policies-audits-start() {
  eval "$(setSimpleOptions SCOPE= NO_CONFIRM:C -- "$@")"

  local SCOPE TIME OWNER AUDIT_PATH FILES
  policy-audit-start-prep "$@"
  policies-audits-setup-work
  policy-audit-initialize-records

  echofmt reset "Would you like to begin processing the audit now? If not, the session will and your previous work will be resumed."
  if yes-no "Begin processing? (y/N)" N; then
    policies-audits-process
  else
    policies-audits-finalize-session "${AUDIT_PATH}" "${TIME}" "$(policies-audits-describe)"
  fi
}
