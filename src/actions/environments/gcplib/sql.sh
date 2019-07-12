function environmentsGet-CLOUDSQL_INSTANCE_NAME() {
  local RESULT_VAR="${1}"

  # for SQL instances, the name is the ID, but the libraries are setup to expect
  # two values
  local NAMES IDS
  environmentsGoogleCloudOptions 'sql instances' 'name' 'name' "project=$GCP_PROJECT_ID"

  local INSTANCE_NAME
  local _DEFAULT="main"
  function createNew() {
    # TODO: select tier
    # TODO: support configurable tier by CURR_ENV_PURPOSE
    # We start the instance so we can setup the DB and user later
    gcloud sql instances create "$INSTANCE_NAME" --tier="db-f1-micro" --database-flags="sql_mode=STRICT_ALL_TABLES,default_time_zone=+00:00" --activation-policy="always" \
      || echoerrandexit "Problem encountered while creating instance (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No CloudSQL instances found. Please provide name: " INSTANCE_NAME "$_DEFAULT"
    createNew
  else
    PS3="CloudSQL instance:"
    echo "To create a new instance, select '<other>' and provide the instance name."
    selectOneCancelOther INSTANCE_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$INSTANCE_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  eval "$RESULT_VAR='$INSTANCE_NAME'"
}

function environmentsGet-CLOUDSQL_CONNECTION_PORT() {
  local RESULT_VAR="${1}"

  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    eval "$RESULT_VAR='tcp'"
  fi
}

function environmentsGet-CLOUDSQL_CONNECTION_NAME() {
  local RESULT_VAR="${1}"

  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    eval "$RESULT_VAR='127.0.0.1:3306'"
  fi
}

function environmentsGet-CLOUDSQL_PROXY_CONNECTION_NAME() {
  local RESULT_VAR="${1}"

  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    local REGION=$(gcloud sql instances describe uno-test --format="value(region)")
    eval "$RESULT_VAR='$GCP_PROJECT_ID:$REGION:$CLOUDSQL_INSTANCE_NAME'"
  fi
}

function environmentsGet-CLOUDSQL_DB() {
  local RESULT_VAR="${1}"

  local NAMES IDS
  # we really only care about name, but helpers expect a name/id format
  environmentsGoogleCloudOptions "sql databases --instance='$CLOUDSQL_INSTANCE_NAME'" 'name' 'name'

  local DB_NAME
  local _DEFAULT
  case "$CURR_ENV_PURPOSE" in
    dev)
      _DEFAULT="dev_${USER}";;
    *)
      _DEFAULT="$CURR_ENV_PURPOSE";;
  esac

  function createNew() {
    gcloud sql databases create "$DB_NAME" --instance="$INSTANCE_NAME" \
      || echoerrandexit "Problem encountered while creating database (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No existing database found. Please provide name: " DB_NAME "$_DEFAULT"
    createNew
  else
    PS3="Database:"
    echo "To create a new DB, select '<other>' and provide the DB name."
    selectOneCancelOther DB_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$DB_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  eval "$RESULT_VAR='$DB_NAME'"
}

function environmentsCloudSQLPasswordFile() {
  echo "$HOME/.catalyst/creds/cloudsql-${CLOUDSQL_INSTANCE_NAME}-user-${USER_NAME}.password"
}

function environmentsGet-CLOUDSQL_USER() {
  local NAME_VAR="${1}"

  local NAMES IDS
  # we really only care about name, but helpers expect a name/id format
  environmentsGoogleCloudOptions "sql users --instance='$CLOUDSQL_INSTANCE_NAME'" 'name' 'name'

  local USER_NAME PASSWORD PASSWORD_FILE
  local _DEFAULT
  case "$CURR_ENV_PURPOSE" in
    dev)
      _DEFAULT="dev_${USER}";;
    *)
      _DEFAULT="api";;
  esac

  function setPwFile() {
    PASSWORD_FILE=$(environmentsCloudSQLPasswordFile)
  }

  function createNew() {
    PASSWORD=$(openssl rand -base64 12)
    gcloud sql users create "$USER_NAME" --instance="$INSTANCE_NAME" --password="$PASSWORD"\
      || echoerrandexit "Problem encountered while creating DB user (see above). Check status via:\nhttps://console.cloud.google.com/"
    echo "$PASSWORD" > "$PASSWORD_FILE"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No existing DB users found. Please provide user name: " USER_NAME "$_DEFAULT"
    setPwFile
    createNew
  else
    PS3="DB user:"
    echo "To create a new DB user, select '<other>' and provide the user name."
    selectOneCancelOther USER_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$USER_NAME")
    setPwFile
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  eval "$RESULT_VAR='$DB_NAME'"
}

function environmentsGet-CLOUDSQL_DB() {
  local NAME_VAR="${1}"

  local PASSWORD
  local PASSWORD_FILE=$(environmentsCloudSQLPasswordFile)

  if [[ -f "$PASSWORD_FILE" ]]; then
    PASSWORD=$(cat "$PASSWORD_FILE")
  else
    echo "Could not find password file for DB user '$USER_NAME'. Please provide password:"
    require-answer "Password:" PASSWORD
    echo "$PASSWORD" > "$PASSWORD_FILE"
  fi

  eval "$RESULT_VAR='$DB_NAME'"
}

function environmentsGet-CLOUDSQL_SERVICE_ACCT() {
  local RESULT_VAR="${1}"

  local NAMES IDS
  environmentsGoogleCloudOptions 'iam service-accounts' 'displayName' 'email' "projectId=$GCP_PROJECT_ID"

  local DISPLAY_NAME ACCT_ID

  function createNew() {
    ACCT_ID=$(environmentsGcpIamCreateAccount "$DISPLAY_NAME")
    environmentsGcpProjectsBindPolicies "$ACCT_ID" "cloudsql.client"
    environmentsGcpIamCreateKeys "$ACCT_ID"
  }

  if [[ -z "$NAMES" ]]; then
    local _DEFAULT="${GCP_PROJECT_ID}-cloudsql-srvacct"
    require-answer "No service accounts found. Please provide display name: " DISPLAY_NAME "$_DEFAULT"
    createNew
  else
    PS3="Service account:"
    local DISPLAY_NAME
    selectOneCancelOther DISPLAY_NAME NAMES
    echo "To create a new service acct, select '<other>' and provide the account display name name."
    local SELECT_IDX=$(list-get-index NAMES "$DISPLAY_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    else
      ACCT_ID=$(list-get-item IDS "$SELECT_IDX")
      environmentsGcpProjectsBindPolicies "${ACCT_ID}" "roles/cloudsql.client"
      environmentsGcpIamCreateKeys "${ACCT_ID}"
    fi
  fi

  eval "$RESULT_VAR='$ACCT_ID'"
}
