help-provided-services() {
  local PREFIX="${1:-}"

handleSummary "${PREFIX}${red_b}(deprated)${reset} ${cyan_u}provided-services${reset} <action>: Manages package service declarations." || cat <<EOF
${PREFIX}${cyan_u}provided-services${reset} <action>:
  ${underline}list${reset} [<package name>...]: Lists the services provided by the named packages or
    all packages in the current repository.
  ${underline}add${reset} [<package name>]: Add a provided service.
  ${underline}delete${reset} [<package name>] <name>: Deletes a provided service.

${red_b}Deprated: These commands will migrate under 'project'.${reset}

The 'add' action works interactively. Non-interactive alternatives will be
provided in future versions.

The ${underline}package name${reset} parameter in the 'add' and 'delete' actions is optional if
there is a single package in the current repository.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
