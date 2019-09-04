help-playground() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}playground${reset} <action>: Manages the local playground." || cat <<EOF
${PREFIX}${cyan_u}playground${reset} <action>:
   ${underline}init${reset}: Initializes the playground.
   ${underline}import${reset} <git url>: Imports a repository into the playground.
   ${underline}close${reset} <name>: Closes the named repository.
EOF
}
