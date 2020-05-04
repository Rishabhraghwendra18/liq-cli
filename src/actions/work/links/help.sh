help-work-links() {
  local PREFIX="${1:-}"

  local SUMMARY="Manage working links between projects."

  handleSummary "${PREFIX}${cyan_u}work links${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}projects issues${reset} <action>:
  ${SUMMARY}
$(_help-actions-list work-links add list remove | indent)
EOF
}

help-work-links-add() {
  cat <<EOF | _help-func-summary add "[--import|-i] <source proj> [--project|-p <target proj>]"
Links the source project to all projects in the current unit of work. The source project must be present in the playground, unless '--import' is specified, in which case it will be imported if not present.

If '--project' is specified, then only that project, which must be in the working set, is linked to the local source project.
EOF
}

help-work-links-list() {
  cat <<EOF | _help-func-summary list "[--project|-p <target proj>]"
List all the links in the current unit of work.

If '--project' is specified, then only links to that project are listed.
EOF
}

help-work-links-remove() {
  cat <<EOF | _help-func-summary remove "[--no-update|-U] [--project|-p <working proj>] <source proj>"
Removes the source project link to all projects in the current unit of work. Exits in error if there are no linkes with the source project. By default, the source project package will be updated after being removed unless '--no-update' is specified.

If '--project' is specified, then only that projecs, which must be in the working set, only that project is de-linked from the source project.
EOF
}
