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
  ${underline}affiliate${reset} [--sensitive] [--leave] [--select|-s] <org url>: Will attempt to retrieve
    the standord org repo at '<org url>/org_settings'. '--sentisive' will also attempt to retrieve the
    sensitive repo. '--select' will cause a successfully retrieved org to be activated. With '--leave',
    provide the org nick instead of URL and the local repos will be removed. This will also de-select
    the named org if it is the currently selected org.
  ${underline}select${reset} [--none] [<org nick>]: Selects/changes currently active org. If no name is
    given, then will enter interactive mode. '--none' de-activates the currently selected org.
  ${underline}list${reset}: Lists the currently affiliated orgs.
  ${underline}show${reset} [--sensitive] [<org nick>]: Displays info on the currently active or named org.

${PREFIX}Sub-resources:
${PREFIX}${cyan_u}staff${reset} <action>:
  ${underline}add${reset} [--email|-e <email>] [--family-name|-f <name>] [--given-name|-g <name>] [--start-date|-s <YYY-MM-DD>]:
  ${underline}list${reset}
  ${underline}remove${reset}

An org(anization) is the legal owner of work and all work is done in the context of an org. It's perfectly fine to create a 'personal' org representing yourself.
EOF
}
