usage-work() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}work${reset} <action>: Manages the current unit of work." || cat <<EOF
${PREFIX}${cyan_u}work${reset} <action>:
  ${underline}show${reset} [<name>]: Shows details for the current or named unit of work.
  ${underline}involve${reset} [<repository name>]: Involves the current or named repository in the current unit
    of work.
  ${underline}start${reset} <name>: Creates a new unit of work and adds the current repository (if any) to it.
  ${underline}stop${reset}: Stops working on the current unit of work.
  ${underline}resume${reset} [<name>]: Resumes work on an existing unit of work.
  ${underline}edit${reset}: Opens a local project editor for all involved repositories.
  ${underline}report${reset}: Reports status of files in the current unit of work.
  ${underline}diff-master${reset}: Shows committed changes since branch from 'master' for all
    involved repositories.
  ${underline}ignore-rest${reset}: Adds any currently untracked files to '.gitignore'.
  ${underline}merge${reset}: Merges current work unit to master branches and updates mirrors.
  ${underline}qa${reset}: Checks the workspace status and runs package audit, version check, and
    tests.

A 'unit of work' is essentially a set of work branches across all involved projects.

${red_b}ALPHA Note:${reset} The 'stop' and 'resume' actions do not currently manage the work branches and only updates the 'current work' pointer.
EOF
}
