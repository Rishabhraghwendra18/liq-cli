help-packages() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${red_b}(deprecated)${reset} ${cyan_u}packages${reset} <action>: Package configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}packages${reset} <action>:
  ${underline}build${reset} [<name>]: Builds all or the named (NPM) package in the current project.
  ${underline}audit${reset} [<name>]: Runs a security audit for all or the named (NPM) package in
    the current project.
  ${red_b}(deprecated)${reset} ${underline}version-check${reset} [-u|update] [<name>]: Runs version check with optional
    interactive update for all or named dependency packages.
    ${red}This will be reworked as 'dependencies'.${reset}
      [-i|--ignore|-I|--unignore] [<name>]: Configures dependency packages
        ignored during update checks.
      [-o|--options <option string>]: Sets options to use with 'npm-check'.
      [-c|--show-config]: Shows the current configuration used with 'npm-check'.
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
  ${underline}lint${reset} [-f|--fix] [<name>]: Lints all or the named (NPM) package in the current
    project.
  ${underline}deploy${reset} [<name>...]: Deploys all or named packages to the current environment.
  ${underline}link${reset} [-l|--list][-f|--fix][-u|--unlink]<package spec>...: Links (via npm) the
    named packages to the current package. '--list' lists the packages linked in
    the current project and takes no arguements. The '--unlink' version will
    unlink all Catalyst linked packages from the current package unless specific
    packages are specified. '--fix' will check and attempt to fix any broken
    package links in the current project and takes no arguments.

${red}Deprecated: these functions will migrate under 'project'.${reset}

${red_b}ALPHA NOTE:${reset} The 'test' action is likely to chaneg significantly in the future to
support the definition of test sets based on type (unit, integration, load,
etc.) and name.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
