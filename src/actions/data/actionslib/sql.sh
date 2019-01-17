data-sql() {
  requireEnvironment

  if [[ $# -eq 0 ]]; then
    usage-data-sql
    echoerrandexit "Missing action argument. See usage above."
  else
    local ACTION="$1"; shift
    if type -t ${GROUP}-${SUBGROUP}-${ACTION} | grep -q 'function'; then
      ${GROUP}-${SUBGROUP}-${ACTION} "$@"
    else
      exitUnknownAction
    fi
  fi
}

data-sql-rebuild() {
  echo 'TODO: sql rebuild'
}
