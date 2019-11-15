requirements-policies() {
  :
}

policies-update() {
  local CURR_ORG POLICY
  CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
  cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"

  for POLICY in $(policiesGetPolicyPackages); do
    npm i "${POLICY}"
  done
}
