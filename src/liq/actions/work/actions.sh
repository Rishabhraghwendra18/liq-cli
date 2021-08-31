requirements-work() {
  :
}

work-backup() {
  work-lib-require-unit-of-work

  eval "$(setSimpleOptions TEST -- "$@")"

  if [[ "$TEST" != true ]]; then
    local OLD_MSG
    OLD_MSG="$(git log -1 --pretty=%B)"
    git commit --amend -m "${OLD_MSG} [no ci]"
  fi
  # TODO: retrive and use workbranch name instead
  git push workspace HEAD
}

work-build() {
  for PROJECT in $INVOLVED_PROJECTS; do
    PROJECT="${PROJECT/@/}"
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    projects-build "$@"
  done
}

work-diff() {
  eval "$(setSimpleOptions MAIN -- "$@")"

  source "${LIQ_WORK_DB}/curr_work"

  local PROJECTS="$INVOLVED_PROJECTS"

  for PROJECT in $PROJECTS; do
    PROJECT="${PROJECT/@/}"
    PROJECT=$(workConvertDot "$PROJECT")
    (
      cd "${LIQ_PLAYGROUND}/${PROJECT}"

      if [[ -n "${MAIN}" ]]; then
        git diff $(git merge-base master HEAD)..HEAD
      else
        git diff
      fi
    )
  done
}

work-diff-master() {
  work-lib-require-unit-of-work

  git diff $(git merge-base master HEAD)..HEAD "$@"
}

work-close() {
  eval "$(setSimpleOptions POP TEST NO_SYNC -- "$@")"
  source "${LIQ_WORK_DB}/curr_work"
  findBase

  local PROJECTS
  if (( $# > 0 )); then
    PROJECTS="$@"
  else
    PROJECTS="$INVOLVED_PROJECTS"
  fi

  local PROJECT
  # first, do the checks
  for PROJECT in $PROJECTS; do
    PROJECT=$(workConvertDot "$PROJECT")
    PROJECT="${PROJECT/@/}"
    local CURR_BRANCH
    (
      cd "${LIQ_PLAYGROUND}/${PROJECT}"
      CURR_BRANCH=$(workCurrentWorkBranch)

      if [[ "$CURR_BRANCH" != "$WORK_BRANCH" ]]; then
        echoerrandexit "Local project '$PROJECT' repo branch does not match expected work branch."
      fi

      requireCleanRepo "$PROJECT"
    )
  done

  # now actually do the closures
  for PROJECT in $PROJECTS; do
    PROJECT=$(workConvertDot "$PROJECT")
    PROJECT="${PROJECT/@/}"
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    local CURR_BRANCH
    CURR_BRANCH=$(git branch | (grep '*' || true) | awk '{print $2}')

    git checkout master
    git push workspace "${WORK_BRANCH}:${WORK_BRANCH}" \
      || echoerrandexit "Could not push '${WORK_BRANCH}' to workspace; refusing to close without backing up."
    git branch -qd "$WORK_BRANCH" \
      || ( echoerr "Could not delete local '${WORK_BRANCH}'. This can happen if the branch was renamed." \
          && false)
    list-rm-item INVOLVED_PROJECTS "@${PROJECT}" # this cannot be done in a subshell
    workUpdateWorkDb
		if [[ -z "$NO_SYNC" ]]; then
			projects-sync --project="${PROJECT}"
		fi
    # Notice we don't close the workspace branch. It may be involved in a PR and, generally, we don't care if the
    # workspace gets a little messy. TODO: reference workspace cleanup method here when we have one.
  done

  # If all involved projects are closed, then our work is done.
  if [[ -z "${INVOLVED_PROJECTS}" ]]; then
    rm "${LIQ_WORK_DB}/curr_work"
    rm "${LIQ_WORK_DB}/${WORK_BRANCH}"

    if [[ -n "$POP" ]]; then
      work-resume --pop
    fi
  fi
}

# Helps get users find the right command.
work-commit() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.
  # The command generator is a bit hackish; do we have a library that handles the quotes correctly?
  echoerrandexit "Invalid action 'commit'; do you want to 'save'?\nRefer to:\nliq help work save\nor try:\nliq work save $(for i in "$@"; do if [[ "$i" == *' '* ]]; then echo -n "'$i' "; else echo -n "$i "; fi; done)"
}

# `liq help work edit`
# TODO: untested
work-edit() {
  source "${LIQ_WORK_DB}/curr_work"
  findBase

  local PROJECTS
  if (( $# > 0 )); then
    PROJECTS="$@"
  else
    PROJECTS="$INVOLVED_PROJECTS"
  fi

  local PROJECT
  # TODO: first, do the checks
  ( for PROJECT in $PROJECTS; do
    PROJECT=$(workConvertDot "$PROJECT")
    PROJECT="${PROJECT/@/}"
    cd "${LIQ_PLAYGROUND}/${PROJECT}"

    projects-edit
  done )
}

work-ignore-rest() {
  findBase
  pushd "${BASE_DIR}" > /dev/null
  touch .gitignore
  # first ignore whole directories
  for i in `git ls-files . --exclude-standard --others --directory`; do
    echo "${i}" >> .gitignore
  done
  popd > /dev/null
}

work-involve() {
  findBase # this will be optional once we support '--project'

  eval "$(setSimpleOptions NO_LINK:L WORK_STARTED:= WORK_INITIATOR:= -- "$@")"

  local PROJECT_NAME WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "There is no active unit of work to involve. Try:\nliq work resume"
  fi

  # check for source repo access
  check-git-access
  # gather necessary information
  if (( $# == 0 )) && [[ -n "$BASE_DIR" ]]; then
    requirePackage
    PROJECT_NAME=$(echo "$PACKAGE" | jq --raw-output '.name | @sh' | tr -d "'")
    PROJECT_NAME=${PROJECT_NAME/@/}
  else
    exactUserArgs PROJECT_NAME -- "$@"
    PROJECT_NAME=${PROJECT_NAME/@/}
    test -d "${LIQ_PLAYGROUND}/${PROJECT_NAME}" \
      || echoerrandexit "Invalid project name '$PROJECT_NAME'. Perhaps it needs to be imported? Try:\nliq playground import <git URL>"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local BRANCH_NAME=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
  requirePackage # used later if auto-linking

  # setup work branch
  cd "${LIQ_PLAYGROUND}/${PROJECT_NAME}"
  if git branch | grep -qE "^\*? *${BRANCH_NAME}\$"; then
    echowarn "Found existing work branch '${BRANCH_NAME}' in project ${PROJECT_NAME}. We will use it. Please fix manually if this is unexpected."
    git checkout -q "${BRANCH_NAME}" || echoerrandexit "There was a problem checking out the work branch. ($?)"
  else
    git checkout -qb "${BRANCH_NAME}" || echoerrandexit "There was a problem creating the work branch. ($?)"
    git push --set-upstream workspace ${BRANCH_NAME}
    echo "Created work branch '${BRANCH_NAME}' for project '${PROJECT_NAME}'."
  fi

  # local administrative stuff
  local OTHER_PROJECTS="${INVOLVED_PROJECTS}" # save this for use in linking later...
  list-add-item INVOLVED_PROJECTS "@${PROJECT_NAME}" # do include the '@' here for display
  workUpdateWorkDb

  # create changelog entry
  work-lib-changelog-add-entry

  # Now, let's see about automatic linking!
  local PRIMARY_PROJECT=$INVOLVED_PROJECTS
  # if this is the first/primary project, no need to worry about linking
  if [[ "$PRIMARY_PROJECT" != "$PROJECT_NAME" ]] && [[ -z "${NO_LINK}" ]]; then
    # first, link this project to other projects
    local LINKS
    work-links-add --set-links LINKS "${PROJECT_NAME}"
    # now link other, already involved projects to this project
    cd "${LIQ_PLAYGROUND}/${PROJECT_NAME}"
    local SOURCE_PROJ
    for SOURCE_PROJ in $OTHER_PROJECTS; do
      if projects-lib-has-any-dep "${PROJECT_NAME}" "${SOURCE_PROJ}"; then
        if [[ -n "$(list-get-index LINKS "${SOURCE_PROJ}")" ]]; then
          echowarn "Project '${SOURCE_PROJ}' linked to '${PROJECT_NAME}', but '${PROJECT_NAME}' also depends on '${SOURCE_PROJ}'; skipping the link back-link to avoid circular reference."
        else
          work-links-add --projects="${PROJECT_NAME}" "${SOURCE_PROJ}"
        fi
      fi
    done
  fi
}

work-issues() {
  findBase

  eval "$(setSimpleOptions LIST ADD= REMOVE= -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current work selected; cannot list issues."
  fi
  source "${LIQ_WORK_DB}/curr_work"

  BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

  if [[ -n "$ADD" ]]; then
    local NEW_ISSUE NEW_ISSUES
    work-lib-process-issues NEW_ISSUES "$ADD" "$BUGS_URL"
    for NEW_ISSUE in $NEW_ISSUES; do
      list-add-item WORK_ISSUES "$NEW_ISSUE"
    done
  fi
  if [[ -n "$REMOVE" ]]; then
    local RM_ISSUE RM_ISSUES
    work-lib-process-issues RM_ISSUES "$REMOVE" "$BUGS_URL"
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

# see liq help work list
work-list() {
  local WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  # find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;
  for i in $(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;); do
    echo "${LIQ_WORK_DB}/${i}"
    source "${LIQ_WORK_DB}/${i}"
    echo -e "* ${yellow_b}${WORK_DESC}${reset}: started ${bold}${WORK_STARTED}${reset} by ${bold}${WORK_INITIATOR}${reset}"
  done
}

# see liq help work merge
work-merge() {
  # TODO: https://github.com/liquid-labs/liq-cli/issues/57 support org-level config to default allow unforced merge
  eval "$(setSimpleOptions FORCE CLOSE PUSH_UPSTREAM -- "$@")"

  if [[ "${PUSH_UPSTREAM}" == true ]] && [[ "$FORCE" != true ]]; then
    echoerrandexit "'work merge --push-upstream' is not allowed by default. You can use '--force', but generally you will either want to configure the project to enable non-forced upstream merges or try:\nliq work submit"
  fi

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "'merge' can only be perfomred on the current unit of work. Try:\nliq work resume"
  fi

  local WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  source "${LIQ_WORK_DB}/curr_work"

  if [[ -z "$INVOLVED_PROJECTS" ]]; then
    echoerrandexit "No projects involved in the current unit of work '${WORK_BRANCH}'."
  fi
  if (( $# == 0 )) && ! yes-no "Are you sure want to merge the entire unit of work? (y/N)" 'N'; then
    return
  fi

  local TO_MERGE="$@"
  if [[ -z "$TO_MERGE" ]]; then
    TO_MERGE="$INVOLVED_PROJECTS"
  fi

  local TM
  for TM in $TO_MERGE; do
    TM=$(workConvertDot "$TM")
    if ! echo "$INVOLVED_PROJECTS" | grep -qE '(^| +)'$TM'( +|$)'; then
      echoerrandexit "Project '$TM' not in the current unit of work."
    fi
    local CURR_BRANCH
    CURR_BRANCH=$(git branch | (grep '*' || true) | awk '{print $2}')
    if [[ "$CURR_BRANCH" != master ]] && [[ "$CURR_BRANCH" != "$WORK_BRANCH" ]]; then
      echoerrandexit "Project '$TM' is not currently on the expected workbranch '$WORK_BRANCH'. Please fix and re-run."
    fi
    requireCleanRepo "$TM"
  done

  for TM in $TO_MERGE; do
    TM=$(workConvertDot "$TM")
    TM=${TM/@/}
    cd "${LIQ_PLAYGROUND}/${TM}"
    local SHORT_STAT=`git diff --shortstat master ${WORK_BRANCH}`
    local INS_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ insertion' | awk '{print $1}' || true`
    INS_COUNT=${INS_COUNT:-0}
    local DEL_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ deletion' | awk '{print $1}' || true`
    DEL_COUNT=${DEL_COUNT:-0}
    local DIFF_COUNT=$(( $INS_COUNT - $DEL_COUNT ))

    # TODO: don't assume the merge closes anything; may be merging for different reasons. Accept '--no-close' option or
    # '--closes=x,y,z' where x etc. are alread associated to the unit of work
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
        fi
      done
    else
      echowarn "No issues URL associated with this project."
    fi

    cleanupMaster() {
      cd ${BASE_DIR}
      git worktree remove _master
    }

    cd ${BASE_DIR}
    # if [[ "${WORK_BRANCH}" != master ]]; then
    #  git checkout -q master \
    #    || echoerrandexit "Could not switch to master branch in project '$TM'."
    # fi
    (git worktree add _master master \
      || echoerrandexit "Could not create 'master' worktree.") \
    && (cd _master; git pull upstream master:master \
        || (cleanupMaster; echoerrandexit $echoerrandexit "Could not update local master from upstream for '$TM'.")) \
    && (cd _master; git merge --no-ff -qm "merge branch $WORK_BRANCH" "$WORK_BRANCH" -m "$CLOSE_MSG" \
        || (cleanupMaster; echoerrandexit "Problem merging '${WORK_BRANCH}' with 'master' for project '$TM'. ($?)")) \
    && (cleanupMaster || echoerr "There was a problem removing '_master' worktree.") \
    && ( (git push -q workspace master:master && echo "Work merged to 'master' and pushed to workspace/master.") \
        || echoerr "Local merge successful, but there was a problem pushing work to workspace/master; bailing out.")

    if [[ "$PUSH_UPSTREAM" == true ]]; then
      git push -q upstream master:master \
        || echoerrandexit "Failed to push local master to upstream master. Bailing out."
    fi

    if [[ "$CLOSE" == true ]]; then
      work-close "$TM"
    fi

    echo "$TM linecount change: $DIFF_COUNT"
  done
}

work-prepare() {
  local TO_PROCESS="$@"
  if [[ -z "${TO_PROCESS}" ]]; then
    TO_PROCESS="${INVOLVED_PROJECTS}"
  fi

  for PROJECT in ${TO_PROCESS}; do
    PROJECT=$(workConvertDot "${PROJECT}")
    requireCleanRepo "${PROJECT}"
  done
  # TODO: pass option to skip clean check
  # work-qa
  # work-build

  for PROJECT in ${TO_PROCESS}; do
    PROJECT=$(workConvertDot "${PROJECT}")
    PROJECT="${PROJECT/@/}"
    (
      cd "${LIQ_PLAYGROUND}/${PROJECT}"
      work-lib-changelog-finalize-entry
      # it's possible the changes have already been made...
      if (( $(git status --porcelain | wc -l) != 0)); then
        git add .meta # this is considered safe becaues we checked the repo was clean
        work-save -m "changelog finalization (by liq)" "${PROJECT}"
      fi
    )
  done
}

work-qa() {
  work-lib-require-unit-of-work

  echo "Checking local repo status..."
  work-report

  for PROJECT in $INVOLVED_PROJECTS; do
    PROJECT="${PROJECT/@/}"
    # TODO: shouldn't this be done in a subshell?
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    projects-qa "$@"
  done
}

work-report() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

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

# See 'liq help work resume'
work-resume() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  eval "$(setSimpleOptions POP -- "$@")"
  local WORK_NAME
  if [[ -z "$POP" ]]; then
    # if no args, gives list of availabale work units; otherwise interprets argument as a work name
    workUserSelectOne WORK_NAME '' true "$@"

    if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
      if [[ "${LIQ_WORK_DB}/curr_work" -ef "${LIQ_WORK_DB}/${WORK_NAME}" ]]; then
        echowarn "'$WORK_NAME' is already the current unit of work."
        exit 0
      fi
    fi
  elif [[ -f "${LIQ_WORK_DB}/prev_work00" ]]; then
    local PREV_WORK
    PREV_WORK="$(ls ${LIQ_WORK_DB}/prev_work?? | sort --reverse | head -n 1)"
    mv "$PREV_WORK" "${LIQ_WORK_DB}/curr_work"
    WORK_NAME="$(source ${LIQ_WORK_DB}/curr_work; echo "$WORK_BRANCH")"
  else
    echoerrandexit "No previous unit of work found."
  fi

  workSwitchBranches --dirty-ok "$WORK_NAME"
  (
    cd "${LIQ_WORK_DB}"
    rm -f curr_work
    ln -s "${WORK_NAME}" curr_work
  )

  echo "Resumed '$WORK_NAME'."
}

# Alias for 'work-resume'
work-join() { work-resume "$@"; }

work-save() {
  findBase
  work-lib-require-unit-of-work

  eval "$(setSimpleOptions ALL MESSAGE= DESCRIPTION= NO_BACKUP:B BACKUP_ONLY -- "$@")"

  if [[ "$BACKUP_ONLY" == true ]] && [[ "$NO_BACKUP" == true ]]; then
    echoerrandexit "Incompatible options: '--backup-only' and '--no-backup'."
  fi

  if [[ "$BACKUP_ONLY" != true ]] && [[ -z "$MESSAGE" ]]; then
    echoerrandexit "Must specify '--message|-m' (summary) for save."
  fi

  local SAVE_ALL=false
  local TO_SAVE="$@"
  if [[ -z "${TO_SAVE:-}" ]]; then
    TO_SAVE="$INVOLVED_PROJECTS"
    SAVE_ALL=true
  fi

  local IP
  for IP in ${TO_SAVE}; do
    IP=$(workConvertDot "$IP")
    IP="${IP/@/}"
    (
      cd "${LIQ_PLAYGROUND}/$IP"
      if [[ "${SAVE_ALL}" != true ]] || ! git diff-index --quiet HEAD --; then
        if [[ "${BACKUP_ONLY}" != true ]]; then
          local OPTIONS="-m '"${MESSAGE//\'/\'\"\'\"\'}"' "
          if [[ $ALL == true ]]; then OPTIONS="${OPTIONS}--all "; fi
          if [[ $DESCRIPTION == true ]]; then OPTIONS="${OPTIONS}-m '"${DESCRIPTION/'//\'/\'\"\'\"\'}"' "; fi
          # I have no idea why, but without the eval (even when "$@" dropped), this
          # produced 'fatal: Paths with -a does not make sense.' What' path?
          eval git commit ${OPTIONS} # "$@" TODO: support this with '--' to pass args to git
        fi
        if [[ "$NO_BACKUP" != true ]]; then
          work-backup
        fi
      fi
    )
  done
}

work-stage() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  eval "$(setSimpleOptions ALL INTERACTIVE REVIEW DRY_RUN -- "$@")"

  local OPTIONS
  if [[ $ALL == true ]]; then OPTIONS="--all "; fi
  if [[ $INTERACTIVE == true ]]; then OPTIONS="${OPTIONS}--interactive "; fi
  if [[ $REVIEW == true ]]; then OPTIONS="${OPTIONS}--patch "; fi
  if [[ $DRY_RUN == true ]]; then OPTIONS="${OPTIONS}--dry-run "; fi

  git add ${OPTIONS} "$@"
}

work-status() {
  eval "$(setSimpleOptions PR_READY: NO_FETCH:F LIST_PROJECTS:p LIST_ISSUES:i -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  check-git-access --no-exit || \
    {
      NO_FETCH=1
      echowarn "No git access. Results may not be in sync with remote sources. Try:\nliq meta logins ensure"
    }

  local WORK_NAME LOCAL_COMMITS REMOTE_COMMITS
  WORK_NAME="${1:-}"
  # Set WORK_NAME to curr work if present
  [[ -n "${WORK_NAME}" ]] || ! [[ -f "${LIQ_WORK_DB}/curr_work" ]] \
    || WORK_NAME="$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))"
  [[ -n "${WORK_NAME}" ]] || echoerrandexit "No current work. You must specify work to show status."

  if [[ "$PR_READY" == true ]]; then
    git fetch workspace "${WORK_NAME}:remotes/workspace/${WORK_NAME}"
    TMP="$(git rev-list --left-right --count $WORK_NAME...workspace/$WORK_NAME)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    (( $LOCAL_COMMITS == 0 )) && (( $REMOTE_COMMITS == 0 ))
    return $?
  fi

  source "${LIQ_WORK_DB}/${WORK_NAME}"
  if [[ -n "$LIST_PROJECTS" ]]; then
    echo "$INVOLVED_PROJECTS"
    return $?
  elif [[ -n "$LIST_ISSUES" ]]; then
    echo "$WORK_ISSUES"
    return $?
  fi

  if [[ -z "$NO_FETCH" ]]; then
    work-sync --fetch-only
  fi

  echo "Branch name: $WORK_NAME"
  echo
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
    IP="${IP/@/}"
    echo
    echo "Repo status for $IP:"
    cd "${LIQ_PLAYGROUND}/$IP"
    TMP="$(git rev-list --left-right --count master...upstream/master)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    if (( $LOCAL_COMMITS == 0 )) && (( $REMOTE_COMMITS == 0 )); then
      echo "  Local master up to date."
    elif (( $LOCAL_COMMITS == 0 )); then
      echo "  ${yellow_b}Local master behind upstream/master $REMOTE_COMMITS.${reset}"
    elif (( $REMOTE_COMMITS == 0 )); then
      echo "  ${yellow_b}Local master ahead upstream/master $LOCAL_COMMITS.${reset}"
    else
      echo "  ${yellow_b}Local master ahead upstream/master $LOCAL_COMMITS and behind $REMOTE_COMMITS.${reset}"
    fi

    local NEED_SYNC
    TMP="$(git rev-list --left-right --count $WORK_NAME...workspace/$WORK_NAME)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    if (( $REMOTE_COMMITS == 0 )) && (( $LOCAL_COMMITS == 0 )); then
      echo "  Local workbranch up to date with workspace."
      TMP="$(git rev-list --left-right --count master...$WORK_NAME)"
      local MASTER_COMMITS WORKBRANCH_COMMITS
      MASTER_COMMITS=$(echo $TMP | cut -d' ' -f1)
      WORKBRANCH_COMMITS=$(echo $TMP | cut -d' ' -f2)
      if (( $MASTER_COMMITS == 0 )) && (( $WORKBRANCH_COMMITS == 0 )); then
        echo "  Local workbranch and master up to date."
      elif (( $MASTER_COMMITS > 0 )); then
        echo "  ${yellow}Workbranch behind master $MASTER_COMMITS commits.${reset}"
        NEED_SYNC=true
      elif (( $WORKBRANCH_COMMITS > 0 )); then
        echo "  Local workbranch ahead of master $WORKBRANCH_COMMITS commits."
      fi
    elif (( $LOCAL_COMMITS == 0 )); then
      echo "  ${yellow}Local workbranch behind workspace by $REMOTE_COMMITS commits.${reset}"
      NEED_SYNC=true
    elif (( $REMOTE_COMMITS == 0 )); then
      echo "  ${yellow}Local workranch ahead of workspace by $LOCAL_COMMITS commits.${reset}"
      NEED_SYNC=true
    else
      echo "  ${yellow}Local workranch ahead of workspace by $LOCAL_COMMITS and behind ${REMOTE_COMMITS} commits.${reset}"
      NEED_SYNC=true
    fi
    if (( $REMOTE_COMMITS != 0 )) || (( $LOCAL_COMMITS != 0 )); then
      echo "  ${yellow}Unable to analyze master-workbranch drift due to above issues.${reset}" | fold -sw 82
    fi
    if [[ -n "$NEED_SYNC" ]]; then
      echo "  Consider running:"
      echo "    liq work sync"
    fi
    echo
    echo "  Local changes:"
    git status --short
  done
}
# alias TODO: I think I might like 'show' better after all
work-show() { work-status "$@"; }

work-start() {
  check-git-access

  findBase

  eval "$(setSimpleOptions ISSUES= PUSH DESCRIPTION= -- "$@")"

  local CURR_PROJECT ISSUES_URL BUGS_URL WORK_ISSUES
  if [[ -n "${BASE_DIR}" ]]; then
    CURR_PROJECT=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name' | tr -d "'")
    BUGS_URL=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.bugs.url' | tr -d "'")
    [[ -n "${BUGS_URL}" ]] && [[ "${BUGS_URL}" != 'null' ]] \
      || echoerrandexit "The '.bugs.url' is not defined in '${BASE_DIR}/package.json'"
  else
    echoerrandexit "Could not determine project base directory."
  fi

  work-lib-process-issues WORK_ISSUES "${ISSUES}" "${BUGS_URL}"

  if [[ -z "$WORK_ISSUES" ]]; then
    echoerrandexit "Must specify at least 1 issue when starting a new unit of work."
  fi

  if [[ -z "$DESCRIPTION" ]]; then
    local PRIMARY_ISSUE
    # The issues have been normalized, so his is always a URL
    PRIMARY_ISSUE=$(list-get-item WORK_ISSUES 0 | sed -Ee 's|.+/([[:digit:]]+)$|\1|')

    DESCRIPTION="$(hub issue show $PRIMARY_ISSUE | head -n 1 | sed -E 's/^# *//')" \
      || echoerrandexit "Error trying to extract issue description from: ${BUGS_URL}/${PRIMARY_ISSUE}\nThe primary issues must be part of the current project."
  fi

  local WORK_STARTED WORK_INITIATOR WORK_BRANCH # set by work-lib-workbranch-name
  work-lib-work-branch-name "${DESCRIPTION}"

  if [[ -f "${LIQ_WORK_DB}/${WORK_BRANCH}" ]]; then
    echoerrandexit "Unit of work '${WORK_BRANCH}' aready exists. Bailing out."
  fi

  # TODO: check that current work branch is clean before switching away from it
  # https://github.com/liquid-labs/liq-cli/issues/14

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    if [[ -n "$PUSH" ]]; then
      local PREV_WORK LAST NEXT
      LAST='-1' # starts us at 0 after the undconditional +1
      if [[ -f ${LIQ_WORK_DB}/prev_work00 ]]; then
        for PREV_WORK in $(ls ${LIQ_WORK_DB}/prev_work?? | sort); do
          LAST=${i:$((${#i} - 2))}
        done
      fi
      NEXT=$(( $LAST + 1 ))
      if (( $NEXT > 99 )); then
        echoerrandexit "There are already 100 'pushed' units of work; limit reached."
      fi
      mv "${LIQ_WORK_DB}/curr_work" "${LIQ_WORK_DB}/prev_work$(printf '%02d' "${NEXT}")"
    else
      rm "${LIQ_WORK_DB}/curr_work"
    fi
  fi
  touch "${LIQ_WORK_DB}/${WORK_BRANCH}"
  cd ${LIQ_WORK_DB} && ln -s "${WORK_BRANCH}" curr_work
  local WORK_DESC="$DESCRIPTION"
  workUpdateWorkDb

  # TODO: see 'TODO: if no BASE_DIR'
  if [[ -n "$CURR_PROJECT" ]]; then
    (
      cd "${LIQ_PLAYGROUND}/${CURR_PROJECT/@/}"
      echo "Adding current project '$CURR_PROJECT' to unit of work..."
      work-involve "$CURR_PROJECT"
    )
  fi
}

work-stop() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  eval "$(setSimpleOptions KEEP_CHECKOUT -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    local CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
    if [[ -z "$KEEP_CHECKOUT" ]]; then
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

work-sync() {
  eval "$(setSimpleOptions FETCH_ONLY -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ ! -f "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current unit of work. Try:\nliq projects sync"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local IP OPTS
  if [[ -n "$FETCH_ONLY" ]]; then OPTS="--fetch-only "; fi
  for IP in $INVOLVED_PROJECTS; do
    (
      cd "${LIQ_PLAYGROUND}/${IP/@/}"
      echo "Syncing project '${IP}'..."
      projects-sync ${OPTS} "${IP}"
    )
  done
}

work-test() {
  eval "$(setSimpleOptions SELECT -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local WORK_NAME
  workUserSelectOne WORK_NAME "$((test -n "$SELECT" && echo '') || echo "true")" '' "$@"
  source "${LIQ_WORK_DB}/${WORK_NAME}"

  local IP
  for IP in $INVOLVED_PROJECTS; do
    IP="${IP/@/}"
    echo "Testing ${IP}..."
    cd "${LIQ_PLAYGROUND}/${IP}"
    projects-test "$@"
  done
}

work-submit() {
  eval "$(setSimpleOptions MESSAGE= NOT_CLEAN:C NO_CLOSE:X NO_BROWSE:B FORCE -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  findBase
  check-git-access

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current unit of work. Try:\nliq work resume."
  fi

  source "${LIQ_WORK_DB}/curr_work"

  work-prepare "$@" # TODO: I'm just kinda jabbing this in here because I want to use the work we did in prepare, but the manual tie in is too much. It needs to happen more automatically.

  if [[ -z "$MESSAGE" ]]; then
    MESSAGE="$WORK_DESC" # sourced from current work
  fi

  local TO_SUBMIT="$@"
  if [[ -z "$TO_SUBMIT" ]]; then
    TO_SUBMIT="$INVOLVED_PROJECTS"
  fi

  local IP
  # preflilght check
  for IP in $TO_SUBMIT; do
    IP=$(workConvertDot "$IP")
    if ! echo "$INVOLVED_PROJECTS" | grep -qE '(^| +)'$IP'( +|$)'; then
      echoerrandexit "Project '$IP' not in the current unit of work."
    fi

    if [[ "$NOT_CLEAN" != true ]]; then
      requireCleanRepo "${IP}"
    fi
    # TODO: This is incorrect, we need to check IP; https://github.com/liquid-labs/liq-cli/issues/121
    # TODO: might also be redundant with 'requireCleanRepo'...
    if ! work-status --pr-ready; then
      echoerrandexit "Local work branch not in sync with remote work branch. Try:\nliq work save --backup-only"
    fi
  done

  # OK, let's do it
  for IP in $TO_SUBMIT; do
    IP=$(workConvertDot "$IP")
    cd "${LIQ_PLAYGROUND}/${IP/@/}"
    echo "Preparing PR for ${IP}..."

    local DESC="Merge ${WORK_BRANCH} to master

## Summary

${MESSAGE}

## Issues

"

    local PROJ_ISSUES=''
    local OTHER_ISSUES=''

    # get IP bugs URL in order to figure out what tasks are directly related to this project.
    local BUGS_URL
    BUGS_URL=$(cat "${LIQ_PLAYGROUND}/${IP/@/}/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

    local ISSUE
    for ISSUE in $WORK_ISSUES; do
      if [[ $ISSUE == $BUGS_URL* ]]; then
        local NUMBER=${ISSUE/$BUGS_URL/}
        NUMBER=${NUMBER/\//}
        list-add-item PROJ_ISSUES "#${NUMBER}"
      else
        local LABEL="$(echo "$ISSUE" | awk -F/ '{ print $4"/"$5"#"$7 }')"
        list-add-item OTHER_ISSUES "[${LABEL}](${ISSUE})"
      fi
    done

    if [[ -n "$PROJ_ISSUES" ]]; then
      if [[ -z "$NO_CLOSE" ]];then
        DESC="${DESC}"$'\n'"$( for ISSUE in $PROJ_ISSUES; do echo "* closes $ISSUE"; done)"
      else
        DESC="${DESC}"$'\n'"$( for ISSUE in $PROJ_ISSUES; do echo "* driven by $ISSUE"; done)"
      fi
    fi
    if [[ -n "$OTHER_ISSUES" ]]; then
      DESC="${DESC}"$'\n'"$( for ISSUE in ${OTHER_ISSUES}; do echo "* involved with $ISSUE"; done)"
    fi

    # check for the 'work-policy-review' extension point
    if [[ $(type -t "work-policy-review" || echo '') == 'function' ]]; then
      DESC="${DESC}$(work-policy-review "$TO_SUBMIT")"
    fi

    local BASE_TARGET # this is the 'org' of the upsteram branch
    BASE_TARGET=$(git remote -v | grep '^upstream' | grep '(push)' | sed -E 's|.+[/:]([^/]+)/[^/]+$|\1|')
    # Some research indicates that explicitly specifying head can work around some bugs...
    # local BASE_HEAD
    # BASE_HEAD=$(git remote -v | grep '^workspace' | grep '(push)' | sed -E 's|.+[/:]([^/]+)/[^/]+$|\1|')
    local PULL_OPTS="--push --base=${BASE_TARGET}:master" #--head=${BASE_HEAD}:${WORK_BRANCH}"
    if [[ -z "$NO_BROWSE" ]]; then
      PULL_OPTS="$PULL_OPTS --browse"
    fi
    if [[ -n "$FORCE" ]]; then
      PULL_OPTS="$PULL_OPTS --force"
    fi
    echo "Submitting PR for '$IP'..."
    hub pull-request $PULL_OPTS -m "${DESC}" || {
      echoerrandexit "Submission failed. If you see an error mentioning 'Invalid value for \"head\"', check to see if your forked working repository has become detached. If this is the case, you can delete the working repo on GitHub, refork from the source, and then 'liq work save --backup-only' from your local checkout. This will update the new forked repo with your workbranch changes and you should be able to submit after that."
    }
  done # TO_SUBMIT processing loop
}

# TODO: temporary until all existing (internal to LL) changelogs are updated. Yes, it's a project command here in work, but it's temporary.
projects-update-changelog-format() {
  liq-work-lib-changelog-update-format
}

# TODO: move to projects... improve interface? support print to stdin, release only changelog, etc.
projects-print-changelog() {
  requirePackage
  local CURR_VER LAST_RELEASE PROJECT NEXT_VER
  CURR_VER=$( echo "${PACKAGE}" | jq -r '.version' )
  LAST_RELEASE="v${CURR_VER}"
  PROJECT=$( echo "${PACKAGE}" | jq -r '.name' )
  echo semver --increment prerelease "${CURR_VER}"
  NEXT_VER="$(semver --increment prerelease "${CURR_VER}")"

  local CHANGELOG_MD='CHANGELOG.md'
  git cat-file -e ${LAST_RELEASE}:"${CHANGELOG_MD}" 2>/dev/null \
    && git cat-file blob ${LAST_RELEASE}:"${CHANGELOG_MD}" \
    || {
      echowarn "Did not find existing '${CHANGELOG_MD}'. Initializing..."
      echo -e "# ${PROJECT} changelog"
    }
  echo -e "\n## Release ${NEXT_VER}\n"

  liq-work-lib-changelog-print-entries-since "${LAST_RELEASE}"
}
