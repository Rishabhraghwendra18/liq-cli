# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echoerr() {
  echo "${red}$*${reset}" >&2
}

echoerrandexit() {
  local MSG="$1"
  local EXIT_CODE="${2:-10}"
  echoerr "$MSG"
  exit $EXIT_CODE
}

colorerr() {
  # SAW_ERROR=`cat <(trap 'tput sgr0' EXIT; eval "$* 2> >(echo -n \"${red}\"; cat - >&2; echo 1)")`"$SAW_ERROR"
  (trap 'tput sgr0' EXIT; eval "$* 2> >(echo -n \"${red}\"; cat -;)")
}

exitUnknownGlobal() {
  print_usage
  echoerr "No such component or global action '$COMPONENT'."
  exit 1
}

exitUnknownAction() {
  print_${COMPONENT}_usage
  if [[ -z "$ACTION" ]]; then
    echoerr "Must specify action."
  else
    echoerr "Unknown action '$ACTION' for component '$COMPONENT'."
  fi
  exit 1
}

getProjFile() {
  local PROJFILE
  while [[ $(cd "$SEARCH_DIR"; echo $PWD) != "/" ]]; do
    PROJFILE=`find "$SEARCH_DIR" -maxdepth 1 -mindepth 1 -name ".catalyst" | grep .catalyst || true`
    if [ -z "$PROJFILE" ]; then
      SEARCH_DIR="$SEARCH_DIR/.."
    else
      break
    fi
  done

  echo "$PROJFILE"
}

sourceCatalystfile() {
  local SEARCH_DIR="$PWD"
  local PROJFILE=`getProjFile`

  if [ -z "$PROJFILE" ]; then
    echoerr "Could not find project file." >&2
    return 1
  else
    source "$PROJFILE"
    BASE_DIR="$( cd "$( dirname "${PROJFILE}" )" && pwd )"
    return 0
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
  touch "$FILE"
  grep "$LINE" "$FILE" > /dev/null || echo "$LINE" >> "$FILE"
}

updateCatalystFile() {
  local SUPPRESS_MSG="${1:-}"
  echo "ORGANIZATION_ID=$ORGANIZATION_ID" > "$BASE_DIR/.catalyst"
  echo "BILLING_ACCOUNT_ID=$BILLING_ACCOUNT_ID" >> "$BASE_DIR/.catalyst"
  echo "PROJECT_ID=$PROJECT_ID" >> "$BASE_DIR/.catalyst"
  if [[ -n "${GOPATH:-}" ]]; then
    echo "GOPATH='$GOPATH'" >> "$BASE_DIR/.catalyst"
  fi
  if [[ -n "${REL_GOAPP_PATH:-}" ]]; then
    echo "REL_GOAPP_PATH='$REL_GOAPP_PATH'" >> "$BASE_DIR/.catalyst"
  fi
  if [[ "$SUPPRESS_MSG" != 'suppress-msg' ]]; then
    echo "Updated '$BASE_DIR/.catalyst'."
    echo
  fi
}

requireArgs() {
  local COUNT=$#
  local I=1
  while (( $I <= $COUNT )); do
    if [[ -z ${!I:-} ]]; then
      if [ -z $ACTION ]; then
        echoerr "Global action '$COMPONENT' requires $COUNT additional arguments."
      else
        echoerr "'$COMPONENT $ACTION' requires $COUNT additional arguments."
      fi
      return 1
    fi
    I=$(( I + 1 ))
  done

  return 0
}

ensureGlobals() {
  local COUNT=$#
  local I=1
  while (( $I <= $COUNT )); do
    local GLOBAL_NAME=${!I}
    if [[ -z ${!GLOBAL_NAME:-} ]]; then
      echoerr "'${GLOBAL_NAME}' not set. Try: 'catalyst ${COMPONENT} configure'."
      return 1
    fi
    I=$(( I + 1 ))
  done

  return 0
}
