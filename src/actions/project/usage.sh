print_project_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid project actions are:\n"
  fi
  echo "${PREFIX}init : Initializes the current directory as the root for local Catalyst project checkout."
  echo "${PREFIX}import : Imports a Catalyst project by name or from a GIT url."
  # TODO: should have 'set-home' for completion. Which would interactively swap home and mirror values as necessary / indicated.
  echo "${PREFIX}add-mirror : Adds a mirror, which will receive 'git push' updates."
  echo "${PREFIX}set-billing : Sets the billing account ID for the project."
}
