help-orgs() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}orgs${reset} <action>: Manages organizations and affiliations." || cat <<EOF
${PREFIX}${cyan_u}orgs${reset} <action>:
  ${underline}create${reset} [--no-subscribe|-S] [--activate|-a]:
    Interactively gathers any org info not specified via CLI options and creates a 'org-settings' and
    'org-settings-sensitive' repos under the indicated GitHub org or user name. The following options
    may be used to specify fields from the CLI. If all options are specified (even if blank), then the
    command will run non-interactively.
    * --common-name
    * --legal-name
    * --address (use $'\n' for linebreaks)
    * --github-name
    * --ein
    * --naics
  ${underline}join${reset}:
  ${underline}select${reset} [--none] [<org nick>]: Selects/changes currently active org. If no name is
    given, then will enter interactive mode. '--none' de-activates the currently selected org.
  ${underline}leave${reset}:
  ${underline}list${reset}:
  ${underline}show${reset} [--sensitive] [<org nick>]: Displays info on the currently active or named org.

An org(anization) is the legal owner of work and all work is done in the context of an org. It's perfectly fine to create a 'personal' org representing yourself.
EOF
}
