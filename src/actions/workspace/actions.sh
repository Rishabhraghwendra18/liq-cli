workspace-init() {
  touch "${_WORKSPACE_CONFIG}"
  WORKSPACE_DIR="$PWD"
  ensureWorkspaceDb
}

_workspace_forEach() {
  for f in `find -L "${BASE_DIR}" -maxdepth 1 -mindepth 1 -type d`; do
    if [[ -f "${f}/.catalyst" ]]; then # TODO: switch '.catalyst' to '_PROJECT_CONFIG'
      (cd "$f" && eval $*)
    fi
  done
}

workspace-report() {
  _workspace_forEach 'catalyst work report'
}

workspace-branch() {
  local BRANCH_DESC="${1:-}"
  requireArgs "$BRANCH_DESC" || exit $?

  _workspace_forEach 'git branch'
}

workspace-import() {
  echoerrandexit "Action 'import' is temporarily disabled in this version pending testing."
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
  cd "$CATALYST_PLAYGROUND"
  if [ -d "$PROJECT_URL" ]; then
    echo "It looks like '${PROJECT_URL}' has already been imported."
    exit 0
  fi
  if [[ -f "${CATALYST_PLAYGROUND}/${_WORKSPACE_DB}/projects/${PROJECT_URL}" ]]; then
    source "${CATALYST_PLAYGROUND}/${_WORKSPACE_DB}/projects/${PROJECT_URL}"
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

    (cd "${CATALYST_PLAYGROUND}"
     git clone --quiet "$PROJECT_URL" && echo "'${PROJECT_NAME}' imported into workspace.")
    # TODO: suport a 'project fork' that resets the _PROJECT_PUB_CONFIG file?

    local PROJECT_DIR="$CATALYST_PLAYGROUND/$PROJECT_NAME"
    cd "$PROJECT_DIR"
    git remote set-url --add --push origin "${PROJECT_URL}"
    touch .catalyst # TODO: switch to _PROJECT_CONFIG
    if [[ -f "$_PROJECT_PUB_CONFIG" ]]; then
      cp "$_PROJECT_PUB_CONFIG" "$CATALYST_PLAYGROUND/$_WORKSPACE_DB/projects/"
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

workspace-close() {
  echoerrandexit "Action 'close' is temporarily disabled in this version pending testing."
  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi

  cd "$CATALYST_PLAYGROUND"
  if [[ -d "$PROJECT_NAME" ]]; then
    cd "$PROJECT_NAME"
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $(git status --porcelain 2>/dev/null| grep "^??" || true | wc -l) == 0 )); then
        if [[ `git rev-parse --verify master` == `git rev-parse --verify origin/master` ]]; then
          cd "$CATALYST_PLAYGROUND"
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
