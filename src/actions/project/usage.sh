# TODO: should be 'provided-services' and 'required-services'

usage-project-packages() {
  local INDENT="${1:-}"
  local PREFIX
  if [[ -z "$INDENT" ]]; then PREFIX="catalyst project "; fi

  echo "${INDENT}${PREFIX}${cyan_u}packages${reset} :"
  echo "${INDENT}  build [<name>]: Builds all or the named (NPM) package in the current project."
  echo "${INDENT}  audit [<name>]: Runs a security audit for all or the named (NPM) package in the current project."
  echo "${INDENT}  lint [-f|--fix] [<name>]: Lints all or the named (NPM) package in the current project."
}

usage-project-provides-service() {
  local INDENT="${1:-}"
  local PREFIX="${2:-}"
  echo "${INDENT}${PREFIX}provides-service [<name>|-a [<name>]|-d [<name>...]] :"
  echo "${INDENT}  no args : Lists provided services by name."
  echo "${INDENT}  <name>... : Displays detailed information about each named service."
  echo "${INDENT}  -a [<name>] : Interactively adds a new service."
  echo "${INDENT}  -d <name> : Deletes the named service."
}

usage-project-requires-service() {
  local INDENT="${1:-}"
  local PREFIX="${2:-}"

  echo "${INDENT}${PREFIX}requires-service [-a <intferface> <name>...|-d [<spec>...]] :"
  echo "${INDENT}  no args : Lists required runtime services."
  echo "${INDENT}  -a [<iface class>...] : Adds named or interactively selected required runtime services by interface."
  echo "${INDENT}  -d [<iface class>...] : Deletes the indicated provider entry. Spec may be '<type>' or '<type>.<provider name>'."
}

usage-project() {
  local INDENT="${1:-}"

  cat <<EOF | sed -E "s/^/${INDENT}/"
foo
EOF
  if [[ -z "$INDENT" ]]; then
    echo -e "Project project commands:\n"
  fi
  usage-project-packages "$INDENT"
  usage-project-provides-service "$INDENT"
  usage-project-requires-service "$INDENT"
  # TODO: change to 'mirrors'; list with no args, take options to add and delete
  echo "${INDENT}add-mirror : Adds a mirror, which will receive 'git push' updates."
  # TODO: init?
  echo "${INDENT}setup : Initializes the current directory as the root for local Catalyst project checkout."
  # TODO: move to 'work'; change to 'prune'; removes all local copies not in the current workset
  echo "${INDENT}close : Removes the local workspace copy of the project after checking that all updates have been pushed."
  # TODO: move to 'work'
  echo "${INDENT}ignore-rest : Adds any currently untracked files to '.gitignore'."
  # TODO: move to 'work'; change to 'add'; imports as side effect, main action is to add it the current workset
  echo "${INDENT}import : Imports a Catalyst project by name or from a GIT url."
  # TODO: move to 'work'
  echo "${INDENT}link <project> : Links the named project (via npm) and updates the current projects 'package.json'."
  # TODO: should have 'set-home' for completion. Which would interactively swap home and mirror values as necessary / indicated.
}
