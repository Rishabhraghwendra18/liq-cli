_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'

global-help() {
  local HELP_COMPONENT="${1:-}"
  if [[ -z "$HELP_COMPONENT" ]]; then
    print_usage
  else
    print_${HELP_COMPONENT}_usage
  fi
}

global-start() {
  db-start-proxy
  sleep 2 # give the proxy a moment to connect; it's generally pretty quick
  api-start
  webapp-start
}

global-stop() {
  webapp-stop
  api-stop
  db-stop-proxy
}

global-deploy() {
  bash -c "cd $GOPATH/src/unodelivers.com/app; gcloud app deploy"
}
