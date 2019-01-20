usage-data() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}data${reset} <action>: Manges data sets and schemas." || cat <<EOF
${PREFIX}${cyan_u}data${reset} <action>:
  ${underline}build${reset} [<iface>...]: Loads the project schema into all or each named data
    service.
  ${underline}reset${reset} [<iface>...]: Resets all or each named data service, clearing all schema
    definitions.
  ${underline}clear${reset} [<iface>...]: Clears all data from all or each named data service.
  ${underline}rebuild${reset}: Effectively resets and builds all or each named data service.
  ${underline}load${reset} <set name>: Loads the named data set into the project data services. Any
    existing data will be cleared.

The only currently supported interface class is 'sql'.
EOF
}
