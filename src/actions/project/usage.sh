print_project_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid project actions are:\n"
  fi
  echo "${PREFIX}service [-a <name>...|-d [<name>...]] : Lists (no args), adds (-a), or deletes (-d) the named or selected service."
  echo "${PREFIX}dependencies [-a <name>...|-d [<name>...]] : Lists (no args), adds (-a), or deletes (-d) the named or selected Catalyst dependency."
  # TODO: change to 'mirrors'; list with no args, take options to add and delete
  echo "${PREFIX}add-mirror : Adds a mirror, which will receive 'git push' updates."
  # TODO: init?
  echo "${PREFIX}setup : Initializes the current directory as the root for local Catalyst project checkout."

  # TODO: move to 'work'; change to 'prune'; removes all local copies not in the current workset
  echo "${PREFIX}close : Removes the local workspace copy of the project after checking that all updates have been pushed."
  # TODO: move to 'work'
  echo "${PREFIX}ignore-rest : Adds any currently untracked files to '.gitignore'."
  # TODO: move to 'work'; change to 'add'; imports as side effect, main action is to add it the current workset
  echo "${PREFIX}import : Imports a Catalyst project by name or from a GIT url."
  # TODO: move to 'work'
  echo "${PREFIX}link <project> : Links the named project (via npm) and updates the current projects 'package.json'."
  # TODO: should have 'set-home' for completion. Which would interactively swap home and mirror values as necessary / indicated.
}
