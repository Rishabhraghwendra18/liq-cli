requirements-projects() {
  :
}

projects-build() {
  findBase
  cd "$BASE_DIR"
  projectsRunPackageScript build
}

projects-close() {
  eval "$(setSimpleOptions FORCE -- "$@")"

  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    findBase
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"

  deleteLocal() {
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}" \
      && rm -rf "$PROJECT_NAME" && echo "Removed project '$PROJECT_NAME'."
    # now check to see if we have an empty "org" dir
    local ORG_NAME
    ORG_NAME=$(dirname "${PROJECT_NAME}")
    if [[ "$ORG_NAME" != "." ]] && (( 0 == $(ls "$ORG_NAME" | wc -l) )); then
      rmdir "$ORG_NAME"
    fi
  }

  cd "$LIQ_PLAYGROUND/${CURR_ORG}"
  if [[ -d "$PROJECT_NAME" ]]; then
    if [[ "$FORCE" == true ]]; then
      deleteLocal
      return
    fi

    cd "$PROJECT_NAME"
    # Are remotes setup as expected?
    if ! git remote -v | grep -q '^upstream$'; then
      echoerrandexit "Did not find expected 'upstream' remote. Verify everything saved+pushed and try:\nliq projects close --force '${PROJECT_NAME}'"
    fi
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $({ git status --porcelain 2>/dev/null| grep '^??' || true; } | wc -l) == 0 )); then
        if [[ $(git rev-parse --verify master) == $(git rev-parse --verify upstream/master) ]]; then
          deleteLocal
        else
          echoerrandexit "Not all changes have been pushed to master." 1
        fi
      else
        echoerrandexit "Found untracked files." 1
      fi
    else
      echoerrandexit "Found uncommitted changes.\n$(git status --porcelain)" 1
    fi
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
  # TODO: need to check whether the project is linked to other projects
}

projects-create() {
  echoerrandexit "'create' needs to be reworked for forks."
  local TMP PROJ_STAGE __PROJ_NAME TEMPLATE_URL
  TMP=$(setSimpleOptions TYPE= TEMPLATE:T= ORIGIN= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  __PROJ_NAME="${1}"
  if [[ -z "$__PROJ_NAME" ]]; then
    echoerrandexit "Must specify project name (1st argument)."
  fi

  if [[ -n "$TYPE" ]] && [[ -n "$TEMPLATE" ]]; then
    echoerrandexit "You specify either project 'type' or 'template, but not both.'"
  elif [[ -z "$TYPE" ]] && [[ -z "$TEMPLATE" ]]; then
    echoerrandexit "You must specify one of 'type' or 'template'."
  elif [[ -n "$TEMPLATE" ]]; then
    # determine if package or URL
    : # TODO: we do this in import too; abstract?
  else # it's a type
    case "$TYPE" in
      bare)
        if [[ -z "$ORIGIN" ]]; then
          echoerrandexit "Creating a 'raw' project, '--origin' must be specified."
        fi
        TEMPLATE_URL="$ORIGIN";;
      *)
        echoerrandexit "Unknown 'type'. Try one of: bare"
    esac
  fi
  projectClone "$TEMPLATE_URL"
  cd "$PROJ_STAGE"
  # re-orient the origin from the template to the ORIGIN URL
  git remote set-url origin "${ORIGIN}"
  git remote set-url origin --push "${ORIGIN}"
  if [[ -f "package.json" ]]; then
    echowarn --no-fold "This project already has a 'project.json' file. Will continue as import.\nIn future, try:\nliq import $__PROJ_NAME"
  else
    local SCOPE
    SCOPE=$(dirname "$__PROJ_NAME")
    if [[ -n "$SCOPE" ]]; then
      npm init --scope "${SCOPE}"
    else
      npm init
    fi
    git add package.json
  fi
  cd
  projectMoveStaged "$__PROJ_NAME" "$PROJ_STAGE"
}

projects-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'liq go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

projects-import() {
  local PROJ_SPEC __PROJ_NAME _PROJ_URL PROJ_STAGE
  eval "$(setSimpleOptions NO_FORK:F SET_NAME= SET_URL= -- "$@")"

  set-stuff() {
    # TODO: protect this eval
    if [[ -n "$SET_NAME" ]]; then eval "$SET_NAME='$_PROJ_NAME'"; fi
    if [[ -n "$SET_URL" ]]; then eval "$SET_URL='$_PROJ_URL'"; fi
  }

  if [[ "$1" == *:* ]]; then # it's a URL
		echo "url" >> ~/log.tmp
    _PROJ_URL="${1}"
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
    if _PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'"); then
      set-stuff
      if projectCheckIfInPlayground "$_PROJ_NAME"; then return 0; fi
    else
      rm -rf "$PROJ_STAGE"
      echoerrandexit -F "The specified source is not a valid Liquid Dev package (no 'package.json'). Try:\nliq projects create --type=bare --origin='$_PROJ_URL' <project name>"
    fi
  else # it's an NPM package
    _PROJ_NAME="${1}"
    set-stuff
    if projectCheckIfInPlayground "$_PROJ_NAME"; then
      _PROJ_URL="$(projectsGetUpstreamUrl "$_PROJ_NAME")"
      set-stuff
      return 0
    fi
    # Note: NPM will accept git URLs, but this saves us a step, let's us check if in playground earlier, and simplifes branching
    _PROJ_URL=$(npm view "$_PROJ_NAME" repository.url) \
      || echoerrandexit "Did not find expected NPM package '${_PROJ_NAME}'. Did you forget the '--url' option?"
    set-stuff
    _PROJ_URL=${_PROJ_URL##git+}
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
  fi

  projectMoveStaged "$_PROJ_NAME" "$PROJ_STAGE"

  echo "'$_PROJ_NAME' imported into playground."
}

projects-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}

projects-sync() {
  eval "$(setSimpleOptions FETCH_ONLY NO_WORK_MASTER_MERGE:M -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  [[ -n "${BASE_DIR:-}" ]] || findBase

  local CURR_BRANCH REMOTE_COMMITS MASTER_UPDATED
  CURR_BRANCH="$(workCurrentWorkBranch)"

  echo "Fetching remote histories..."
  git fetch upstream master:remotes/upstream/master
  if [[ "$CURR_BRANCH" != "master" ]]; then
    git fetch workspace master:remotes/workspace/master
    git fetch workspace "${CURR_BRANCH}:remotes/workspace/${CURR_BRANCH}"
  fi
  echo "Fetch done."

  if [[ "$FETCH_ONLY" == true ]]; then
    return 0
  fi

  cleanupMaster() {
    cd ${BASE_DIR}
    # heh, need this to always be 'true' or 'set -e' complains
    [[ ! -d _master ]] || git worktree remove _master
  }

  REMOTE_COMMITS=$(git rev-list --right-only --count master...upstream/master)
  if (( $REMOTE_COMMITS > 0 )); then
    echo "Syncing with upstream master..."
    cd "$BASE_DIR"
    if [[ "$CURR_BRANCH" != 'master' ]]; then
      (git worktree add _master master \
        || echoerrandexit "Could not create 'master' worktree.") \
      && { cd _master; git merge remotes/upstream/master; } || \
          { cleanupMaster; echoerrandexit "Could not merge upstream master to local master."; }
      MASTER_UPDATED=true
    else
      git pull upstream master \
        || echoerrandexit "There were problems merging upstream master to local master."
    fi
  fi
  echo "Upstream master synced."

  if [[ "$CURR_BRANCH" != "master" ]]; then
    REMOTE_COMMITS=$(git rev-list --right-only --count master...workspace/master)
    if (( $REMOTE_COMMITS > 0 )); then
      echo "Syncing with workspace master..."
      cd "$BASE_DIR/_master"
      git merge remotes/workspace/master || \
          { cleanupMaster; echoerrandexit "Could not merge upstream master to local master."; }
      MASTER_UPDATED=true
    fi
    echo "Workspace master synced."
    cleanupMaster
    
    REMOTE_COMMITS=$(git rev-list --right-only --count ${CURR_BRANCH}...workspace/${CURR_BRANCH})
    if (( $REMOTE_COMMITS > 0 )); then
      echo "Synching with workspace workbranch..."
      git pull workspace "${CURR_BRANCH}:remotes/workspace/${CURR_BRANCH}"
    fi
    echo "Workspace workbranch synced."

    if [[ -z "$NO_WORK_MASTER_MERGE" ]] && [[ "$MASTER_UPDATED" == true ]]; then
      echo "Merging master updates to work branch..."
      git merge master || echoerrandexit "Could not merge master updates to workbranch."
      echo "Master updates merged to workbranch."
    fi
  fi # on workbranach check
}

projects-qa() {
  eval "$(setSimpleOptions UPDATE^ OPTIONS=^ AUDIT LINT VERSION_CHECK -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  findBase
  cd "$BASE_DIR"

  local RESTRICTED=''
  if [[ -n "$AUDIT" ]] || [[ -n "$LINT" ]] || [[ -n "$VERSION_CHECK" ]]; then
    RESTRICTED=true
  fi

  if [[ -z "$RESTRICTED" ]] || [[ -n "$AUDIT" ]]; then
    projectsNpmAudit "$@" || true
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$LINT" ]]; then
    projectsLint "$@" || true
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$VERSION_CHECK" ]]; then
    projectsVersionCheck "$@" || true
  fi
}

projects-test() {
  eval "$(setSimpleOptions TYPES= NO_DATA_RESET:D GO_RUN= NO_START:S NO_SERVICE_CHECK:C -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -z "${NO_SERVICE_CHECK}" ]] \
     && ( [[ -z "${TEST_TYPES:-}" ]] \
       || echo "$TEST_TYPES" | grep -qE '(^|, *| +)int(egration)?(, *| +|$)' ); then
    requireEnvironment
    echo -n "Checking services... "
    if ! services-list --show-status --exit-on-stopped --quiet > /dev/null; then
      if [[ -z "${NO_START:-}" ]]; then
        services-start || echoerrandexit "Could not start services for testing."
      else
        echo "${red}necessary services not running.${reset}"
        echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\nliq projects test --types=unit\nliq services start"
      fi
    else
      echo "${green}looks good.${reset}"
    fi
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" projectsRunPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\nliq projects test --type=unit" $?
}
