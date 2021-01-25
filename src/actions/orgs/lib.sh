# Ensures that policy repo can be resolved or errors out with a useful message. Can even try to import the necessary
# project.
lib-orgs-ensure-policy-repo() {
  [[ -n "${ORG_POLICY_REPO}" ]] || echoerrandexit "Try setting company parameter 'ORG_POLICY_REPO'."
  ORG_POLICY_REPO="${ORG_POLICY_REPO/@/}" # TODO: standardize sans '@'
  if ! [[ -d "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO}" ]]; then
    if yes-no "Did not find local '${ORG_POLICY_REPO}'. Would you like to attempt import? " Y; then
      projects-import --source "${ORG_POLICY_REPO}" \
        echoerrandexit "Project import failed. See above."
    else
      echowarnandexit "Try manual import:\nliq projects import --source '${ORG_POLICY_REPO}'"
    fi
  fi
}

# Calls lib-orgs-ensure-policy-repo and then echoes an absolute path if successful.
lib-orgs-policy-repo-path() {
  lib-orgs-ensure-policy-repo

  echo "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}"
}

# Takes a CLI friendly org ID (as found in LIQ_ORGS_DB) and resolves that to the path to the primary org repo.
lib-orgs-resolve-path() {
  # expects ORG_ID to be set (by post-options-liq-orgs)

  [[ -L "${LIQ_ORG_DB}/${ORG_ID}" ]] \
    || echoerrandexit "Could not resolve inferred org ID '${ORG_ID}'. Perhaps the base org repo is not locally installed? If the base package follows convetion, you can try:\nliq orgs import ${ORG_ID}/${ORG_ID}"

  real_path "${LIQ_ORG_DB}/${ORG_ID}"
}

# Retrieves the policy dir for the named NPM org or will infer from context. Org base and, when private, policy projects
# must be locally available.
#
# @deprecated: prefer lib-orgs-policy-repo-path
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
