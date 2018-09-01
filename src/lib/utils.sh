# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echoerr() {
  echo "${red}$*${reset}" >&2
}

colorerr() {
  # SAW_ERROR=`cat <(trap 'tput sgr0' EXIT; eval "$* 2> >(echo -n \"${red}\"; cat - >&2; echo 1)")`"$SAW_ERROR"
  (trap 'tput sgr0' EXIT; eval "$* 2> >(echo -n \"${red}\"; cat -;)")
}

sourcegcprojfile() {
  local SEARCH_DIR="$PWD"
  local PROJFILE
  while [[ $(cd "$SEARCH_DIR"; echo $PWD) != "/" ]]; do
    PROJFILE=`find "$SEARCH_DIR" -maxdepth 1 -mindepth 1 -name "gcprojfile" | grep gcprojfile || true`
    if [ -z "$PROJFILE" ]; then
      SEARCH_DIR="$SEARCH_DIR/.."
    else
      break
    fi
  done

  if [ -z "$PROJFILE" ]; then
    echoerr "Could not find project file." >&2
    exit 1
  else
    source "$PROJFILE"
    BASE_DIR="$( cd "$( dirname "${PROJFILE}" )" && pwd )"
  fi
}

yesno() {
  local PROMPT="$1"
  local DEFAULT=$2
  local HANDLE_YES=$3
  local HANDLE_NO=$4

  local ANSWER=''
  read -p "$PROMPT" ANSWER
  if [ -z "$ANSWER" ]; then
    case "$DEFAULT" in
      Y*|y*)
        $HANDLE_YES;;
      N*|n*)
        $HANDLE_NO;;
      *)
        echo "Bad default, please answer explicitly."
        yesno "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO
    esac
  else
    case "$ANSWER" in
      Y*|y*)
        $HANDLE_YES;;
      N*|n*)
        $HANDLE_NO;;
      *)
        echo "Did not understand response, please answer 'y(es)' or 'n(o)'."
        yesno "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO
    esac
  fi
}

addLineIfNotPresentInFile() {
  local FILE="${1:-}"
  local LINE="${2:-}"
  grep "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
}

updateGcprojfile() {
  local SUPPRESS_MSG="${1:-}"
  echo "ORGANIZATION_ID=$ORGANIZATION_ID" > "$BASE_DIR/gcprojfile"
  echo "BILLING_ACCOUNT_ID=$BILLING_ACCOUNT_ID" >> "$BASE_DIR/gcprojfile"
  echo "PROJECT_ID=$PROJECT_ID" >> "$BASE_DIR/gcprojfile"
  if [[ "$SUPPRESS_MSG" != 'suppress-msg' ]]; then
    echo "Updated '$BASE_DIR/gcprojfile'."
    echo
  fi
}

requireArgs() {
  local COUNT=$#
  local I=${COUNT}
  while (( $I != 0 )); do
    if [[ -z ${!COUNT:-} ]]; then
      if [ -z $ACTION ]; then
        echoerr "Global action '$COMPONENT' requires $COUNT additional arguments."
      else
        echoerr "'$COMPONENT $ACTION' requires $COUNT additional arguments."
      fi
      return 1
    fi
    I=$(( I - 1 ))
  done

  return 0
}
