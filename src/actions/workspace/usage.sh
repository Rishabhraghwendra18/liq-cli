usage-workspace() {
  local PREFIX="${1:-}"

  cat <<EOF
${PREFIX}${cyan_u}workspace${reset} <action>:
   init: Initializes the workspace.
   import <git url>: Imports a repository into the workspace.
   close <name>: Closes the named repository.
EOF
}
