updateEnvironment() {
  local ENV_NAME="${1}"

  cat <<EOF > "$_CATALYST_ENVS/${ENV_NAME}"
CURR_ENV_TYPE="${CURR_ENV_TYPE}"
CURR_ENV_PURPOSE="${CURR_ENV_PURPOSE}"
EOF

  if [[ "$CURR_ENV_TYPE" == "gcp" ]]; then
    cat <<EOF >> "$_CATALYST_ENVS/${ENV_NAME}"
CURR_ENV_GCP_PROJ_ID="${CURR_ENV_GCP_PROJ_ID}"
CURR_ENV_GCP_ORG_ID="${CURR_ENV_GCP_ORG_ID}"
CURR_ENV_GCP_BILLING_ID="${CURR_ENV_GCP_BILLING_ID}"
EOF
  fi
}

getEnv() {
  local ENV_NAME="${1:-}"
  if [ -z "$ENV_NAME" ]; then
    ENV_NAME="$CURR_ENV"
  fi

  if [ -z "$ENV_NAME" ]; then
    echoerrandexit "Could not determine environment. Try 'catalyst environment select'."
  else
    echo "$ENV_NAME"
  fi
}

environment-show() {
  if [ -n "$CURR_ENV" ]; then
    echo "Current environment:"
    echo "$CURR_ENV"
    echo
    cat "$_CATALYST_ENVS/${CURR_ENV}"
  else
    echoerrandexit "Environment is not set. Try 'catalyst environment set'."
  fi
}

environment-set-billing() {
  local ENV_NAME=`getEnv "${1:-}"`

  handleOpenBilling() {
    open "${_BILLING_ACCT_URL}${CURR_ENV_GCP_ORG_ID}" || FALLBACK=Y
    echo
  }
  handleManual() {
    echo "Check this page for existing billing account or to set one up:"
    echo "${_BILLING_ACCT_URL}${CURR_ENV_GCP_ORG_ID}"
    echo
  }
  yesno "Would you like me to open the billing page for you? (Y/n) " Y handleOpenBilling handleManual
  if [[ $FALLBACK == 'Y' ]]; then handleManual; fi
  read -p 'Billing account ID: ' CURR_ENV_GCP_BILLING_ID
  updateEnvironment "$ENV_NAME"
}

gatherGcpData() {
  if [[ -z "$CURR_ENV_GCP_ORG_ID" ]]; then
    echo "First we need to determine your 'organization ID' of the GCP Project hosting this environment."
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
    read -p 'Organization ID: ' CURR_ENV_GCP_ORG_ID
  fi
  updateEnvironment "${ENV_NAME}"

  if [[ -z "$CURR_ENV_GCP_BILLING_ID" ]]; then
    handleBilling() {
      echo "Then let's get your billing id."
      environment-set-billing "${ENV_NAME}"
    }
    handleNoBilling() {
      echo "After setting up billing, you can set the billing account with 'catalyst environment set-billing'."
    }
    yesno "Have you set up billing for this account yet? (Y\n) " Y handleBilling handleNoBilling
  fi
}

environment-add() {
  local ENV_NAME="${1:-}"
  if [ -z "${1}" ]; then
    requireAnswer 'Local environment name: ' ENV_NAME
  fi

  if [[ -z "$CURR_ENV_TYPE" ]]; then
    select CURR_ENV_TYPE in local gcp; do break; done
  fi

  if [[ -z "$CURR_ENV_PURPOSE" ]]; then
    select CURR_ENV_PURPOSE in test pre-production production <other>; do break; done
    if [[ "$CURR_ENV_PURPOSE" == '<other>' ]]; then
      requireAnswer 'Purpose label: ' CURR_ENV_PURPOSE
  fi

  if [[ "$CURR_ENV_TYPE" == 'gcp' ]]; then
    gatherGcpData
  fi
}

doEnvironmentList() {
  find "$_CATALYST_ENVS" -mindepth 1 -maxdepth 1 -type f -exec basename '{}' \;
}

environment-list() {
  if test -n "$(doEnvironmentList)"; then
    doEnvironmentList
  else
    echo "No environments defined. Use 'catalyst environment add'."
  fi
}

environment-select() {
  local ENV_NAME="${1:-}"
  if [[ -z "$ENV_NAME" ]]; then
    if test -z "$(doEnvironmentList)"; then
      echoerrandexit "No environments defined. Try 'catalyst environment add'."
    fi
    select ENV_NAME in `doEnvironmentList`; do break; done
  fi
  if [ -f "$_CATALYST_ENVS/${ENV_NAME}" ]; then
    echo "CURR_ENV='${ENV_NAME}'" > "$_CURR_ENV_FILE"
  else
    echoerrandexit "No such environment '$ENV_NAME' defined."
  fi
}

environment-delete() {
  local ENV_NAME="${1:-}"

  onConfirm() {
    rm ${_CATALYST_ENVS}/${ENV_NAME} && echo "Local '${ENV_NAME}' entry deleted."
  }

  onCancel() {
    return 0 # noop
  }

  if [[ -z "$ENV_NAME" ]]; then
    if [[ -z "$CURR_ENV" ]]; then
      echoerrandexit "No current environment defined. Try 'catalyst environment delete <env name>'."
    fi
    # else

    yesno \
      "Confirm deletion of local records for current environment '${$CURR_ENV}': (y/N)" \
      N \
      onDeleteConfirm \
      onDeleteCancel
  elif [[ -f "${_CATALYST_ENVS}/${ENV_NAME}" ]]; then
    yesno \
      "Confirm deletion of local records for environment '${$CURR_ENV}': (y/N)" \
      N \
      onDeleteConfirm \
      onDeleteCancel
  else
    echoerrandexit "No such environment '${ENV_NAME}' found. Try 'catalyst environment list'."
  fi
}
