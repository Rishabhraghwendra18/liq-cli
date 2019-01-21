work-diff-master() {
  git diff HEAD..$(git merge-base master HEAD)
}

work-edit() {
  requireCatalystfile
  # TODO: make editor configurable
  local EDITOR_CMD='atom'
  local OPEN_PROJ_CMD="${EDITOR_CMD} ."
  cd "${BASE_DIR}" && ${OPEN_PROJ_CMD}
}

work-start() {
  local BRANCH_DESC="${1:-}"
  local BRANCH_NAME=`branchName "${BRANCH_DESC}"`
  (requireArgs "${BRANCH_DESC}" \
   && git checkout -qb "${BRANCH_NAME}" \
   && echo "Now working on branch '${BRANCH_NAME}'.") \
  || exit $?
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

work-merge() {
  sourceCatalystfile

  git diff-index --quiet HEAD -- \
    || echoerrandexit 'Currint working branch has uncommitted changes. Please resolve before merging.' 1

  local WORKBRANCH=`git branch | (grep '*' || true) | awk '{print $2}'`
  if [ $WORKBRANCH == 'master' ]; then
    echoerr "Can't 'merge work' from master branch. Switch to workbranch with 'git checkout'." >&2
    return
  fi

  local SHORT_STAT=`git diff --shortstat master ${WORKBRANCH}`
  local INS_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ insertion' | awk '{print $1}' || true`
  INS_COUNT=${INS_COUNT:-0}
  local DEL_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ deletion' | awk '{print $1}' || true`
  DEL_COUNT=${DEL_COUNT:-0}
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
  git branch -qd "$WORKBRANCH" \
    || echoerr "Could not delete '${WORKBRANCH}'. This can happen if the branch was renamed."
  # TODO: provide a reference for checking the merge is present and if safe to delete.
  echo "linecount change: $DIFF_COUNT"
}

work-qa() {
  echo "Checking local repo status..."
  work-report
  echo "Checking package dependencies..."
  packages-version-check
  echo "Linting code..."
  packages-lint
  echo "Running tests..."
  packages-test
}

work-report() {
  local BRANCH_NAME
  statusReport() {
    local COUNT="$1"
    local DESC="$2"
    if (( $COUNT > 0 )); then
      echo "$1 files $2."
    fi
  }

  requireCatalystfile
  (cd "${BASE_DIR}"
   echo
   echo "${green}"`basename "$PWD"`; tput sgr0
   BRANCH_NAME=`git rev-parse --abbrev-ref HEAD 2> /dev/null || echo ''`
   if [[ $BRANCH_NAME == "HEAD" ]]; then
     echo "${red}NO WORKING BRANCH"
  else
    echo "On branch: ${green}${BRANCH_NAME}"
  fi
  tput sgr0
  statusReport `git status --porcelain | grep '^ M' | wc -l || true` 'modified'
  statusReport `git status --porcelain | grep '^R ' | wc -l || true` 'renamed'
  statusReport `git status --porcelain | grep '^RM' | wc -l || true` 'renamed and modifed'
  statusReport `git status --porcelain | grep '^D ' | wc -l || true` 'deleted'
  statusReport `git status --porcelain | grep '^ D' | wc -l || true` 'missing'
  statusReport `git status --porcelain | grep '^??' | wc -l || true` 'untracked'
  local TOTAL_COUNT=`git status --porcelain | wc -l | xargs || true`
  if (( $TOTAL_COUNT > 0 )); then
    echo -e "------------\n$TOTAL_COUNT total"
  fi
 )

  tput sgr0 # TODO: put this in the exit trap, too, I think.
}
