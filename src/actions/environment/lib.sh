doEnvironmentList() {
  find "$_CATALYST_ENVS" -mindepth 1 -maxdepth 1 -type f -exec basename '{}' \;
}

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

updateEnvParam() {
  local KEY="$1"
  local VALUE="$2"

  local VAR_NAME=${KEY//:/_}
  VAR_NAME=${VAR_NAME}// /_}
  VAR_NAME="CURR_ENV_${VAR_NAME^^}"

  declare "$VAR_NAME"="$VALUE"
}
