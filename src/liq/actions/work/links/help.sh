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
  cat <<EOF | _help-func-summary add "[--import|-i] [--projects|-p <target proj>...] [--force|-f] <source proj>"
Links the source project to all projects in the current unit of work or the specified target projects that have a dependency on the source project. The source project must be present in the playground, unless '--import' is specified, in which case it will be imported if not present.

The '--force' option will add the dependency even if the target project is not already dependent. E.g., for use when the work adds the dependency and the source project is also being updated or is newly created.

If '--projects' is specified (as a space or comma separated list), then only those project, which must be in the working set, is linked to the local source project.
EOF
}

help-work-links-list() {
  cat <<EOF | _help-func-summary list "[--projects|-p <target proj>...]"
List all the for each each project in the currrent unit of work or, if specified, the '--projects' option (a (as a space or comma separated list).
EOF
}

help-work-links-remove() {
  cat <<EOF | _help-func-summary remove "[--no-update|-U] [--projects|-p <target proj>...] <source proj>"
Removes the source project link to all projects in the current unit of work. Exits in error if there are no linkes with the source project. By default, the source project package will be updated after being removed unless '--no-update' is specified.

If '--projects' is specified (as a space or comma separated list), then only those project, which must be in the working set, are de-linked from the source project.
EOF
}
