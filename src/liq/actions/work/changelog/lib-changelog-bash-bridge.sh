LIQ_WORK_CHANGELOG_FILE="./.meta/changelog.yaml"

work-lib-changelog-add-entry() {
  work-lib-require-unit-of-work

  # ensure there's a changelog
  [[ -f "${LIQ_WORK_CHANGELOG_FILE}" ]] || { mkdir -p $(dirname "${LIQ_WORK_CHANGELOG_FILE}"); echo "[]" > "${LIQ_WORK_CHANGELOG_FILE}"; }
  # Grab some useful data from git
  local CURR_USER CURR_REPO_VERSION
  CURR_USER="$(git config --get user.email)"
  CURR_REPO_VERSION="$(git rev-parse HEAD)"

  CHANGELOG_FILE="${LIQ_WORK_CHANGELOG_FILE}" \
    CURR_USER="${CURR_USER}" \
    CURR_REPO_VERSION="${CURR_REPO_VERSION}" \
    node "${LIQ_DIST_DIR}/manage-changelog.js" add-entry \
    && echofmt --info "Changelog data updated."
}

liq-work-lib-ensure-changelog-exists() {
  [[ -f "${LIQ_WORK_CHANGELOG_FILE}" ]] \
    || echoerrandexit "Did not find expected changelog at: ${LIQ_WORK_CHANGELOG_FILE}"
}

work-lib-changelog-finalize-entry() {
  work-lib-require-unit-of-work
  liq-work-lib-ensure-changelog-exists

  CHANGELOG_FILE="${LIQ_WORK_CHANGELOG_FILE}" \
    node "${LIQ_DIST_DIR}/manage-changelog.js" finalize-entry \
    && echofmt --info "Changelog data updated."
}

liq-work-lib-changelog-print-entries-since() {
  local SINCE_VERSION="${1}"
  liq-work-lib-ensure-changelog-exists

  # setting the file to '-' causes us to read from STDIN
  local ORIG_LC=0
  if git cat-file -e ${SINCE_VERSION}:"${LIQ_WORK_CHANGELOG_FILE}" 2>/dev/null; then
    ORIG_LC=$(git show ${SINCE_VERSION}:"${LIQ_WORK_CHANGELOG_FILE}" | wc -l)
  fi
  tail +${ORIG_LC} "${LIQ_WORK_CHANGELOG_FILE}" | \
    CHANGELOG_FILE="-" \
    node "${LIQ_DIST_DIR}/manage-changelog.js" print-entries
}

liq-work-lib-changelog-update-format() {
  liq-work-lib-ensure-changelog-exists

  CHANGELOG_FILE="${LIQ_WORK_CHANGELOG_FILE}" \
    node "${LIQ_DIST_DIR}/manage-changelog.js" update-format \
    && echofmt --info "Changelog format updated."
}
