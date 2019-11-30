policiesGetPolicyDirs() {
  (
    local CURR_ORG
    CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
    cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"
    find "./node_modules/@liquid-labs" -maxdepth 1 -type d -name "policy-*" -exec echo "${PWD}/{}" \;
  )
}

policiesGetPolicyFiles() {
  local DIRS DIR
  DIRS="$(policiesGetPolicyDirs)"
  for DIR in $DIRS; do
    find $DIR -name "*.tsv"
  done
}

# Gets the installed policy projects. Note that we get installed rather than declared as policies are often an
# 'optional' dependency, so this is considered slightly more robust.
policiesGetPolicyProjects() {
  local DIR
  for DIR in $(policiesGetPolicyDirs); do
    cat "${DIR}/package.json" | jq --raw-output '.name' | tr -d "'"
  done
}
