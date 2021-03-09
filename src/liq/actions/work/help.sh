WORK_GROUPS="links"

help-work() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages the current unit of work."

  handleSummary "${PREFIX}${cyan_u}work${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}work${reset} <action>:
$(echo "${SUMMARY} A 'unit of work' is essentially a set of work branches across all involved projects. The first project involved in a unit of work is considered the primary project, which will effect automated linking when involving other projects.

${red_b}ALPHA Note:${reset} The 'stop' and 'resume' actions do not currently manage the work branches and only updates the 'current work' pointer." | fold -sw 82 | indent)
$(_help-actions-list work diff-master edit ignore-rest involve issues list merge report qa resume save stage start status stop submit sync test | indent)
$(_help-sub-group-list work WORK_GROUPS)
EOF
}

help-work-diff() {
  cat <<EOF | _help-func-summary diff "[--main|-m]"
By default, diffs each work repository HEAD with uncomitted files.

With '--main', shows committed changes since branch from 'main' for all involved repositories.
EOF
}

help-work-edit() {
  cat <<EOF | _help-func-summary edit
Opens a local project editor for all involved repositories. See `liq help projects edit`.
EOF
}

help-work-ignore-rest() {
  cat <<EOF | _help-func-summary ignore-rest
Adds any currently untracked files to '.gitignore'.
EOF
}

help-work-involve() {
  cat <<EOF | _help-func-summary involve "[--no-link|-L] [<repository name>]"
Involves the current or named repository in the current unit of work. The newly involved project will be linked to other involved projects with a dependincy, and vice-a-versa, unless this would result in a circular reference in which case the 'back link' (from the prior involved project to the newly added project) is skipped and a warning is given. The '--no-link' option will suppress the linking behavior.
EOF
}

help-work-issues() {
  cat <<EOF | _help-func-summary issues "[--list|--add|--remove]"
Manages issues associated with the current unit of work. TODO: this should be re-worked as sub-group.
EOF
}

help-work-list() {
  cat <<EOF | _help-func-summary list
Lists the current, local, unclosed units of work.
EOF
}

help-work-merge() {
  cat <<EOF | _help-func-summary merge
Merges current work unit to master branches and updates mirrors.
EOF
}

help-work-report() {
  cat <<EOF | _help-func-summary report
Reports status of files in the current unit of work.
EOF
}

help-work-qa() {
  cat <<EOF | _help-func-summary qa
Checks the playground status and runs package audit, version check, and tests.
EOF
}

help-work-resume() {
  cat <<EOF | _help-func-summary resume "[--pop] [<name>]"
alias: ${underline}join${reset}

Resume work or join an existing unit of work. If the '--pop' option is specified, then arguments will be ignored and the last 'pushed' unit of work (see 'liq work start --push') will be resumed.
EOF
}

help-work-save() {
  cat <<EOF | _help-func-summary save "[-a|--all] [--backup-only|-b] [--message|-m=<version ][<path spec>...]"
Save staged files to the local working branch. '--all' auto stages all known files (does not include new files) and saves them to the local working branch. '--backup-only' is useful if local commits have been made directly through 'git' and you want to push them.
EOF
}

help-work-stage() {
  cat <<EOF | _help-func-summary stage "[-a|--all] [-i|--interactive] [-r|--review] [-d|--dry-run] [<path spec>...]"
Stages files for save.
EOF
}

help-work-start() {
  cat <<EOF | _help-func-summary start "[--issues|-i <# or URL>] [--description|-d <work desc>] [--push|-p]"
Creates a new unit of work and adds the current repository (if any) to it. You must specify at least one issue. Use a comma separated list to specify mutliple issues. The first issue must be in the current working project and by default the 'work description' is extracted from the issue summary/title. If '--description' is specified, then that description is used instead of the first issue title. The '--push' option will record the current unit of work which can then be recovered with 'liq work resume --pop'.
EOF
}

help-work-status() {
  cat <<EOF | _help-func-summary status "[--list-projects|-p] [--list-issues|-i] [--no-fetch|-F] [--pr-ready] [<name>]"
Shows details for the current or named unit of work. Will enter interactive selection if no option and no current work or the '--select' option is given. The '--list-projects' and '--list-issues' options are meant to be used on their own and will just list the involved projects or associated issues respectively. '--no-fetch' skips updating the local repositories. '--pr-ready' suppresses all output and just return (bash) true or false.
EOF
}

help-work-stop() {
  cat <<EOF | _help-func-summary stop "[-k|--keep-checkout]"
Stops working on the current unit of work. The master branch will be checked out for all involved projects unless '--keep-checkout' is used.
EOF
}

help-work-submit() {
  cat <<EOF | _help-func-summary submit "[--message|-m <summary message>][--not-clean|-C] [--no-close|-X][<projects>]"
Submits pull request for the current unit of work. With no projects specified, submits patches for all projects in the current unit of work. By default, PR will claim to close related issues unless '--no-close' is included.
EOF
}

help-work-sync() {
  cat <<EOF | _help-func-summary sync "[--fetch-only|-f] [--no-work-master-merge|-M]"
Synchronizes local project repos for all work. See 'liq help work sync' for details.
EOF
}

help-work-test() {
  cat <<EOF | _help-func-summary test
Runs tests for each involved project in the current unit of work. See 'project test' for details on options for the 'test' action.
EOF
}
