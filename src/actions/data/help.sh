help-data() {
  local PREFIX="${1:-}"

  local SUMMARY='Manges data sets and schemas.'

  handleSummary "${PREFIX}${cyan_u}data${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}data${reset} <action>:
$(echo "${SUMMARY} The data commands deal exclusively with primary interface classes (iface). Thus even if the current project requires 'sql-mysql', the data commands will work and require an 'iface' designation of 'sql'." | fold -sw 80 | indent)
$(_help-actions-list data build dump load rebuild reset test | indent)
EOF
}

help-data-build() {
  cat <<EOF | _help-func-summary build "[<iface>...]"
Loads the project schema into all or each named data service.
EOF
}

help-data-dump() {
  cat <<EOF | _help-func-summary dump "[--output-set-name|-o <set name>] <iface>"
Dumps the data from all or the named interface. If '--output-set-name' is speciifed, will put data in './data/<iface>/<set name>/' or output to stdout if no output is specified. This is a 'data only' dump.
EOF
}

help-data-load() {
  cat <<EOF | _help-func-summary load "<set name>"
Loads the named data set into the project data services. Any existing data will be cleared.
EOF
}

help-data-reset() {
  cat <<EOF | _help-func-summary reset "[<iface>...]"
Resets all or each named data service, clearing all schema definitions.
EOF
}

help-data-rebuild() {
  cat <<EOF | _help-func-summary rebuild
Effectively resets and builds all or each named data service.
EOF
}

help-data-test() {
  cat <<EOF | _help-func-summary test
Runs data tests.
EOF
}
