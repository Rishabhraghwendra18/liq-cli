work-start() {
  local BRANCH_DESC="${1:-}"
  local BRANCH_NAME="`date +%Y-%m-%d`-`whoami`-${BRANCH_DESC}"
  (requireArgs "${BRANCH_DESC}" \
   && git checkout -qb "${BRANCH_NAME}" \
   && echo "Now working on branch '${BRANCH_NAME}'.") \
  || exit $?
}

work-merge() {
  sourceCatalystfile

  git diff-index --quiet HEAD -- \
    || echoerrandexit 'Currint working branch has uncommitted changes. Please resolve before merging.' 1

  local WORKBRANCH=`git branch | (grep '*' || true) | awk '{print $2}'`
  if [ $WORKBRANCH == 'master' ]; then
    echoerr "Can't 'merge work' from master branch. Switch to workbranch with 'git checkout'." >&2
    return
  fi

  local INS_COUNT
  local DEL_COUNT
  for i in `git diff --shortstat master ${WORKBRANCH} | egrep -Eio -e '\d+ insertion|\d+ deletion' | awk '{print $1}'`; do
    if [[ -z "$INS_COUNT" ]]; then
      INS_COUNT="${i}"
    else DEL_COUNT="${i}"; fi
  done
  local DIFF_COUNT=$(( $INS_COUNT - $DEL_COUNT ))

  local PUSH_FAILED=N
  # in case the current working dir does not exist in master
  pushd ${BASE_DIR} > /dev/null \
  && (git checkout -q master \
      || (popd > /dev/null && echoerrandexit "Could not switch to master branch.")) \
  && (git merge --no-ff -qm "merge branch $WORKBRANCH" "$WORKBRANCH" \
      || (echoerrandexit "Problem merging work branch with master. (Working directory now: '$PWD')")) \
  && popd > /dev/null \
  && ( (git push -q && echo "Work merged and pushed to origin.") \
      || (PUSH_FAILED=Y && echoerr "Local merge successful, but there was a problem pushing work to master."))
  # if we have not exited, then the merge was made and we'll attempt to clean up
  # local work branch (even if the push fails)
  # git branch -qd "$WORKBRANCH" \
  # || echoerr "Could not delete '${WORKBRANCH}'. This can happen if the branch was renamed."
  # TODO: provide a reference for checking the merge is present and if safe to delete.
  echo "Linecount change: $DIFF_COUNT"
}

work-diff-master() {
  git diff HEAD..$(git merge-base master HEAD)
}

work-ignore-rest() {
  sourceCatalystfile

  pushd "${BASE_DIR}" > /dev/null
  touch .gitignore
  # first ignore whole directories
  for i in `git ls-files . --exclude-standard --others --directory`; do
    echo "${i}" >> .gitignore
  done
  popd > /dev/null
}
