project-init_new() {
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

project-init() {
  local ORIGIN="${1:-}"
  if [[ -z "$ORIGIN" ]]; then
    project-init_new
  fi
}

project-set-billing() {
  handleOpenBilling() {
    open "${_BILLING_ACCT_URL}${ORGANIZATION_ID}" || FALLBACK=Y
    echo
  }
  handleManual() {
    echo "Check this page for existing billing account or to set one up:"
    echo "${_BILLING_ACCT_URL}${ORGANIZATION_ID}"
    echo
  }
  yesno "Would you like me to open the billing page for you? (Y/n) " Y handleOpenBilling handleManual
  if [[ $FALLBACK == 'Y' ]]; then handleManual; fi
  read -p 'Billing account ID: ' BILLING_ACCOUNT_ID
  updateGcprojfile
}
