project-init_git_setup() {
  local CURR_ORIGIN=`git config --get remote.origin.url || true`
  if [[ -z "$CURR_ORIGIN" ]]; then
    if [[ -z "$ORIGIN_URL" ]]; then
      read -p 'Origin URL: ' ORIGIN_URL
    fi

    local HAS_FILES=`ls "${BASE_DIR}" | wc -w`
    if [[ -n "$ORIGIN_URL" ]] && (( $HAS_FILES == 0 )); then
      git clone -q "$ORIGIN_URL" "${BASE_DIR}" && echo "Cloned '$ORIGIN_URL' into '${BASE_DIR}'."
    elif [[ -n "$ORIGIN_URL" ]] && (( $HAS_FILES != 0 )); then
      get remote add origin "$ORIGIN_URL"
    elif [[ -z "$ORIGIN_URL" ]] && [[ ! -d "${BASE_DIR}/.git" ]]; then
      git init "${BASE_DIR}"
    fi
  fi

  addLineIfNotPresentInFile "${BASE_DIR}/.gitignore" '.catalyst'
}

project-init() {
  local FOUND_PROJECT=Y
  sourceCatalystfile 2> /dev/null || FOUND_PROJECT=N
  if [[ $FOUND_PROJECT == Y ]]; then
    echoerr "It looks like there's already a '.catalyst' file in place. Bailing out..."
    exit 1
  else
    BASE_DIR="$PWD"
  fi

  project-init_git_setup

  if [[ -z "$ORGANIZATION_ID" ]]; then
    echo "First we need to determine your 'organization ID' where your project lives."
    echo "If the local project is not currentyl associated with a GCP Project, it's fine to leave this value blank."
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
  fi
  updateCatalystFile 'suppress-msg'

  if [[ -z "$BILLING_ACCOUNT_ID" ]]; then
    handleBilling() {
      echo "Then let's get your billing id."
      project-set-billing
    }
    handleNoBilling() {
      echo "After setting up billing, you can set the billing account with 'catalyst project set-billing'."
      echo
      updateCatalystFile # so the user gets the update message
    }
    yesno "Have you set up billing for this account yet? (Y\n) " Y handleBilling handleNoBilling
  fi
  updateCatalystFile
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
  updateCatalystFile
}

project-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'catalyst go configure'."
    exit 1
  fi
  colorerr "bash -c 'cd $GOPATH/src/unodelivers.com/app; gcloud app deploy'"
}
