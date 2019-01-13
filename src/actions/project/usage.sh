usage-project-requires-service() {
  local TAB="${1:-}"
  local PREFIX="${2:-}"

  echo "${TAB}${PREFIX}providers [-a <intferface> <name>...|-d [<spec>...]] :"
  echo "${TAB}  no args : Lists required runtime services."
  echo "${TAB}  -a [<iface class>...] : Adds named or interactively selected required runtime services by interface."
  echo "${TAB}  -d [<iface class>...] : Deletes the indicated provider entry. Spec may be '<type>' or '<type>.<provider name>'."
}

print_project_usage() {
  local TAB="${1:-}"
  if [[ -z "$TAB" ]]; then
    echo -e "Valid project actions are:\n"
  fi
  echo "${TAB}service [-a [<name>]|-d [<name>...]] : Lists (no args), adds (-a), or deletes (-d) the named or selected service."
  usage-project-requires-service "$TAB"
  # TODO: change to 'mirrors'; list with no args, take options to add and delete
  echo "${TAB}add-mirror : Adds a mirror, which will receive 'git push' updates."
  # TODO: init?
  echo "${TAB}setup : Initializes the current directory as the root for local Catalyst project checkout."

  # TODO: move to 'work'; change to 'prune'; removes all local copies not in the current workset
  echo "${TAB}close : Removes the local workspace copy of the project after checking that all updates have been pushed."
  # TODO: move to 'work'
  echo "${TAB}ignore-rest : Adds any currently untracked files to '.gitignore'."
  # TODO: move to 'work'; change to 'add'; imports as side effect, main action is to add it the current workset
  echo "${TAB}import : Imports a Catalyst project by name or from a GIT url."
  # TODO: move to 'work'
  echo "${TAB}link <project> : Links the named project (via npm) and updates the current projects 'package.json'."
  # TODO: should have 'set-home' for completion. Which would interactively swap home and mirror values as necessary / indicated.
}
