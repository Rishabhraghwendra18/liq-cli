ORGS_GROUPS=""

help-orgs() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages organizations and affiliations."

  handleSummary "${PREFIX}${cyan_u}orgs${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}orgs${reset} <action>:
$(echo "${SUMMARY} An org(anization) is the legal owner of work and all work is done in the context of an org. An org may represent a employer, an open source project, a department, or yourself. Certain policies and settings are defined at the org level which would then apply to all work done in that org.

* There is a 1-1 correspondance between the liq org, a GitHub organization (or individual), and—if publishing publicly—an npm package scope.
* The GitHub organization (or individual) must exist prior to creating an org." | fold -sw 80 | indent)
$(_help-actions-list orgs create close import list show | indent)
$(_help-sub-group-list orgs ORGS_GROUPS)
EOF
}

help-orgs-create() {
  cat <<EOF | _help-func-summary create "[--no-sensitive] [--no-staff] [-private-policy] <base org-package>"
Interactively gathers any org info not specified via CLI options and creates the indicated repos under the indicated GitHub org or user.

The following options may be used to specify fields from the CLI. If all required options are specified (even if blank), then the command will run non-interactively and optional fields will be set to default values unless specified:

* --common-name
* --legal-name
* --address (use $'\n' for linebreaks)
* --github-name
* (optional )--ein
* (optional) --naics
* (optional) --npm-registry$(

)
EOF
}

help-orgs-close() {
  cat <<EOF | _help-func-summary close "[--force] <name>..."
After checking that all changes are committed and pushed, closes the named org-project by deleting it from the local playground. '--force' will skip the 'up-to-date checks.
EOF
}

help-orgs-import() {
  cat <<EOF | _help-func-summary import "[--import-refs:r] <package or URL>"
Imports the 'base' org package into your playground. The '--import-refs' option will attempt to import any referenced repos. The access rights on referenced repos might be different than the base repo and could fail, in which case the script will attempt to move on to the next, if any.
EOF
}

help-orgs-list() {
  cat <<EOF | _help-func-summary list
Lists the currently affiliated orgs.
EOF
}

help-orgs-refresh() {
  cat <<EOF | _help-func-summray refresh "[--projects]"
Refreshes the compiled/generated company data.
EOF
}

help-orgs-show() {
  cat <<EOF | _help-func-summary show "[--sensitive] [<org nick>]"
Displays info on the currently active or named org.
EOF
}
