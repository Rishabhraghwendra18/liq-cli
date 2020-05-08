requirements-projects() {
  :
}

# see: liq help projects build
projects-build() {
  findBase
  cd "$BASE_DIR"
  projectsRunPackageScript build
}

# see: liq help projects close
projects-close() {
  eval "$(setSimpleOptions FORCE -- "$@")"

  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    findBase
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi
  PROJECT_NAME="${PROJECT_NAME/@/}"

  deleteLocal() {
    cd "${LIQ_PLAYGROUND}" \
      && rm -rf "$PROJECT_NAME" && echo "Removed project '@${PROJECT_NAME}'."
    # now check to see if we have an empty "org" dir
    local ORG_NAME
    ORG_NAME=$(dirname "${PROJECT_NAME}")
    if [[ "$ORG_NAME" != "." ]] && (( 0 == $(ls "$ORG_NAME" | wc -l) )); then
      rmdir "$ORG_NAME"
    fi
  }

  cd "$LIQ_PLAYGROUND"
  if [[ -d "$PROJECT_NAME" ]]; then
    if [[ "$FORCE" == true ]]; then
      deleteLocal
      return
    fi

    cd "$PROJECT_NAME"
    # Are remotes setup as expected?
    if ! git remote | grep -q '^upstream$'; then
      echoerrandexit "Did not find expected 'upstream' remote. Verify everything saved+pushed and try:\nliq projects close --force '${PROJECT_NAME}'"
    fi
    requireCleanRepo --check-all-branches "$PROJECT_NAME" # exits if not clean + branches saved to remotes
    deleteLocal # didn't exit? OK to delete
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
  # TODO: need to check whether the project is linked to other projects
}

# see: liq help projects create
projects-create() {
  local PKG_ORG_NAME PKG_BASENAME
  # TODO: Support 'NPM_PASSTHRUOGH:P' which will use the NPM default values for version and license.
  eval "$(setSimpleOptions NEW= SOURCE= FOLLOW NO_FORK:F VERSION= LICENSE= DESCRIPTION= PUBLIC: -- "$@")"

  # first, check that we can access GitHub
  check-git-access
  # TODO: check that the upstream and workspace projects don't already exist

  if [[ -n "$NEW" ]] && [[ -n "$SOURCE" ]]; then
    echoerrandexit "The '--new' and '--source' options are not compatible. Please refer to:\nliq help projects create"
  elif [[ -z "$NEW" ]] && [[ -z "$SOURCE" ]]; then
    echoerrandexit "You must specify one of the '--new' or '--source' options when creating a project.Please refer to:\nliq help projects create"
  fi

  __PROJ_NAME="${1:-}"
  if [[ -z "${__PROJ_NAME:-}" ]]; then
    if [[ -n "$SOURCE" ]]; then
      __PROJ_NAME=$(basename "$SOURCE" | sed -e 's/\.[a-zA-Z0-9]*$//')
      echo "Default project name to: ${__PROJ_NAME}"
    else
      echoerrandexit "Must specify project name for '--new' projects."
    fi
  fi

  projectsSetPkgNameComponents "${__PROJ_NAME}"
  if [[ "$PKG_ORG_NAME" == '.' ]]; then
    echoerrandexit "Must specify org scope in name when creating a project. E.g. 'my-org/my-project'."
  fi

  if [[ -e "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]]; then
    source "${LIQ_ORG_DB}/${PKG_ORG_NAME}/settings.sh"
  else
    echoerrandexit "Did not find base org repo for '$PKG_ORG_NAME'. Try:\nliq orgs import <base org pkg or URL>"
  fi

  local REPO_FRAG REPO_URL BUGS_URL README_URL
  REPO_FRAG="github.com/${ORG_GITHUB_NAME}/${PKG_BASENAME}"
  REPO_URL="git+ssh://git@${REPO_FRAG}.git"
  BUGS_URL="https://${REPO_FRAG}/issues"
  HOMEPAGE="https://${REPO_FRAG}#readme"

  update_pkg() {
    update_pkg_line ".name = \"@${ORG_NPM_SCOPE}/${PKG_BASENAME}\""
    [[ -n "$VERSION" ]] || VERSION='1.0.0-alpha.0'
    update_pkg_line ".version = \"${VERSION}\""
    [[ -n "$LICENSE" ]] \
      || { [[ -n "${ORG_DEFAULT_LICENSE:-}" ]] && LICENSE="$ORG_DEFAULT_LICENSE"; } \
      || LICENSE='UNLICENSED'
    update_pkg_line ".license = \"${LICENSE}\""
    update_pkg_line ".repository = { type: \"git\", url: \"${REPO_URL}\"}"
    update_pkg_line ".bugs = { url: \"${BUGS_URL}\"}"
    update_pkg_line ".homepage = \"${HOMEPAGE}\""
    if [[ -n "$DESCRIPTION" ]]; then
      update_pkg_line ".description = \"${DESCRIPTION}\""
    fi
  }

  update_pkg_line() {
    echo "$(cat package.json | jq "${1}")" > package.json
  }

  if [[ -n "$NEW" ]]; then
    local STAGING PROJ_STAGE
    projectResetStaging "$__PROJ_NAME"
    mkdir -p "${PROJ_STAGE}"
    cd "${PROJ_STAGE}"
    git init --quiet .
    npm init -y > /dev/null

    if [[ "$NEW" == "raw" ]]; then
      update_pkg
    else
      # TODO
      echoerr "Only the 'raw' type is currently supported in this alpha version."
    fi
    git add package.json
    git commit -m "packaage initialization"
  else
    projectClone "$SOURCE" 'source'
    cd "$PROJ_STAGE"
    git remote set-url --push source no_push

    echo "Setting up package.json..."
    # setup all the vars
    [[ -n "$VERSION" ]] || VERSION='1.0.0'

    [[ -f "package.json" ]] || echo '{}' > package.json

    update_pkg

    git add package.json
    git commit -m "setup and/or updated package.json"
  fi

  echo "Creating upstream repo..."
  local CREATE_OPTS="--remote-name upstream"
  if [[ -z "$PUBLIC" ]]; then CREATE_OPTS="${CREATE_OPTS} --private"; fi
  hub create --remote-name upstream ${CREATE_OPTS} -d "$DESCRIPTION" "${ORG_GITHUB_NAME}/${__PROJ_NAME}"
  local RETRY=4
  git push --all upstream || { echowarn "Upstream repo not yet available.";
    while (( $RETRY > 0 )); do
      echo "Waiting for upstream repo to stabilize..."
      local COUNTDOWN=3
      while (( $COUNTDOWN > 0 )); do
        echo -n "${COUNTDOWN}..."
        COUNTDOWN=$(( $COUNTDOWN - 1 ))
      done
      if (( $RETRY == 1 )); then
        git push --all upstream || echoerr "Could not push to upstream. Manually update."
      else
        { git push --all upstream && RETRY=0; } || RETRY=$(( $RETRY - 1 ))
      fi
    done;
  }

  if [[ -z "$NO_FORK" ]]; then
    echo "Creating fork..."
    hub fork --remote-name workspace
    git branch -u upstream/master master
  fi
  if [[ -z "$NEW" ]] && [[ -z "$FOLLOW" ]]; then
    echo "Un-following source repo..."
    git remote remove source
  fi

  cd -
  projectMoveStaged "${PKG_ORG_NAME}/${PKG_BASENAME}" "$PROJ_STAGE"
}

# see: liq help projects deploy
projects-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'liq go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

# see: liq help projects import; The '--set-name' and '--set-url' options are for internal use and each take a var name
# which will be 'eval'-ed to contain the project name and URL.
projects-import() {
  local PROJ_SPEC __PROJ_NAME _PROJ_URL PROJ_STAGE
  eval "$(setSimpleOptions NO_FORK:F NO_INSTALL SET_NAME= SET_URL= -- "$@")"

  set-stuff() {
    # TODO: protect this eval
    if [[ -n "$SET_NAME" ]]; then eval "$SET_NAME='$_PROJ_NAME'"; fi
    if [[ -n "$SET_URL" ]]; then eval "$SET_URL='$_PROJ_URL'"; fi
  }

  fork_check() {
    local GIT_URL="${1:-}"
    local PRIVATE GIT_OWNER GIT REPO
    echo "URL: $GIT_URL"

    if [[ -z "$NO_FORK" ]]; then
      GIT_URL="$(echo "$GIT_URL" | sed -e 's/[^:]*://' -e 's/\.git$//')"
      echo "URL2: $GIT_URL"
      GIT_OWNER="$(basename "$(dirname "$GIT_URL")")"
      GIT_REPO="$(basename "$GIT_URL")"

      echo hub api -X GET "/repos/${GIT_OWNER}/${GIT_REPO}"
      PRIVATE="$(hub api -X GET "/repos/${GIT_OWNER}/${GIT_REPO}" | jq '.private')"
      if [[ "${PRIVATE}" == 'true' ]]; then
        NO_FORK='true'
      fi
    fi
  }

  if [[ "$1" == *:* ]]; then # it's a URL
    _PROJ_URL="${1}"
    fork_check "${_PROJ_URL}"
    # We have to grab the project from the repo in order to figure out it's (npm-based) name...
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
    _PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'")
    if [[ -n "$_PROJ_NAME" ]]; then
      set-stuff
      if projectCheckIfInPlayground "$_PROJ_NAME"; then
        echo "Project '$_PROJ_NAME' is already in the playground. No changes made."
        return 0
      fi
    else
      rm -rf "$PROJ_STAGE"
      echoerrandexit -F "The specified source is not a valid Liquid Dev package (no 'package.json'). Try:\nliq projects create --type=bare --origin='$_PROJ_URL' <project name>"
    fi
  else # it's an NPM package
    _PROJ_NAME="${1}"
    set-stuff
    if projectCheckIfInPlayground "$_PROJ_NAME"; then
      echo "Project '$_PROJ_NAME' is already in the playground. No changes made."
      _PROJ_URL="$(projectsGetUpstreamUrl "$_PROJ_NAME")"
      set-stuff
      return 0
    fi
    # Note: NPM will accept git URLs, but this saves us a step, let's us check if in playground earlier, and simplifes branching
    _PROJ_URL=$(npm view "$_PROJ_NAME" repository.url) \
      || echoerrandexit "Did not find expected NPM package '${_PROJ_NAME}'. Did you forget the '--url' option?"
    set-stuff
    _PROJ_URL=${_PROJ_URL##git+}
    fork_check "$_PROJ_URL"
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
  fi

  projectMoveStaged "$_PROJ_NAME" "$PROJ_STAGE"

  echo "'$_PROJ_NAME' imported into playground."
  if [[ -z "$NO_INSTALL" ]]; then
    cd "${LIQ_PLAYGROUND}/${_PROJ_NAME/@/}"
    echo "Installing project..."
    npm install || echoerrandexit "Installation failed."
    echo "Install complete."
  fi
}

# see: liq help projects publish
projects-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}

# see: liq help projects qa
projects-qa() {
  eval "$(setSimpleOptions UPDATE^ OPTIONS=^ AUDIT LINT LIQ_CHECK VERSION_CHECK -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  findBase
  cd "$BASE_DIR"

  local RESTRICTED=''
  if [[ -n "$AUDIT" ]] || [[ -n "$LINT" ]] || [[ -n "$LIQ_CHECK" ]] || [[ -n "$VERSION_CHECK" ]]; then
    RESTRICTED=true
  fi

  local FIX_LIST
  if [[ -z "$RESTRICTED" ]] || [[ -n "$AUDIT" ]]; then
    projectsNpmAudit "$@" || list-add-item FIX_LIST '--audit'
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$LINT" ]]; then
    projectsLint "$@" || list-add-item FIX_LIST '--lint'
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$LIQ_CHECK" ]]; then
    projectsLiqCheck "$@" || true # Check provides it's own instrucitons.
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$VERSION_CHECK" ]]; then
    projectsVersionCheck "$@" || list-add-item FIX_LIST '--version-check'
  fi
  if [[ -n "$FIX_LIST" ]]; then
    echowarn "To attempt automated fixes, try:\nliq projects qa --update $(list-join FIX_LIST ' ')"
  fi
}

# see: liq help projects sync
projects-sync() {
  eval "$(setSimpleOptions FETCH_ONLY NO_WORK_MASTER_MERGE:M PROJECT= -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -z "$PROJECT" ]]; then
    [[ -n "${BASE_DIR:-}" ]] || findBase
    PROJECT="$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name' | tr -d "'")"
  fi
  PROJECT=${PROJECT/@/}
  local PROJ_DIR="${PROJ_DIR}"

  if [[ -z "$NO_WORK_MASTER_MERGE" ]] && [[ -z "$FETCH_ONLY" ]]; then
    requireCleanRepo "$PROJECT"
  fi

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
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    # heh, need this to always be 'true' or 'set -e' complains
    [[ ! -d _master ]] || git worktree remove _master
  }

  REMOTE_COMMITS=$(git rev-list --right-only --count master...upstream/master)
  if (( $REMOTE_COMMITS > 0 )); then
    echo "Syncing with upstream master..."
    cd "${PROJ_DIR}"
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
      cd "${PROJ_DIR}/_master"
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

    if [[ -z "$NO_WORK_MASTER_MERGE" ]] \
         && ( [[ "$MASTER_UPDATED" == true ]] || ! git merge-base --is-ancestor master $CURR_BRANCH ); then
      echo "Merging master updates to work branch..."
      git merge master --no-commit --no-ff || true # might fail with conflicts, and that's OK
      if git diff-index --quiet HEAD "${PROJ_DIR}" \
         && git diff --quiet HEAD "${PROJ_DIR}"; then
        echowarn "Hmm... expected to see changes from master, but none appeared. It's possible the changes have already been incorporated/recreated without a merge, so this isn't necessarily an issue, but you may want to double check that everything is as expected."
      else
        if ! git diff-index --quiet HEAD "${PROJ_DIR}/dist" || ! git diff --quiet HEAD "${PROJ_DIR}/dist"; then # there are changes in ./dist
          echowarn "Backing out merge updates to './dist'; rebuild to generate current distribution:\nliq projects build $PROJECT"
          git checkout -f HEAD -- ./dist
        fi
        if git diff --quiet "${PROJ_DIR}"; then # no conflicts
          git add -A
          git commit -m "Merge updates from master to workbranch."
          work-save --backup-only
          echo "Master updates merged to workbranch."
        else
          echowarn "Merge was successful, but conflicts exist. Please resolve and then save changes:\nliq work save"
        fi
      fi
    fi
  fi # on workbranach check
}

# see: liq help projects test
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
