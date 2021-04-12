# Basic indent of a line.
indent() {
  cat | sed -e 's/^/  /'
}

# Folds the summary with a hanging indent.
_help-func-summary() {
  local FUNC_NAME="${1}"
  local OPTIONS="${2:-}"

  local STD_FOLD=82
  local WIDTH
  WIDTH=$(( $STD_FOLD - 2 ))

  (
    # echo -n "${underline}${yellow}${FUNC_NAME}${reset} "
    echo -n "${FUNC_NAME} "
    [[ -z "$OPTIONS" ]] || echo -n "${OPTIONS}"
    echo -n ": "
    cat
  ) | fold -sw $WIDTH | sed -E \
    -e "1 s/^([[:alpha:]-]+) /\\1 ${green}/" \
    -e "1,/:/ s/:/${reset}:/" \
    -e "1 s/^([[:alpha:]-]+)/${yellow}${underline}\\1${reset}/" \
    -e '2,$s/^/  /'
    # We fold, then color because fold sees the control characters as just plain characters, so it throws the fold off.
    # The non-printing characters are only really understood as such by the terminal and individual programs that
    # support it (which fold should, but, as this is written, doesn't).
    # 1 & 2) make options green
    # 3) yellow underline function name
    # 4) add hanging indent
}

# Prints and indents the help for each action
_help-actions-list() {
  local GROUP="${1}"; shift
  local ACTION
  for ACTION in "$@"; do
    echo
    help-$GROUP-$ACTION -i
  done
}

_help-sub-group-list() {
  local PREFIX="${1}"
  local GROUPS_VAR="${2}"

  if [[ -n "${!GROUPS_VAR}" ]]; then
    local SG
    echo "$( {  echo -e "\n${bold}Sub-groups${reset}:";
                for SG in ${!GROUPS_VAR}; do
                  echo "* $( SUMMARY_ONLY=true; help-${PREFIX}-${SG} )";
                done; } | indent)"
  fi
}

helpActionPrefix() {
  if [[ -z "${INDENT:-}" ]]; then
    echo -n "liq $1 "
  fi
}

colorerr() {
  # TODO: in the case of long output, it would be nice to notice whether we saw
  # error or not and tell the user to scroll back and check the logs. e.g., if
  # we see an error and then 20+ lines of stuff, then emit advice.
  (eval "$@ 2> >(echo -n \"${red}\"; cat -; tput sgr0)")
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

# Verifies access to github.
check-git-access() {
  eval "$(setSimpleOptions NO_EXIT -- "$@")"
  # if we don't supress the output, then we get noise even when successful
  ssh -qT git@github.com 2> /dev/null || if [ $? -ne 1 ]; then
    [[ -z "${NO_EXIT}" ]] || return 1
    echoerrandexit "Could not connect to github; try to add add your GitHub key like:\nssh-add /example/path/to/key"
  fi
}

change-working-project() {
  if [[ -n "$PROJECT" ]]; then
    if ! [[ -d "${LIQ_PLAYGROUND}/${PROJECT}" ]]; then
      echoerrandexit "No such project '${PROJECT}' found locally."
    fi
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
  fi
}

findFile() {
  local SEARCH_DIR="${1}"
  local FILE_NAME="${2}"
  local RES_VAR="${3}"
  local FOUND_FILE
  local START_DIR="$SEARCH_DIR"

  while SEARCH_DIR="$(cd "$SEARCH_DIR"; echo $PWD)" && [[ "${SEARCH_DIR}" != "/" ]]; do
    FOUND_FILE=`find -L "$SEARCH_DIR" -maxdepth 1 -mindepth 1 -name "${FILE_NAME}" -type f | grep "${FILE_NAME}" || true`
    if [ -z "$FOUND_FILE" ]; then
      SEARCH_DIR="$SEARCH_DIR/.."
    else
      break
    fi
  done

  if [ -z "$FOUND_FILE" ]; then
    echoerr "Could not find '${FILE_NAME}' in '$START_DIR' or any parent directory."
    return 1
  else
    eval $RES_VAR="$FOUND_FILE"
  fi
}

findBase() {
  findFile "${PWD}" package.json PACKAGE_FILE
  BASE_DIR="$( cd "$( dirname "${PACKAGE_FILE}" )" && pwd )"
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
    || echoerrandexit "Run 'liq projects init' from project root." 1
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
  PACKAGE="$(cat $PACKAGE_FILE)"
  PACKAGE_NAME="$(echo "$PACKAGE" | jq --raw-output ".name")"
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

addLineIfNotPresentInFile() {
  local FILE="${1:-}"
  local LINE="${2:-}"
  touch "$FILE"
  grep "$LINE" "$FILE" > /dev/null || echo "$LINE" >> "$FILE"
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
      echoerr "'${GLOBAL_NAME}' not set. Try:\nliq ${COMPONENT} configure"
      exit 1
    fi
    I=$(( I + 1 ))
  done

  return 0
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

  # The project we're looking at might be our own or might be a dependency.
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

# Takes a project name and checks that the local repo is clean. By specifyng '--check-branch' (which will take a comma
# separated list of branch names) or '--check-all-branches', the function will also check that the current head of each
# branch is present in the remote repo. The branch checks do not include a 'fetch', so local information may be out of
# date.
requireCleanRepo() {
  eval "$(setSimpleOptions CHECK_BRANCH= CHECK_ALL_BRANCHES -- "$@")"

  local _IP="$1"
  _IP="${_IP/@/}"
  # TODO: the '_WORK_BRANCH' here seem to be more of a check than a command to check that branch.
  _IP=${_IP/@/}

  local BRANCHES_TO_CHECK
  if [[ -n "$CHECK_ALL_BRANCHES" ]]; then
    BRANCHES_TO_CHECK="$(git branch --list --format='%(refname:lstrip=-1)')"
  elif [[ -n "$CHECK_BRANCH" ]]; then
    list-from-csv BRANCHES_TO_CHECK "$CHECK_BRANCH"
  fi

  cd "${LIQ_PLAYGROUND}/${_IP}"

  echo "Checking ${_IP}..."
  # credit: https://stackoverflow.com/a/8830922/929494
  # look for uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echoerrandexit "Found uncommitted changes.\n$(git status --porcelain)"
  fi
  # check for untracked files
  if (( $({ git status --porcelain 2>/dev/null| grep '^??' || true; } | wc -l) != 0 )); then
    echoerrandexit "Found untracked files."
  fi
  # At this point, the local repo is clean. Now we look at any branches of interest to make sure they've been pushed.
  if [[ -n "$BRANCHES_TO_CHECK" ]]; then
    local BRANCH_TO_CHECK
    for BRANCH_TO_CHECK in $BRANCHES_TO_CHECK; do
      if [[ "$BRANCH_TO_CHECK" == master ]] \
         && ! git merge-base --is-ancestor master upstream/master; then
        echoerrandexit "Local master has not been pushed to upstream master."
      fi
      # if the repo was created without forking, then there's no separate workspace
      if git remote | grep -e '^workspace$' \
          && ! git merge-base --is-ancestor "$BRANCH_TO_CHECK" "workspace/${BRANCH_TO_CHECK}"; then
        echoerrandexit "Local branch '$BRANCH_TO_CHECK' has not been pushed to workspace."
      fi
    done
  fi
}

# For each 'involved project' in the indicated unit of work (default to current unit of work), checks that the repo is
# clean.
requireCleanRepos() {
  local _WORK_NAME="${1:-curr_work}"

  ( # isolate the source
    source "${LIQ_WORK_DB}/${_WORK_NAME}"

    local IP
    for IP in $INVOLVED_PROJECTS; do
      requireCleanRepo "$IP"
    done
  )
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
