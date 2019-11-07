orgsOrgList() {
  eval "$(setSimpleOptions LIST_ONLY -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local CURR_ORG
  if [[ -L "${CURR_ORG_FILE}" ]]; then
    CURR_ORG=`readlink "${CURR_ORG_FILE}" | xargs basename`
  fi
  local ORG
  echo 'blah2' >> log.tmp
  echo "find \"${LIQ_ORG_DB}\" -type f -not -name \"*~\" -exec basename '{}' \; | sort" >> log.tmp
  for ORG in $(find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; | sort); do
    ( ( test -z "$LIST_ONLY" && test "$ORG" == "${CURR_ORG:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ORG"
  done
}
