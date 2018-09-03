print_project_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid project actions are:\n"
  fi
  echo "${PREFIX}init : Initializes the current directory as the root for local Catalyst project checkout."
  echo "${PREFIX}set-billing : Sets the billing account ID for the project."
}
