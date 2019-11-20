orgs-staff() {
  local ACTION="${1}"; shift
  local CMD="orgs-staff-${ACTION}"
  echo $CMD

  if [[ $(type -t "${CMD}" || echo '') == 'function' ]]; then
    ${CMD} "$@"
  else
    exitUnknownAction
  fi
}

orgs-staff-add() {
  :
}
