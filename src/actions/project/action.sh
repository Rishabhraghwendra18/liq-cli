CAT_PROVIDES_SERVICE="_catServices"
STD_IFACE_CLASSES="http http-html http-rest sql sql-mysql"
STD_PLATFORM_TYPES="local gcp aws"
STD_PURPOSES="dev test pre-production produciton"

#source "`dirname ${BASH_SOURCE[0]}`/actionslib/packages.sh"
#source "`dirname ${BASH_SOURCE[0]}`/actionslib/provided-services.sh"
#source "`dirname ${BASH_SOURCE[0]}`/actionslib/required-services.sh"

runtime-environment() {
  requireCatalystfile
  requireNpmPackage

  if [[ $# -eq 0 ]]; then
    usage-runtime-environments
    echoerrandexit "Missing action argument. See usage above."
  else
    local ACTION="$1"; shift
    if type -t ${GROUP}-${SUBGROUP}-${ACTION} | grep -q 'function'; then
      ${GROUP}-${SUBGROUP}-${ACTION} "$@"
    else
      exitUnknownAction
    fi
  fi
}

project-setup_git_setup() {
  local HAS_FILES=`ls -a "${BASE_DIR}" | (grep -ve '^\.$' || true) | (grep -ve '^\.\.$' || true) | wc -w`
  local IS_GIT_REPO
  if [[ -d "${BASE_DIR}"/.git ]]; then
    IS_GIT_REPO='true'
  else
    IS_GIT_REPO='false'
  fi
  # first we test if set externally as environment variable (used in testing).
  if [[ -z "${ORIGIN_URL}" ]]; then
    ORIGIN_URL=`git config --get remote.origin.url || true`
    if [[ -z "${ORIGIN_URL:-}" ]]; then
      if [[ -z "${ORIGIN_URL:-}" ]]; then
        if (( $HAS_FILES == 0 )) && [[ $IS_GIT_REPO == 'false' ]]; then
          echo "The origin will be cloned, if provided."
        elif [[ -n "$ORIGIN_URL" ]] && [[ $IS_GIT_REPO == 'false' ]]; then
          echo "The current directory will be initialized as a git repo with the provided origin."
        else
          echo "The origin of this existing git repo will be set, if provided."
        fi
        read -p 'git origin URL: ' ORIGIN_URL
      fi
    fi # -z "$ORIGIN_URL" - git test
  fi # -z "$ORIGIN_URL" - external / global

  if [[ -n "$ORIGIN_URL" ]] && (( $HAS_FILES == 0 )) && [[ $IS_GIT_REPO == 'false' ]]; then
    git clone -q "$ORIGIN_URL" "${BASE_DIR}" && echo "Cloned '$ORIGIN_URL' into '${BASE_DIR}'."
  elif [[ -n "$ORIGIN_URL" ]] && [[ $IS_GIT_REPO == 'false' ]]; then
    git init "${BASE_DIR}"
    git remote add origin "$ORIGIN_URL"
  fi

  if [[ -d "${BASE_DIR}/.git" ]]; then
    git remote set-url --add --push origin "${ORIGIN_URL}"
  fi
  if [[ -n "$ORIGIN_URL" ]]; then
    PROJECT_HOME="$ORIGIN_URL"
    PROJECT_DIR="${BASE_DIR}"
    updateProjectPubConfig
    # TODO: the above overwrites the project BASE_DIR, which we rely on later. See https://github.com/Liquid-Labs/catalyst-cli/issues/2
    BASE_DIR="$PROJECT_DIR"
  fi
}

project-setup() {
  local FOUND_PROJECT=Y
  sourceCatalystfile 2> /dev/null || FOUND_PROJECT=N
  if [[ $FOUND_PROJECT == Y ]]; then
    echoerr "It looks like there's already a '.catalyst' file in place. Bailing out..."
    exit 1
  else
    BASE_DIR="$PWD"
  fi
  # TODO: verify that the parent directory is a workspace?

  project-setup_git_setup

  updateCatalystFile
}

project-import() {
  setupMirrors() {
    local PROJECT_DIR="$1"
    local PROJECT_HOME="$2"
    local PROJECT_MIRRORS="$3"

    if [[ -n "$PROJECT_MIRRORS" ]]; then
      cd "$PROJECT_DIR"
      git remote set-url --add --push origin "${PROJECT_HOME}"
      for MIRROR in $PROJECT_MIRRORS; do
        git remote set-url --add --push origin "$MIRROR"
      done
    fi
  }

  local PROJECT_URL="${1:-}"
  requireArgs "$PROJECT_URL" || exit 1
  requireWorkspaceConfig
  cd "$BASE_DIR"
  if [ -d "$PROJECT_URL" ]; then
    echo "It looks like '${PROJECT_URL}' has already been imported."
    exit 0
  fi
  if [[ -f "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}" ]]; then
    source "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}"
    # TODO: this assumes SSH style access, which we should, but need to enforce
    # the 'ssh' will be denied with 1 if successful and 255 if no key found.
    ssh -qT git@github.com 2> /dev/null || if [ $? -ne 1 ]; then echoerrandexit "Could not connect to github; add your github key with 'ssh-add'."; fi
    git clone --quiet "${PROJECT_HOME}" && echo "'$PROJECT_URL' imported into workspace."
    setupMirrors "$PROJECT_URL" "$PROJECT_HOME" "${PROJECT_MIRRORS:-}"
  else
    local PROJECT_NAME=`basename "${PROJECT_URL}"`
    if [[ -n `expr "$PROJECT_NAME" : '.*\(\.git\)'` ]]; then
      PROJECT_NAME=${PROJECT_NAME::${#PROJECT_NAME}-4}
    fi

    (cd "${BASE_DIR}"
     git clone --quiet "$PROJECT_URL" && echo "'${PROJECT_NAME}' imported into workspace.")
    # TODO: suport a 'project fork' that resets the _PROJECT_PUB_CONFIG file?

    local PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"
    cd "$PROJECT_DIR"
    git remote set-url --add --push origin "${PROJECT_URL}"
    touch .catalyst # TODO: switch to _PROJECT_CONFIG
    if [[ -f "$_PROJECT_PUB_CONFIG" ]]; then
      cp "$_PROJECT_PUB_CONFIG" "$BASE_DIR/$_WORKSPACE_DB/projects/"
      source "$_PROJECT_PUB_CONFIG"
      setupMirrors "$PROJECT_DIR" "$PROJECT_URL" "${PROJECT_MIRRORS:-}"
    else
      requireCatalystfile
      PROJECT_HOME="$PROJECT_URL"
      updateProjectPubConfig
      echoerr "Please add the '${_PROJECT_PUB_CONFIG}' file to the git repo."
    fi
  fi
}

project-setup-scripts() {
  source `dirname $BASH_SOURCE`/../../../lib/files/find-exec.func.sh
  local CATALYST_SCRIPTS=`find-exec 'catalyst-scripts' "$BASE_DIR"`
  if [[ ! -x $CATALYST_SCRIPTS ]] && which -s npm; then
    cd $BASE_DIR && npm install @liquid-labs/catalyst-scripts
    CATALYST_SCRIPTS=$(npm bin)/catalyst-scripts
  fi
  if [[ -x $CATALYST_SCRIPTS ]]; then
    "$CATALYST_SCRIPTS" "$BASE_DIR" setup-scripts
  fi
}

project-test() {
  runPackageScript pretest
  runPackageScript test
}

project-qa() {
  echo "Checking local repo status..."
  work-report
  echo "Checking package dependencies..."
  project-npm-check
  echo "Linting code..."
  project-lint
}

project-close() {
  local PROJECT_NAME="${1:-}"

    # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    cd "$BASE_DIR"
    PROJECT_NAME=`basename $PWD`
  fi
  # TODO: confirm this
  requireWorkspaceConfig
  cd "$BASE_DIR"
  if [[ -d "$PROJECT_NAME" ]]; then
    cd "$PROJECT_NAME"
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $(git status --porcelain 2>/dev/null| grep "^??" || true | wc -l) == 0 )); then
        if [[ `git rev-parse --verify master` == `git rev-parse --verify origin/master` ]]; then
          cd "$BASE_DIR"
          rm -rf "$PROJECT_NAME" && echo "Removed project '$PROJECT_NAME'."
        else
          echoerrandexit "Not all changes have been pushed to master." 1
        fi
      else
        echoerrandexit "Found untracked files." 1
      fi
    else
      echoerrandexit "Found uncommitted changes." 1
    fi
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
}

project-add-mirror() {
  local GIT_URL="${1:-}"
  requireArgs "$GIT_URL" || exit 1
  source "$BASE_DIR/${_PROJECT_PUB_CONFIG}"
  PROJECT_MIRRORS=${PROJECT_MIRRORS:-}
  if [[ $PROJECT_MIRRORS = *$GIT_URL* ]]; then
    echoerr "Remote URL '$GIT_URL' already in mirror list."
  else
    git remote set-url --add --push origin "$GIT_URL"
    if [[ -z "$PROJECT_MIRRORS" ]]; then
      PROJECT_MIRRORS=$GIT_URL
    else
      PROJECT_MIRRORS="$PROJECT_MIRRORS $GIT_URL"
    fi
    updateProjectPubConfig
  fi
}

project-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'catalyst go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

project-ignore-rest() {
  sourceCatalystfile

  pushd "${BASE_DIR}" > /dev/null
  touch .gitignore
  # first ignore whole directories
  for i in `git ls-files . --exclude-standard --others --directory`; do
    echo "${i}" >> .gitignore
  done
  popd > /dev/null
}
