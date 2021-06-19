# work-lib-changelog-add-entry() {
work-blah() {
  local CHANGELOG_FILE="./.meta/changelog.json"
  # ensure there's a changelog
  [[ -f "${CHANGELOG_FILE}" ]] || { mkdir -p $(dirname "${CHANGELOG_FILE}"); echo "[]" > "${CHANGELOG_FILE}"; }

  CHANGELOG_FILE="${CHANGELOG_FILE}" node "${LIQ_DIST_DIR}/lib-changelog.js"
}
