orgsStaffCommit() {
  cd "${CURR_ORG_DIR}/sensitive" \
    && git add staff.tsv \
    && git commit -am "Added staff member '${EMAIL}'." \
    && git push
}
