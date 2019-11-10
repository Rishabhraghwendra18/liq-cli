orgsCurrentOrg() {
  eval "$(setSimpleOptions REQUIRE REQUIRE_SENSITIVE:s -- "$@")"

  if [[ -n "$REQUIRE_SENSITIVE" ]]; then
    REQUIRE=true
  fi

  if [[ -L "${CURR_ORG_DIR}" ]]; then
    if [[ -n "$REQUIRE_SENSITIVE" ]]; then
      if [[ ! -d "${CURR_ORG_DIR}/sensitive" ]]; then
        echoerrandexit "Command requires access to the sensitive org settings. Try:\nliq orgs import --sensitive"
      fi
    fi
    CURR_ORG="$(readlink "${CURR_ORG_DIR}" | xargs basename)"
  elif [[ -n "$REQUIRE" ]]; then
    echoerrandexit "Command requires active org selection. Try:\nliq orgs select"
  fi
}

orgsOrgList() {
  eval "$(setSimpleOptions LIST_ONLY -- "$@")"

  local CURR_ORG ORG
  CURR_ORG=$(orgsCurrentOrg)

  for ORG in $(find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; | sort); do
    ( ( test -z "$LIST_ONLY" && test "$ORG" == "${CURR_ORG:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ORG"
  done
}
