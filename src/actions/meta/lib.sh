metaSetupLiqDb() {
  # TODO: check LIQ_PLAYGROUND is set
  createDir() {
    local DIR="${1}"
    echo -n "Creating Liquid Dev DB ('${DIR}')... "
    mkdir -p "$DIR" \
      || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development DB at: ${LIQ_DB}")
    echo "${green}success${reset}"
  }
  createDir "$LIQ_DB"
  createDir "$_CATALYST_ENVS"
  createDir "$CATALYST_WORK_DB"
  createDir "$_CATALYST_ENV_LOGS"
  createDir "$LIQ_PLAYGROUND"
  #mkdir -p "$LIQ_DB" || echoerrandexit "Error creating Liquid Development DB at: ${LIQ_DB}"
  #mkdir -p "$_CATALYST_ENVS" || echoerrandexit "Error creating Liquid Development DB at: ${_CATALYST_ENVS}"
  #mkdir -p "$CATALYST_WORK_DB" || echoerrandexit "Error creating Liquid Development DB at: ${CATALYST_WORK_DB}"
  #mkdir -p "$_CATALYST_ENV_LOGS" || echoerrandexit "Error creating Liquid Development DB at: ${_CATALYST_ENV_LOGS}"
  echo -n "Initializing Liquid Dev settings... "
  cat <<EOF > "${LIQ_DB}/settings.sh" || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development settings.")
LIQ_PLAYGROUND="$LIQ_PLAYGROUND"
EOF
  echo "${green}success${reset}"
}
