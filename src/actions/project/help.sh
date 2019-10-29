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
  ${underline}create${reset} [--type|-t <bare|lib|model|api|webapp>|| --template|-T <package name|git URL>] [--origin|-o <url>] <project name>:
    Creates a new Liquid project from one of the standard types or the given template URL. When the 'bare'
    type is specified, 'origin' must be specified. The project is initially cloned from the template, and then
    re-oriented to the project origin, unless the type is 'bare' in which case the project is cloned directly
    from the origin URL. Use 'liq project import' to import an existing project from a URL.
  ${underline}publish${reset}: Performs verification tests, updates package version, and publishes package.
  ${underline}test${reset} [-t|--types <types>][-D|--no-data-reset][-g|--go-run <testregex>][--no-start|-S] [<name>]:
    Runs unit tests for all or the named packages in the current project.
    * 'types' may be 'unit' or 'integration' (=='int') or 'all', which is default.
      Multiple tests may be specified in a comma delimited list. E.g.,
      '-t=unit,int' is equivalent no type or '-t=""'.
    * '--no-start' will skip tryng to start necessary services.
    * '--no-data-reset' will cause the standard test DB reset to be skipped.
    * '--no-service-check' will skip checking service status. This is useful when
      re-running tests and the services are known to be running.
    * '--go-run' will only run those tests matching the provided regex (per go
      '-run' standards).
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
