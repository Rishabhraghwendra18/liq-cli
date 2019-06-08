function environmentsGet-GCP_PROJECT_ID() {
  local RESULT_VAR="$1"

  local NAMES IDS
  environmentsGoogleCloudOptions 'projects' 'name' 'projectId'

  local PROJ_NAME PROJ_ID

  function createNew() {
    PROJ_ID=gcpNameToId "$PROJ_NAME"
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
    selectOneCancelOther PROJ_NAME $NAMES
    local SELECT_IDX=$(list-get-index NAMES "$PROJ_NAME" "\n")
    if [[ -n "$SELECT_IDX" ]]; then
      PROJ_ID=$(list-get-item IDS $SELECT_IDX "\n")
    else # it's a new project
      createNew
    fi
  fi

  eval "$RESULT_VAR='$PROJ_ID'"
}
