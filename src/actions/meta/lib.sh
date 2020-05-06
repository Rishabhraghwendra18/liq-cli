meta-lib-setup-liq-db() {
  # TODO: check LIQ_PLAYGROUND is set
  create-dir() {
    local DIR="${1}"
    echo -n "Creating Liquid Dev DB ('${DIR}')... "
    mkdir -p "$DIR" \
      || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development DB (${DIR})\nSee above for further details.")
    echo "${green}success${reset}"
  }
  create-dir "$LIQ_DB"
  create-dir "$LIQ_ENV_DB"
  create-dir "$LIQ_WORK_DB"
  create-dir "$LIQ_EXTS_DB"
  create-dir "$LIQ_ENV_LOGS"
  create-dir "$LIQ_PLAYGROUND"
  echo -n "Initializing Liquid Dev settings... "
  cat <<EOF > "${LIQ_DB}/settings.sh" || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development settings.")
LIQ_PLAYGROUND="$LIQ_PLAYGROUND"
EOF
  echo "${green}success${reset}"
}
