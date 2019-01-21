# http://linuxcommand.org/lc3_adv_tput.php
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
purple=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`

bold=`tput bold`
red_b="${red}${bold}"
green_b="${green}${bold}"
yellow_b="${yellow}${bold}"
blue_b="${blue}${bold}"
purple_b="${purple}${bold}"
cyan_b="${cyan}${bold}"
white_b="${white}${bold}"

underline=`tput smul`
red_u="${red}${underline}"
green_u="${green}${underline}"
yellow_u="${yellow}${underline}"
blue_u="${blue}${underline}"
purple_u="${purple}${underline}"
cyan_u="${cyan}${underline}"
white_u="${white}${underline}"

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
  (trap 'EXIT_STATUS=$?; tput sgr0; exit $EXIT_STATUS' EXIT; eval "$* 2> >(echo -n \"${red}\"; cat -;)")
}

# TODO: is this better? We switched to it for awhile, but there were problems.
# The reasons for both the initial switch and the switchback are now obscured
# but may have been due to failure of the original code to exit with the
# underling error status from the eval, which has since been fixed. The
# switchback was, in part, because of problems with syncronous calls. Of course,
# it didn't wait as we would like, but it was also causing functional problems
# with... somethnig.
# TODO: We are currently not using colorerrbg anywhere.
colorerrbg() {
  (eval "$@" 2>&1>&3|sed 's/^\(.*\)$/'$'\e''[31m\1'$'\e''[m/'>&2)3>&1 &
}

ensureConfig() {
  mkdir -p "$_CATALYST_DB"
  mkdir -p "$_CATALYST_ENVS"
}

exitUnknownGroup() {
  help --summary-only

  echoerrandexit "No such resource or group '$GROUP'. See usage above."
}

exitUnknownSubgroup() {
  print_${GROUP}_usage # TODO: change format to usage-${group}
  echoerrandexit "Unknown sub-group '$SUBGROUP'. See usage above."
}

exitUnknownAction() {
  usage-${GROUP} # TODO: support per-action help.
  echoerrandexit "Unknown action '$ACTION'. See usage above."
}

findFile() {
  local SEARCH_DIR="${1}"
  local FILE_NAME="${2}"
  local RES_VAR="${3}"
  local FOUND_FILE

  while SEARCH_DIR="$(cd "$SEARCH_DIR"; echo $PWD)" && [[ "${SEARCH_DIR}" != "/" ]]; do
    FOUND_FILE=`find -L "$SEARCH_DIR" -maxdepth 1 -mindepth 1 -name "${FILE_NAME}" -type f | grep "${FILE_NAME}" || true`
    if [ -z "$FOUND_FILE" ]; then
      SEARCH_DIR="$SEARCH_DIR/.."
    else
      break
    fi
  done

  if [ -z "$FOUND_FILE" ]; then
    echoerr "Could not find '${FILE_NAME}' config file in any parent directory."
    return 1
  else
    eval $RES_VAR="$FOUND_FILE"
  fi
}

sourceFile() {
  local SEARCH_DIR="${1}"
  local FILE_NAME="${2}"
  local PROJFILE
  findFile "$SEARCH_DIR" "$FILE_NAME" PROJFILE && {
    source "$PROJFILE"
    # TODO: this works (at time of note) because all the files we currently source are in the root, but it's a bit odd and should be reworked.
    BASE_DIR="$( cd "$( dirname "${PROJFILE}" )" && pwd )"
    return 0
  }
}

sourceCatalystfile() {
  sourceFile "${PWD}" '.catalyst'
  return $? # TODO: is this how this works in bash?
}

requireCatalystfile() {
  sourceCatalystfile \
    || echoerrandexit "Run 'catalyst project init' from project root." 1
}

requireNpmPackage() {
  findFile "${PWD}" 'package.json' PACKAGE_FILE
}

sourceWorkspaceConfig() {
  sourceFile "${PWD}" "${_WORKSPACE_CONFIG}"
  return $? # TODO: is this how this works in bash?
}

requirePackage() {
  requireNpmPackage
  PACKAGE=`cat $PACKAGE_FILE`
  PACKAGE_NAME=`echo "$PACKAGE" | jq --raw-output ".name"`
}

requireEnvironment() {
  requirePackage
  requireCatalystfile
  CURR_ENV_FILE="${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env"
  if [[ ! -f "$CURR_ENV_FILE" ]]; then
    echoerrandexit "Must select environment to work with '${COMPONENT} ${ACTION}' module."
  fi
  CURR_ENV=`readlink "${CURR_ENV_FILE}" | xargs basename`
}

requireWorkspaceConfig() {
  sourceWorkspaceConfig \
    || echoerrandexit "Run 'catalyst workspace init' from workspace root." 1
}

yesno() {
  local PROMPT="$1"
  local DEFAULT=$2
  local HANDLE_YES=$3
  local HANDLE_NO="${4:-}" # default to noop

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

requireAnswer() {
  local PROMPT="$1"
  local VAR="$2"
  local DEFAULT="${3:-}"

  if [[ -n "${DEFAULT}" ]]; then
    PROMPT="${PROMPT}(${DEFAULT}) "
  fi

  while [ -z ${!VAR:-} ]; do
    read -p "$PROMPT" $VAR
    if [[ -z ${!VAR:-} ]] && [[ -z "$DEFAULT" ]]; then
      echoerr "A response is required."
    elif [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
      # MacOS dosen't support 'declare -g' :(
      eval ${VAR}="${DEFAULT}"
    fi
  done
}

addLineIfNotPresentInFile() {
  local FILE="${1:-}"
  local LINE="${2:-}"
  touch "$FILE"
  grep "$LINE" "$FILE" > /dev/null || echo "$LINE" >> "$FILE"
}

updateCatalystFile() {
  local SUPPRESS_MSG="${1:-}"
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

updateProjectPubConfig() {
  PROJECT_DIR="$BASE_DIR"
  requireWorkspaceConfig
  WORKSPACE_DIR="$BASE_DIR"
  ensureWorkspaceDb
  local SUPPRESS_MSG="${1:-}"
  echo "PROJECT_HOME='$PROJECT_HOME'" > "$PROJECT_DIR/$_PROJECT_PUB_CONFIG"
  for VAR in PROJECT_MIRRORS; do
    if [[ -n "${!VAR:-}" ]]; then
      echo "$VAR='${!VAR}'" >> "$PROJECT_DIR/$_PROJECT_PUB_CONFIG"
    fi
  done

  local PROJECT_NAME=`basename $PROJECT_DIR`
  cp "$PROJECT_DIR/$_PROJECT_PUB_CONFIG" "$BASE_DIR/$_WORKSPACE_DB/projects/$PROJECT_NAME"
  if [[ "$SUPPRESS_MSG" != 'suppress-msg' ]]; then
    echo "Updated '$PROJECT_DIR/$_PROJECT_PUB_CONFIG' and '$BASE_DIR/projects/$PROJECT_NAME'."
  fi
}

# Sets up Workspace DB directory structure.
ensureWorkspaceDb() {
  cd "$WORKSPACE_DIR"
  mkdir -p "${_WORKSPACE_DB}"
  mkdir -p "${_WORKSPACE_DB}"/projects
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
  echo `date +%Y-%m-%d`-`whoami`-"${BRANCH_DESC}"
}

loadCurrEnv() {
  resetEnv() {
    CURR_ENV=''
    CURR_ENV_TYPE=''
    CURR_ENV_PURPOSE=''
  }

  local PACKAGE_NAME=`cat $BASE_DIR/package.json | jq --raw-output ".name"`
  local CURR_ENV_FILE="${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env"

  if [[ -f "${CURR_ENV_FILE}" ]]; then
    source "$CURR_ENV_FILE"
  else
    resetEnv
  fi
}

_commonSelectHelper() {
  # TODO: the '_' is to avoid collision, but is a bit hacky; in particular, some callers were using 'local OPTIONS'
  local _VAR_NAME="$1"; shift
  local _PRE_OPTS="$1"; shift
  local _POST_OPTS="$1"; shift
  local _SELECTION
  local _OPTIONS="$@"
  local _QUIT='false'

  if [[ -n "$_PRE_OPTS" ]]; then
    _OPTIONS="$_PRE_OPTS $_OPTIONS"
  fi
  if [[ -n "$_POST_OPTS" ]]; then
    _OPTIONS="$_OPTIONS $_POST_OPTS"
  fi

  while [[ $_QUIT == 'false' ]]; do
    select _SELECTION in $_OPTIONS; do
      case "$_SELECTION" in
        '<cancel>')
          exit;;
        '<done>')
          echo "Final selection: ${!_VAR_NAME}"
          _QUIT='true';;
        '<other>')
          _SELECTION=''
          requireAnswer "$PS3" _SELECTION
          eval $_VAR_NAME=\"${!_VAR_NAME}'${_SELECTION}' \";;
        '<any>')
          echo "Final selection: 'any'"
          eval $_VAR_NAME='any'
          _QUIT='true';;
        '<all>')
          echo "Final selection: 'all'"
          eval $_VAR_NAME=\""$@"\"
          _QUIT='true';;
        *)
          eval $_VAR_NAME=\"${!_VAR_NAME}'${_SELECTION}' \";;
      esac
      if [[ -z "$_QUIT" ]]; then
        echo "Current selections: ${!_VAR_NAME}"
      fi
      _OPTIONS=${_OPTIONS/$_SELECTION/}
      # if we only have the default options left, then we're done
      _OPTIONS=`echo "$_OPTIONS" | sed -Ee 's/^<done> <cancel>[ ]*(<all>)?[ ]*(<any>)?[ ]*(<other>)?$//'`
      if [[ -z "$_OPTIONS" ]]; then
        _QUIT='true'
      fi
      break
    done
  done
}

selectDoneCancelAnyOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper "$VAR_NAME" '<done> <cancel>' '<any> <other>' "$@"
}

selectDoneCancelOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper "$VAR_NAME" '<done> <cancel>' '<other>' "$@"
}

selectDoneCancel() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper "$VAR_NAME" '<done> <cancel>' '' "$@"
}

selectDoneCancelAll() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper "$VAR_NAME" '<done> <cancel>' '<all>' "$@"
}

getRequiredParameters() {
  local SERV_KEY="$1"
  local SERV_IFACE=`echo "$SERV_KEY" | cut -d: -f1`
  local SERV_PACKAGE_NAME=`echo "$SERV_KEY" | cut -d: -f2`
  local SERV_NAME=`echo "$SERV_KEY" | cut -d: -f3`
  local SERV_PACKAGE=`npm explore "$SERV_PACKAGE_NAME" -- cat package.json`

  echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"params-req\" | @sh" | tr -d "'"
}

pressAnyKeyToContinue() {
  read -n 1 -s -r -p "Press any key to continue..."
  echo
}

getCatPackagePaths() {
  local NPM_ROOT=`npm root`
  local CAT_PACKAGE_PATHS=`find "$NPM_ROOT"/\@* -maxdepth 2 -name ".catalyst" -exec dirname {} \;`
  CAT_PACKAGE_PATHS="${CAT_PACKAGE_PATHS} "`find "$NPM_ROOT" -maxdepth 2 -name ".catalyst" -exec dirname {} \;`

  echo "$CAT_PACKAGE_PATHS"
}

setSimpleOptions() {
  local VAR_SPEC SHORT_OPTS LONG_OPTS LOCAL_DECLS
  local OPTS_COUNT=0
  # This looks like a straight up bug in bash, but the left-paren in '--)' was
  # matching the '$(' and causing a syntax error. So we use ']' and replace it
  # later.
  local CASE_HANDLER=$(cat <<EOF
    --]
      break;;
EOF
)
  while true; do
    VAR_SPEC="$1"; shift
    local VAR_NAME LOWER_NAME SHORT_OPT LONG_OPT
    if [[ "$VAR_SPEC" == '--' ]]; then
      break
    elif [[ "$VAR_SPEC" == *':'* ]]; then
      VAR_NAME=$(echo "$VAR_SPEC" | cut -d: -f1)
      SHORT_OPT=$(echo "$VAR_SPEC" | cut -d: -f2)
    else # each input is a variable name
      VAR_NAME="$VAR_SPEC"
      SHORT_OPT=$(echo "${VAR_NAME::1}" | tr '[:upper:]' '[:lower:]')
    fi
    local OPT_REQ=$(echo "$VAR_NAME" | sed -Ee 's/[^=]//g' | tr '=' ':')
    VAR_NAME=`echo "$VAR_NAME" | tr -d "="`
    LOWER_NAME=`echo "$VAR_NAME" | tr '[:upper:]' '[:lower:]'`
    LONG_OPT="$(echo "${LOWER_NAME}" | tr '_' '-')"

    SHORT_OPTS="${SHORT_OPTS}${SHORT_OPT}${OPT_REQ}"
    LONG_OPTS=$( ( test ${#LONG_OPTS} -gt 0 && echo -n "${LONG_OPTS}${OPT_REQ},") || true && echo -n "${LONG_OPT}${OPT_REQ}")
    # set on declaration so nested calles get reset
    LOCAL_DECLS="${LOCAL_DECLS}local ${VAR_NAME}='';"
    local VAR_SETTER="echo \"${VAR_NAME}=true;\""
    if [[ -n "$OPT_REQ" ]]; then
      LOCAL_DECLS="${LOCAL_DECLS}local ${VAR_NAME}_SET='';"
      VAR_SETTER="echo \"${VAR_NAME}='\$2'; ${VAR_NAME}_SET=true;\"; shift;"
    fi
    CASE_HANDLER=$(cat <<EOF
    ${CASE_HANDLER}
      -${SHORT_OPT}|--${LONG_OPT}]
        $VAR_SETTER
        OPTS_COUNT=\$(( \$OPTS_COUNT + 1));;
EOF
)
  done
  CASE_HANDLER=$(cat <<EOF
    case "\$1" in
      $CASE_HANDLER
    esac
EOF
)
  CASE_HANDLER=`echo "$CASE_HANDLER" | tr ']' ')'`

  echo "$LOCAL_DECLS"

  local TMP # because of the '||', we have to break up the set
  TMP=`${GNU_GETOPT} -o "${SHORT_OPTS}" -l "${LONG_OPTS}" -- "$@"` \
    || exit 1
  eval set -- "$TMP"
  while true; do
    eval "$CASE_HANDLER"
    shift
  done
  shift

  echo "local _OPTS_COUNT=${OPTS_COUNT};"
  echo set -- "$@"
}
