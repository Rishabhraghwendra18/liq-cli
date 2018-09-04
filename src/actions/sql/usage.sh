print_sql_usage() {
  local PREFIX="${1:-}"
  if [[ -z "$PREFIX" ]]; then
    echo -e "Valid sql actions are:\n"
  fi
  echo "${PREFIX}start-proxy : Starts the local proxy to the Cloud SQL instance."
  echo "${PREFIX}stop-proxy : Stops tho local proxy to the Cloud SQL instance."
  echo "${PREFIX}view-proxy-log : Display the local proxy logs."
  echo "${PREFIX}connect [test]: Connects to the Cloud SQL database developer or shared test database."
  echo "${PREFIX}rebuild [test] : Rebuilds the developer or shared test database."
}
