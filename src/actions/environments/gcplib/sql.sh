# https://github.com/Liquid-Labs/ld-cli/issues/37
function environmentsReducePurpose() {
  case "$CURR_ENV_PURPOSE" in
    *dev*)
      echo dev;;
    *test*)
      echo test;;
    *production*)
      echo production;;
    *)
      echo other;;
  esac
}

function environmentsGet-CLOUDSQL_INSTANCE_NAME() {
  local RESULT_VAR="${1}"

  # for SQL instances, the name is the ID, but the libraries are setup to expect
  # two values
  local NAMES IDS
  environmentsGoogleCloudOptions "sql instances" 'name' 'name' "project=$GCP_PROJECT_ID"

  local INSTANCE_NAME
  local _DEFAULT
  _DEFAULT="${GCP_PROJECT_ID}-$(environmentsReducePurpose)"

  function createNew() {
    # TODO: select tier
    # TODO: support configurable tier by CURR_ENV_PURPOSE
    # We start the instance now so we can setup the DB and user later
    # local MYSQL_OPTIONS='--database-version=MYSQL_5_7 --database-flags="sql_mode=STRICT_ALL_TABLES,default_time_zone=+00:00"'
    echo "Creating new SQL instance '$INSTANCE_NAME'..."
    local POSTGRES_OPTIONS='--database-version=POSTGRES_11'
    gcloud beta sql instances create "$INSTANCE_NAME" $POSTGRES_OPTIONS \
        --tier="db-f1-micro" --activation-policy="always" --project="${GCP_PROJECT_ID}" \
      || ( echo "Startup may be taking a little extra time. We'll give it another 5 minutes. (error $?)"; \
           gcloud sql operations wait --quiet $(gcloud sql operations list --instance="${INSTANCE_NAME}" --filter='status=RUNNING' --format="value(NAME)" --project="${GCP_PROJECT_ID}") --project="${GCP_PROJECT_ID}" ) \
      || echoerrandexit "Problem encountered while creating instance (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No CloudSQL instances found. Please provide name: " INSTANCE_NAME "$_DEFAULT"
    createNew
  else
    PS3="CloudSQL instance: "
    selectOneCancelNew INSTANCE_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$INSTANCE_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  environmentsActivateAPI sqladmin.googleapis.com

  CLOUDSQL_INSTANCE_NAME="$INSTANCE_NAME"
}

function environmentsGet-CLOUDSQL_CONNECTION_PORT() {
  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    CLOUDSQL_CONNECTION_PORT='tcp'
  fi
}

function environmentsGet-CLOUDSQL_CONNECTION_NAME() {
  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    CLOUDSQL_CONNECTION_NAME='127.0.0.1:5432'
  fi
}

function environmentsGet-CLOUDSQL_PROXY_CONNECTION_NAME() {
  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    local REGION=$(gcloud sql instances describe "${CLOUDSQL_INSTANCE_NAME}" --format="value(region)" --project="${GCP_PROJECT_ID}")
    CLOUDSQL_PROXY_CONNECTION_NAME="$GCP_PROJECT_ID:$REGION:$CLOUDSQL_INSTANCE_NAME"
  fi
}

function environmentsGet-CLOUDSQL_DB() {
  local RESULT_VAR="${1}"

  local NAMES IDS
  # we really only care about name, but helpers expect a name/id format
  environmentsGoogleCloudOptions "sql databases" 'name' 'name' '' "--instance='$CLOUDSQL_INSTANCE_NAME'"

  local DB_NAME
  local _DEFAULT
  case "$CURR_ENV_PURPOSE" in
    dev)
      _DEFAULT="dev_${USER}";;
    *)
      _DEFAULT="$CURR_ENV_PURPOSE";;
  esac

  function createNew() {
    gcloud sql databases create "$DB_NAME" --instance="$CLOUDSQL_INSTANCE_NAME" --project="${GCP_PROJECT_ID}" \
      || echoerrandexit "Problem encountered while creating database (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No existing database found. Please provide name: " DB_NAME "$_DEFAULT"
    createNew
  else
    PS3="Database: "
    selectOneCancelNew DB_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$DB_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  CLOUDSQL_DB="$DB_NAME"
}

function environmentsCloudSQLPasswordFile() {
  local USER_NAME="${1}"
  echo "$HOME/.catalyst/creds/cloudsql-${CLOUDSQL_INSTANCE_NAME}-user-${USER_NAME}.password"
}

function environmentsGet-CLOUDSQL_USER() {
  local _SKIP_CURR_ENV_FILE=0
  if ! services-list --exit-on-stopped -q sql; then
    services-start sql
  fi
  unset _SKIP_CURR_ENV_FILE

  local NAMES IDS
  # we really only care about name, but helpers expect a name/id format
  environmentsGoogleCloudOptions "sql users" 'name' 'name' '' "--instance='$CLOUDSQL_INSTANCE_NAME'"

  local USER_NAME PASSWORD PASSWORD_FILE
  local _DEFAULT
  case "$CURR_ENV_PURPOSE" in
    dev)
      _DEFAULT="dev_${USER}";;
    *)
      _DEFAULT="api";;
  esac

  function createNew() {
    PASSWORD=$(openssl rand -base64 12)
    gcloud sql users create "$USER_NAME" --instance="$CLOUDSQL_INSTANCE_NAME" --password="$PASSWORD" --project="${GCP_PROJECT_ID}"\
      || echoerrandexit "Problem encountered while creating DB user (see above). Check status via:\nhttps://console.cloud.google.com/"
    PASSWORD_FILE=$(environmentsCloudSQLPasswordFile "$USER_NAME")
    echo "$PASSWORD" > "$PASSWORD_FILE"
  }

  function setPw() {
    gcloud sql users set-password "$USER_NAME" --instance="$CLOUDSQL_INSTANCE_NAME" --password="$PASSWORD" --project="$GCP_PROJECT_ID" \
      || echoerrandexit "Problem setting new password.\nTry updating manually."
    echo "$PASSWORD" > "$PASSWORD_FILE"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No existing DB users found. Please provide user name: " USER_NAME "$_DEFAULT"
    createNew
  else
    PS3="DB user: "
    selectOneCancelNew USER_NAME NAMES
    local SELECT_IDX
    SELECT_IDX=$(list-get-index NAMES "$USER_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    else
      PASSWORD_FILE=$(environmentsCloudSQLPasswordFile "$USER_NAME")
      if [[ ! -f "$PASSWORD_FILE" ]]; then
        echo "No local password file found for user."
        local PW_OPTIONS="enter current password"$'\n'"generate and reset password"$'\n'"specify and reset"
        local PW_CHOICE
        selectOneCancel PW_CHOICE PW_OPTIONS
        case "$PW_CHOICE" in
          'enter current password')
            require-answer "Current password: " PASSWORD
            echo "$PASSWORD" > "$PASSWORD_FILE"
            ;;
          'generate and reset password')
            PASSWORD=$(openssl rand -base64 12)
            setPw
            ;;
          'specify and reset password')
            require-answer "New password: " PASSWORD
            setPw
            ;;
          *)
            echoerrandexit "Program error; unknown selection '$PW_CHOICE'";;
        esac
        echo "$PASSWORD" > "$PASSWORD_FILE"
      else
        PASSWORD=$(cat "$PASSWORD_FILE")
      fi
    fi
  fi

  CLOUDSQL_USER="$USER_NAME"
  CLOUDSQL_PASSWORD="$PASSWORD"
}

function environmentsGet-CLOUDSQL_PASSWORD() {
  echoerrandexit "'CLOUDSQL_PASSWORD' should be set when selecting 'CLOUDSQL_USER'. Check configuration to ensure that the password parameter comes after the user parameter."
}

function environmentsGet-CLOUDSQL_SERVICE_ACCT() {
  local RESULT_VAR="${1}"

  local NAMES IDS
  environmentsGoogleCloudOptions "iam service-accounts" 'displayName' 'email' "projectId=$GCP_PROJECT_ID"

  local DISPLAY_NAME ACCT_ID

  function createNew() {
    ACCT_ID=$(environmentsGcpIamCreateAccount "$DISPLAY_NAME")
    environmentsGcpProjectsBindPolicies "$ACCT_ID" "cloudsql.client"
    environmentsGcpIamCreateKeys "$ACCT_ID"
  }

  local _DEFAULT
  # TODO: Only if not in names
  _DEFAULT="$(environmentsReducePurpose)-cloudsql-srvacct"

  if [[ -z "$NAMES" ]]; then
    require-answer "No service accounts found. Please provide display name: " DISPLAY_NAME "$_DEFAULT"
    createNew
  else
    PS3="Service account: "
    local DISPLAY_NAME
    echo "To create a new service acct, select '<other>' and provide the account display name name."
    selectOneCancelOther DISPLAY_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$DISPLAY_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    else
      ACCT_ID=$(list-get-item IDS "$SELECT_IDX")
      environmentsGcpProjectsBindPolicies "${ACCT_ID}" "roles/cloudsql.client"
      environmentsGcpIamCreateKeys "${ACCT_ID}"
    fi
  fi

  CLOUDSQL_SERVICE_ACCT="$ACCT_ID"
}
