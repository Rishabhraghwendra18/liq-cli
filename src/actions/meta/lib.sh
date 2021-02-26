meta-lib-setup-liq-db() {
  # TODO: check LIQ_PLAYGROUND is set
  create-dir() {
    local DIR="${1}"
    echo -n "Creating local liq DB ('${DIR}')... "
    mkdir -p "$DIR" \
      || echoerrandexit "Failed!\nError creating liq DB directory '${DIR}'.\nSee above for further details."
    echo "${green}success${reset}"
  }
  create-dir "$LIQ_DB"
  create-dir "$LIQ_ENV_DB"
  create-dir "$LIQ_WORK_DB"
  create-dir "$LIQ_EXTS_DB"
  create-dir "$LIQ_ENV_LOGS"
  echo -n "Initializing local liq DB settings... "
  cat <<EOF > "${LIQ_DB}/settings.sh" || echoerrandexit "Failed!\nError creating local liq settings."
LIQ_PLAYGROUND="${LIQ_DB}/.liq"
EOF
  echo "${green}success${reset}"
}
