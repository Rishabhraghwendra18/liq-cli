requirements-policies() {
  :
}

policies-document() {
  local NODE_SCRIPT CURR_ORG TARGET_DIR
  NODE_SCRIPT="$(dirname $(real_path ${BASH_SOURCE[0]}))/index.js"
  CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
  TARGET_DIR="${LIQ_ORG_DB}/${CURR_ORG}/sensitive/policy"

  rm -rf "$TARGET_DIR"
  mkdir -p "$TARGET_DIR"
  node -e "require('$NODE_SCRIPT').refreshDocuments('${TARGET_DIR}', process.argv.slice(1))" $(policiesGetPolicyFiles)
}

policies-update() {
  local CURR_ORG POLICY
  CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
  cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"

  for POLICY in $(policiesGetPolicyProjects); do
    npm i "${POLICY}"
  done
}
