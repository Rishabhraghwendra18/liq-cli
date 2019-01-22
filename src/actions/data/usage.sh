usage-data() {
  local PREFIX="${1:-}"
  local INDENT=1

  handleSummary "${PREFIX}${cyan_u}data${reset} <action>: Manges data sets and schemas." || cat <<EOF
${PREFIX}${cyan_u}data${reset} <action>:
$(usage-data-build)
  ${underline}reset${reset} [<iface>...]: Resets all or each named data service, clearing all schema
    definitions.
  ${underline}clear${reset} [<iface>...]: Clears all data from all or each named data service.
  ${underline}rebuild${reset}: Effectively resets and builds all or each named data service.
  ${underline}load${reset} <set name>: Loads the named data set into the project data services. Any
    existing data will be cleared.

The data commands deal exclusively with primary interface classes (${underline}iface${reset}). Thus even
if the current package requires 'sql-mysql', the data commands will work and
require an 'iface' designation of 'sql'.

${red_b}ALPHA NOTE:${reset} The only currently supported interface class is 'sql'.
EOF
}
