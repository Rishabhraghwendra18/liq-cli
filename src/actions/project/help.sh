help-project() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}project${reset} <action>: Project configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}project${reset} <action>:
  ${underline}init${reset}: Configures all packages in the current repository folders as Catalyst
    packages.
  ${underline}publish${reset}: Updates the project site.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
