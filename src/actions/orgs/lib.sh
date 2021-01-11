# Takes a CLI friendly org ID (as found in ~/.liq/orgs) and resolves that to the path to the primary org repo.
lib-orgs-resolve-path() {
  local ORG_ID="${1:-}"
  [[ -L "${LIQ_ORG_DB}/${ORG_ID}" ]] || echoerrandexit "Unknown org reference. Try:\nliq orgs list\nliq orgs import"

  real_path "${LIQ_ORG_DB}/${ORG_ID}"
}

# deprecated; use orgs-lib-source-settings
# sourceCurrentOrg() {

# Retrieves the policy dir for the named NPM org or will infer from context. Org base and, when private, policy projects
# must be locally available.
orgsPolicyRepo() {
  orgs-lib-source-settings "${1:-}"

  echo "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}"
}

# TODO: rename 'lib-ogs-source-settings'
# Sources the named base org settings or will infer org context. If the base org cannot be found, the execution will
# halt and the user will be advised to timport it.
orgs-lib-source-settings() {
  local NPM_ORG="${1:-}"

  if [[ -z "$NPM_ORG" ]]; then
    findBase
    NPM_ORG="$(cd "${BASE_DIR}/.."; basename "$PWD")"
  else
    NPM_ORG=${NPM_ORG/@/}
  fi

  if [[ -e "$LIQ_ORG_DB/${NPM_ORG}" ]]; then
    local SETTINGS="${LIQ_ORG_DB}/${NPM_ORG}/data/orgs/settings.sh"
    [[ -f "${SETTINGS}" ]] || echoerrandexit "Could not locate settings file for '${NPM_ORG}' (${SETTINGS})."
    source "${SETTINGS}"

    ORG_CHART_TEMPLATE="${ORG_CHART_TEMPLATE/\~/$LIQ_PLAYGROUND}" # TODO: huh? explain this...
  else
    echoerrandexit "Did not find expected base org package. Try:\nliq orgs import <pkg || URL>"
  fi
}
