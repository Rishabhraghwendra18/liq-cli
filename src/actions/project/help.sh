help-project() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}project${reset} <action>: Project configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}project${reset} <action>:
  ${underline}import${reset} <package or URL>: Imports the indicated package into your
    playground. By default, the first arguments are understood as NPM package names and the URL
    will be retrieved via 'npm view'. If the '--url' option is specified, then the arguments are 
    understood to be git repo URLs, which should contain a 'package.json' file in the repository
    root.
  ${underline}init${reset}: Configures all packages in the current repository folders as Catalyst
    packages.
  ${underline}publish${reset}: Updates the project site.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
