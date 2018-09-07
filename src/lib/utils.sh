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
  # the subshell around '$*' is to suppress not-so-useful error report on failure.
  # it's a hack and have posted question to try and find better fix:
  # https://unix.stackexchange.com/questions/467558/why-is-the-err-trap-being-invoked-here
  (trap 'tput sgr0' EXIT; eval "($*) 2> >(echo -n \"${red}\"; cat -;)") || true

  # TODO: in case the output is long, want to note whether we noted any problems
  # at the end; however, we're having troubling capturing 'SAW_ERROR'.
  # But that was in an earlier implementation, so might be worth taking another
  # run at it.
  # echo
  # if [ -n "$SAW_ERROR" ]; then
  #   echo "${red}Errors were observed. Check the logs above.${reset}"
  # else
  #   echo "${green}Everything looks good.${reset}"
  # fi
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

requireCatalystfile() {
  sourceCatalystfile \
    || (echoerr "Did not find 'Catalystfile'; run 'catalyst project init'." \
        && exit 1)
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
  for VAR in GOPATH REL_GOAPP_PATH SQL_DIR TEST_DATA_DIR \
      CLOUDSQL_CONNECTION_NAME CLOUDSQL_CREDS CLOUDSQL_DB_DEV CLOUDSQL_DB_TEST \
      WEB_APP_DIR; do
    if [[ -n "${!VAR:-}" ]]; then
      echo "$VAR='${!VAR}'" >> "$BASE_DIR/.catalyst"
    fi
  done

  if [[ "$SUPPRESS_MSG" != 'suppress-msg' ]]; then
    echo "Updated '$BASE_DIR/.catalyst'."
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

requireGlobals() {
  local COUNT=$#
  local I=1
  while (( $I <= $COUNT )); do
    local GLOBAL_NAME=${!I}
    if [[ -z ${!GLOBAL_NAME:-} ]]; then
      echoerr "'${GLOBAL_NAME}' not set. Try: 'catalyst ${COMPONENT} configure'."
      exit 1
    fi
    I=$(( I + 1 ))
  done

  return 0
}
