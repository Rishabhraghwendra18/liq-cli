# Takes a CLI friendly org ID (as found in ~/.liq/orgs) and resolves that to the path to the primary org repo.
lib-orgs-resolve-path() {
  local ORG_ID="${1:-}"
  [[ -L "${LIQ_ORG_DB}/${ORG_ID}" ]] || echoerrandexit "Unknown org reference. Try:\nliq orgs list\nliq orgs import"

  real_path "${LIQ_ORG_DB}/${ORG_ID}"
}

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
  local ORG_ID="${1:-}"

  if [[ -z "$ORG_ID" ]]; then
    if [[ -n "${CURR_ORG}" ]]; then
      ORG_ID="${CURR_ORG}"
    else
      findBase
      ORG_ID="$(cd "${BASE_DIR}/.."; basename "$PWD")"
    fi
  else
    ORG_ID=${ORG_ID/@/}
  fi

  if [[ -e "$LIQ_ORG_DB/${ORG_ID}" ]]; then
    local SETTINGS="${LIQ_ORG_DB}/${ORG_ID}/data/orgs/settings.sh"
    [[ -f "${SETTINGS}" ]] || echoerrandexit "Could not locate settings file for '${ORG_ID}' (${SETTINGS})."
    source "${SETTINGS}"

    ORG_CHART_TEMPLATE="${ORG_CHART_TEMPLATE/\~/$LIQ_PLAYGROUND}" # TODO: huh? explain this...
  else
    echoerrandexit "Did not find expected base org package. Try:\nliq orgs import <pkg || URL>"
  fi
}
