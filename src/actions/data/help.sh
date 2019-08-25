help-data() {
  local PREFIX="${1:-}"
  local INDENT=1

  handleSummary "${PREFIX}${cyan_u}data${reset} <action>: Manges data sets and schemas." || cat <<EOF
${PREFIX}${cyan_u}data${reset} <action>:
$(help-data-build)
  ${underline}reset${reset} [<iface>...]: Resets all or each named data service, clearing all schema
    definitions.
  ${underline}clear${reset} [<iface>...]: Clears all data from all or each named data service.
  ${underline}rebuild${reset}: Effectively resets and builds all or each named data service.
  ${underline}dump${reset} [--output-set-name|-o <set name>] <iface>: Dumps the data from all or the
    named interface. If '--output-set-name' is speciifed, will put data in
    './data/<iface>/<set name>/' or output to stdout if no output is specified.
    This is a 'data only' dump.
  ${underline}load${reset} <set name>: Loads the named data set into the project data services. Any
    existing data will be cleared.

The data commands deal exclusively with primary interface classes (${underline}iface${reset}). Thus even
if the current package requires 'sql-mysql', the data commands will work and
require an 'iface' designation of 'sql'.

${red_b}ALPHA NOTE:${reset} The only currently supported interface class is 'sql'.
EOF
}
