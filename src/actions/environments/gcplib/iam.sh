function environmentsGet-CLOUDSQL_SERVICE_ACCOUNT() {
  local RESULT_VAR="${1}"

  local NAMES IDS
  environmentsGoogleCloudOptions 'iam service-accounts' 'displayName' 'email' "projectId=$GCP_PROJECT_ID"

  local ACCT_NAME
  local _DEFAULT="${GCP_PROJECT_ID}-cloudsql-srvacct"

  function createNew() {
    local SA_NAME=`gcpNameToId "${GCP_PROJECT_ID}-$ACCT_NAME"`
    gcloud iam service-accounts create "$SA_NAME" --display-name="$ACCT_NAME" --format="value(email)" \
      || echoerrandexit "Problem encountered while creating instance (see above). Check status via:\nhttps://console.cloud.google.com/"
    local SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
    gcloud projects add-iam-policy-bindng $GCP_PROJECT_ID --member "serviceAccount:${SA_EMAIL}" --role="roles/cloudsql.client" \
      || echoerrandexit "Problem encountered while granting role 'cloudsql.client' to newly created service account\n'$SA_EMAIL'.\nPlease update the role manually."
    local CRED_FILE="$HOME/.catalyst/creds/${SA_EMAIL}.json"
    gcloud iam service-accounts keys create "$CRED_FILE" --iam-account "$SA_EMAIL" \
      || echoerrandexit "Problem encountered while creating credentials file for '$SA_EMAIL'.\nPlease generate file:\n$CRED_FILE"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No service accounts found. Please provide name: " ACCT_NAME "$_DEFAULT"
    createNew
  else
    PS3="Service account:"
    selectOneCancelOther ACCT_NAME NAMES
    echo "To create a new service acct, select '<other>' and provide the instance name."
    local SELECT_IDX=$(list-get-index NAMES "$ACCT_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  eval "$RESULT_VAR='$ACCT_NAME'"
}
