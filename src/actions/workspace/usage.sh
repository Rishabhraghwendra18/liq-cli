usage-workspace() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}workspace${reset} <action>: Manages the local workspace." || cat <<EOF
${PREFIX}${cyan_u}workspace${reset} <action>:
   ${underline}init${reset}: Initializes the workspace.
   ${underline}import${reset} <git url>: Imports a repository into the workspace.
   ${underline}close${reset} <name>: Closes the named repository.
EOF
}
