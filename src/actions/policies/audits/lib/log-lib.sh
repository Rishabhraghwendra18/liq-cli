# Gets the current time (resolution: 1 second) in UTC for use by log functions.
policies-audits-now() { date -u +%Y%m%d%H%M%S; }

# Adds log entry. Takes a single argument, the message to add to the log entry.
# outer vars: RECORDS_FOLDER
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

  echo "$(policies-audits-now) UTC ${USER} ${MESSAGE}" >> "${RECORDS_FOLDER}/refs/history.log"
}

# Signs the log. Takes the records folder as first argument.
policies-audits-sign-log() {
  local RECORDS_FOLDER="${1}"
  local USER SIGNED_AT
  USER="$(git config user.email)"
  SIGNED_AT=$(policies-audits-now)

  echo "Signing current log file..."

  mkdir -p "${RECORDS_FOLDER}/sigs"
  gpg2 --output "${RECORDS_FOLDER}/sigs/history-${SIGNED_AT}-zane.sig" \
    -u ${USER} \
    --detach-sig \
    --armor \
    "${RECORDS_FOLDER}/refs/history.log"
}

# Gets all entries since the indicated time (see policies-audits-now for format). Takes records folder and the key time as the first and second arguments.
policies-audits-summarize-since() {
  local RECORDS_FOLDER="${1}"
  local SINCE="${2}"

  local ENTRY_TIME LINE LINE_NO
  LINE_NO=1
  for ENTRY_TIME in $(awk '{print $1}' "${RECORDS_FOLDER}/refs/history.log"); do
    if (( $ENTRY_TIME < $SINCE )); then
      LINE_NO=$(( $LINE_NO + 1 ))
    else
      break
    fi
  done

  echofmt reset "Summary of actions:"
  # for each line in history log, turn into a word-wrapped bullet point
  while read -e LINE; do
    echo "$LINE" | fold -sw 82 | sed -e '1s/^/* /' -e '2,$s/^/  /'
    LINE_NO=$(( $LINE_NO + 1 ))
  done <<< "$(tail +${LINE_NO} "${RECORDS_FOLDER}/refs/history.log")"
  echo
}
