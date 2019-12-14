help-projects() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}projects${reset} <action>: Project configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}projects${reset} <action>:
$(help-projects-build | sed -e 's/^/  /')
$(help-projects-close | sed -e 's/^/  /')
$(help-projects-create | sed -e 's/^/  /')
$(help-projects-import | sed -e 's/^/  /')
$(help-projects-publish | sed -e 's/^/  /')
$(help-projects-qa | sed -e 's/^/  /')
$(help-projects-sync | sed -e 's/^/  /')
$(help-projects-test | sed -e 's/^/  /')
  ${underline}services${reset}: sub-resource for managing services provided by the package.
    ${underline}add${reset} [<service name>]: Add a provided service to the current project.
    ${underline}list${reset} [<project name>...]: Lists the services provided by the current or named projects.
    ${underline}delete${reset} [<project name>] <name>: Deletes a provided service.
    ${underline}show${reset} [<service name>...]: Show service details.
EOF
}

help-projects-build() {
  cat <<EOF
${underline}build${reset} [<name>...]: Builds the current or specified project(s).
EOF
}

help-projects-close() {
  cat <<EOF
${underline}close${reset} [<name>...]: Closes (deletes from playground) either the
  current or named project after checking that all changes are committed and pushed. ${red_b}Alpha
  note:${reset} The tool does not currently check whether the project is linked with other projects.
EOF
}

help-projects-create() {
  cat <<EOF
${underline}create${reset} [[--new <type>] || [--source|-s <pkg|URL>] [--follow|-f]] [--no-fork|-F] [--version|-v <semver> ] [--license|-l <license name>] [--description|-d <desc>] [--public] [<project name>]:
  Note, 'project name' should be a bare name. The scope is determined by the current org settings. An
  explicit name is required for '--new' projects. If no name is given for '--source' projects, then
  the base source name is used.

  Creates a new Liquid project in one of two modes. If '--new' is specified, then the indicated type
  will be used to initiate a 'create' script. There are various '@liquid-labs/create-*' projects
  which may be used, and third-party or private scripts may developed as well. This essentially
  calls 'npm init <type>' and then sets up the GitHub repository and working repo (unless --no-fork
  is specified).

  If '--source' is specified, will first clone the source repo as a starting point. This can be used
  to "convert" non-Liquid projects (from GitHub or other sources) as well as to create re-named
  duplicates of Liquid projects If set to '--follow' the source, then this effectively sets up a
  'source' remote conceptually upstream from 'upstream' and future invocations of 'project sync' will
  attempt to merge changes from 'source' to 'upstream'. This can later be managed using the 'projects
  remotes' sub-group.

  Regardless, the following 'package.json' fields will be set according to the following:
  * the package will be scoped accourding to the org scope.
  * 'project name' will be used to create a git repository under the org scope.
  * the 'repository' and 'bugs' fields will be set to match.
  * the 'homepage' will be set to the repo 'README.md' (#readme).
  * version to '--version', otherwise '1.0.0'.
  * license to the '--license', otherwise org's default license, otherwise 'UNLICENSED'.

  Any compatible create script must conform to the above, though additional rules and/or interactions
  may added. Note, just because no option is given to change some of the above parameters they can, of
  course, be modified post-create (though they are "very standard" for Liquid projects).

  Use 'liq projects import' to import an existing project from a URL.
EOF
}

help-projects-deploy() {
  cat <<EOF
${underline}deploy${reset} [<name>...]: Deploys the current or named project(s).
EOF
}

help-projects-import() {
  cat <<EOF
${underline}import${reset} [--url] <package or URL>: Imports the indicated package into your
  playground. By default, the first arguments are understood as NPM package names and the URL
  will be retrieved via 'npm view'. If the '--url' option is specified, then the arguments are
  understood to be git repo URLs, which should contain a 'package.json' file in the repository
  root.
EOF
}

help-projects-publish() {
  cat <<EOF
${underline}publish${reset}: Performs verification tests, updates package version, and publishes package.
EOF
}

help-projects-qa() {
  cat <<EOF
${underline}qa${reset} [--update|-u] [--audit|-a] [--lint|-l] [--version-check|-v]:
  Performs NPM audit, eslint, and NPM version checks. By default, all three checks are performed, but options
  can be used to select specific checks. The '--update' option instruct to the selected options to attempt
  updates/fixes.
EOF
}

help-projects-sync() {
  cat <<EOF
${underline}sync${reset} [--fetch-only|-f] [--no-work-master-merge|-M]:
  Updates the remote master with new commits from upstream/master and, if currently on a work branch,
  workspace/master and workspace/<workbranch> and then merges those updates with the current workbranch (if any).
  '--fetch-only' will update the appropriate remote refs, and exit. --no-work-master-merge update the local master
  branch and pull the workspace workbranch, but skips merging the new master updates to the workbranch.
EOF
}

help-projects-test() {
  cat <<EOF
${underline}test${reset} [-t|--types <types>][-D|--no-data-reset][-g|--go-run <testregex>][--no-start|-S] [<name>]:
  Runs unit tests the current or named projects.
  * 'types' may be 'unit' or 'integration' (=='int') or 'all', which is default.
    Multiple tests may be specified in a comma delimited list. E.g.,
    '-t=unit,int' is equivalent no type or '-t=""'.
  * '--no-start' will skip tryng to start necessary services.
  * '--no-data-reset' will cause the standard test DB reset to be skipped.
  * '--no-service-check' will skip checking service status. This is useful when
    re-running tests and the services are known to be running.
  * '--go-run' will only run those tests matching the provided regex (per go
    '-run' standards).
EOF
}
