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
  # TODO: in the case of long output, it would be nice to notice whether we saw
  # error or not and tell the user to scroll back and check the logs. e.g., if
  # we see an error and then 20+ lines of stuff, then emit advice.
  # TODO: I think the background should be conditional?
  (eval "$@" 2>&1>&3|sed 's/^\(.*\)$/'$'\e''[31m\1'$'\e''[m/'>&2)3>&1 &
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

sourceFile() {
  local SEARCH_DIR="${1}"
  local FILE_NAME="${2}"
  local PROJFILE
  while SEARCH_DIR="$(cd "$SEARCH_DIR"; echo $PWD)" && [[ "${SEARCH_DIR}" != "/" ]]; do
    PROJFILE=`find -L "$SEARCH_DIR" -maxdepth 1 -mindepth 1 -name "${FILE_NAME}" | grep "${FILE_NAME}" || true`
    if [ -z "$PROJFILE" ]; then
      SEARCH_DIR="$SEARCH_DIR/.."
    else
      break
    fi
  done

  if [ -z "$PROJFILE" ]; then
    echoerr "Could not find '${FILE_NAME}' config file in any parent directory."
    return 1
  else
    source "$PROJFILE"
    BASE_DIR="$( cd "$( dirname "${PROJFILE}" )" && pwd )"
    return 0
  fi
}

sourceCatalystfile() {
  sourceFile "${PWD}" '.catalyst'
  return $? # TODO: is this how this works in bash?
}

requireCatalystfile() {
  sourceCatalystfile \
    || echoerrandexit "Run 'catalyst project init' from project root." 1
}

sourceWorkspaceConfig() {
  sourceFile "${PWD}" "${_WORKSPACE_CONFIG}"
  return $? # TODO: is this how this works in bash?
}

requireWorkspaceConfig() {
  sourceWorkspaceConfig \
    || echoerrandexit "Run 'catalyst workspace init' from workspace root." 1
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
      if [[ -z $ACTION ]]; then
        echoerr "Global action '$COMPONENT' requires $COUNT additional arguments."
      else
        echoerr "'$COMPONENT $ACTION' requires $COUNT additional arguments."
      fi
      # TODO: as 'requireArgs' this should straight up exit.
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

branchName() {
  local BRANCH_DESC="${1:-}"
  requireArgs "$BRANCH_DESC" || exit $?
  "`date +%Y-%m-%d`-`whoami`-${BRANCH_DESC}"
}
