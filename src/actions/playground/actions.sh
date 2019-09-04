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
