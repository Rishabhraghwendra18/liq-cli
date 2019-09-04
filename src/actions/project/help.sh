help-project() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}project${reset} <action>: Project configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}project${reset} <action>:
  ${underline}close${reset} [<project name>]: Closes (deletes from playground) either the
    current or named project after checking that all changes are committed and pushed. ${red_b}Alpha
    note:${reset} The tool does not currently check whether the project is linked with other projects.
  ${underline}import${reset} <package or URL>: Imports the indicated package into your
    playground. By default, the first arguments are understood as NPM package names and the URL
    will be retrieved via 'npm view'. If the '--url' option is specified, then the arguments are
    understood to be git repo URLs, which should contain a 'package.json' file in the repository
    root.
  ${underline}create${reset} [--type|-t <lib|model|api|webapp>|| --template|-T <package name|git URL>] [--origin|-o <url>]
      [--no-origin|-O] <project name>:
    Creates a new Catalyst project from one of the standard types or the given template URL. The
    user will be queried for the URL to use at the git origin unless either the '--origin' or
    '--no-origin' option are specified. The project is initially cloned from the template, and then
    re-oriented to the project origin, if provided. Use 'catalyst project import' to import a
    project from a URL.
  ${underline}public${reset}: Performs verification tests, updates package version, and publishes package.
  ${underline}save${reset}: Pushes local changes to the project remotes.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
