# Takes a CLI friendly org ID (as found in LIQ_ORGS_DB) and resolves that to the path to the primary org repo.
lib-orgs-resolve-path() {
  # expects ORG_ID to be set (by post-options-liq-orgs)

  [[ -L "${LIQ_ORG_DB}/${ORG_ID}" ]] \
    || echoerrandexit "Could not resolve inferred org ID '${ORG_ID}'. Perhaps the base org repo is not locally installed? If the base package follows convetion, you can try:\nliq orgs import ${ORG_ID}/${ORG_ID}"

  real_path "${LIQ_ORG_DB}/${ORG_ID}"
}

# Retrieves the policy dir for the named NPM org or will infer from context. Org base and, when private, policy projects
# must be locally available.
orgsPolicyRepo() {
  [[ -n "${ORG_POLICY_REPO}" ]] || orgs-lib-source-settings

  echo "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}"
}

# TODO: rename 'lib-ogs-source-settings'
# Sources the named base org settings or will infer org context. If the base org cannot be found, the execution will
# halt and the user will be advised to timport it.
orgs-lib-source-settings() {
  # expects ORG_ID to be set (by post-options-liq-orgs)

  if [[ -z "$ORG_ID" ]]; then # this should have been done by post-options-liq-orgs; if we get here, something is wrong
    echoerrandexit "Execution environment is inconsistent; cannot find required data. This may be an error in the tool, so unfortunately we have no user advice for this error."
  else
    ORG_ID=${ORG_ID/@/}
  fi

  if [[ -e "$LIQ_ORG_DB/${ORG_ID}" ]]; then
    local SETTINGS="${LIQ_ORG_DB}/${ORG_ID}/data/orgs/settings.sh"
    [[ -f "${SETTINGS}" ]] || echoerrandexit "Could not locate settings file for '${ORG_ID}' (${SETTINGS})."
    source "${SETTINGS}"

    ORG_CHART_TEMPLATE="${ORG_CHART_TEMPLATE/\~/$LIQ_PLAYGROUND}" # TODO: huh? explain this...
  else
    echoerrandexit "Did not find expected local org for package '${ORG_ID}'. Try:\nliq orgs import <pkg || URL>"
  fi
}
