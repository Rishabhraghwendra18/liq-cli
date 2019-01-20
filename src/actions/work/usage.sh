usage-work() {
  local PREFIX="${1:-}"

  cat <<EOF
${PREFIX}${cyan_u}workspace${reset} <action>:
  involve <repository name>: Involves the named repository in the current unit
    of work.
  start <desc>: creates work branch and switches to it.
  edit: Opens a local project editor for all involved repositories.
  diff-master: Shows committed changes since branch from 'master' for all
    involved repositories.
  ignore-rest: Adds any currently untracked files to '.gitignore'.
  merge: Merges current work branch commits to master, deletes the current work
    branch, and attempts to push changes to all mirrors.
EOF
}
