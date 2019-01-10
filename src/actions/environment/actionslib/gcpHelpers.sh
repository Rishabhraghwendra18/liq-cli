gatherGcpData() {
  if [[ -z "$CURR_ENV_GCP_PROJ_ID" ]]; then
    # TODO: offer to open 'projects' page
    requireAnswer 'GCP Project name for environment: ' CURR_ENV_GCP_PROJ_ID
  fi

  if [[ -z "$CURR_ENV_GCP_ORG_ID" ]]; then
    echo "First we need to determine your 'organization ID' of the GCP Project hosting this environment."
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
    read -p 'Organization ID: ' CURR_ENV_GCP_ORG_ID
  fi
  updateEnvironment "${ENV_NAME}"

  if [[ -z "$CURR_ENV_GCP_BILLING_ID" ]]; then
    handleBilling() {
      echo "Then let's get your billing id."
      environment-set-billing "${ENV_NAME}"
    }
    handleNoBilling() {
      echo "After setting up billing, you can set the billing account with 'catalyst environment set-billing'."
    }
    yesno "Have you set up billing for this account yet? (Y\n) " Y handleBilling handleNoBilling
  fi
}

environment-set-gcp-billing-id() {
  local ENV_NAME=`getEnv "${1:-}"`

  handleOpenBilling() {
    open "${_BILLING_ACCT_URL}${CURR_ENV_GCP_ORG_ID}" || FALLBACK=Y
    echo
  }
  handleManual() {
    echo "Check this page for existing billing account or to set one up:"
    echo "${_BILLING_ACCT_URL}${CURR_ENV_GCP_ORG_ID}"
    echo
  }
  yesno "Would you like me to open the billing page for you? (Y/n) " Y handleOpenBilling handleManual
  if [[ $FALLBACK == 'Y' ]]; then handleManual; fi
  read -p 'Billing account ID: ' CURR_ENV_GCP_BILLING_ID
}
