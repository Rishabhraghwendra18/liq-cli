requirements-policies() {
  :
}

policies-document() {
  local NODE_SCRIPT
  NODE_SCRIPT="$(dirname $(real_path ${BASH_SOURCE[0]}))/../src/actions/policies/lib/policies-document.js"
  node "$NODE_SCRIPT"
}

policies-update() {
  local CURR_ORG POLICY
  CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
  cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"

  for POLICY in $(policiesGetPolicyPackages); do
    npm i "${POLICY}"
  done
}
