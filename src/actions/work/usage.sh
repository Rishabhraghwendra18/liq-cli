print_work_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid work actions are:\n"
  fi
  echo "${PREFIX}start <desc> : creates work branch and switches to it"
  echo "${PREFIX}merge : merges current work branch commits to master and deletes work branch"
  echo "${PREFIX}diff-master : shows committed changes since branch from 'master'"
}