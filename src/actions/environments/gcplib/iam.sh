function environmentsGcpIamCreateAccount() {
  local ACCT_NAME="${1}"
  environmentsGcpEnsureProjectId

  echo "Creating service account '${ACCT_NAME}...'"
  gcloud iam service-accounts create "$ACCT_NAME" --display-name="$ACCT_NAME" --format="value(email)" --project="$GCP_PROJECT_ID"\
    || echoerrandexit "Problem encountered while creating instance (see above). Check status via:\nhttps://console.cloud.google.com/"
}

function environmentsGcpIamCreateKeys() {
  local ACCT_ID="${1}"

  local CRED_FILE="$HOME/.catalyst/creds/${ACCT_ID}.json"
  if [[ ! -f "$CRED_FILE" ]]; then
    echo "Creating keys..."
    gcloud iam service-accounts keys create "$CRED_FILE" --iam-account "${ACCT_ID}" --project="${GCP_PROJECT_ID}" \
      || echoerrandexit "Problem encountered while creating credentials file for '${ACCT_ID}'.\nPlease generate file:\n$CRED_FILE"
  else
    echo "Existing credential key file found: ${CRED_FILE}"
  fi
}
