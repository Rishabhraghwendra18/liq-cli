usage-packages() {
  local PREFIX="${1:-}"

cat <<EOF
${PREFIX}${cyan_u}packages${reset} <action>:
  init: Configures all packages in the current repository folders as Catalyst
    projects.
  build [<name>]: Builds all or the named (NPM) package in the current project.
  audit [<name>]: Runs a security audit for all or the named (NPM) package in
    the current project.
  lint [-f|--fix] [<name>]: Lints all or the named (NPM) package in the current
    project.
  link <package>: Links (via npm) the named package to the current package.

Unlike most action, the 'link' works off the current package rather than
repository context.
EOF

  helperHandler "$PREFIX" usageHelperAlphaPackagesNote
}
