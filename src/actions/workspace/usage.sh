print_workspace_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid workspace actions are:\n"
  fi
  echo "${PREFIX}init : initializes the workspace."
  echo "${PREFIX}branch : branches all projects in the current workspace"
  echo "${PREFIX}stash : creates work branch and switches to it"
  echo "${PREFIX}merge : merges current work branch commits to master and deletes work branch"
  echo "${PREFIX}diff-master : shows committed changes since branch from 'master'"
}
