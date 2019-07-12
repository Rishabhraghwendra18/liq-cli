function environmentsGcpProjectsBindPolicies() {
  local ACCT_ID="${1}"; shift
  if (( $# == 0 )); then
    echoerrandexit "Program error: no role names provided for policy."
  fi
  environmentsGcpEnsureProjectId

  while (( $# > 0 )); do
    local POLICY_NAME="$1"; shift

    local GRANTED
    # I don't believe the test can be accomplished with just gcloud as of 2019-07-12
    GRANTED=$(gcloud projects get-iam-policy ${GCP_PROJECT_ID} --filter="bindings.members='serviceAccount:${ACCT_ID}'" --format=json \
                | jq ".[].bindings[] | select(.members[]==\"serviceAccount:${ACCT_ID}\") | select(.role==\"${POLICY_NAME}\")")
    if [[ -z "$GRANTED" ]]; then
      gcloud projects add-iam-policy-bindng ${GCP_PROJECT_ID} --member="serviceAccount:${ACCT_ID}" --role="${POLICY_NAME}" \
        || echoerrandexit "Problem encountered while granting role '${POLICY_NAME}' to service account '$ACCT_ID'.\nPlease update the role manually."
    fi
  done
}

function environmentsGet-GCP_PROJECT_ID() {
  local RESULT_VAR="$1"

  local NAMES IDS
  environmentsGoogleCloudOptions 'projects' 'name' 'projectId'

  local PROJ_NAME PROJ_ID

  function createNew() {
    PROJ_ID=$(gcpNameToId "$PROJ_NAME")
    local ORG_ID
    environmetsGet-GCP_ORGANIZATION ORG_ID

    gcloud projects create "$PROJ_ID" --name="$PROJ_NAME" --organization="$ORG_ID" \
      || echoerrandexit "Problem encountered while creating project (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No projects found. Please provide name: " PROJ_NAME
    createNew
  else
    PS3="Project name:"
    echo "To create a new project, select '<other>' and provide the project name."
    selectOneCancelOther PROJ_NAME NAMES
    local SELECT_IDX
    SELECT_IDX=$(list-get-index NAMES "$PROJ_NAME")
    if [[ -n "$SELECT_IDX" ]]; then
      PROJ_ID=$(list-get-item IDS $SELECT_IDX)
    else # it's a new project
      createNew
    fi
  fi

  eval "$RESULT_VAR='$PROJ_ID'"
}
