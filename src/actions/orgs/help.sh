help-orgs() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages organizations and affiliations."

  handleSummary "${PREFIX}${cyan_u}orgs${reset} <action>: $SUMMARY" || cat <<EOF
${PREFIX}${cyan_u}orgs${reset} <action>:
  An org(anization) is the legal owner of work and all work is done in the context of an org. An org may represent a employer, an open source project, a department, or yourself. Certain policies and settings are defined at the org level which would then apply to all work done in that org.

  * There is a 1-1 correspondance between the liq org, a GitHub organization (or individual), and—if publishing publicly—an npm package scope.
  * The GitHub organization (or individual) must exist prior to creating an org.

  $(help-orgs-create | sed -e 's/^/  /')

  $(help-orgs-import | sed -e 's/^/  /')
  ${underline}list${reset}: Lists the currently affiliated orgs.
  ${underline}show${reset} [--sensitive] [<org nick>]: Displays info on the currently active or named org.
EOF
}

help-orgs-close() {
  cat <<EOF
${underline}close${reset} [--force] <name>...: Closes (deletes from playground) the named org-project after
  checking that all changes are committed and pushed. '--force' will skip the 'up-to-date checks.
EOF
}

help-orgs-create() {
  cat <<EOF
${underline}create${reset} [--no-sensitive] [--no-staff] [-private-policy] <base org-package>:
  Interactively gathers any org info not specified via CLI options and creates the indicated repos under the indicated
  GitHub org or user.

  The following options may be used to specify fields from the CLI. If all required options are specified (even if
  blank), then the command will run non-interactively and optional fields will be set to default values unless
  specified:
  * --common-name
  * --legal-name
  * --address (use $'\n' for linebreaks)
  * --github-name
  * (optional )--ein
  * (optional) --naics
  * (optional) --npm-registry
EOF
}

help-orgs-import() {
  cat <<EOF
${underline}import${reset} [--import-refs:r] <package or URL>: Imports the 'base' org package into your playground. The
  '--import-refs' option will attempt to import any referenced repos. The access rights on referenced repos might be
  different than the base repo and could fail, in which case the script will attempt to move on to the next, if any.
EOF
}
