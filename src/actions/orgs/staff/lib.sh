# Commits the org staff data.
orgsStaffCommit() {
  cd "${LIQ_PLAYGROUND}/${ORG_STAFF_REPO/@/}" \
    && git add staff.tsv \
    && git commit -am "Added staff member '${EMAIL}'." \
    && git push
}

# Verifies the that the staff related parameters have been set. Typcially, these settings are handlid in the org
# 'settings.sh' file loaded by 'orgs-lib-source-settings'. If the expected parameters are not found, the process will
# exit with an appropriate message regarding the first missing parameter. General usage is:
#    orgs-lib-source-settings
#    orgs-staff-lib-verify-settings
orgs-staff-lib-check-parameters() {
  [[ -n "${ORG_STAFF_REPO:-}" ]] || echoerrandexit "'ORG_STAFF_REPO' not defined in base org project."

  [[ -n "${ORG_ROLES:-}" ]] || echoerrandexit "You must define 'ORG_ROLES' to point to a valid TSV file in the 'settings.sh' file."
  [[ -f "$ORG_ROLES" ]] || echoerrandexit "'ORG_ROLES' defnied, but does not point to a file."

  [[ -n "${ORG_STRUCTURE:-}" ]] || echoerrandexit "You must define 'ORG_STRUCTURE' to point to a valid JSON file in the 'settings.sh' file."
  [[ -f "$ORG_STRUCTURE" ]] || echoerrandexit "'ORG_STRUCTURE' defnied, but does not point to a file."
}
