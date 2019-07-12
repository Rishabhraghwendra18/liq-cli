function environmentsGcpIamCreateAccount() {
  local ACCT_NAME="${1}"
  environmentsGcpEnsureProjectId

  gcloud iam service-accounts create "$ACCT_NAME" --display-name="$ACCT_NAME" --format="value(email)" --project="$GCP_PROJECT_ID"\
    || echoerrandexit "Problem encountered while creating instance (see above). Check status via:\nhttps://console.cloud.google.com/"
}

function environmentsGcpIamCreateKeys() {
  local ACCT_ID="${1}"

  local CRED_FILE="$HOME/.catalyst/creds/${ACCT_ID}.json"
  if [[ ! -f "$CRED_FILE" ]]; then
    gcloud iam service-accounts keys create "$CRED_FILE" --iam-account "$SA_EMAIL" \
      || echoerrandexit "Problem encountered while creating credentials file for '$SA_EMAIL'.\nPlease generate file:\n$CRED_FILE"
  else
    echo "Existing credential key file found: ${CRED_FILE}"
  fi
}
