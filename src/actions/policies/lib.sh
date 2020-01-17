# Retrieves the policy directories from the current org. Currenly requires sensitive until we think through the
# implication of having 'partial' policy access and whether that's ever useful.
#
# Returns one file per line, suitable for use with:
#
# while read VAR; do ... ; done < <(policiesGetPolicyDirs)
policiesGetPolicyDirs() {
  find "$(orgsPolicyRepo "$@")/node_modules/@liquid-labs" -maxdepth 1 -type d -name "policy-*"
}

# Will search policy dirs for TSV files. '--find-options' will be passed verbatim to find (see code). This function uses eval and it is unsafe to incorporate raw user input into the '--find-options' parameter.
policiesGetPolicyFiles() {
  eval "$(setSimpleOptions FIND_OPTIONS= -- "$@")"

  local DIR
  for DIR in $(policiesGetPolicyDirs); do
    # Not sure why the eval is necessary, but it is... (MacOS/Bash 3.x, 2020-01)
    eval find $DIR $FIND_OPTIONS -name '*.tsv'
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
