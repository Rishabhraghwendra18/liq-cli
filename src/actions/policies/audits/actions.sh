policies-audits() {
  local ACTION="${1}"; shift

  if [[ $(type -t "policies-audits-${ACTION}" || echo '') == 'function' ]]; then
    policies-audits-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" policies audits
  fi
}

policies-audits-start() {
  eval "$(setSimpleOptions SCOPE= NO_CONFIRM:C -- "$@")"

  local SCOPE TIME OWNER RECORDS_FOLDER FILES
  policy-audit-start-prep "$@"
  policies-audits-setup-work
  policy-audit-initialize-records
  policies-audits-finalize-session "${RECORDS_FOLDER}" "${TIME}"
}
