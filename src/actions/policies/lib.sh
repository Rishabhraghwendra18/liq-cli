# Retrieves the policy directories from the current org. Currenly requires sensitive until we think through the
# implication of having 'partial' policy access and whether that's ever useful.
#
# Returns one file per line, suitable for use with:
#
# while read VAR; do ... ; done < <(policiesGetPolicyDirs)
policiesGetPolicyDirs() {
  {
    local CURR_ORG REPO
    CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
    for REPO in public sensitive; do
      find "${LIQ_ORG_DB}/${CURR_ORG}/${REPO}/node_modules/@liquid-labs" -maxdepth 1 -type d -name "policy-*"
    done
  } | uniq
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
