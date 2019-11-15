policiesGetPolicyDirs() {
  (
    local CURR_ORG
    CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
    cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"
    find "./node_modules/@liquid-labs" -maxdepth 1 -type d -name "policy-*" -exec echo "${PWD}/{}" \;
  )
}

policiesGetPolicyPackages() {
  local DIR
  for DIR in $(policiesGetPolicyDirs); do
    cd "${DIR}"
    cat package.json | jq --raw-output '.name' | tr -d "'"
  done
}
