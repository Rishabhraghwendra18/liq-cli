print_project_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid api actions are:\n"
  fi
  echo "${PREFIX}configure : Sets up configuration for the api module."
  echo "${PREFIX}get-deps : Downloads all necessary dependencies for the go app."
  echo "${PREFIX}build : Builds the go app. The app will normally automatically rebuild, but this"
  echo "${PREFIX}  useful for debug-compiling or when automated rebuilds fail."
  echo "${PREFIX}start : Start the local api dev server."
  echo "${PREFIX}stop : Stop the local api dev server."
  echo "${PREFIX}view-log : View the local server logs."
}
