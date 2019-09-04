# TODO: move to bash-toolkit
echogreen() {
  echo -e "${green}$*${reset}" | fold -sw 82
}

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

helpActionPrefix() {
  if [[ -z "${INDENT:-}" ]]; then
    echo -n "catalyst $1 "
  fi
}

colorerr() {
  # TODO: in the case of long output, it would be nice to notice whether we saw
  # error or not and tell the user to scroll back and check the logs. e.g., if
  # we see an error and then 20+ lines of stuff, then emit advice.
  (eval "$* 2> >(echo -n \"${red}\"; cat -; tput sgr0)")
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

exitUnknownGroup() {
  help --summary-only

  echoerrandexit "No such resource or group '$GROUP'. See help above."
}

exitUnknownSubgroup() {
  print_${GROUP}_help # TODO: change format to help-${group}
  echoerrandexit "Unknown sub-group '$SUBGROUP'. See help above."
}

exitUnknownAction() {
  help-${GROUP} # TODO: support per-action help.
  echoerrandexit "Unknown action '$ACTION'. See help above."
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
  CURR_ENV_FILE="${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env"
  if [[ ! -L "$CURR_ENV_FILE" ]]; then
    contextHelp
    echoerrandexit "No environment currently selected."
  fi
  CURR_ENV=`readlink "${CURR_ENV_FILE}" | xargs basename`
}

yesno() {
  default-yes() { return 0; }
  default-no() { return 1; } # bash fals-y

  local PROMPT="$1"
  local DEFAULT=$2
  local HANDLE_YES="${3:-default-yes}"
  local HANDLE_NO="${4:-default-no}" # default to noop

  local ANSWER=''
  read -p "$PROMPT" ANSWER
  if [ -z "$ANSWER" ]; then
    case "$DEFAULT" in
      Y*|y*)
        $HANDLE_YES; return $?;;
      N*|n*)
        $HANDLE_NO; return $?;;
      *)
        echo "You must choose an answer."
        yesno "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO
    esac
  else
    case "$ANSWER" in
      Y*|y*)
        $HANDLE_YES; return $?;;
      N*|n*)
        $HANDLE_NO; return $?;;
      *)
        echo "Did not understand response, please answer 'y(es)' or 'n(o)'."
        yesno "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO;;
    esac
  fi
}

addLineIfNotPresentInFile() {
  local FILE="${1:-}"
  local LINE="${2:-}"
  touch "$FILE"
  grep "$LINE" "$FILE" > /dev/null || echo "$LINE" >> "$FILE"
}

updateProjectPubConfig() {
  PROJECT_DIR="$BASE_DIR"
  LIQ_PLAYGROUND="$BASE_DIR"
  ensureWorkspaceDb
  local SUPPRESS_MSG="${1:-}"
  echo "PROJECT_HOME='$PROJECT_HOME'" > "$PROJECT_DIR/$_PROJECT_PUB_CONFIG"
  for VAR in PROJECT_MIRRORS; do
    if [[ -n "${!VAR:-}" ]]; then
      echo "$VAR='${!VAR}'" >> "$PROJECT_DIR/$_PROJECT_PUB_CONFIG"
    fi
  done

  local PROJECT_NAME=$(cat "${PROJECT_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  cp "$PROJECT_DIR/$_PROJECT_PUB_CONFIG" "$BASE_DIR/$_WORKSPACE_DB/projects/$PROJECT_NAME"
  if [[ "$SUPPRESS_MSG" != 'suppress-msg' ]]; then
    echo "Updated '$PROJECT_DIR/$_PROJECT_PUB_CONFIG' and '$BASE_DIR/projects/$PROJECT_NAME'."
  fi
}

# Sets up Workspace DB directory structure.
ensureWorkspaceDb() {
  cd "$LIQ_PLAYGROUND"
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
  # TODO: this is a bit of a workaround until all the ACTION helps are broken
  # out into ther own function.
  if type -t help-${GROUP}-${ACTION} | grep -q 'function'; then
    help-${GROUP}-${ACTION}
  else
    help-${GROUP}
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
  local CURR_ENV_FILE="${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env"

  if [[ -f "${CURR_ENV_FILE}" ]]; then
    source "$CURR_ENV_FILE"
  else
    resetEnv
  fi
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

  echo "$SERV_PACKAGE" | jq --raw-output ".catalyst.provides | .[] | select(.name == \"$SERV_NAME\") | .\"${FIELD_LABEL}\" | @sh" | tr -d "'" \
    || ( ( [[ -n $SERV_PACKAGE_NAME ]] && echoerrandexit "$SERV_PACKAGE_NAME package.json does not define .catalyst.provides[${SERV_NAME}]." ) || \
         echoerrandexit "Local package.json does not define .catalyst.provides[${SERV_NAME}]." )
}

getRequiredParameters() {
  getProvidedServiceValues "${1:-}" "params-req"
}

# TODO: this is not like the others; it should take an optional package name, and the others should work with package names, not service specs. I.e., decompose externally.
# TODO: Or maybe not. Have a set of "objective" service key manipulators to build from and extract parts?
getConfigConstants() {
  local SERV_IFACE="${1}"
  echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$SERV_IFACE\") | .\"config-const\" | keys | @sh" | tr -d "'"
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
  local CAT_PACKAGE_PATHS=`find -L "$NPM_ROOT"/\@* -maxdepth 2 -name ".catalyst" -not -path "*.prelink/*" -exec dirname {} \;`
  CAT_PACKAGE_PATHS="${CAT_PACKAGE_PATHS} "`find -L "$NPM_ROOT" -maxdepth 2 -name ".catalyst" -not -path "*.prelink/*" -exec dirname {} \;`

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

  local TMP # see https://unix.stackexchange.com/a/88338/84520
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

  cd "${LIQ_PLAYGROUND}/${_IP}"
  ( test -n "$_WORK_BRANCH" \
      && git branch | grep -qE "^\* ${_WORK_BRANCH}" ) \
    || git diff-index --quiet HEAD -- \
    || echoerrandexit "Cannot perform action '${ACTION}'. '${_IP}' has uncommitted changes. Please resolve." 1
}

requireCleanRepos() {
  local _WORK_NAME="${1:-curr_work}"

  # we expect existence already ensured
  source "${LIQ_WORK_DB}/${_WORK_NAME}"

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
      require-answer "Value: " PARAM_VAL
      eval $SERVICE_DEF_VAR='$(echo "$'$SERVICE_DEF_VAR'" | jq ". + { \"config-const\": (.\"config-const\" + { \"'$PARAM_NAME'\" : \"'$PARAM_VAL'\" }) }")'
    fi
  done
}
