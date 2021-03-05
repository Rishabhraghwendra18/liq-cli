pre-options-liq-orgs() {
  echo -n "$(pre-options-liq) ORG:="
}

# Sets CURR_ORG and CURR_ORG_PATH
post-options-liq-orgs() {
  post-options-liq

  orgs-lib-process-org-opt
}

orgs-lib-process-org-opt() {
  # 'ORG' is the parameter set by the user (or not)
  # 'ORG_ID' is the resolved ORG_ID
  # 'CURR_ORG' is the base org package name; e.g., liquid-labs/liquid-labs TODO: rename to 'CURR_ORG'?
  # 'CURR_ORG_PATH' is the absolute path to the CURR_ORG project

  # TODO: Check if the project 'class' is correct; https://github.com/liquid-labs/liq-cli/issues/238
  if [[ -z "${ORG:-}" ]] || [[ "${ORG}" == '.' ]]; then
    findBase
    ORG_ID="$(cd "${BASE_DIR}/.."; basename "$PWD")"
  else
    ORG_ID="${ORG}"
  fi
  # the following will exit if the ORG_ID cannot be resolved to a local checkout
  CURR_ORG_PATH="$(lib-orgs-resolve-path "${ORG_ID}")"
  CURR_ORG="$( cat "${CURR_ORG_PATH}/package.json" | jq -r '.name' )"
  CURR_ORG="${CURR_ORG/@/}"
}
