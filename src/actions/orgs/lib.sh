# sources the current org settings, if any
sourceCurrentOrg() {
  local REL_DIR
  if [[ -d org_settings ]]; then
    REL_DIR="."
  elif [[ -n "$BASE_DIR" ]]; then
    REL_DIR="$BASE_DIR/.."
  else
    echoerrandexit "Cannot get current organization outside of project context."
  fi

  source "${REL_DIR}/org_settings/settings.sh"
  if [[ -d "${REL_DIR}/org_settings_sensitive" ]]; then
    source "${REL_DIR}/org_settings_sensitive/settings.sh"
  fi
}

# Retrieves the policy dir for the named NPM org or will infer from context. Org base and, when private, policy projects
# must be locally available.
orgsPolicyRepo() {
  orgs-lib-source-settings "${1:-}"

  echo "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}"
}

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
    [[ -f "$LIQ_ORG_DB/${NPM_ORG}/settings.sh" ]] || echoerrandexit "Could not locate settings file for '${NPM_ORG}'."
    source "$LIQ_ORG_DB/${NPM_ORG}/settings.sh"

    ORG_ROLES="${ORG_ROLES/\~/$LIQ_PLAYGROUND}"
    ORG_STRUCTURE="${ORG_STRUCTURE/\~/$LIQ_PLAYGROUND}"
    ORG_CHART_TEMPLATE="${ORG_CHART_TEMPLATE/\~/$LIQ_PLAYGROUND}"
  else
    echoerrandexit "Did not find expected base org package. Try:\nliq orgs import <pkg || URL>"
  fi
}
