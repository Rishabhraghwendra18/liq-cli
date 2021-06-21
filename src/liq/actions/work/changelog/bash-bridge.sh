# work-lib-changelog-add-entry() {
work-blah() {
  work-lib-require-unit-of-work

  local CHANGELOG_FILE="./.meta/changelog.json"
  # ensure there's a changelog
  [[ -f "${CHANGELOG_FILE}" ]] || { mkdir -p $(dirname "${CHANGELOG_FILE}"); echo "[]" > "${CHANGELOG_FILE}"; }
  # Grab some useful data from git
  local CURR_USER CURR_REPO_VERSION
  CURR_USER="$(git config --get user.email)"
  CURR_REPO_VERSION="$(git rev-parse HEAD)"

  CHANGELOG_FILE="${CHANGELOG_FILE}" \
    CURR_USER="${CURR_USER}" \
    CURR_REPO_VERSION="${CURR_REPO_VERSION}" \
    node "${LIQ_DIST_DIR}/manage-changelog.js" add-entry \
    && echofmt --info "Changelog data updated."
}
