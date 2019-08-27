playground-init() {
  touch "${_WORKSPACE_CONFIG}"
  WORKSPACE_DIR="$PWD"
  ensureWorkspaceDb
}

_playground_forEach() {
  for f in `find -L "${BASE_DIR}" -maxdepth 1 -mindepth 1 -type d`; do
    if [[ -f "${f}/.catalyst" ]]; then # TODO: switch '.catalyst' to '_PROJECT_CONFIG'
      (cd "$f" && eval $*)
    fi
  done
}

playground-report() {
  _playground_forEach 'catalyst work report'
}

playground-branch() {
  local BRANCH_DESC="${1:-}"
  requireArgs "$BRANCH_DESC" || exit $?

  _playground_forEach 'git branch'
}

playground-close() {
  echoerrandexit "Action 'close' is temporarily disabled in this version pending testing."
  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi

  cd "$LIQ_PLAYGROUND"
  if [[ -d "$PROJECT_NAME" ]]; then
    cd "$PROJECT_NAME"
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $(git status --porcelain 2>/dev/null| grep "^??" || true | wc -l) == 0 )); then
        if [[ `git rev-parse --verify master` == `git rev-parse --verify origin/master` ]]; then
          cd "$LIQ_PLAYGROUND"
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
