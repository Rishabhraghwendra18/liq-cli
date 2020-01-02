requirements-policies() {
  :
}

# see ./help.sh for behavior
policies-document() {
  local TARGET_DIR NODE_SCRIPT
  TARGET_DIR="$(orgsPolicyRepo "${1:-}")/policy"
  NODE_SCRIPT="$(dirname $(real_path ${BASH_SOURCE[0]}))/index.js"

  rm -rf "$TARGET_DIR"
  mkdir -p "$TARGET_DIR"
  node -e "require('$NODE_SCRIPT').refreshDocuments('${TARGET_DIR}', process.argv.slice(1))" $(policiesGetPolicyFiles)
}

# see ./help.sh for behavior
policies-update() {
  local POLICY
  for POLICY in $(policiesGetPolicyProjects "$@"); do
    npm i "${POLICY}"
  done
}
