print_project_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid project actions are:\n"
  fi
  echo "${PREFIX}add-mirror : Adds a mirror, which will receive 'git push' updates."
  echo "${PREFIX}close : Removes the local workspace copy of the project after checking that all updates have been pushed."
  echo "${PREFIX}setup : Initializes the current directory as the root for local Catalyst project checkout."
  echo "${PREFIX}ignore-rest : Adds any currently untracked files to '.gitignore'."
  echo "${PREFIX}import : Imports a Catalyst project by name or from a GIT url."
  echo "${PREFIX}link <project> : Links the named project (via npm) and updates the current projects 'package.json'."
  # TODO: should have 'set-home' for completion. Which would interactively swap home and mirror values as necessary / indicated.
}
