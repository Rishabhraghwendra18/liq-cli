usage-packages() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}project${reset} <action>: Project configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}project${reset} <action>:
  ${underline}init${reset}: Configures all packages in the current repository folders as Catalyst
    packages.
EOF

  test -n "$SUMMARY_ONLY" || helperHandler "$PREFIX" usageHelperAlphaPackagesNote
}
