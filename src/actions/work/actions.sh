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
    || ( echoerr 'Currint working branch has uncommitted changes. Please resolve before merging.' \
         && exit 1 )

  local WORKBRANCH=`git branch | (grep '*' || true) | awk '{print $2}'`
  if [ $WORKBRANCH == 'master' ]; then
    echoerr "Can't 'merge work' from master branch. Switch to workbranch with 'git checkout'." >&2
    return
  fi

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
  git branch -qd "$WORKBRANCH" \
   || echoerr "Could not delete '${WORKBRANCH}'. This can happen if the branch was renamed."
  # TODO: provide a reference for checking the merge is present and if safe to delete.
}

work-diff-master() {
  git diff HEAD..$(git merge-base master HEAD)
}

work-ignore-rest() {
  sourceCatalystfile

  touch "${BASE_DIR}/.gitignore"
  for i in `git ls-files . --exclude-standard --others --directory`; do
    local REL_PATH=`python -c "import os.path; print os.path.relpath('${PWD}/${i}', '${BASE_DIR}')"`
    echo "${REL_PATH}" >> "${BASE_DIR}/.gitignore"
  done
}
