usage-work() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}work${reset} <action>: Manages the current unit of work." || cat <<EOF
${PREFIX}${cyan_u}work${reset} <action>:
  ${underline}involve${reset} <repository name>: Involves the named repository in the current unit
    of work.
  ${underline}start${reset} <desc>: creates work branch and switches to it.
  ${underline}edit${reset}: Opens a local project editor for all involved repositories.
  ${underline}report${reset}: Reports status of files in the current unit of work.
  ${underline}diff-master${reset}: Shows committed changes since branch from 'master' for all
    involved repositories.
  ${underline}ignore-rest${reset}: Adds any currently untracked files to '.gitignore'.
  ${underline}merge${reset}: Merges current work branch commits to master, deletes the current work
    branch, and attempts to push changes to all mirrors.
  ${underline}qa${reset}: Checks the workspace status and runs package audit, version check, and
    tests.

${red_b}ALHPA Note:${reset} 'start' currently branches off the current work branch. Future versions will
accept a '-m|--master' switch. It is not currenty possible to remove a project repository from the current
unit of work using the CLI. Future versions will support an 'eject' action.
EOF
}
