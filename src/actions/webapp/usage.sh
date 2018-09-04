print_webapp_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid webapp actions are:\n"
  fi
  echo "${PREFIX}build : Creates a production build and stages it for deployment."
  echo "${PREFIX}audit : Audits the webapp packages."
  echo "${PREFIX}start : Starts the local development web server."
  echo "${PREFIX}stop : Stops the local development web server."
  echo "${PREFIX}view-log : Displays the local development web server log."
}
