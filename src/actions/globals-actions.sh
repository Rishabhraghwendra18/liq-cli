_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'

global-help() {
  local HELP_COMPONENT="${1:-}"
  if [[ -z "$HELP_COMPONENT" ]]; then
    print_usage
  else
    print_${HELP_COMPONENT}_usage
  fi
}

global-init() {
  addLineIfNotPresentInFile "${BASE_DIR}/.gitignore" 'gcprojfile'
  if [[ -f "${BASE_DIR}/gcprojfile" ]]; then
    echoerr "It looks like there's already a gcprojfile in place. Bailing out..."
    exit 1
  fi
  echo "First we need to determine your 'organization ID' where your project lives."
  local FALLBACK=N
  handleOpenOrgSettings() {
    open ${_ORG_ID_URL} || FALLBACK=Y
    echo
  }
  handleManual() {
    echo 'If you have access to the GCP console, you can find it here:'
    echo $_ORG_ID_URL
    echo 'or find further instructions here:'
    echo 'https://cloud.google.com/resource-manager/docs/creating-managing-organization#retrieving_your_organization_id'
    echo
  }
  yesno 'Would you like me to try and open the Google Console for you? (Y/n) ' Y handleOpenOrgSettings handleManual
  if [[ $FALLBACK == 'Y' ]]; then handleManual; fi
  read -p 'Organization ID: ' ORGANIZATION_ID
  updateGcprojfile 'suppress-msg'
  handleBilling() {
    echo "Then let's get your billing id."
    project-set-billing
  }
  handleNoBilling() {
    echo "After setting up billing, you can set the billing account with 'gcproj project set-billing'."
    echo
    updateGcprojfile # so the user gets the update message
  }
  yesno "Have you set up billing for this account yet? (Y\n) " Y handleBilling handleNoBilling
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
