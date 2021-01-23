pre-options-liq-orgs() {
  echo -n "$(pre-options-liq) ORG:="
}

# Sets CURR_ORG and CURR_ORG_PATH
post-options-liq-orgs() {
  post-options-liq

  # TODO: Check if the project 'class' is correct; https://github.com/Liquid-Labs/liq-cli/issues/238
  if [[ -z "${ORG:-}" ]]; then
    findBase
    CURR_ORG_PATH="${BASE_DIR}"
    CURR_ORG="$( cat "${CURR_ORG_PATH}/package.json" | jq -r '.name' )"
    CURR_ORG="${CURR_ORG/@/}"
  else
    CURR_ORG="${ORG}"
    CURR_ORG_PATH="$(lib-orgs-resolve-path "${CURR_ORG}")"
  fi
}
