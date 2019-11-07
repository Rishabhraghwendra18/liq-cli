orgsCurrentOrg() {
  if [[ -L "${CURR_ORG_FILE}" ]]; then
    readlink "${CURR_ORG_FILE}" | xargs basename
  fi
}

orgsOrgList() {
  eval "$(setSimpleOptions LIST_ONLY -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local CURR_ORG ORG
  CURR_ORG=$(orgsCurrentOrg)

  for ORG in $(find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; | sort); do
    ( ( test -z "$LIST_ONLY" && test "$ORG" == "${CURR_ORG:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ORG"
  done
}
