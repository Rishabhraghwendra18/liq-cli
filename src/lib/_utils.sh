indent() {
  local LEADING_INDENT=''
  local PAR_INDENT='  '
  local WIDTH=82
  if [[ -n "${INDENT:-}" ]]; then
    LEADING_INDENT=`printf '  %.0s' {1..$INDENT}`
    PAR_INDENT=`printf '  %.0s' {1..$(( $INDENT + 1))}`
    WIDTH=$(( $WIDTH - $INDENT * 2 ))
  fi

  fold -sw $WIDTH | sed -e "1,\$s/^/${LEADING_INDENT}/" -e "2,\$s/^/${PAR_INDENT}/"
}

usageActionPrefix() {
  if [[ -z "${INDENT:-}" ]]; then
    echo -n "catalyst $1 "
  fi
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
  mkdir -p "$CATALYST_WORK_DB"
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

requireCatalystSettings() {
  source "${CATALYST_SETTINGS}" 2> /dev/null \
    || echoerrandexit "Could not source global Catalyst settings. Try:\ncatalyst workspace init"
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
  findFile "${BASE_DIR}" 'package.json' PACKAGE_FILE
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
  requireCatalystfile
  requirePackage
  CURR_ENV_FILE="${_CATALYST_ENVS}/${PACKAGE_NAME}/curr_env"
  if [[ ! -L "$CURR_ENV_FILE" ]]; then
    contextHelp
    echoerrandexit "No environment currently selected."
  fi
  CURR_ENV=`readlink "${CURR_ENV_FILE}" | xargs basename`
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
    PROMPT="${PROMPT} (${DEFAULT}) "
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
  CATALYST_PLAYGROUND="$BASE_DIR"
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
  cd "$CATALYST_PLAYGROUND"
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

contextHelp() {
  # TODO: this is a bit of a workaround until all the ACTION usages are broken
  # out into ther own function.
  if type -t usage-${GROUP}-${ACTION} | grep -q 'function'; then
    usage-${GROUP}-${ACTION}
  else
    usage-${GROUP}
  fi
}

exactUserArgs() {
  local REQUIRED_ARGS=()
  while true; do
    case "$1" in
      --)
        break;;
      *)
        REQUIRED_ARGS+=("$1");;
    esac
    shift
  done
  shift

  if (( $# < ${#REQUIRED_ARGS[@]} )); then
    contextHelp
    echoerrandexit "Insufficient number of arguments."
  elif (( $# > ${#REQUIRED_ARGS[@]} )); then
    contextHelp
    echoerrandexit "Found extra arguments."
  else
    local I=0
    while (( $# > 0 )); do
      eval "${REQUIRED_ARGS[$I]}='$1'"
      shift
      I=$(( $I + 1 ))
    done
  fi
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
  # TODO TODO: when declared local here, it should not change the caller... I tihnk the original analysis was flawed.
  local _SELECT_LIMIT="$1"; shift
  local _VAR_NAME="$1"; shift
  local _PRE_OPTS="$1"; shift
  local _POST_OPTS="$1"; shift
  local _SELECTION
  local _QUIT='false'

  local _ENUM_OPTIONS=''
  # This crazyness is to preserve quotes; we use '%' as IFS later
  while (( $# > 0 )); do
    local OPT="$1"; shift
    local DEFAULT
    # This is another quote preserving technique. We expect 'SELECT_DEFAULT'
    # might be "'foo bar' 'baz'".
    eval 'for DEFAULT in '${SELECT_DEFAULT:-}'; do
      if [[ "$DEFAULT" == "$OPT" ]]; then
        OPT="*${OPT}"
      fi
    done'
    if [[ -z "$_ENUM_OPTIONS" ]]; then
      _ENUM_OPTIONS="$OPT"
    else
      _ENUM_OPTIONS="$_ENUM_OPTIONS%$OPT"
    fi
  done

  local _OPTIONS="$_ENUM_OPTIONS"
  if [[ -n "$_PRE_OPTS" ]]; then
    _OPTIONS="$(echo "$_PRE_OPTS" | tr ' ' '%')%$_OPTIONS"
  fi
  if [[ -n "$_POST_OPTS" ]]; then
    _OPTIONS="$_OPTIONS%$(echo "$_POST_OPTS" | tr ' ' '%')"
  fi

  updateVar() {
    _SELECTION="$(echo "$_SELECTION" | sed -Ee 's/^\*//')"
    if [[ -z "${!_VAR_NAME:-}" ]]; then
      eval "${_VAR_NAME}='${_SELECTION}'"
    else
      eval "$_VAR_NAME='${!_VAR_NAME} ${_SELECTION}'"
    fi
    _SELECTED_COUNT=$(( $_SELECTED_COUNT + 1 ))
  }

  local _SELECTED_COUNT=0

  while [[ $_QUIT == 'false' ]]; do
    local OLDIFS="$IFS"
    IFS='%'
    select _SELECTION in $_OPTIONS; do
      case "$_SELECTION" in
        '<cancel>')
          exit;;
        '<done>')
          _QUIT='true';;
        '<other>')
          _SELECTION=''
          requireAnswer "$PS3" _SELECTION
          updateVar;;
        '<any>')
          eval $_VAR_NAME='any'
          _QUIT='true';;
        '<all>')
          eval "$_VAR_NAME='$(echo $_ENUM_OPTIONS | tr '%' ' ')'"
          _QUIT='true';;
        '<default>')
          eval "${_VAR_NAME}=\"${SELECT_DEFAULT}\""
          _QUIT='true';;
        *)
          updateVar;;
      esac

      # after first selection, 'default' is nullified
      SELECT_DEFAULT=''
      _OPTIONS=$(echo "$_OPTIONS" | sed -Ee 's/(^|%)<default>(%|$)//' | tr -d '*')

      if [[ -n "$_SELECT_LIMIT" ]] && (( $_SELECT_LIMIT >= $_SELECTED_COUNT )); then
        _QUIT='true'
      fi
      if [[ "$_QUIT" != 'true' ]]; then
        echo "Current selections: ${!_VAR_NAME}"
      else
        echo "Final selections: ${!_VAR_NAME}"
      fi
      _OPTIONS=${_OPTIONS/$_SELECTION/}
      _OPTIONS=${_OPTIONS//%%/%}
      # if we only have the default options left, then we're done
      _OPTIONS=`echo "$_OPTIONS" | sed -Ee 's/^(<done>)?%?(<cancel>)?%?(<all>)?%?(<any>)?%?(<default>)?%?(<other>)?$//'`
      if [[ -z "$_OPTIONS" ]]; then
        _QUIT='true'
      fi
      break
    done
    IFS="$OLDIFS"
  done
}

selectOneCancel() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper 1 "$VAR_NAME" '<cancel>' '' "$@"
}

selectOneCancelDefault() {
  local VAR_NAME="$1"; shift
  if [[ -z "$SELECT_DEFAULT" ]]; then
    echowarn "Requested 'default' select, but no default provided. Falling back to non-default selection."
    selectOneCancel "$VAR_NAME" "$@"
  else
    _commonSelectHelper 1 "$VAR_NAME" '<cancel>' '<default>' "$@"
  fi
}

selectOneCancelOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper 1 "$VAR_NAME" '<cancel>' '<other>' "$@"
}

selectCancel() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<cancel>' '' "$@"
}

selectDoneCancel() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '' "$@"
}

selectDoneCancelAllOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<all> <other>' "$@"
}

selectDoneCancelAnyOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<any> <other>' "$@"
}

selectDoneCancelOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<other>' "$@"
}

selectDoneCancelOtherDefault() {
  local VAR_NAME="$1"; shift
  if [[ -z "$SELECT_DEFAULT" ]]; then
    echowarn "Requested 'default' select, but no default provided. Falling back to non-default selection."
    selectDoneCancelOther "$VAR_NAME" "$@"
  else
    _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<other> <default>' "$@"
  fi
}

selectDoneCancelAll() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<all>' "$@"
}

getPackageDef() {
  local VAR_NAME="$1"
  local FQN_PACKAGE_NAME="${2:-}"

  # The package we're looking at might be our own or might be a dependency.
  if [[ -z "$FQN_PACKAGE_NAME" ]] || [[ "$FQN_PACKAGE_NAME" == "$PACKAGE_NAME" ]]; then
    eval "$VAR_NAME=\"\$PACKAGE\""
  else
    eval "$VAR_NAME=\$(npm explore \"$FQN_PACKAGE_NAME\" -- cat package.json)"
  fi
}

runScript() {
  local SERV_SCRIPT="$1"; shift

  # The script might be our own or an installed dependency.
  if [[ -e "${BASE_DIR}/bin/${SERV_SCRIPT}" ]]; then
    "${BASE_DIR}/bin/${SERV_SCRIPT}" "$@"
  else
    npx --no-install $SERV_SCRIPT "$@"
  fi
}

getProvidedServiceValues() {
  local SERV_KEY="${1:-}"
  local FIELD_LABEL="$2"

  local SERV_PACKAGE SERV_NAME SERV
  if [[ -n "$SERV_KEY" ]];then
    # local SERV_IFACE=`echo "$SERV_KEY" | cut -d: -f1`
    local SERV_PACKAGE_NAME=`echo "$SERV_KEY" | cut -d: -f2`
    SERV_NAME=`echo "$SERV_KEY" | cut -d: -f3`
    getPackageDef SERV_PACKAGE "$SERV_PACKAGE_NAME"
  else
    SERV_PACKAGE="$PACKAGE"
  fi

  echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"${FIELD_LABEL}\" | @sh" | tr -d "'"
}

getRequiredParameters() {
  getProvidedServiceValues "${1:-}" "params-req"
}

# TODO: this is not like the others; it should take an optional package name, and the others should work with package names, not service specs. I.e., decompose externally.
# TODO: Or maybe not. Have a set of "objective" service key manipulators to build from and extract parts?
getConfigConstants() {
  local SERV_IFACE="${1}"
  echo "$PACKAGE" | jq --raw-output ".\"$CAT_REQ_SERVICES_KEY\" | .[] | select(.iface==\"$SERV_IFACE\") | .\"config-const\" | keys | @sh" | tr -d "'"
}

getCtrlScripts() {
  getProvidedServiceValues "${1:-}" "ctrl-scripts"
}

pressAnyKeyToContinue() {
  read -n 1 -s -r -p "Press any key to continue..."
  echo
}

getCatPackagePaths() {
  local NPM_ROOT=`npm root`
  local CAT_PACKAGE_PATHS=`find "$NPM_ROOT"/\@* -maxdepth 2 -name ".catalyst" -not -path "*.prelink/*" -exec dirname {} \;`
  CAT_PACKAGE_PATHS="${CAT_PACKAGE_PATHS} "`find "$NPM_ROOT" -maxdepth 2 -name ".catalyst" -not -path "*.prelink/*" -exec dirname {} \;`

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

requireCleanRepo() {
  local _IP="$1"
  local _WORK_BRANCH="${2:-}"

  cd "${CATALYST_PLAYGROUND}/${_IP}"
  ( test -n "$_WORK_BRANCH" \
      && git branch | grep -qE "^\* ${_WORK_BRANCH}" ) \
    || git diff-index --quiet HEAD -- \
    || echoerrandexit "Cannot perform action '${ACTION}'. '${_IP}' has uncommitted changes. Please resolve." 1
}

requireCleanRepos() {
  local _WORK_NAME="${1:-curr_work}"

  # we expect existence already ensured
  source "${CATALYST_WORK_DB}/${_WORK_NAME}"

  local IP
  for IP in $INVOLVED_PROJECTS; do
    requireCleanRepo "$IP" "$_WORK_NAME"
  done
}

defineParameters() {
  local SERVICE_DEF_VAR="$1"

  echo "Enter required parameters. Enter blank line when done."
  local PARAM_NAME
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Required parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then
      PARAM_NAME='...quit...'
    else
      eval $SERVICE_DEF_VAR'=$(echo "$'$SERVICE_DEF_VAR'" | jq ". + { \"params-req\": (.\"params-req\" + [\"'$PARAM_NAME'\"]) }")'
    fi
  done

  PARAM_NAME=''
  echo "Enter optional parameters. Enter blank line when done."
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Optional parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then
      PARAM_NAME='...quit...'
    else
      eval $SERVICE_DEF_VAR='$(echo "$'$SERVICE_DEF_VAR'" | jq ". + { \"params-opt\": (.\"params-opt\" + [\"'$PARAM_NAME'\"]) }")'
    fi
  done

  PARAM_NAME=''
  echo "Enter configuration constants. Enter blank line when done."
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Configuration constant: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then
      PARAM_NAME='...quit...'
    else
      local PARAM_VAL=''
      requireAnswer "Value: " PARAM_VAL
      eval $SERVICE_DEF_VAR='$(echo "$'$SERVICE_DEF_VAR'" | jq ". + { \"config-const\": (.\"config-const\" + { \"'$PARAM_NAME'\" : \"'$PARAM_VAL'\" }) }")'
    fi
  done
}
