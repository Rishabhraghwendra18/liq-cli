usage-work() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}work${reset} <action>: Manages the current unit of work." || cat <<EOF
${PREFIX}${cyan_u}work${reset} <action>:
  ${underline}involve${reset} <repository name>: Involves the named repository in the current unit
    of work.
  ${underline}start${reset} <desc>: creates work branch and switches to it.
  ${underline}edit${reset}: Opens a local project editor for all involved repositories.
  ${underline}diff-master${reset}: Shows committed changes since branch from 'master' for all
    involved repositories.
  ${underline}ignore-rest${reset}: Adds any currently untracked files to '.gitignore'.
  ${underline}merge${reset}: Merges current work branch commits to master, deletes the current work
    branch, and attempts to push changes to all mirrors.
EOF
}
