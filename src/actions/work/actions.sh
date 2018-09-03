work-start() {
  local BRANCH_DESC="${1:-}"
  local BRANCH_NAME="`date +%Y-%m-%d`-`whoami`-${BRANCH_DESC}"
  (requireArgs "${BRANCH_DESC}" \
   && git checkout -qb "${BRANCH_NAME}" \
   && echo "Now working on branch '${BRANCH_NAME}'.") \
  || exit $?
}

work-merge() {
  local WORKBRANCH=`git branch | (grep '*' || true) | awk '{print $2}'`
  if [ $WORKBRANCH == 'master' ]; then
    echoerr "Can't 'merge work' from master branch. Switch to workbranch with 'git checkout'." >&2
    return
  fi

  # in case the current working dir does not exist in master
  pushd ${BASE_DIR} \
  && git checkout master \
  && git merge --no-ff -m "merge branch $WORKBRANCH" "$WORKBRANCH" \
  && git push
  # TODO: provide a reference for checking the merge is present and if safe to delete.
  git branch -d "$WORKBRANCH" || echo "Could not delete '${WORKBRANCH}'. This can happen if the branch was renamed."
  popd
}

work-diff-master() {
  git diff HEAD..$(git merge-base master HEAD)
}
