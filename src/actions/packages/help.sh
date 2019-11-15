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
  ${underline}lint${reset} [-f|--fix] [<name>]: Lints all or the named (NPM) package in the current
    project.
  ${underline}deploy${reset} [<name>...]: Deploys all or named packages to the current environment.
  ${underline}link${reset} [-l|--list][-f|--fix][-u|--unlink]<package spec>...: Links (via npm) the
    named packages to the current package. '--list' lists the packages linked in
    the current project and takes no arguements. The '--unlink' version will
    unlink all Catalyst linked packages from the current package unless specific
    packages are specified. '--fix' will check and attempt to fix any broken
    package links in the current project and takes no arguments.
  ${underline}services${reset}: sub-resource for managing services provided by the package.
    ${underline}add${reset} [<package name>]: Add a provided service.
    ${underline}list${reset} [<package name>...]: Lists the services provided by the named packages or
      all packages in the current repository.
    ${underline}delete${reset} [<package name>] <name>: Deletes a provided service.
    ${underline}show${reset} [<service name>...]: Show service details.

${red}Deprecated: these functions will migrate under 'project'.${reset}

${red_b}ALPHA NOTE:${reset} The 'test' action is likely to chaneg significantly in the future to
support the definition of test sets based on type (unit, integration, load,
etc.) and name.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
