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

  local SCOPE TIME OWNER FILE_NAME FILES
  policy-audit-start-prep "$@"
  policy-audit-initialize-records

  echoerrandexit "Not implemented."
}
