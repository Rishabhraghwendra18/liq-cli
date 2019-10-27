requirements-work() {
  findBase
}

work-backup() {
  local TMP
  TMP=$(setSimpleOptions TEST -- "$@")
  eval "$TMP"

  if [[ "$TEST" != true ]]; then
    local OLD_MSG
    OLD_MSG="$(git log -1 --pretty=%B)"
    git commit --amend -m "${OLD_MSG} [no ci]"
  fi
  # TODO: retrive and use workbranch name instead
  git push workspace HEAD
}

work-diff-master() {
  git diff $(git merge-base master HEAD)..HEAD "$@"
}

work-edit() {
  # TODO: make editor configurable
  local EDITOR_CMD='atom'
  local OPEN_PROJ_CMD="${EDITOR_CMD} ."
  cd "${BASE_DIR}" && ${OPEN_PROJ_CMD}
}

work-ignore-rest() {
  pushd "${BASE_DIR}" > /dev/null
  touch .gitignore
  # first ignore whole directories
  for i in `git ls-files . --exclude-standard --others --directory`; do
    echo "${i}" >> .gitignore
  done
  popd > /dev/null
}

work-involve() {
  local PROJECT_NAME WORK_DESC WORK_STARTED WORK_INITIATOR WORK_BRANCH INVOLVED_PROJECTS
  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "There is no active unit of work to involve. Try:\nliq work resume"
  fi

  if (( $# == 0 )) && [[ -n "$BASE_DIR" ]]; then
    requirePackage
    PROJECT_NAME=$(echo "$PACKAGE" | jq --raw-output '.name | @sh' | tr -d "'")
  else
    exactUserArgs PROJECT_NAME -- "$@"
    test -d "${LIQ_PLAYGROUND}/${PROJECT_NAME}" \
      || echoerrandexit "Invalid project name '$PROJECT_NAME'. Perhaps it needs to be imported? Try:\nliq playground import <git URL>"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local BRANCH_NAME=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
  requirePackage # used later if auto-linking

  echo "${LIQ_PLAYGROUND}/${PROJECT_NAME}"
  cd "${LIQ_PLAYGROUND}/${PROJECT_NAME}"
  if git branch | grep -qE "^\*? *${BRANCH_NAME}\$"; then
    echowarn "Found existing work branch '${BRANCH_NAME}' in project ${PROJECT_NAME}. We will use it. Please fix manually if this is unexpected."
    git checkout -q "${BRANCH_NAME}" || echoerrandexit "There was a problem checking out the work branch. ($?)"
  else
    git checkout -qb "${BRANCH_NAME}" || echoerrandexit "There was a problem creating the work branch. ($?)"
    git push --set-upstream workspace ${BRANCH_NAME}
    echo "Created work branch '${BRANCH_NAME}' for project '${PROJECT_NAME}'."
  fi

  list-add-item INVOLVED_PROJECTS "${PROJECT_NAME}"
  workUpdateWorkDb

  local PRIMARY_PROJECT=$INVOLVED_PROJECTS
  if [[ "$PRIMARY_PROJECT" != "$PROJECT_NAME" ]]; then
    local NEW_PACKAGE_FILE
    while read NEW_PACKAGE_FILE; do
      local NEW_PACKAGE_NAME
      NEW_PACKAGE_NAME=$(cat "$NEW_PACKAGE_FILE" | jq --raw-output '.name | @sh' | tr -d "'")
      if echo "$PACKAGE" | jq -e ".dependencies and ((.dependencies | keys | any(. == \"${NEW_PACKAGE_NAME}\"))) or (.devDependencies and (.devDependencies | keys | any(. == \"${NEW_PACKAGE_NAME}\")))" > /dev/null; then
        :
        # Currently disabled
        # packages-link "${PROJECT_NAME}:${NEW_PACKAGE_NAME}"
      fi
    done < <(find "${LIQ_PLAYGROUND}/${PROJECT_NAME}" -name "package.json" -not -path "*node_modules/*")
  fi
}

work-issues() {
  local TMP
  TMP=$(setSimpleOptions LIST ADD= REMOVE= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current work selected; cannot list issues."
  fi
  source "${LIQ_WORK_DB}/curr_work"

  BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

  if [[ -n "$ADD" ]]; then
    local NEW_ISSUE NEW_ISSUES
    NEW_ISSUES="$(workProcessIssues "$ADD" "$BUGS_URL")"
    for NEW_ISSUE in $NEW_ISSUES; do
      list-add-item WORK_ISSUES "$NEW_ISSUE"
    done
  fi
  if [[ -n "$REMOVE" ]]; then
    local RM_ISSUE RM_ISSUES
    RM_ISSUES="$(workProcessIssues "$REMOVE" "$BUGS_URL")"
    for RM_ISSUE in $RM_ISSUES; do
      list-rm-item WORK_ISSUES "$RM_ISSUE"
    done
  fi
  if [[ -n "$LIST" ]] || [[ -z "$LIST" ]] && [[ -z "$ADD" ]] && [[ -z "$REMOVE" ]]; then
    echo "$WORK_ISSUES"
  fi
  if [[ -n "$ADD" ]] || [[ -n "$REMOVE" ]]; then
    workUpdateWorkDb
  fi
}

work-list() {
  local WORK_DESC WORK_STARTED WORK_INITIATOR WORK_BRANCH INVOLVED_PROJECTS
  # find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;
  for i in $(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;); do
    echo "${LIQ_WORK_DB}/${i}"
    source "${LIQ_WORK_DB}/${i}"
    echo -e "* ${yellow_b}${WORK_DESC}${reset}: started ${bold}${WORK_STARTED}${reset} by ${bold}${WORK_INITIATOR}${reset}"
  done
}

work-merge() {
  local WORK_DESC WORK_STARTED WORK_INITIATOR WORK_BRANCH INVOLVED_PROJECTS

  if [[ ! -f "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "You can only merge work in the current unit of work. Try:\nliq work select"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work" ))

  if [[ -z "$INVOLVED_PROJECTS" ]]; then
    echoerrandexit "No projects involved in the current unit of work '$CURR_WORK'."
  fi
  if (( $# == 0 )) && ! yesno "Are you sure want to merge the entire unit of work? (y/N)" 'N'; then
    return
  fi

  local TO_MERGE="$@"
  if [[ -z "$TO_MERGE" ]]; then
    TO_MERGE="$INVOLVED_PROJECTS"
  fi

  convert-dot() {
    if [[ . == "$TM" ]]; then
      TM=$(cat "$BASE_DIR/package.json" | jq --raw-output '.name' | tr -d "'")
    fi
  }

  local TM
  for TM in $TO_MERGE; do
    convert-dot
    if ! echo "$INVOLVED_PROJECTS" | grep -qE '(^| +)'$TM'( +|$)'; then
      echoerrandexit "Project '$TM' not in the current unit of work."
    fi
    requireCleanRepo "$TM"

    local WORKBRANCH=`git branch | (grep '*' || true) | awk '{print $2}'`
    if [[ "$WORKBRANCH" != "$CURR_WORK" ]]; then
      echoerrandexit "Project '$TM' is not currently on the expected workbranch '$CURR_WORK'. Please fix and re-run."
    fi
  done

  for TM in $TO_MERGE; do
    convert-dot
    cd "${LIQ_PLAYGROUND}/${TM}"
    local SHORT_STAT=`git diff --shortstat master ${WORKBRANCH}`
    local INS_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ insertion' | awk '{print $1}' || true`
    INS_COUNT=${INS_COUNT:-0}
    local DEL_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ deletion' | awk '{print $1}' || true`
    DEL_COUNT=${DEL_COUNT:-0}
    local DIFF_COUNT=$(( $INS_COUNT - $DEL_COUNT ))

    local CLOSE_MSG BUGS_URL
    BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")
    if [[ -z "$WORK_ISSUES" ]]; then
      echowarn "No issues associated with this unit of work."
    elif [[ -n "$BUGS_URL" ]]; then
      local ISSUE
      for ISSUE in $WORK_ISSUES; do
        if [[ $ISSUE == $BUGS_URL* ]]; then
          local NUMBER=${ISSUE/$BUGS_URL/}
          NUMBER=${NUMBER/\//}
          list-add-item CLOSE_MSG "closes #${NUMBER}"
          list-rm-item WORK_ISSUES "$ISSUE"
        fi
      done
    else
      echowarn "No issues URL associated with this project."
    fi

    local PUSH_FAILED=N
    # in case the current working dir does not exist in master
    (git checkout -q master \
        || echoerrandexit "Could not switch to master branch in project '$TM'.") \
    && (git merge --no-ff -qm "merge branch $WORKBRANCH" "$WORKBRANCH" -m "$CLOSE_MSG" \
        || echoerrandexit "Problem merging work branch with master for project '$TM'. ($?)") \
    && ( (git push -q && echo "Work merged and pushed to remotes.") \
        || (PUSH_FAILED=Y && echoerr "Local merge successful, but there was a problem pushing work to master."))
    # if we have not exited, then the merge was made and we'll attempt to clean up
    # local work branch (even if the push fails)
    git push workspace --delete $WORKBRANCH
    git branch -qd "$WORKBRANCH" \
      || echoerr "Could not delete '${WORKBRANCH}'. This can happen if the branch was renamed."
    # TODO: provide a reference for checking the merge is present and if safe to delete.
    echo "$TM linecount change: $DIFF_COUNT"

    # TODO: create and use 'lists-remove-item' in bash-tools
    list-rm-item INVOLVED_PROJECTS "$TM"
    workUpdateWorkDb
  done

  if (( $# == 0 )) && [[ -n "$INVOLVED_PROJECTS" ]]; then
    echoerrandexit "It may be that not all involved projects were committed. Leaving possibly uncomitted projects as part of the current unit of work."
  fi
  if [[ -z "${INVOLVED_PROJECTS}" ]]; then
    rm "${LIQ_WORK_DB}/curr_work"
    rm "${LIQ_WORK_DB}/${CURR_WORK}"
  fi
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
  # TODO: once 'git status' once and capture output
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

work-resume() {
  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    requireCleanRepos
  fi

  local WORK_NAME
  workUserSelectOne WORK_NAME '' true "$@"

  requireCleanRepos "${WORK_NAME}"

  local CURR_WORK
  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
    if [[ "${CURR_WORK}" == "${WORK_NAME}" ]]; then
      echowarn "'$CURR_WORK' is already the current unit of work."
      exit 0
    fi
    workSwitchBranches master
    rm "${LIQ_WORK_DB}/curr_work"
  fi
  cd "${LIQ_WORK_DB}" && ln -s "${WORK_NAME}" curr_work
  source "${LIQ_WORK_DB}"/curr_work
  workSwitchBranches "$WORK_NAME"

  if [[ -n "$CURR_WORK" ]]; then
    echo "Switched from '$CURR_WORK' to '$WORK_NAME'."
  else
    echo "Resumed '$WORK_NAME'."
  fi
}

work-save() {
  local TMP
  TMP=$(setSimpleOptions ALL MESSAGE= DESCRIPTION= -- "$@")
  eval "$TMP"

  if [[ -z "$MESSAGE" ]]; then
    echoerrandexit "Must specify '--message|-m' (summary) for save."
  fi

  local OPTIONS="-m '${MESSAGE/'//\'/\'}' "
  if [[ $ALL == true ]]; then OPTIONS="${OPTIONS}--all "; fi
  if [[ $DESCRIPTION == true ]]; then OPTIONS="${OPTIONS}-m '${MESSAGE/'//\'/\'}' "; fi
  git commit ${OPTIONS}commit
}

work-stage() {
  local TMP
  TMP=$(setSimpleOptions ALL INTERACTIVE REVIEW DRY_RUN -- "$@")
  eval "$TMP"

  local OPTIONS
  if [[ $ALL == true ]]; then OPTIONS="--all "; fi
  if [[ $INTERACTIVE == true ]]; then OPTIONS="${OPTIONS}--interactive "; fi
  if [[ $REVIEW == true ]]; then OPTIONS="${OPTIONS}--patch "; fi
  if [[ $DRY_RUN == true ]]; then OPTIONS="${OPTIONS}--dry-run "; fi

  git add ${OPTIONS}"$@"
}

work-status() {
  local TMP
  TMP=$(setSimpleOptions SELECT -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  local WORK_NAME
  workUserSelectOne WORK_NAME "$((test -n "$SELECT" && echo '') || echo "true")" '' "$@"

  echo "Branch name: $WORK_NAME"
  echo
  source "${LIQ_WORK_DB}/${WORK_NAME}"
  if [[ -z "$INVOLVED_PROJECTS" ]]; then
    "Involved projects: <none>"
  else
    echo "Involved projects:"
    local IP
    for IP in $INVOLVED_PROJECTS; do
      echo "  $IP"
    done
  fi

  echo
  if [[ -z "$WORK_ISSUES" ]]; then
    "Issues: <none>"
  else
    echo "Issues:"
    local ISSUE
    for ISSUE in $WORK_ISSUES; do
      echo "  $ISSUE"
    done
  fi

  for IP in $INVOLVED_PROJECTS; do
    echo
    echo "Repo status for $IP:"
    cd "${LIQ_PLAYGROUND}/$IP"
    TMP="$(git rev-list --left-right --count master...upstream/master)"
    local LOCAL_COMMITS REMOTE_COMMITS MASTER_UP_TO_DATE
    MASTER_UP_TO_DATE=false
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    if (( $LOCAL_COMMITS > 0 )); then
      echo "  ${red_b}Local master corrupted.${reset} Found $LOCAL_COMMITS local commits not on upstream." | fold -sw 82
    fi
    case $REMOTE_COMMITS in
      0)
        MASTER_UP_TO_DATE=true
        echo "  Local master up to date.";;
      *)
        echo "  ${yellow}Local master behind $REMOTE_COMMITS commits.${reset}";;
    esac

    TMP="$(git rev-list --left-right --count $WORK_NAME...workspace/$WORK_NAME)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    if (( $REMOTE_COMMITS == 0 )) && (( $LOCAL_COMMITS == 0 )); then
      echo "  Local workbranch up to date."
      TMP="$(git rev-list --left-right --count master...$WORK_NAME)"
      local MASTER_COMMITS WORKBRANCH_COMMITS
      MASTER_COMMITS=$(echo $TMP | cut -d' ' -f1)
      WORKBRANCH_COMMITS=$(echo $TMP | cut -d' ' -f2)
      if (( $MASTER_COMMITS == 0 )) && (( $WORKBRANCH_COMMITS == 0 )); then
        echo "  Workbranch and master up to date."
      elif (( $MASTER_COMMITS > 0 )); then
        echo "  Workbranch behind master $MASTER_COMMITS commits."
      elif (( $WORKBRANCH_COMMITS > 0 )); then
        echo "  Workbranch ahead of master $WORKBRANCH_COMMITS commits."
      fi
    elif (( $REMOTE_COMMITS > 0 )); then
      echo "  ${yellow}Local workbranch behind $REMOTE_COMMITS commits.${reset}"
    elif (( $LOCAL_COMMITS > 0 )); then
      echo "  ${yellow}Local workranch ahead $LOCAL_COMMITS commits.${reset}"
    fi
    if (( $REMOTE_COMMITS != 0 )) && (( $LOCAL_COMMITS != 0 )); then
      echo "  ${yellow}Unable to analyze master-workbranch drift due to above issues.${reset}" | fold -sw 82
    fi
    echo "  Local changes:"
    git status --short
  done
}

work-start() {
  local WORK_DESC WORK_STARTED WORK_INITIATOR WORK_BRANCH INVOLVED_PROJECTS WORK_ISSUES ISSUE TMP
  TMP=$(setSimpleOptions ISSUES= -- "$@")
  eval "$TMP"

  local CURR_PROJECT ISSUES_URL
  if [[ -n "$BASE_DIR" ]]; then
    CURR_PROJECT=$(cat "$BASE_DIR/package.json" | jq --raw-output '.name' | tr -d "'")
    BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")
  fi

  WORK_ISSUES="$(workProcessIssues "$ISSUES" "$BUGS_URL")"

  if [[ -z "$WORK_ISSUES" ]]; then
    echoerrandexit "Must specify at least 1 issue when starting a new unit of work."
  fi
  exactUserArgs WORK_DESC -- "$@"
  local WORK_DESC_SPEC='^[[:alnum:]][[:alnum:] -]+$'
  # TODO: require a minimum length of 5 alphanumeric characters.
  echo "$WORK_DESC" | grep -qE "$WORK_DESC_SPEC" \
    || echoerrandexit "Work description must begin with a letter or number, contain only letters, numbers, dashes and spaces, and have at least 2 characters (/$WORK_DESC_SPEC/)."

  WORK_STARTED=$(date "+%Y.%m.%d")
  WORK_INITIATOR=$(whoami)
  WORK_BRANCH=`workBranchName "${WORK_DESC}"`

  if [[ -f "${LIQ_WORK_DB}/${WORK_BRANCH}" ]]; then
    echoerrandexit "Unit of work '${WORK_BRANCH}' aready exists. Bailing out."
  fi

  # TODO: check that current work branch is clean before switching away from it
  # https://github.com/Liquid-Labs/liq-cli/issues/14

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    rm "${LIQ_WORK_DB}/curr_work"
  fi
  touch "${LIQ_WORK_DB}/${WORK_BRANCH}"
  cd ${LIQ_WORK_DB} && ln -s "${WORK_BRANCH}" curr_work
  workUpdateWorkDb

  if [[ -n "$CURR_PROJECT" ]]; then
    echo "Adding current project '$CURR_PROJECT' to unit of work..."
    work-involve "$CURR_PROJECT"
  fi
}

work-stop() {
  local TMP
  TMP=$(setSimpleOptions KEEP_CHECKOUT -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    local CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
    if [[ -z "$KEEP_CHECKOUT" ]]; then
      requireCleanRepos
      workSwitchBranches master
    else
      source "${LIQ_WORK_DB}/curr_work"
      echo "Current branch "$CURR_WORK" maintained for ${INVOLVED_PROJECTS}."
    fi
    rm "${LIQ_WORK_DB}/curr_work"
    echo "Paused work on '$CURR_WORK'. No current unit of work."
  else
    echoerrandexit "No current unit of work to stop."
  fi
}
