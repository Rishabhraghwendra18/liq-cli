workspace-init() {
  touch "${_WORKSPACE_CONFIG}"
}

_workspace_forEach() {
  for f in `find -L "${BASE_DIR}" -maxdepth 1 -mindepth 1 -type d`; do
    if [[ -f "${f}/.catalyst" ]]; then # TODO: switch '.catalyst' to '_PROJECT_CONFIG_'
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
