help-orgs() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages organizations and affiliations."

  handleSummary "${PREFIX}${cyan_u}orgs${reset} <action>: $SUMMARY" || cat <<EOF
${PREFIX}${cyan_u}orgs${reset} <action>:
  An org(anization) is the legal owner of work and all work is done in the context of an org. An org may represent a employer, an open source project, a department, or yourself. Certain policies and settings are defined at the org level which would then apply to all work done in that org.

  * There is a 1-1 correspondance between the liq org, a GitHub organization (or individual), and—if publishing publicly—an npm package scope.
  * The GitHub organization (or individual) must exist prior to creating an org.

  ${underline}affiliate${reset} [--sensitive] [--leave] [--select|-s] <org url>: Will attempt to retrieve
    the standord org repo at '<org url>/org_settings'. '--sentisive' will also attempt to retrieve the
    sensitive repo. '--select' will cause a successfully retrieved org to be activated. With '--leave',
    provide the org nick instead of URL and the local repos will be removed. This will also de-select
    the named org if it is the currently selected org.
  ${underline}create${reset} [--no-subscribe|-S] [--activate|-a]:
    Interactively gathers any org info not specified via CLI options and creates a 'org-settings' and
    'org-settings-sensitive' repos under the indicated GitHub org or user name. The following options
    may be used to specify fields from the CLI. If all options are specified (even if blank), then the
    command will run non-interactively.

    The org fields are:
    * --common-name
    * --legal-name
    * --address (use $'\n' for linebreaks)
    * --github-name
    * --ein
    * --naics
    * (optional) --nmp-registry
  ${underline}list${reset}: Lists the currently affiliated orgs.
  ${underline}select${reset} [--none] [<org nick>]: Selects/changes currently active org. If no name is
    given, then will enter interactive mode. '--none' de-activates the currently selected org.
  ${underline}show${reset} [--sensitive] [<org nick>]: Displays info on the currently active or named org.
EOF
}
