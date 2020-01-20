policies-audits-add-log-entry() {
  local MESSAGE="${1}"

  if [[ -z "${RECORDS_FOLDER}" ]]; then
    echoerrandexit "Could not update log; 'RECORDS_FOLDER' not set."
  fi

  local USER
  USER="$(git config user.email)"
  if [[ -z "$USER" ]]; then
    echoerrandexit "Must set git 'user.email' for use by audit log."
  fi

  echo "$(date +%Y%m%d%H%M) UTC ${USER} : ${MESSAGE}" >> "${RECORDS_FOLDER}/history.log"
}
