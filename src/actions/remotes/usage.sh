usage-remotes() {
  local PREFIX="${1:-}"

  cat <<EOF
${PREFIX}${cyan_u}remotes${reset} <action>:
   add: Adds a mirror repository.
   delete: Deletes a mirror repository.
   set-main [<name>]: Sets the 'main' repository by name or interactively.

Remotes are synchronized across all packages in the current repository folder.
EOF
}
