usage-packages() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}packages${reset} <action>: Package configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}packages${reset} <action>:
  ${underline}build${reset} [<name>]: Builds all or the named (NPM) package in the current project.
  ${underline}audit${reset} [<name>]: Runs a security audit for all or the named (NPM) package in
    the current project.
  ${underline}lint${reset} [-f|--fix] [<name>]: Lints all or the named (NPM) package in the current
    project.
  ${underline}link${reset} <package>: Links (via npm) the named package to the current package.

Unlike most action, the 'link' works off the current package rather than
repository context.
EOF

  test -n "$SUMMARY_ONLY" || helperHandler "$PREFIX" usageHelperAlphaPackagesNote
}
