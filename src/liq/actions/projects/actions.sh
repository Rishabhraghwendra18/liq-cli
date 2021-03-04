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

  # check that we can access GitHub
  check-git-access

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
      && rm -rf "$PROJECT_NAME" && echo "Removed local work directory for project '@${PROJECT_NAME}'."
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
      echoerrandexit "Did not find expected 'upstream' remote. Try:\n\ncd '$LIQ_PLAYGROUND'\n\nThen manually verify everything has been saved and pushed to the canonical remote. Then you can force local deletion with:\n\nliq projects close --force '${PROJECT_NAME}' #use-with-extreme-caution"
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
  eval "$(setSimpleOptions NEW= SOURCE= FOLLOW NO_FORK:F VERSION= LICENSE= DESCRIPTION= PUBLIC: ORG_BASE= -- "$@")"

  __PROJ_NAME="${1:-}"
  if [[ -z "${ORG_BASE}" ]]; then
    local ORG_BIT=$(dirname "${__PROJ_NAME/@/}")
    local ORG_LINK="${LIQ_DB}/orgs/${ORG_BIT}"
    if [[ -L "$ORG_LINK" ]]; then
      ORG_BASE="$(cat "${ORG_LINK}/package.json" \
        | jq -r '.repository.url' \
        | sed -E -e 's|^[^/]*//[^/]+/||' -e 's/\.git$//')"
    else
      echoerrandexit "Could not determine org base through local checkouts; specify '--org-base <github org/repo>' for the project."
    fi
  fi

  # first, check that we can access GitHub
  check-git-access
  # TODO: check that the upstream and workspace projects don't already exist

  if [[ -n "$NEW" ]] && [[ -n "$SOURCE" ]]; then
    echoerrandexit "The '--new' and '--source' options are not compatible. Please refer to:\nliq help projects create"
  elif [[ -z "$NEW" ]] && [[ -z "$SOURCE" ]]; then
    echoerrandexit "You must specify one of the '--new' or '--source' options when creating a project.Please refer to:\nliq help projects create"
  fi

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
    source "${LIQ_ORG_DB}/${PKG_ORG_NAME}/data/orgs/settings.sh"
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

  echo "Adding basic liq data to package.json..."
  cat package.json | jq '. + { "'"${LIQ_NPM_KEY}"'": { "orgBase": "git@github.com:'"${ORG_BASE}"'.git" } }' > package.new.json
  mv package.new.json package.json
  git commit -am "Added basic liq data to package.json"

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

  cd - > /dev/null
  projectMoveStaged "${PKG_ORG_NAME}/${PKG_BASENAME}" "$PROJ_STAGE"
  cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}/${PKG_BASENAME}"
  projects-setup --unpublished
}

# see: liq help projects deploy
projects-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'liq go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

# see: liq help projects edit
projects-edit() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  local EDITOR_CMD="${LIQ_EDITOR_CMD:-}"
  [[ -n "${EDITOR_CMD}" ]] || EDITOR_CMD="atom ."
  cd "${BASE_DIR}" && ${EDITOR_CMD}
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

projects-list() {
  local OPTIONS
  OPTIONS="$(pre-options-liq-projects) ORG:= LOCAL ALL_ORGS NAMES_ONLY FILTER="
  eval "$(setSimpleOptions ${OPTIONS} -- "$@")"
  post-options-liq-projects
  orgs-lib-process-org-opt

  [[ -n "${LOCAL}" ]] && [[ -n "${NAMES_ONLY}" ]] || NAMES_ONLY=true # local implies '--names-only'
  [[ -n "${ORG}" ]] || ALL_ORGS=true # ALL_ORGS is default

  # INTERNAL HELPERS
  local NON_PROD_ORGS # gather up non-prod so we can issue warnings
  function echo-header() { echo -e "Name\tRepo scope\tPublished scope\tVersion"; }
  # Extracts data to display from package.json data embedded in the projects.json or from the package.json file itself
  # in the local checkouts.
  function process-proj-data() {
    local PROJ_NAME="${1}"
    local PROJ_DATA="$(cat -)"

    # Name; col 1
    echo -en "${PROJ_NAME}\t"

    # Repo scope status cos 2
    echo -en "$(echo "${PROJ_DATA}" | jq -r 'if .repository.private then "private" else "public" end')\t"

    # Published scope status cos 3
    echo -en "$(echo "${PROJ_DATA}" | jq -r 'if .package.liq.public then "public" else "private" end')\t"

    # Version cols 4
    local VERSION # we do these extra steps so echo, which is known to provide the newline, does the output
    VERSION="$(echo "${PROJ_DATA}" | jq -r '.package.version')"
    echo "${VERSION}"
  }

  function process-org() {
    if [[ -z "${LOCAL}" ]]; then # list projects from the 'projects.json' file
      local DATA_PATH
      [[ -z "${ORG_PROJECTS_REPO:-}" ]] || DATA_PATH="${LIQ_PLAYGROUND}/${ORG_PROJECTS_REPO/@/}"
      [[ -n "${DATA_PATH:-}" ]] || DATA_PATH="${CURR_ORG_PATH}"
      DATA_PATH="${DATA_PATH}/data/orgs/projects.json"

      [[ -f "${DATA_PATH}" ]] || echoerrandexit "Did not find expected project definition '${DATA_PATH}'. Try:\nliq orgs refresh --projects"

      if [[ -n "${NAMES_ONLY}" ]]; then
        cat "${DATA_PATH}" | jq -r 'keys | .[]'
      else
        local PROJ_DATA="$(cat "${DATA_PATH}")"
        local PROJ_NAME
        while read -r PROJ_NAME; do
          echo "${PROJ_DATA}" | jq ".[\"${PROJ_NAME}\"]" | process-proj-data "${PROJ_NAME}"
        done < <(echo "${PROJ_DATA}" | jq -r 'keys | .[]')
      fi

      # The non-production source is only a concern if we're looking at the org repo.
      if ! projects-lib-is-at-production "${CURR_ORG_PATH}"; then
        list-add-item NON_PROD_ORGS "${ORG}"
      fi
    else # list local projects; recall this is limited to '--name-only'
      local PROJ
      find "${CURR_ORG_PATH}/.." -maxdepth 1 -type d -not -name '.*' -exec basename {} \; \
        | while read -r PROJ; do ! [[ -f "${CURR_ORG_PATH}/../${PROJ}/package.json" ]] || echo "${PROJ}"; done \
        | sort
    fi
  }

  # This is where all the data/output is generated, which gets fed to the filter and formatter
  function process-cmd() {
    [[ -n "${NAMES_ONLY:-}" ]] || echo-header
    if [[ -n "${ALL_ORGS}" ]]; then # all is the default
      for ORG in $(orgs-list); do
        orgs-lib-process-org-opt
        process-org
      done
    else
      process-org
    fi
  }

  if [[ -n "${FILTER}" ]]; then
    process-cmd > >(awk "\$1~/.*${FILTER}.*/" | column -s $'\t' -t)
  else
    process-cmd > >(column -s $'\t' -t)
  fi

  # finally, issue non-prod warnings if any
  exec 10< <(echo "$NON_PROD_ORGS") # this craziness is because if we do 'process-cmd | column...' above, then
  # 'process-cmd' would get run in a sub-shell and NON_PROD_ORGS updates get trapped. So, we have to rewrite without
  # pipes. BUT that causes 'read -r NP_ORG; do... done<<<${NON_PROD_ORGS}' to fail with a 'cannot create temp file for
  # here document: Interrupted system call'. I *think* the <<< creates the heredoc but the redirect to column still has
  # a handle on STDIN... Really, I'm not clear, but this seems to work.
  local NP_ORG
  [[ -z "${NON_PROD_ORGS}" ]] || while read -u 10 -r NP_ORG; do
    echowarn "\nWARNING: Non-production data shown for '${NP_ORG}'."
  done
  exec 10<&-
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

projects-setup() {
  local OPTIONS="PROJECT= SKIP_LABELS:L NO_DELETE_LABELS:D NO_UPDATE_LABELS:U SKIP_MILESTONES:M UNPUBLISHED:P"
  eval "$(setSimpleOptions $OPTIONS -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -z "$PROJECT" ]]; then
    requirePackage
    PROJECT="${PACKAGE_NAME}"
  fi
  PROJECT="${PROJECT/@/}"

  cd "${LIQ_PLAYGROUND}/${PROJECT}"
  if [[ -z "$PACKAGE_NAME" ]]; then
    requirePackage
  fi

  local GIT_BASE
  GIT_BASE="$(echo "${PACKAGE}" | jq -r '.repository.url')"
  if [[ "${GIT_BASE}" == *'github.com'*'git' ]]; then # it's a git URL
    GIT_BASE="$(echo "${GIT_BASE}" | awk -F/ '{ print $4"/"$5 }')"
    GIT_BASE="${GIT_BASE:0:$(( ${#GIT_BASE} - 4 ))}" # remove '.git'
  else
    echoerrandexit "'repository.url' from 'package.json' in unknown format; only github currently supported."
  fi

  [[ -n "$SKIP_LABELS" ]] || projects-lib-setup-labels-sync

  [[ -n "$SKIP_MILESTONES" ]] || {
    echo "Setting up milestones..."
    # Expects PACKAGE_NAME
    local CURR_MILESTONES EXPECTED_MILESTONES TYPICAL_MILESTONES
    CURR_MILESTONES="$(hub api "/repos/${GIT_BASE}/milestones" | jq -r ".[].title")"

    if [[ -n "$CURR_MILESTONES" ]]; then
      echo -e "  Current milestones:\n$(echo "${CURR_MILESTONES}" | awk '{print "    * "$0}')"
      echo
    else
      echo "  No existing milestones found."
    fi

    local EXPECTED_MILESTONES_PRESENT=false
    local MILESTONES_SYNCED=true
    check-and-add-milestone() {
      local TITLE="${1}"
      local RESULT TITLE_OUT NUMBER
      if [[ -z "$(list-get-index CURR_MILESTONES "${TITLE}")" ]]; then
        echo "  Attempting to add milestone '${TITLE}'..."
        RESULT="$(hub api -X POST "/repos/${GIT_BASE}/milestones" -f title="${TITLE}")" && \
        { # milestone create success
          TITLE_OUT="$(echo "${RESULT}" | jq -r '.title')"
          [[ "${TITLE_OUT}" == "${TITLE}" ]] || \
            echowarn "  Created title '${TITLE_OUT}' does not match input title '${TITLE}'"
          NUMBER="$(echo "${RESULT}" | jq -r '.number')"
          echo "  Created milestone '${TITLE}' (milestone number: ${NUMBER})..."
        } || \
        { # milestone create failed
          echoerr "  Failed to create milestone '${TITLE}' (probably); check and add manually."
          MILESTONES_SYNCED=false
        }
      else
        echo "  Milestone '${TITLE}' already present."
      fi
    }

    semver-to-milestone() {
      sed -E -e 's/([[:digit:]]+\.[[:digit:]]+)\.[[:digit:]]+/\1/' -e 's/\.[[:digit:]]+$//'
    }

    EXPECTED_MILESTONES="backlog"

    local CURR_VERSION CURR_PREID
    if [[ -z "${UNPUBLISHED}" ]] && npm search "${PACKAGE_NAME}" --parseable | grep -q "${PACKAGE_NAME}"; then
      CURR_VERSION="$(npm info "${PACKAGE_NAME}" version)"
    else
      # The package is not-published/not-findable.
      if [[ -z "${UNPUBLISHED}" ]]; then
        echowarn "Package '${PACKAGE_NAME}' not publised or not findable. Consider publishing."
        echowarn "Current version will be read locally."
      fi
      CURR_VERSION="$(echo "$PACKAGE" | jq -r '.version')"
    fi

    if [[ "${CURR_VERSION}" == *"-"* ]]; then # it's a pre-release version
      local NEXT_VER NEXT_PREID
      CURR_PREID="$(echo "${CURR_VERSION}" | cut -d- -f2 | cut -d. -f1)"
      if [[ "${CURR_PREID}" == 'alpha' ]]; then
        list-add-item EXPECTED_MILESTONES \
          "$(semver "$CURR_VERSION" --increment prerelease --preid beta | semver-to-milestone)"
      elif [[ "${CURR_PREID}" == 'rc' ]] || [[ "${CURR_PREID}" == 'beta' ]]; then
         # a released ver
        list-add-item EXPECTED_MILESTONES "$(semver "$CURR_VERSION" --increment | semver-to-milestone)"
      else
        echowarn "Unknown pre-release type '${CURR_PREID}'; defaulting to 'beta' as next target release. Consider updating released version to standard 'alpha', 'beta', or 'rc' types."
        list-add-item EXPECTED_MILESTONES \
          "$(semver "$CURR_VERSION" --increment prerelease --preid beta | semver-to-milestone)"
      fi
    else # it's a released version tag
      list-add-item TYPICAL_MILESTONES \
        "$(semver "$CURR_VERSION" --increment premajor --preid alpha | semver-to-milestone)"
      list-add-item TYPICAL_MILESTONES "$(semver "$CURR_VERSION" --increment minor | semver-to-milestone)"
    fi

    if [[ -n "${EXPECTED_MILESTONES}" ]]; then
      local TEST_MILESTONE
      while read -r TEST_MILESTONE; do
        check-and-add-milestone "${TEST_MILESTONE}"
      done <<< "${EXPECTED_MILESTONES}"
    fi
    if [[ -n "${TYPICAL_MILESTONES}" ]]; then
      while read -r TEST_MILESTONE; do
        check-and-add-milestone "${TEST_MILESTONE}"
      done <<< "${TYPICAL_MILESTONES}"
    fi

    [[ "${MILESTONES_SYNCED}" != true ]] || echo "Milestone setup complete."
    [[ "${MILESTONES_SYNCED}" == true ]] || \
      echowarn "One or more expected milestones may be missing. Check above output for additional informaiton."
  } # end SKIP_MILESTONES check
}

# see: liq help projects sync
projects-sync() {
  eval "$(setSimpleOptions FETCH_ONLY NO_WORK_MASTER_MERGE:M PROJECT= -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -z "$PROJECT" ]]; then
    [[ -n "${BASE_DIR:-}" ]] || findBase
    PROJECT="$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name' | tr -d "'")"
  fi
  PROJECT=${PROJECT/@/}
  local PROJ_DIR="${LIQ_PLAYGROUND}/${PROJECT}"

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
    if type -t projects-services-list | grep -q 'function'; then
      requireEnvironment
      echo -n "Checking services... "
      if ! projects-services-list --show-status --exit-on-stopped --quiet > /dev/null; then
        if [[ -z "${NO_START:-}" ]]; then
          services-start || echoerrandexit "Could not start services for testing."
        else
          echo "${red}necessary services not running.${reset}"
          echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\nliq projects test --types=unit\nliq services start"
        fi
      else
        echo "${green}looks good.${reset}"
      fi
    fi # check if runtime extesions present
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" projectsRunPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\nliq projects test --type=unit" $?
}
