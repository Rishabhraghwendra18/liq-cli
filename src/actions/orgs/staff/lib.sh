# Commits the org staff data.
orgsStaffCommit() {
  orgsStaffRepo
  cd "${LIQ_PLAYGROUND}/${ORG_STAFF_REPO/@/}" \
    && git add staff.tsv \
    && git commit -am "Added staff member '${EMAIL}'." \
    && git push
}

# Verifies the existence of and provides 'ORG_STAFF_REPO' as a global var (and the rest of the org vars as a side
# effect). Will exit and report error if the base org project is not locally available or 'ORG_STAFF_REPO' is not
# defined.
orgsStaffRepo() {
  orgsSourceOrg || echoerrandexit "Could not locate local base org project."
  [[ -n "${ORG_STAFF_REPO:-}" ]] || echoerrandexit "'ORG_STAFF_REPO' not defined in base org project."
}
