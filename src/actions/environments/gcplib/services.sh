function environmentsActivateAPI() {
  local SERVICE_NAME="${1}"

  echo -n "Checking API '${SERVICE_NAME}' status... "
  local STATUS
  STATUS="$(gcloud services list --available --project="${GCP_PROJECT_ID}" --filter="NAME=${SERVICE_NAME}" --format="value(state)")"
  echo "$STATUS"

  if [[ "$STATUS" == DISABLED ]]; then
    echo "Enabling..."
    gcloud services enable $SERVICE_NAME --project="${GCP_PROJECT_ID}"
  fi
}
