function environmentsGet-GCP_ORGANIZATION() {
  local RESULT_VAR="${1}"

  local LINE NAMES IDS
  environmentsGoogleCloudOptions 'organizations' 'displayName' 'name'

  local ORG_NAME ORG_ID
  # TODO: should periodically check if create has been enbaled via the CLI
  echo "If you want to create a new organization, you must do this via the Cloud Console:"
  echo "https://console.cloud.google.com/"
  read -p "Hit <enter> to continue..."
  selectOneCancel ORG_NAME NAMES
  local SELECT_IDX=$(list-get-index NAMES "$ORG_NAME")
  ORG_ID=$(list-get-item IDS $SELECT_IDX)

  eval "$RESULT_VAR='$ORG_ID'"
}
