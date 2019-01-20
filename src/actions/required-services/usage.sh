usage-required-services() {
  local PREFIX="${1:-}"

  handleSummary 'required-services' || cat <<EOF
${PREFIX}${cyan_u}required-services${reset} <action>:"
  ${underline}list${reset} [<package name>...]: Lists the services required by the named packages or
    all packages in the current repository.
  ${underline}add${reset} [<package name>]: Add a required service.
  ${underline}delete${reset} [<package name>] <name>: Deletes a required service.

The 'add' action works interactively. Non-interactive alternatives will be
provided in future versions.

The ${underline}package name${reset} parameter in the 'add' and 'delete' actions is optional if
there is a single package in the current repository.
EOF

  helperHandler "$PREFIX" usageHelperAlphaPackagesNote
}
