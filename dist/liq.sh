#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

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

red_bu="${red}${bold}${underline}"
green_bu="${green}${bold}${underline}"
yellow_bu="${yellow}${bold}${underline}"
blue_bu="${blue}${bold}${underline}"
purple_bu="${purple}${bold}${underline}"
cyan_bu="${cyan}${bold}${underline}"
white_bu="${white}${bold}${underline}"

reset=`tput sgr0`
if [[ $(uname) == 'Darwin' ]]; then
  GNU_GETOPT="$(brew --prefix gnu-getopt)/bin/getopt"
else
  GNU_GETOPT="$(which getopt)"
fi

# Usage:
#   eval "$(setSimpleOptions SHORT LONG= SPECIFY_SHORT:X LONG_SPEC:S= -- "$@")" \
#     || ( contextHelp; echoerrandexit "Bad options."; )
#
# Note the use of the intermediate TMP is important to preserve the exit value
# setSimpleOptions. E.g., doing 'eval "$(setSimpleOptions ...)"' will work fine,
# but because the last statement is the eval of the results, and not the function
# call itself, the return of setSimpleOptions gets lost.
#
# Instead, it's generally recommended to be strict, 'set -e', and use the TMP-form.
setSimpleOptions() {
  local VAR_SPEC LOCAL_DECLS
  local LONG_OPTS=""
  local SHORT_OPTS=""
  # Bash Bug? This looks like a straight up bug in bash, but the left-paren in
  # '--)' was matching the '$(' and causing a syntax error. So we use ']' and
  # replace it later.
  local CASE_HANDLER=$(cat <<EOF
    --]
      break;;
EOF
)
  while true; do
    if (( $# == 0 )); then
      echoerrandexit "setSimpleOptions: No argument to process; did you forget to include the '--' marker?"
    fi
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
    local OPT_ARG=$(echo "$VAR_NAME" | sed -Ee 's/[^=]//g' | tr '=' ':')
    VAR_NAME=$(echo "$VAR_NAME" | tr -d "=")
    LOWER_NAME=$(echo "$VAR_NAME" | tr '[:upper:]' '[:lower:]')
    LONG_OPT="$(echo "${LOWER_NAME}" | tr '_' '-')"

    if [[ -n "${SHORT_OPT}" ]]; then
      SHORT_OPTS="${SHORT_OPTS:-}${SHORT_OPT}${OPT_ARG}"
    fi

    LONG_OPTS=$( ( test ${#LONG_OPTS} -gt 0 && echo -n "${LONG_OPTS},") || true && echo -n "${LONG_OPT}${OPT_ARG}")

    LOCAL_DECLS="${LOCAL_DECLS:-}local ${VAR_NAME}='';"
    local VAR_SETTER="${VAR_NAME}=true;"
    if [[ -n "$OPT_ARG" ]]; then
      LOCAL_DECLS="${LOCAL_DECLS}local ${VAR_NAME}_SET='';"
      VAR_SETTER=${VAR_NAME}'="${2}"; '${VAR_NAME}'_SET=true; shift;'
    fi
    local CASE_SELECT="-${SHORT_OPT}|--${LONG_OPT}]"
    if [[ -z "$SHORT_OPT" ]]; then
      CASE_SELECT="--${LONG_OPT}]"
    fi
    CASE_HANDLER=$(cat <<EOF
    ${CASE_HANDLER}
      ${CASE_SELECT}
        $VAR_SETTER
        _OPTS_COUNT=\$(( \$_OPTS_COUNT + 1));;
EOF
)
  done # main while loop
  CASE_HANDLER=$(cat <<EOF
    case "\$1" in
      $CASE_HANDLER
    esac
EOF
)
  # replace the ']'; see 'Bash Bug?' above
  CASE_HANDLER=$(echo "$CASE_HANDLER" | perl -pe 's/\]$/)/')

  echo "$LOCAL_DECLS"

  cat <<EOF
local TMP # see https://unix.stackexchange.com/a/88338/84520
TMP=\$(${GNU_GETOPT} -o "${SHORT_OPTS}" -l "${LONG_OPTS}" -- "\$@") \
  || exit \$?
eval set -- "\$TMP"
local _OPTS_COUNT=0
while true; do
  $CASE_HANDLER
  shift
done
shift
EOF
#  echo 'if [[ -z "$1" ]]; then shift; fi' # TODO: explain this
}

echoerr() {
  local TMP
  TMP=$(setSimpleOptions NO_FOLD:F -- "$@")
  eval "$TMP"

  if [[ -z "$NO_FOLD" ]]; then
    echo -e "${red}$*${reset}" | fold -sw 82 >&2
  else
    echo -e "${red}$*${reset}"
  fi
}

echowarn() {
  local TMP
  TMP=$(setSimpleOptions NO_FOLD:F -- "$@")
  eval "$TMP"

  if [[ -z "$NO_FOLD" ]]; then
    echo -e "${yellow}$*${reset}" | fold -sw 82 >&2
  else
    echo -e "${yellow}$*${reset}"
  fi
}

echoerrandexit() {
  local TMP
  TMP=$(setSimpleOptions NO_FOLD:F -- "$@") || $(echo "Bad options: $*"; exit -10)
  eval "$TMP"

  local MSG="$1"
  local EXIT_CODE="${2:-10}"
  # TODO: consider providing 'passopts' method which coordites with 'setSimpleOptions' to recreate option string
  if [[ -n "$NO_FOLD" ]]; then
    echoerr --no-fold "$MSG"
  else
    echoerr "$MSG"
  fi
  exit $EXIT_CODE
}
list-add-item() {
  local LIST_VAR="${1}"; shift
  while (( $# > 0 )); do
    local ITEM
    ITEM="${1}"; shift
    # TODO: enforce no newlines in item

    if [[ -n "$ITEM" ]]; then
      if [[ -z "${!LIST_VAR:-}" ]]; then
        eval $LIST_VAR='"$ITEM"'
      else
        # echo $LIST_VAR='"${!LIST_VAR}"$'"'"'\n'"'"'"${ITEM}"'
        eval $LIST_VAR='"${!LIST_VAR}"$'"'"'\n'"'"'"${ITEM}"'
      fi
    fi
  done
}

list-add-uniq() {
  local LIST_VAR="${1}"; shift
  while (( $# > 0 )); do
    local ITEM
    ITEM="${1}"; shift
    # TODO: enforce no newlines in item
    if [[ -z $(list-get-index $LIST_VAR "$ITEM") ]]; then
      list-add-item $LIST_VAR "$ITEM"
    fi
  done
}

list-rm-item() {
  local LIST_VAR="${1}"; shift
  while (( $# > 0 )); do
    local ITEM NEW_ITEMS
    ITEM="${1}"; shift
    ITEM=${ITEM//\/\\/}
    ITEM=${ITEM//#/\\#}
    ITEM=${ITEM//./\\.}
    ITEM=${ITEM//[/\\[}
    # echo "ITEM: $ITEM" >&2
    NEW_ITEMS="$(echo "${!LIST_VAR}" | sed -e '\#^'$ITEM'$#d')"
    eval $LIST_VAR='"'"$NEW_ITEMS"'"'
  done
}

list-get-index() {
  local LIST_VAR="${1}"
  local TEST="${2}"

  local ITEM
  local INDEX=0
  while read -r ITEM; do
    if [[ "${ITEM}" == "${TEST}" ]]; then
      echo $INDEX
      return
    fi
    INDEX=$(($INDEX + 1))
  done <<< "${!LIST_VAR}"
}

list-get-item() {
  local LIST_VAR="${1}"
  local INDEX="${2}"

  local CURR_INDEX=0
  local ITEM
  while read -r ITEM; do
    if (( $CURR_INDEX == $INDEX )) ; then
      echo -n "${ITEM%\\n}"
      return
    fi
    CURR_INDEX=$(($CURR_INDEX + 1))
  done <<< "${!LIST_VAR}"
}

list-replace-by-string() {
  local LIST_VAR="${1}"
  local TEST_ITEM="${2}"
  local NEW_ITEM="${3}"

  local ITEM INDEX NEW_LIST
  INDEX=0
  for ITEM in ${!LIST_VAR}; do
    if [[ "$(list-get-item $LIST_VAR $INDEX)" == "$TEST_ITEM" ]]; then
      list-add-item NEW_LIST "$NEW_ITEM"
    else
      list-add-item NEW_LIST "$ITEM"
    fi
    INDEX=$(($INDEX + 1))
  done
  eval $LIST_VAR='"'"$NEW_LIST"'"'
}

list-from-csv() {
  local LIST_VAR="${1}"
  local CSV="${2}"

  while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
      list-add-item "$LIST_VAR" "$i"
    done
  done <<< "$CSV"
}

get-answer() {
  eval "$(setSimpleOptions MULTI_LINE -- "$@")"
  local PROMPT="$1"
  local VAR="$2" # TODO: if name is 'VAR', then this breaks...
  local DEFAULT="${3:-}"

  if [[ -n "${DEFAULT}" ]]; then
    PROMPT="${PROMPT} (${DEFAULT}) "
  fi

  if [[ -z "$MULTI_LINE" ]]; then
    read -r -p "$PROMPT" $VAR
    if [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
      # MacOS dosen't support 'declare -g' :(
      eval "${VAR}='$(echo "$DEFAULT" | sed "s/'/'\"'\"'/g")'"
    fi
  else
    local LINE
    echo "${green_bu}End multi-line input with single '.'${reset}"
    echo "$PROMPT"
    unset $VAR
    while true; do
      read -r LINE
      [[ "$LINE" == '.' ]] && break
      if [[ -z "$LINE" ]] && [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
        eval "${VAR}='$(echo "$DEFAULT" | sed "s/'/'\"'\"'/g")'"
        break
      fi
      list-add-item $VAR "$LINE"
    done
  fi
}

require-answer() {
  eval "$(setSimpleOptions FORCE MULTI_LINE -- "$@")"
  local PROMPT="$1"
  local VAR="$2" # TODO: if name is 'VAR', then this breaks...
  local DEFAULT="${3:-}"

  if [[ -n "$FORCE" ]] && [[ -z "$DEFAULT" ]]; then
    DEFAULT="${!VAR}"
  fi

  # TODO: support 'pass-through' options in 'setSimpleOptions'
  local OPTS=''
  if [[ -n "$MULTI_LINE" ]]; then
    OPTS="${OPTS}--multi-line "
  fi
  while [[ -z ${!VAR:-} ]] || [[ -n "$FORCE" ]]; do
    get-answer ${OPTS} "$PROMPT" "$VAR" "$DEFAULT" # can't use "$@" because default may be overriden
    if [[ -z ${!VAR:-} ]]; then
      echoerr "A response is required."
    else
      FORCE='' # if forced into loop, then we un-force when we get an answer
    fi
  done
}
function real_path {
  local FILE="${1:-}"
  if [[ -z "$FILE" ]]; then
    echo "'real_path' requires target file specified." >&2
    return 1
  elif [[ ! -e "$FILE" ]]; then
    echo "Target file '$FILE' does not exist." >&2
    return 1
  fi

  function trim_slash {
    # sed adds a newline ()
    printf "$1" | sed 's/\/$//' | tr -d '\n'
  }
  # [[ -h /foo/link_dir ]] works, but [[ -h /foo/link_dir/ ]] does not!
  FILE=`trim_slash "$FILE"`

  if [[ -h "$FILE" ]]; then
    function resolve_link {
      local POSSIBLE_REL_LINK="${1:-}"
      local APPEND="${2:-}"
      if [[ "$POSSIBLE_REL_LINK" == /* ]]; then
        # for some reason 'echo -n' was echoing the '-n' when this was used
        # included in the catalyst-scripts. Not sure why, and don't know how
        # to test, but 'printf' does what we need.
        printf "$POSSIBLE_REL_LINK${APPEND}"
      else
        # Now we go into the dir containg the link and then navigate the possibly
        # relative link to the real dir. The subshell preserves the caller's PWD.
        (cd "$(dirname "$FILE")"
        cd "$POSSIBLE_REL_LINK"
        printf "${PWD}${APPEND}")
      fi
    }

    if [[ ! -d "$FILE" ]]; then
      # we need to get the real path to the real file
      local REAL_FILE_LINK_PATH="$(readlink "$FILE")"
      resolve_link "$(dirname "$REAL_FILE_LINK_PATH")" "/$(basename "$REAL_FILE_LINK_PATH")"
    else
      # we need to get the real path of the linked directory
      resolve_link "$(readlink "$FILE")"
    fi
  else
    printf "$FILE"
  fi
}
# You have two options when passing in the options to any of the select
# functions. You can separate each item by space and use quotes, such as:
#
# selectOneCancel RESULT option1 "option with space"
#
# Or you can embed newlines in the option string, such as:
#
# OPTIONS="option1
# option with space"
# selectOneCancel RESULT "$OPTIONS"
#
# The second method can be combined with 'list-add-item' to safely build up
# options (which may contain spaces) dynamically. The two methods cannot be
# combined and the presece of a newline in any option will cause the input to
# interepretted by the second method.


_commonSelectHelper() {
  # TODO: the '_' is to avoid collision, but is a bit hacky; in particular, some callers were using 'local OPTIONS'
  # TODO TODO: when declared local here, it should not change the caller... I tihnk the original analysis was flawed.
  local _SELECT_LIMIT="$1"; shift
  local _VAR_NAME="$1"; shift
  local _PRE_OPTS="$1"; shift
  local _POST_OPTS="$1"; shift
  local _OPTIONS_LIST_NAME="$1"; shift
  local _SELECTION
  local _QUIT='false'

  local _OPTIONS="${!_OPTIONS_LIST_NAME:-}"
  # TODO: would be nice to have a 'prepend-' or 'unshift-' items.
  if [[ -n "$_PRE_OPTS" ]]; then
    _OPTIONS="$_PRE_OPTS"$'\n'"$_OPTIONS"
  fi
  list-add-item _OPTIONS $_POST_OPTS

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
    IFS=$'\n'
    echo >&2
    select _SELECTION in $_OPTIONS; do
      case "$_SELECTION" in
        '<cancel>')
          return;;
        '<done>')
          _QUIT='true';;
        '<other>'|'<new>')
          _SELECTION=''
          require-answer "$PS3" _SELECTION "$_DEFAULT"
          updateVar;;
        '<any>')
          eval $_VAR_NAME='any'
          _QUIT='true';;
        '<all>')
          eval $_VAR_NAME='"$_ENUM_OPTIONS"'
          _QUIT='true';;
        '<default>')
          eval "${_VAR_NAME}=\"${SELECT_DEFAULT}\""
          _QUIT='true';;
        *)
          updateVar;;
      esac

      # after first selection, 'default' is nullified
      SELECT_DEFAULT=''
      _OPTIONS=$(echo "$_OPTIONS" | sed -Ee 's/(^|\n)<default>(\n|$)//' | tr -d '*')

      if [[ -n "$_SELECT_LIMIT" ]] && (( $_SELECT_LIMIT >= $_SELECTED_COUNT )); then
        _QUIT='true'
      fi
      # Our user feedback should go to stderr just like the user prompts from select
      if [[ "$_QUIT" != 'true' ]]; then
        echo "Current selections: ${!_VAR_NAME}" >&2
      else
        echo -e "Final selections: ${!_VAR_NAME}" >&2
      fi
      # remove the just selected option
      _OPTIONS=${_OPTIONS/$_SELECTION/}
      _OPTIONS=${_OPTIONS//$'\n'$'\n'/$'\n'}

      # if we only have the default options left, then we're done
      local EMPTY_TEST # sed inherently matches lines, not strings
      EMPTY_TEST=`echo "$_OPTIONS" | sed -Ee 's/^(<done>)?\n?(<cancel>)?\n?(<all>)?\n?(<any>)?\n?(<default>)?\n?(<other>)?\n?(<new>)?$//'`

      if [[ -z "$EMPTY_TEST" ]]; then
        _QUIT='true'
      fi
      break
    done # end select
    IFS="$OLDIFS"
  done
}

selectOneCancel() {
  _commonSelectHelper 1 "$1" '<cancel>' '' "$2"
}

selectOneCancelDefault() {
  if [[ -z "$SELECT_DEFAULT" ]]; then
    echowarn "Requested 'default' select, but no default provided. Falling back to non-default selection."
    selectOneCancel "$1" "$2"
  else
    _commonSelectHelper 1 "$1" '<cancel>' '<default>' "$2"
  fi
}

selectOneCancelOther() {
  _commonSelectHelper 1 "$1" '<cancel>' '<other>' "$2"
}

selectOneCancelNew() {
  _commonSelectHelper 1 "$1" '<cancel>' '<new>' "$2"
}

selectDoneCancel() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '' "$2"
}

selectDoneCancelOther() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<other>' "$2"
}

selectDoneCancelNew() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<new>' "$2"
}

selectDoneCancelAllOther() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<all>'$'\n''<other>' "$2"
}

selectDoneCancelAllNew() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<all>'$'\n''<new>' "$2"
}

selectDoneCancelAnyOther() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<any>'$'\n''<other>' "$2"
}

selectDoneCancelAnyNew() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<any>'$'\n''<new>' "$2"
}

selectDoneCancelOtherDefault() {
  if [[ -z "$SELECT_DEFAULT" ]]; then
    echowarn "Requested 'default' select, but no default provided. Falling back to non-default selection."
    selectDoneCancelOther "$1" "$2"
  else
    _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<other>'$'\n''<default>' "$2"
  fi
}

selectDoneCancelNewDefault() {
  if [[ -z "$SELECT_DEFAULT" ]]; then
    echowarn "Requested 'default' select, but no default provided. Falling back to non-default selection."
    selectDoneCancelOther "$1" "$2"
  else
    _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<new>'$'\n''<default>' "$2"
  fi
}

selectDoneCancelAll() {
  _commonSelectHelper '' "$1" '<done>'$'\n''<cancel>' '<all>' "$2"
}
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
    echo -n "liq $1 "
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
    || echoerrandexit "Run 'liq project init' from project root." 1
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

requireCleanRepo() {
  local _IP="$1"
  # TODO: the '_WORK_BRANCH' here seem to be more of a check than a command to check that branch.
  local _WORK_BRANCH="${2:-}"

  cd "${LIQ_PLAYGROUND}/$(orgsCurrentOrg --require)/${_IP}"
  ( test -n "$_WORK_BRANCH" \
      && git branch | grep -qE "^\* ${_WORK_BRANCH}" ) \
    || git diff-index --quiet HEAD -- \
    || echoerrandexit "Cannot perform action '${ACTION}'. '${_IP}' has uncommitted changes. Try:\nliq work save"
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
# Global constants.
LIQ_DB="${HOME}/.liquid-development"
LIQ_SETTINGS="${LIQ_DB}/settings.sh"
LIQ_ENV_DB="${LIQ_DB}/environments"
LIQ_ORG_DB="${LIQ_DB}/orgs"
LIQ_WORK_DB="${LIQ_DB}/work"
LIQ_ENV_LOGS="${LIQ_DB}/logs"

# defined in $CATALYST_SETTING; during load in dispatch.sh
LIQ_PLAYGROUND=''

_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='

# Global variables.
CURR_ORG_DIR="${LIQ_ORG_DB}/curr_org"
CURR_ENV_FILE='' # set by 'requireEnvironment'
CURR_ENV='' # set by 'requireEnvironment'
# 'requireEnvironment' calls 'requirePackage'
PACKAGE='' # set by 'requirePackage'
PACKAGE_NAME='' # set by 'requirePackage'
PACKAGE_FILE='' # set by 'requirePackage', 'requireNpmPackage'

BASE_DIR=''
WORKSPACE_DIR=''

COMPONENT=''
ACTION=''

INVOLVED_PROJECTS='' # defined in the $LIQ_WORK_DB files

# Configurable globals.
ORIGIN_URL='' # can be set externally to avoid interactive questions on 'project init'

STD_ENV_PURPOSES=dev$'\n'test$'\n'pre-production$'\n'production
STD_IFACE_CLASSES=http$'\n'html$'\n'rest$'\n'sql
STD_PLATFORM_TYPES=local$'\n'gcp$'\n'aws
set -o errtrace # inherits trap on ERR in function and subshell

trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
# trap 'trapexit $? $LINENO' EXIT

function trapexit() {
  echo "$(date) $(hostname) $0: EXIT on line $2 (exit status $1)"
}

function traperror () {
    local err=$1 # error status
    local line=$2 # LINENO
    local linecallfunc=$3
    local command="$4"
    local funcstack="$5"

    # for a log use
    # $(date) $(hostname) $0: ERROR '$command' failed at line $line - exited with status: $err'
    # for dev
    echo "${red}ERROR '$command' failed at line $line - exited with status: $err${reset}" >&2

    if [ "$funcstack" != "::" ]; then
      # if generating logs directly, the following is useful:
      # echo -n "$(date) $(hostname) $0: DEBUG Error in ${funcstack} "
      echo "$0: DEBUG Error in ${funcstack} "
      if [ "$linecallfunc" != "" ]; then
        echo "called at line $linecallfunc"
      else
        echo
      fi
    fi
    # echo "'$command' failed at line $line - exited with status: $err" | mail -s "ERROR: $0 on $(hostname) at $(date)" xxx@xxx.com
}

function log() {
    local msg=$1
    now=$(date)
    i=${#FUNCNAME[@]}
    lineno=${BASH_LINENO[$i-2]}
    file=${BASH_SOURCE[$i-1]}
    echo "${now} $(hostname) $0:${lineno} ${msg}"
}
CATALYST_COMMAND_GROUPS=(data environments meta orgs packages project provided-services required-services services work)

help() {
  local TMP
  TMP=$(setSimpleOptions SUMMARY_ONLY -- "$@") \
    || ( help-runtime-services; echoerrandexit "Bad options." )
  eval "$TMP"

  local GROUP="${1:-}"
  local ACTION="${2:-}"

  if (( $# == 0 )); then
    cat <<EOF
Usage:
  liq <resource/group> <action> [...options...] [...selectors...]
  liq ${cyan_u}help${reset} [<group or resource> [<action>]
EOF

    local GROUP
    for GROUP in ${CATALYST_COMMAND_GROUPS[@]}; do
      echo
      help-${GROUP}
    done

    if [[ -z "$SUMMARY_ONLY" ]]; then
      echo
      helpHelperAlphaPackagesNote
    fi
  elif (( $# == 1 )); then
    if type -t help-${GROUP} | grep -q 'function'; then
      help-${GROUP} "liq "
    else
      exitUnknownGroup
    fi
  elif (( $# == 2 )); then
    if type -t help-${GROUP}-${ACTION} | grep -q 'function'; then
      help-${GROUP}-${ACTION} "liq ${GROUP} "
    else
      exitUnknownAction
    fi
  else
    echo "Usage:"
    echo "liq ${cyan_u}help${reset} [<group or resource> [<action>]"
    echoerrandexit "To many arguments in help."
  fi
}

helperHandler() {
  local PREFIX="$1"; shift
  if [[ -n "$PREFIX" ]]; then
    local HELPER
    for HELPER in "$@"; do
      echo
      $HELPER
    done
  fi
}

helpHelperAlphaPackagesNote() {
cat <<EOF
${red_b}Alpha note:${reset} There is currently no support for multiple packages in a single
repository and the 'package.json' file is assumed to be in the project root.
EOF
}

handleSummary() {
  local SUMMARY="${1}"; shift

  if [[ -n "${SUMMARY_ONLY:-}" ]]; then
    echo "$SUMMARY"
    return 0
  else
    return 1
  fi
}
function dataSQLCheckRunning() {
  local TMP
  TMP=$(setSimpleOptions NO_CHECK -- "$@") \
    || ( help-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"
  if [[ -z "$NO_CHECK" ]] && ! services-list --exit-on-stopped -q sql; then
    services-start sql
  fi

  echo "$@"
}

function dataSqlGetSqlVariant() {
  echo "${CURR_ENV_SERVICES[@]:-}" | sed -Ee 's/.*(^| *)(sql(-[^:]+)?).*/\2/'
}

data-build-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  echo -n "Creating schema; "
  source "${CURR_ENV_FILE}"
  local SQL_VARIANT=$(dataSqlGetSqlVariant)
  local SCHEMA_FILES SCHEMA_FILE_COUNT
  findDataFiles SCHEMA_FILES SCHEMA_FILE_COUNT "$SQL_VARIANT" "schema"
  echo "Loading $SCHEMA_FILE_COUNT schema files..."
  cat $SCHEMA_FILES | services-connect sql
  echo "Memorializing schema definations..."
  local SCHEMA_HASH=$(cat $SCHEMA_FILES | shasum -a 256 | sed -Ee 's/ *- *$//')
  local SCHEMA_VER_SPEC=()
  local PACKAGE_ROOT
  for PACKAGE_ROOT in $SCHEMA_FILES; do
    # TODO: this breaks if 'data' appears twice in the path. We want a reluctant match, but sed doesn't support it. I guess flip to Perl?
    PACKAGE_ROOT=$(echo "$PACKAGE_ROOT" | sed -Ee 's|/data/.+||')
    local PACK_DEF=
    PACK_DEF=$(cat "${PACKAGE_ROOT}/package.json")
    local PACK_NAME=
    PACK_NAME=$(echo "$PACK_DEF" | jq --raw-output '.name' | tr -d "'")
    if ! echo "${SCHEMA_VER_SPEC[@]:-}" | grep -q "$PACK_NAME"; then
      local PACK_VER=$(echo "$PACK_DEF" | jq --raw-output '.version' | tr -d "'")
      SCHEMA_VER_SPEC+=("${PACK_NAME}:${PACK_VER}")
    fi
  done
  SCHEMA_VER_SPEC=$(echo "${SCHEMA_VER_SPEC[@]}" | sort)
  echo "INSERT INTO catalystdb (schema_hash, version_spec) VALUES('$SCHEMA_HASH', '${SCHEMA_VER_SPEC[@]}')" | services-connect sql
}

data-dump-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  local DATE_FMT='%Y-%m-%d %H:%M:%S %z'
  local MAIN=$(cat <<'EOF'
    if runServiceCtrlScript --no-env $SERV_SCRIPT dump-check 2> /dev/null; then
      if [[ -n "$SERV_SCRIPTS_COOKIE" ]]; then
        echoerrandexit "Multilpe dump providers found; try specifying service process."
      fi
      SERV_SCRIPTS_COOKIE='found'
      if [[ -n "$OUT_FILE" ]]; then
        mkdir -p "$(dirname "${OUT_FILE}")"
        echo "-- start $(date +'%Y-%m-%d %H:%M:%S %z')" > "${OUT_FILE}"
        runServiceCtrlScript $SERV_SCRIPT dump >> "${OUT_FILE}"
        echo "-- end $(date +'%Y-%m-%d %H:%M:%S %z')" >> "${OUT_FILE}"
      else
        echo "-- start $(date +"${DATE_FMT}")"
        runServiceCtrlScript $SERV_SCRIPT dump
        echo "-- end $(date +"${DATE_FMT}")"
      fi
    fi
EOF
)
  # After we've tried to connect with each process, check if anything worked
  local ALWAYS_RUN=$(cat <<'EOF'
    if (( $SERV_SCRIPT_COUNT == ( $SERV_SCRIPT_INDEX + 1 ) )) && [[ -z "$SERV_SCRIPTS_COOKIE" ]]; then
      echoerrandexit "${PROCESS_NAME}' does not support data dumps."
    fi
EOF
)

  runtimeServiceRunner "$MAIN" "$ALWAYS_RUN" sql
}

data-load-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  if [[ ! -d "${BASE_DIR}/data/sql/${SET_NAME}" ]]; then
    echoerrandexit "No such set '$SET_NAME' found."
  fi

  local DATA_FILES DATA_FILES_COUNT
  findDataFiles DATA_FILES DATA_FILES_COUNT "sql" "$SET_NAME"
  echo "Loading ${DATA_FILES_COUNT} data files..."
  cat $DATA_FILES | services-connect sql
}

data-rebuild-sql() {
  dataSQLCheckRunning "$@" > /dev/null
  # TODO: break out the file search and do it first to avoid dropping when the build is sure to fail.
  data-reset-sql --no-check
  data-build-sql --no-check
}

data-reset-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  echo "Dropping..."
  # https://stackoverflow.com/a/36023359/929494
  cat <<'EOF' | services-connect sql > /dev/null
DO $$ DECLARE
    r RECORD;
BEGIN
    -- if the schema you operate on is not "current", you will want to
    -- replace current_schema() in query with 'schematodeletetablesfrom'
    -- *and* update the generate 'DROP...' accordingly.
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
EOF
  # for MySQL
  # relative to dist
  # colorerr "cat '$(dirname $(real_path ${BASH_SOURCE[0]}))/../tools/data/drop_all.sql' | services-connect sql"
}

data-test-sql() {
  echo "Checking for SQL unit test files..."
  source "${CURR_ENV_FILE}"
  local SQL_VARIANT=$(dataSqlGetSqlVariant)
  local TEST_FILES TEST_FILE_COUNT
  findDataFiles TEST_FILES TEST_FILE_COUNT "$SQL_VARIANT" "test"
  if (( $TEST_FILE_COUNT > 0 )); then
    echo "Found $TEST_FILE_COUNT unit test files."
    if [[ -z "$SKIP_REBUILD" ]]; then
      data-rebuild-sql
    else
      echo "Skipping RDB rebuild."
    fi
    dataSQLCheckRunning "$@" > /dev/null
    echo "Starting tests..."
    cat $TEST_FILES | services-connect sql
    echo "Testing complete!"
  else
    echo "No SQL unit tests found."
  fi
}

requirements-data() {
  requireEnvironment
}

help-data-build() {
  cat <<EOF | indent
$(helpActionPrefix data)${underline}build${reset} [<iface>...]: Loads the project schema into all or
each named data service.
EOF
}

data-build() {
  local MAIN='data-build-${IFACE}'
  dataRunner "$@"
}

data-dump() {
  local TMP
  TMP=$(setSimpleOptions OUTPUT_SET_NAME= FORCE -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  local MAIN=$(cat <<'EOF'
    local OUT_FILE
    if [[ -n "${OUTPUT_SET_NAME}" ]]; then
      OUT_FILE="${BASE_DIR}/data/${IFACE}/${OUTPUT_SET_NAME}/all.sql"
      if [[ -d "$(dirname "${OUT_FILE}")" ]] && [[ -z "$FORCE" ]]; then
        if [[ -f "$OUT_FILE" ]]; then
          function clearPrev() { rm "$OUT_FILE"; }
          function cancelDump() { echo "Bailing out..."; exit 0; }
          yesno "Found existing dump for '$OUTPUT_SET_NAME'. Would you like to replace? (y\N) " \
            N \
            clearPrev \
            cancelDump
        else
          echoerrandexit "It appears there is an existing, manually created '${OUTPUT_SET_NAME}' data set. You must remove it manually to re-use that name."
        fi
      fi
    fi
    data-dump-${IFACE}
EOF
)
  dataRunner "$@"
}

data-load() {
  if (( $# != 1 )); then
    contextHelp
    echoerrandexit "Must specify exactly one data set name."
  fi

  local MAIN='data-load-${IFACE}'
  # notice 'load' is a little different
  local SET_NAME="${1}"
  dataRunner
}

data-reset() {
  local MAIN='data-reset-${IFACE}'
  dataRunner "$@"
}

data-rebuild() {
  local MAIN='data-rebuild-${IFACE}'
  dataRunner "$@"
}

data-test() {
  local TMP
  TMP=$(setSimpleOptions SKIP_REBUILD -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  local MAIN='data-test-${IFACE}'
  dataRunner "$@"
}

dataRunner() {
  local SERVICE_STATUSES
  SERVICE_STATUSES=`services-list -sp`

  local IFACES="$@"
  if (( $# == 0 )); then
    IFACES=$(echo "$PACKAGE" | jq --raw-output '.catalyst.requires | .[] | .iface | capture("(?<iface>sql)") | .iface' | tr -d '"')
  fi

  local IFACE
  for IFACE in $IFACES; do
    # Check all the parameters are good.
    if [[ "$IFACE" == *'-'* ]]; then
      help-data "liq "
      echoerrandexit "The 'data' commands work with primary interfaces. See help above"
    else
      local SERV
      SERV="$(echo "$SERVICE_STATUSES" | grep -E "^${IFACE}(.[^: ]+)?:")" || \
        echoerrandexit "Could not find a service to handle interface class '${IFACE}'. Check package configuration and command typos."
      local SERV_SCRIPT NOT_RUNNING SERV_STATUS
      local SOME_RUNNING=false
      while read SERV_STATUS; do
        SERV_SCRIPT="$(echo "${SERV_STATUS}" | cut -d':' -f1)"
        echo "${SERV_STATUS}" | cut -d':' -f2 | grep -q 'running' && SOME_RUNNING=true || \
          NOT_RUNNING="${NOT_RUNNING} ${SERV_SCRIPT}"
      done <<< "${SERV}"
      if [[ -n "${NOT_RUNNING}" ]]; then
        if [[ "$SOME_RUNNING" == true ]]; then
          echoerrandexit "Some necessary processes providing the '${IFACE}' service are not running. Try:\nliq services start${NOT_RUNNING}"
        else
          echoerrandexit "The '${IFACE}' service is not available. Try:\nliq services start ${IFACE}"
        fi
      fi
    fi
  done

  if [[ -z "$IFACES" ]]; then
    source "${CURR_ENV_FILE}"
    IFACES=$(echo ${CURR_ENV_SERVICES[@]:-} | tr " " "\n" | sed -Ee 's/^(sql).+/\1/')
  fi

  for IFACE in $IFACES; do
    eval "$MAIN"
  done
}
findDataFiles() {
  local _FILES_VAR="$1"
  local _COUNT_VAR="$2"
  local DATA_IFACE="$3"
  local FILE_TYPE="$4"
  local _FILES

  local CAT_PACKAGE FIND_RESULTS
  # search Catalyst packages in dependencies (i.e., ./node_modules)
  for CAT_PACKAGE in `getCatPackagePaths`; do
    if [[ -d "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
      FIND_RESULTS="$(find "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" -type f)"
      list-add-item _FILES "$FIND_RESULTS"
    fi
  done
  # search our own package
  if [[ -d "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
    FIND_RESULTS="$(find "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" -type f)"
    list-add-item _FILES "$FIND_RESULTS"
  fi

  if [[ -z "$_FILES" ]]; then
    echoerrandexit "\nDid not find any ${FILE_TYPE} files for '${DATA_IFACE}'."
  else
    # TODO: should verify all the files have the required naming convention.
    # sort the files so dependency orders are respected
    # 1) awk will pull off the last 'field'=='the file name', so
    # 2) sort will then sort against the filename, and
    # 3) sed removes the leading filename getting us back to a list of sorted files.
    _FILES=`echo "${_FILES}" | awk -F/ '{ print $NF, $0 }' | sort -n -k1 | sed -Ee 's/[^ ]+ //'`
    eval "$_FILES_VAR=\"${_FILES}\""
  fi

  eval "$_COUNT_VAR"=$(echo "$_FILES" | wc -l | tr -d ' ')
}
help-data() {
  local PREFIX="${1:-}"
  local INDENT=1

  handleSummary "${PREFIX}${cyan_u}data${reset} <action>: Manges data sets and schemas." || cat <<EOF
${PREFIX}${cyan_u}data${reset} <action>:
$(help-data-build)
  ${underline}reset${reset} [<iface>...]: Resets all or each named data service, clearing all schema
    definitions.
  ${underline}clear${reset} [<iface>...]: Clears all data from all or each named data service.
  ${underline}rebuild${reset}: Effectively resets and builds all or each named data service.
  ${underline}dump${reset} [--output-set-name|-o <set name>] <iface>: Dumps the data from all or the
    named interface. If '--output-set-name' is speciifed, will put data in
    './data/<iface>/<set name>/' or output to stdout if no output is specified.
    This is a 'data only' dump.
  ${underline}load${reset} <set name>: Loads the named data set into the project data services. Any
    existing data will be cleared.

The data commands deal exclusively with primary interface classes (${underline}iface${reset}). Thus even
if the current package requires 'sql-mysql', the data commands will work and
require an 'iface' designation of 'sql'.

${red_b}ALPHA NOTE:${reset} The only currently supported interface class is 'sql'.
EOF
}

requirements-environments() {
  requireCatalystfile
  requirePackage
}

function environmentsGatherEnvironmentSettings() {
  # Expects caller to declare:
  # local ENV_NAME REQ_PARAMS
  # CURR_ENV_SERVICES as global
  environmentsCheckCloudSDK

  ENV_NAME="${1:-}"

  if [ -z "${ENV_NAME}" ]; then
    require-answer 'Local environment name: ' ENV_NAME
  fi

  if [[ -z "${CURR_ENV_PURPOSE:-}" ]]; then
    PS3="Select purpose: "
    selectOneCancelOther CURR_ENV_PURPOSE STD_ENV_PURPOSES
  fi

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  for REQ_SERV_IFACE in $REQ_SERV_IFACES; do
    # select the service provider
    local FQN_SERVICE
    environmentsFindProvidersFor "$REQ_SERV_IFACE" FQN_SERVICE
    CURR_ENV_SERVICES+=("$FQN_SERVICE")

    # define required params
    local SERV_REQ_PARAMS
    SERV_REQ_PARAMS=$(getRequiredParameters "$FQN_SERVICE")
    local ADD_REQ_PARAMS=$((echo "$PACKAGE" | jq -e --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"params-req\" | @sh" 2> /dev/null || echo '') | tr -d "'")
    if [[ -n "$ADD_REQ_PARAMS" ]]; then
      list-add-item SERV_REQ_PARAMS "$ADD_REQ_PARAMS"
    fi

    local REQ_PARAM
    for REQ_PARAM in $SERV_REQ_PARAMS; do
      local DEFAULT_VAL
      environmentsGetDefaultFromScripts DEFAULT_VAL "$FQN_SERVICE" "$REQ_PARAM"
      if [[ -n "$DEFAULT_VAL" ]]; then
        eval "${REQ_PARAM}_DEFAULT_VAL='$DEFAULT_VAL'"
      fi
    done

    # and set configuration constants
    for REQ_PARAM in $(echo $PACKAGE | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\" | keys | @sh" | tr -d "'"); do
      local CONFIG_VAL=$(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\".\"$REQ_PARAM\" | @sh" | tr -d "'")
      eval "$REQ_PARAM='$CONFIG_VAL'"
    done
    list-add-item REQ_PARAMS "$SERV_REQ_PARAMS"
  done
}

function environmentsAskIfSelect() {
  function selectNewEnv() {
    environments-select "${ENV_NAME}"
  }

  yesno "Would you like to select the newly added '${ENV_NAME}'? (Y\n) " \
    Y \
    selectNewEnv \
    || true
}
doEnvironmentList() {
  eval "$(setSimpleOptions LIST_ONLY -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ ! -d "${LIQ_ENV_DB}/${PACKAGE_NAME}" ]]; then
    return
  fi
  local CURR_ENV
  if [[ -L "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ]]; then
    CURR_ENV=`readlink "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" | xargs basename`
  fi
  local ENV
  for ENV in `find "${LIQ_ENV_DB}/${PACKAGE_NAME}" -type f -not -name "*~" -exec basename '{}' \; | sort`; do
    ( ( test -z "$LIST_ONLY" && test "$ENV" == "${CURR_ENV:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ENV"
  done
}

environmentsServiceDescription() {
  local VAR_NAME="$1"
  local SERVICE="$2"
  local PACKAGE_NAME="$3"

  eval "$VAR_NAME='${SERVICE} from ${PACKAGE_NAME}'"
}

environmentsFigureFqnService() {
  local VAR_NAME="$1"
  local REQ_SERVICE="$2"
  local SERVICE_DESC="$3"

  local SELECTED_PROVIDER=$(echo "$SERVICE_DESC" | sed -E -e 's/[^ ]+ from (.+)/\1/')
  local SELECTED_SERVICE=$(echo "$SERVICE_DESC" | sed -E -e 's/ from .+//')

  eval "$VAR_NAME='${REQ_SERVICE}:${SELECTED_PROVIDER}:${SELECTED_SERVICE}'"
}

environmentsFindProvidersFor() {
  local REQ_SERVICE="${1}"
  # TODO: put var name first for consistency
  local RESULT_VAR_NAME="${2}"
  local DEFAULT="${3:-}"

  local CAT_PACKAGE_PATHS=`getCatPackagePaths`
  local SERVICES SERVICE_PACKAGES PROVIDER_OPTIONS CAT_PACKAGE_PATH
  for CAT_PACKAGE_PATH in "${BASE_DIR}" $CAT_PACKAGE_PATHS; do
    local NPM_PACKAGE=$(cat "${CAT_PACKAGE_PATH}/package.json")
    local PACKAGE_NAME=$(echo "$NPM_PACKAGE" | jq --raw-output ".name")
    local SERVICE
    for SERVICE in $((echo "$NPM_PACKAGE" | jq --raw-output ".catalyst.provides | .[] | select((.\"interface-classes\" | .[] | select(. == \"$REQ_SERVICE\")) | length > 0) | .name | @sh" 2>/dev/null || echo '') | tr -d "'"); do
      SERVICES=$((test -n "$SERVICE" && echo "$SERVICES '$SERVICE'") || echo "'$SERVICE'")
      SERVICE_PACKAGES=$((test -n "$SERVICE_PACKAGES" && echo "$SERVICE_PACKAGES '$PACKAGE_NAME'") || echo "'$PACKAGE_NAME'")
      local SERV_DESC
      environmentsServiceDescription SERV_DESC "$SERVICE" "$PACKAGE_NAME"
      list-add-item PROVIDER_OPTIONS "$SERV_DESC"
    done
  done

  if test -z "$SERVICES"; then
    echoerrandexit "Could not find any providers for '$REQ_SERVICE'."
  fi

  PS3="Select provider for required service '$REQ_SERVICE': "
  local PROVIDER
  if [[ -z "${SELECT_DEFAULT:-}" ]]; then
    # TODO: is there a better way to preserve the word boundries? We can use the '${ARRAY[@]@Q}' construct in bash 4.4
    # We 'eval' because 'PROVIDER_OPTIONS' may have quoted words, but if we just
    # expanded it directly, we could options like:
    # 1) 'foo
    # 2) bar'
    # 3) 'baz'
    # instead of:
    # 1) foo bar
    # 2) baz
    eval "selectOneCancel PROVIDER PROVIDER_OPTIONS"
  else
    eval "selectOneCancelDefault PROVIDER PROVIDER_OPTIONS"
  fi

  environmentsFigureFqnService "$RESULT_VAR_NAME" "$REQ_SERVICE" "$PROVIDER"
}

environmentsGetDefaultFromScripts() {
  local VAR_NAME="$1"
  local FQ_SERVICE="$2"
  local REQ_PARAM="$3"

  local SERV_SCRIPT
  for SERV_SCRIPT in `getCtrlScripts "$FQ_SERVICE"`; do
    DEFAULT_VAL=`runServiceCtrlScript --no-env "$SERV_SCRIPT" param-default "$CURR_ENV_PURPOSE" "$REQ_PARAM"` \
      || echoerrandexit "Service script '$SERV_SCRIPT' does not support 'param-default'. Perhaps the package is out of date?"
    if [[ -n "$DEFAULT_VAL" ]]; then
      eval "$VAR_NAME='$DEFAULT_VAL'"
      break
    fi
  done
}
updateEnvironment() {
  # expects caller to define globals, either initilized or read from env file.
  # CURR_ENV_SERVICES CURR_ENV_PURPOSE
  local ENV_PATH="$LIQ_ENV_DB/${PACKAGE_NAME}/${ENV_NAME}"
  mkdir -p "`dirname "$ENV_PATH"`"

  # TODO: use '${CURR_ENV_SERVICES[@]@Q}' once upgraded to bash 4.4
  cat <<EOF > "$ENV_PATH"
CURR_ENV_SERVICES=(${CURR_ENV_SERVICES[@]:-})
CURR_ENV_PURPOSE='${CURR_ENV_PURPOSE}'
EOF

  local SERV_KEY REQ_PARAM
  # TODO: again, @Q when available
  for SERV_KEY in ${CURR_ENV_SERVICES[@]:-}; do
    for REQ_PARAM in $(getRequiredParameters "$SERV_KEY"); do
      if [[ -z "${!REQ_PARAM:-}" ]]; then
        echoerrandexit "Did not find definition for required parameter '${REQ_PARAM}'."
      fi
      cat <<EOF >> "$ENV_PATH"
$REQ_PARAM='${!REQ_PARAM}'
EOF
    done
  done

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  for REQ_SERV_IFACE in $REQ_SERV_IFACES; do
    for REQ_PARAM in $(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"params-req\" | @sh" | tr -d "'"); do
      if [[ -z "${!REQ_PARAM:-}" ]]; then
        echoerrandexit "Did not find definition for required parameter '${REQ_PARAM}'."
      fi
      cat <<EOF >> "$ENV_PATH"
$REQ_PARAM='${!REQ_PARAM}'
EOF
    done

    for REQ_PARAM in $(getConfigConstants "$REQ_SERV_IFACE"); do
      local CONFIG_VAL=$(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\".\"$REQ_PARAM\" | @sh" | tr -d "'")
      cat <<EOF >> "$ENV_PATH"
$REQ_PARAM='$CONFIG_VAL'
EOF
    done
  done
}

updateEnvParam() {
  local KEY="$1"
  local VALUE="$2"

  local VAR_NAME=${KEY//:/_}
  VAR_NAME=${VAR_NAME}// /_}
  VAR_NAME="CURR_ENV_${VAR_NAME^^}"

  declare "$VAR_NAME"="$VALUE"
}
function environmentsGcpIamCreateAccount() {
  local ACCT_NAME="${1}"
  environmentsGcpEnsureProjectId

  echo "Creating service account '${ACCT_NAME}...'"
  gcloud iam service-accounts create "$ACCT_NAME" --display-name="$ACCT_NAME" --format="value(email)" --project="$GCP_PROJECT_ID"\
    || echoerrandexit "Problem encountered while creating instance (see above). Check status via:\nhttps://console.cloud.google.com/"
}

function environmentsGcpIamCreateKeys() {
  local ACCT_ID="${1}"

  local CRED_FILE="$HOME/.catalyst/creds/${ACCT_ID}.json"
  if [[ ! -f "$CRED_FILE" ]]; then
    echo "Creating keys..."
    gcloud iam service-accounts keys create "$CRED_FILE" --iam-account "${ACCT_ID}" --project="${GCP_PROJECT_ID}" \
      || echoerrandexit "Problem encountered while creating credentials file for '${ACCT_ID}'.\nPlease generate file:\n$CRED_FILE"
  else
    echo "Existing credential key file found: ${CRED_FILE}"
  fi
}
function environmentsGet-GCP_ORGANIZATION() {
  local RESULT_VAR="${1}"

  local LINE NAMES IDS
  environmentsGoogleCloudOptions 'organizations' 'displayName' 'name'

  local ORG_NAME ORG_ID
  # TODO: should periodically check if create has been enbaled via the CLI
  echo "If you want to create a new organization, you must do this via the Cloud Console:"
  echo "https://console.cloud.google.com/"
  read -p "Hit <enter> to continue..."
  selectOneCancel ORG_NAME NAMES
  local SELECT_IDX=$(list-get-index NAMES "$ORG_NAME")
  ORG_ID=$(list-get-item IDS $SELECT_IDX)

  eval "$RESULT_VAR='$ORG_ID'"
}
function environmentsGcpProjectsBindPolicies() {
  local ACCT_ID="${1}"; shift
  if (( $# == 0 )); then
    echoerrandexit "Program error: no role names provided for policy."
  fi
  environmentsGcpEnsureProjectId

  while (( $# > 0 )); do
    local POLICY_NAME="$1"; shift

    echo -n "Checking if '${ACCT_ID}' has '${POLICY_NAME}'... "
    local GRANTED
    # I don't believe the test can be accomplished with just gcloud as of 2019-07-12
    GRANTED=$(gcloud projects get-iam-policy ${GCP_PROJECT_ID} --filter="bindings.members='serviceAccount:${ACCT_ID}'" --format=json --project="${GCP_PROJECT_ID}" \
                | jq ".[].bindings[] | select(.members[]==\"serviceAccount:${ACCT_ID}\") | select(.role==\"${POLICY_NAME}\")")
    if [[ -z "$GRANTED" ]]; then
      echo "no; granting..."
      gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${ACCT_ID}" --role="${POLICY_NAME}" \
        || echoerrandexit "Problem encountered while granting role '${POLICY_NAME}' to service account '$ACCT_ID'.\nPlease update the role manually."
    else
      echo "yes."
    fi
  done
}

function environmentsGet-GCP_PROJECT_ID() {
  local RESULT_VAR="$1"

  local NAMES IDS
  environmentsGoogleCloudOptions 'projects' 'name' 'projectId'

  local PROJ_NAME PROJ_ID

  function createNew() {
    PROJ_ID=$(gcpNameToId "$PROJ_NAME")
    local ORG_ID
    environmetsGet-GCP_ORGANIZATION ORG_ID

    gcloud projects create "$PROJ_ID" --name="$PROJ_NAME" --organization="$ORG_ID" \
      || echoerrandexit "Problem encountered while creating project (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No projects found. Please provide name: " PROJ_NAME
    createNew
  else
    PS3="Project name: "
    selectOneCancelNew PROJ_NAME NAMES
    local SELECT_IDX
    SELECT_IDX=$(list-get-index NAMES "$PROJ_NAME")
    if [[ -n "$SELECT_IDX" ]]; then
      PROJ_ID=$(list-get-item IDS $SELECT_IDX)
    else # it's a new project
      createNew
    fi
  fi

  eval "$RESULT_VAR='$PROJ_ID'"
}
function environmentsActivateAPI() {
  local SERVICE_NAME="${1}"

  echo -n "Checking API '${SERVICE_NAME}' status... "
  local STATUS
  STATUS="$(gcloud services list --available --project="${GCP_PROJECT_ID}" --filter="NAME=${SERVICE_NAME}" --format="value(state)")"
  echo "$STATUS"

  if [[ "$STATUS" == DISABLED ]]; then
    echo "Enabling..."
    gcloud services enable $SERVICE_NAME --project="${GCP_PROJECT_ID}"
  fi
}
# https://github.com/Liquid-Labs/liq-cli/issues/37
function environmentsReducePurpose() {
  case "$CURR_ENV_PURPOSE" in
    *dev*)
      echo dev;;
    *test*)
      echo test;;
    *production*)
      echo production;;
    *)
      echo other;;
  esac
}

function environmentsGet-CLOUDSQL_INSTANCE_NAME() {
  local RESULT_VAR="${1}"

  # for SQL instances, the name is the ID, but the libraries are setup to expect
  # two values
  local NAMES IDS
  environmentsGoogleCloudOptions "sql instances" 'name' 'name' "project=$GCP_PROJECT_ID"

  local INSTANCE_NAME
  local _DEFAULT
  _DEFAULT="${GCP_PROJECT_ID}-$(environmentsReducePurpose)"

  function createNew() {
    # TODO: select tier
    # TODO: support configurable tier by CURR_ENV_PURPOSE
    # We start the instance now so we can setup the DB and user later
    # local MYSQL_OPTIONS='--database-version=MYSQL_5_7 --database-flags="sql_mode=STRICT_ALL_TABLES,default_time_zone=+00:00"'
    echo "Creating new SQL instance '$INSTANCE_NAME'..."
    local POSTGRES_OPTIONS='--database-version=POSTGRES_11'
    gcloud beta sql instances create "$INSTANCE_NAME" $POSTGRES_OPTIONS \
        --tier="db-f1-micro" --activation-policy="always" --project="${GCP_PROJECT_ID}" \
      || ( echo "Startup may be taking a little extra time. We'll give it another 5 minutes. (error $?)"; \
           gcloud sql operations wait --quiet $(gcloud sql operations list --instance="${INSTANCE_NAME}" --filter='status=RUNNING' --format="value(NAME)" --project="${GCP_PROJECT_ID}") --project="${GCP_PROJECT_ID}" ) \
      || echoerrandexit "Problem encountered while creating instance (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No CloudSQL instances found. Please provide name: " INSTANCE_NAME "$_DEFAULT"
    createNew
  else
    PS3="CloudSQL instance: "
    selectOneCancelNew INSTANCE_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$INSTANCE_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  environmentsActivateAPI sqladmin.googleapis.com

  CLOUDSQL_INSTANCE_NAME="$INSTANCE_NAME"
}

function environmentsGet-CLOUDSQL_CONNECTION_PORT() {
  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    CLOUDSQL_CONNECTION_PORT='tcp'
  fi
}

function environmentsGet-CLOUDSQL_CONNECTION_NAME() {
  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    CLOUDSQL_CONNECTION_NAME='127.0.0.1:5432'
  fi
}

function environmentsGet-CLOUDSQL_PROXY_CONNECTION_NAME() {
  if [[ "$CURR_ENV_PURPOSE" == 'dev' ]]; then
    local REGION=$(gcloud sql instances describe "${CLOUDSQL_INSTANCE_NAME}" --format="value(region)" --project="${GCP_PROJECT_ID}")
    CLOUDSQL_PROXY_CONNECTION_NAME="$GCP_PROJECT_ID:$REGION:$CLOUDSQL_INSTANCE_NAME"
  fi
}

function environmentsGet-CLOUDSQL_DB() {
  local RESULT_VAR="${1}"

  local NAMES IDS
  # we really only care about name, but helpers expect a name/id format
  environmentsGoogleCloudOptions "sql databases" 'name' 'name' '' "--instance='$CLOUDSQL_INSTANCE_NAME'"

  local DB_NAME
  local _DEFAULT
  case "$CURR_ENV_PURPOSE" in
    dev)
      _DEFAULT="dev_${USER}";;
    *)
      _DEFAULT="$CURR_ENV_PURPOSE";;
  esac

  function createNew() {
    gcloud sql databases create "$DB_NAME" --instance="$CLOUDSQL_INSTANCE_NAME" --project="${GCP_PROJECT_ID}" \
      || echoerrandexit "Problem encountered while creating database (see above). Check status via:\nhttps://console.cloud.google.com/"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No existing database found. Please provide name: " DB_NAME "$_DEFAULT"
    createNew
  else
    PS3="Database: "
    selectOneCancelNew DB_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$DB_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    fi
  fi

  CLOUDSQL_DB="$DB_NAME"
}

function environmentsCloudSQLPasswordFile() {
  local USER_NAME="${1}"
  echo "$HOME/.catalyst/creds/cloudsql-${CLOUDSQL_INSTANCE_NAME}-user-${USER_NAME}.password"
}

function environmentsGet-CLOUDSQL_USER() {
  local _SKIP_CURR_ENV_FILE=0
  if ! services-list --exit-on-stopped -q sql; then
    services-start sql
  fi
  unset _SKIP_CURR_ENV_FILE

  local NAMES IDS
  # we really only care about name, but helpers expect a name/id format
  environmentsGoogleCloudOptions "sql users" 'name' 'name' '' "--instance='$CLOUDSQL_INSTANCE_NAME'"

  local USER_NAME PASSWORD PASSWORD_FILE
  local _DEFAULT
  case "$CURR_ENV_PURPOSE" in
    dev)
      _DEFAULT="dev_${USER}";;
    *)
      _DEFAULT="api";;
  esac

  function createNew() {
    PASSWORD=$(openssl rand -base64 12)
    gcloud sql users create "$USER_NAME" --instance="$CLOUDSQL_INSTANCE_NAME" --password="$PASSWORD" --project="${GCP_PROJECT_ID}"\
      || echoerrandexit "Problem encountered while creating DB user (see above). Check status via:\nhttps://console.cloud.google.com/"
    PASSWORD_FILE=$(environmentsCloudSQLPasswordFile "$USER_NAME")
    echo "$PASSWORD" > "$PASSWORD_FILE"
  }

  function setPw() {
    gcloud sql users set-password "$USER_NAME" --instance="$CLOUDSQL_INSTANCE_NAME" --password="$PASSWORD" --project="$GCP_PROJECT_ID" \
      || echoerrandexit "Problem setting new password.\nTry updating manually."
    echo "$PASSWORD" > "$PASSWORD_FILE"
  }

  if [[ -z "$NAMES" ]]; then
    require-answer "No existing DB users found. Please provide user name: " USER_NAME "$_DEFAULT"
    createNew
  else
    PS3="DB user: "
    selectOneCancelNew USER_NAME NAMES
    local SELECT_IDX
    SELECT_IDX=$(list-get-index NAMES "$USER_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    else
      PASSWORD_FILE=$(environmentsCloudSQLPasswordFile "$USER_NAME")
      if [[ ! -f "$PASSWORD_FILE" ]]; then
        echo "No local password file found for user."
        local PW_OPTIONS="enter current password"$'\n'"generate and reset password"$'\n'"specify and reset"
        local PW_CHOICE
        selectOneCancel PW_CHOICE PW_OPTIONS
        case "$PW_CHOICE" in
          'enter current password')
            require-answer "Current password: " PASSWORD
            echo "$PASSWORD" > "$PASSWORD_FILE"
            ;;
          'generate and reset password')
            PASSWORD=$(openssl rand -base64 12)
            setPw
            ;;
          'specify and reset password')
            require-answer "New password: " PASSWORD
            setPw
            ;;
          *)
            echoerrandexit "Program error; unknown selection '$PW_CHOICE'";;
        esac
        echo "$PASSWORD" > "$PASSWORD_FILE"
      else
        PASSWORD=$(cat "$PASSWORD_FILE")
      fi
    fi
  fi

  CLOUDSQL_USER="$USER_NAME"
  CLOUDSQL_PASSWORD="$PASSWORD"
}

function environmentsGet-CLOUDSQL_PASSWORD() {
  echoerrandexit "'CLOUDSQL_PASSWORD' should be set when selecting 'CLOUDSQL_USER'. Check configuration to ensure that the password parameter comes after the user parameter."
}

function environmentsGet-CLOUDSQL_SERVICE_ACCT() {
  local RESULT_VAR="${1}"

  local NAMES IDS
  environmentsGoogleCloudOptions "iam service-accounts" 'displayName' 'email' "projectId=$GCP_PROJECT_ID"

  local DISPLAY_NAME ACCT_ID

  function createNew() {
    ACCT_ID=$(environmentsGcpIamCreateAccount "$DISPLAY_NAME")
    environmentsGcpProjectsBindPolicies "$ACCT_ID" "cloudsql.client"
    environmentsGcpIamCreateKeys "$ACCT_ID"
  }

  local _DEFAULT
  # TODO: Only if not in names
  _DEFAULT="$(environmentsReducePurpose)-cloudsql-srvacct"

  if [[ -z "$NAMES" ]]; then
    require-answer "No service accounts found. Please provide display name: " DISPLAY_NAME "$_DEFAULT"
    createNew
  else
    PS3="Service account: "
    local DISPLAY_NAME
    echo "To create a new service acct, select '<other>' and provide the account display name name."
    selectOneCancelOther DISPLAY_NAME NAMES
    local SELECT_IDX=$(list-get-index NAMES "$DISPLAY_NAME")
    if [[ -z "$SELECT_IDX" ]]; then # it's a new instance
      createNew
    else
      ACCT_ID=$(list-get-item IDS "$SELECT_IDX")
      environmentsGcpProjectsBindPolicies "${ACCT_ID}" "roles/cloudsql.client"
      environmentsGcpIamCreateKeys "${ACCT_ID}"
    fi
  fi

  CLOUDSQL_SERVICE_ACCT="$ACCT_ID"
}
function gcpNameToId() {
  echo "$1" | tr ' ' '-' | tr '[:upper:]' '[:lower:]'
}

function environmentsCheckCloudSDK() {
  command -v gcloud >/dev/null || \
    echoerrandexit "Required 'gcloud' command not found. Refer to:\nhttps://cloud.google.com/sdk/docs/"

  # beta needed for billing management and it's easier to just install rather
  # than deal with whether or not they need billing management
  local COM
  for COM in beta ; do
    if [ 0 -eq `gcloud --verbosity error components list --filter="Status='Installed'" --format="value(ID)" 2>/dev/null | grep $COM | wc -l` ]; then
      gcloud components install $COM
    fi
  done
}

function environmentsGoogleCloudOptions() {
  # TODO: can't use setSimpleOptions because it doesn't handle input with spaces correctly.
  # local TMP # see https://unix.stackexchange.com/a/88338/84520
  # TMP=$(setSimpleOptions FILTER= -- "$@") \
  #  || ( contextHelp; echoerrandexit "Bad options." )
  # eval "$TMP"

  local GROUP="${1}"; shift
  local NAME_FIELD="${1}"; shift
  local ID_FIELD="${1}"; shift
  local FILTER="${1:-}"
  if (( $# > 0 )); then shift; fi

  local QUERY="gcloud $GROUP list --format=\"value($NAME_FIELD,$ID_FIELD)[quote,separator=' ']\""
  if [[ -n "$FILTER" ]]; then
    QUERY="$QUERY --filter=\"$FILTER\""
  fi
  if [[ "$GROUP" != 'projects' ]] && [[ "$GROUP" != 'organizations' ]]; then
    QUERY="$QUERY --project='${GCP_PROJECT_ID}'"
  fi

  # expects 'NAMES' and 'IDS' to have been declared by caller
  local LINE NAME ID
  function split() {
    NAME="$1"
    ID="$2"
  }
  while read LINE; do
    eval "split $LINE"
    list-add-item NAMES "$NAME"
    list-add-item IDS "$ID"
  done < <(eval "$QUERY" "$@")
}

function environmentsGcpEnsureProjectId() {
  if [[ -z $GCP_PROJECT_ID ]]; then
    echoerrandexit "'GCP_PROJECT_ID' unset; likely program error."
  fi
}

environments-add() {
  local ENV_NAME REQ_PARAMS DEFAULT_SETTINGS
  CURR_ENV_SERVICES=()
  environmentsGatherEnvironmentSettings "$@"

  if [[ -n "$REQ_PARAMS" ]]; then
    local REQ_PARAM
    for REQ_PARAM in $REQ_PARAMS; do
      if [[ -z "${!REQ_PARAM:-}" ]]; then
        local PARAM_VAL=''
        local DEFAULT_VAR_NAME="${REQ_PARAM}_DEFAULT_VAL"
        if declare -F environmentsGet-$REQ_PARAM >/dev/null; then
          environmentsGet-$REQ_PARAM $REQ_PARAM
        fi
        if [[ -z ${!REQ_PARAM:-} ]]; then
          require-answer "Value for required parameter '$REQ_PARAM': " PARAM_VAL "${!DEFAULT_VAR_NAME:-}"
          eval "$REQ_PARAM='$PARAM_VAL'"
        fi
      fi
    done
  fi
  # else, there are no required service interfaces and we're done.

  updateEnvironment
  environmentsAskIfSelect
}

environments-delete() {
  local ENV_NAME="${1:-}"
  test -n "$ENV_NAME" || echoerrandexit "Must specify enviromnent for deletion."

  if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    echoerrandexit "No such environment '$ENV_NAME'."
  fi

  onDeleteConfirm() {
    rm "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" && echo "Local '${ENV_NAME}' entry deleted."
  }

  onDeleteCurrent() {
    onDeleteConfirm
    environments-select 'none'
  }

  onDeleteCancel() {
    return 0 # noop
  }

  if [[ "$ENV_NAME" == "$CURR_ENV" ]]; then
    yesno \
      "Confirm deletion of current environment '${CURR_ENV}': (y/N) " \
      N \
      onDeleteCurrent \
      onDeleteCancel
  elif [[ -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    yesno \
      "Confirm deletion of environment '${ENV_NAME}': (y/N) " \
      N \
      onDeleteConfirm \
      onDeleteCancel
  else
    echoerrandexit "No such environment '${ENV_NAME}' found. Try:\nliq environment list"
  fi
}

environments-deselect() {
  ( test -L "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" \
    && rm "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ) \
    || echoerrandexit "No environment currently selected."
  loadCurrEnv
}

environments-list() {
  local RESULT="$(doEnvironmentList "$@")"
  if test -n "$RESULT"; then
    echo "$RESULT"
  else
    echo "No environments defined for '${PACKAGE_NAME}'. Try:\nliq environment add"
  fi
}

environments-select() {
  local ENV_NAME="${1:-}"
  if [[ -z "$ENV_NAME" ]]; then
    if test -z "$(doEnvironmentList)"; then
      echoerrandexit "No environments defined. Try:\nliq environment add"
    fi
    echo "Select environment:"
    local ENVS
    ENVS="$(doEnvironmentList)"
    selectOneCancel ENV_NAME ENVS
    ENV_NAME="${ENV_NAME//[ *]/}"
  fi
  local CURR_ENV_FILE="${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env"
  if [[ -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    if [[ -L $CURR_ENV_FILE ]]; then rm $CURR_ENV_FILE; fi
    cd "${LIQ_ENV_DB}/${PACKAGE_NAME}/" && ln -s "./${ENV_NAME}" curr_env
  else
    echoerrandexit "No such environment '$ENV_NAME' defined."
  fi
  # if not error and exit
  loadCurrEnv
}

environments-set() {
  echoerr "TODO: sorry, 'set' implementation is outdated"
  exit
  local ENV_NAME KEY VALUE
  if [[ $# -eq 3 ]]; then
    ENV_NAME="$1"
    KEY="$2"
    VALUE="$3"
  elif [[ $# -eq 2 ]]; then
    ENV_NAME="$CURR_ENV"
    KEY="$1"
    VALUE="$2"
  elif [[ $# -eq 0 ]]; then
    ENV_NAME="$CURR_ENV"
    echo "Select parameter to update"
    # TODO: add 'selectOrOther' function; we use this pattern in a few places
    select KEY in `getEnvTypeKeys` '<other>'; do break; done
    if [[ "$KEY" == '<other>' ]]; then
      require-answer 'Parameter key: ' KEY
    fi
    require-answer 'Parameter value: ' VALUE
    updateEnvParam "$KEY" "$VALUE"
  else
    echoerrandexit "Unexpected number of arguments to 'liq environment set'."
    # TODO: print action specific help would be nice
  fi

  updateEnvironment
}

environments-show() {
  local ENV_NAME="${1:-}"

  if [[ -n "$ENV_NAME" ]]; then
    if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
      echoerrandexit "No such environment '$ENV_NAME' found for '$PACKAGE_NAME'."
    fi
  else
    if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ]]; then
      echoerrandexit "No environment selected for '$PACKAGE_NAME'. Try:\nliq environments select\n  or\nliq environments add"
    fi
    ENV_NAME='curr_env'
  fi
  cat "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}"

  # if [[ -n "$CURR_ENV" ]] && [[ "$CURR_ENV" == "$ENV_NAME" ]]; then
  #  echo "Current environment:"
  #  echo "$CURR_ENV"
  #  echo
  #fi
  #local ENV_DB="${LIQ_ENV_DB}/${ENV_NAME}"
  #if [[ -f "$ENV_DB" ]]; then
  #  cat "$ENV_DB"
  #else
  #  echoerrandexit "No such environment '${ENV_NAME}'."
  #fi
}

# TODO: this shares a lot of code with environments-add
environments-update() {
  local TMP
  TMP=$(setSimpleOptions NEW_ONLY -- "$@") \
    || ( help-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  local ENV_NAME="${1:-}"

  if [[ -z "${ENV_NAME}" ]]; then
    if [[ -L "${LIQ_ENV_DB}/${PACKAGE_NAME}/curr_env" ]]; then
      requireEnvironment
      ENV_NAME="$CURR_ENV"
    else
      local ENV_LIST
      ENV_LIST=$(environments-list --list-only)
      selectOneCancel ENV_NAME ENV_LIST
    fi
  fi

  if [[ ! -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    contextHelp
    echoerrandexit "Unknown environment name '${ENV_NAME}'."
  else
    source "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}"
  fi

  # Handle the purpose
  if [[ -z "$NEW_ONLY" ]]; then
    local SELECT_DEFAULT="$CURR_ENV_PURPOSE"
    unset CURR_ENV_PURPOSE
    PS3="Select purpose: "
    selectOneCancelOtherDefault CURR_ENV_PURPOSE STD_ENV_PURPOSES
  fi

  local REQ_SERV_IFACES=`required-services-list`
  local REQ_SERV_IFACE
  local PRIOR_ENV_SERVICES="${CURR_ENV_SERVICES[@]:-}"
  CURR_ENV_SERVICES=()
  for REQ_SERV_IFACE in $REQ_SERV_IFACES; do
    local PRIOR_MATCH="$(echo "$PRIOR_ENV_SERVICES" | sed -Ee 's/(^|.* +)('$REQ_SERV_IFACE':[^ ]+)( +|$).*/\2/')"
    if echo "$PRIOR_ENV_SERVICES" | grep -qE '(^|.* +)('$REQ_SERV_IFACE':[^ ]+)( +|$).*'; then
      local PRIOR_SERVICE=$(echo "$PRIOR_MATCH" | cut -d: -f3)
      local PRIOR_PACKAGE=$(echo "$PRIOR_MATCH" | cut -d: -f2)
      environmentsServiceDescription SELECT_DEFAULT "$PRIOR_SERVICE" "$PRIOR_PACKAGE"
      SELECT_DEFAULT="'${SELECT_DEFAULT}'"
    else
      SELECT_DEFAULT=''
    fi
    local FQN_SERVICE
    if [[ -z "$NEW_ONLY" ]] || [[ -z "$SELECT_DEFAULT" ]]; then
      environmentsFindProvidersFor "$REQ_SERV_IFACE" FQN_SERVICE
    else
      environmentsFigureFqnService FQN_SERVICE "$REQ_SERV_IFACE" "$(echo "$SELECT_DEFAULT" | tr -d "'")"
    fi
    CURR_ENV_SERVICES+=("$FQN_SERVICE")

    local REQ_PARAMS=$(getRequiredParameters "$FQN_SERVICE")
    local ADD_REQ_PARAMS=$((echo "$PACKAGE" | jq -e --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"params-req\" | @sh" 2> /dev/null || echo '') | tr -d "'")
    if [[ -n "$ADD_REQ_PARAMS" ]]; then
      if [[ -n "$REQ_PARAMS" ]]; then
        REQ_PARAMS="$REQ_PARAMS $ADD_REQ_PARAMS"
      else
        REQ_PARAMS="$ADD_REQ_PARAMS"
      fi
    fi
    local REQ_PARAM
    for REQ_PARAM in $REQ_PARAMS; do
      local DEFAULT_VAL=${!REQ_PARAM:-}
      if [[ -z "$NEW_ONLY" ]] || [[ -z "$DEFAULT_VAL" ]]; then
        if [[ -n "${!REQ_PARAM:-}" ]]; then # it's set in the prior env def
          eval "$REQ_PARAM=''"
        else
          # check the scripts for defaults for new values
          environmentsGetDefaultFromScripts DEFAULT_VAL "$FQN_SERVICE" "$REQ_PARAM"
        fi

        local PARAM_VAL=''
        require-answer "Value for required parameter '$REQ_PARAM': " PARAM_VAL "$DEFAULT_VAL"
        eval "$REQ_PARAM='$PARAM_VAL'"
      fi
    done

    # update configuration constants
    for REQ_PARAM in $(echo $PACKAGE | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\" | keys | @sh" | tr -d "'"); do
      local CONFIG_VAL=$(echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | select(.iface==\"$REQ_SERV_IFACE\") | .\"config-const\".\"$REQ_PARAM\" | @sh" | tr -d "'")
      eval "$REQ_PARAM='$CONFIG_VAL'"
    done
  done

  updateEnvironment
}
help-environments() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}environments${reset} <action>: Runtime environment configurations." || cat <<EOF
${PREFIX}${cyan_u}environments${reset}:
  ${underline}list${reset}: List available environments for the current project.
  ${underline}show${reset} [<name>]: Display the named or current environment.
  ${underline}add${reset} [<name>]: Interactively adds a new environment definition to the current
    project.
  ${underline}delete${reset} <name>: Deletes named environment for the current project.
  ${underline}select${reset} [<name>]: Selects one of the available environment.
  ${underline}deselect${reset}: Unsets the current environment.
  ${underline}set${reset} [<key> <value>] | [<env name> <key> <value>]: Updates environment
    settings.
  ${underline}update${reset} [-n|--new-only]: Interactively update the current environment.
EOF
}

# TODO: share this with '/install.sh'
COMPLETION_PATH="/usr/local/etc/bash_completion.d"

requirements-meta() {
  :
}

meta-init() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions ORG= PLAYGROUND= SILENT -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -z "$PLAYGROUND" ]]; then
    # TODO: require-answer-matching (or something) to force absolute path here
    require-answer "Liquid playground location: " LIQ_PLAYGROUND "${HOME}/playground"
  else
    LIQ_PLAYGROUND="$PLAYGROUND"
  fi
  if [[ "$LIQ_PLAYGROUND" != /* ]]; then
    echoerrandexit "Playground path must be absolute."
  fi

  if [[ -n "$SILENT" ]]; then
    metaSetupLiqDb > /dev/null
  else
    metaSetupLiqDb
  fi

  if [[ -n "$ORG" ]]; then
    orgs-affiliate --select "$ORG"
  elif [[ -z "$SILENT" ]]; then
    echo "Don't forget to create or affiliate with an organization."
  fi
}

meta-bash-config() {
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
}
help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles liq self-config and meta operations." \
   || cat <<EOF
${PREFIX}${cyan_u}meta${reset} <action>:
   ${underline}init${reset} [--silent|-s] [--playground|-p <absolute path>]: Creates the Liquid
     Development DB (a local directory) and playground.
   ${underline}bash-config${reset}: Prints bash configuration. Try: eval \`liq meta bash-config\`
EOF
}
metaSetupLiqDb() {
  # TODO: check LIQ_PLAYGROUND is set
  createDir() {
    local DIR="${1}"
    echo -n "Creating Liquid Dev DB ('${DIR}')... "
    mkdir -p "$DIR" \
      || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development DB (${DIR})\nSee above for further details.")
    echo "${green}success${reset}"
  }
  createDir "$LIQ_DB"
  createDir "$LIQ_ENV_DB"
  createDir "$LIQ_WORK_DB"
  createDir "$LIQ_ENV_LOGS"
  createDir "$LIQ_PLAYGROUND"
  echo -n "Initializing Liquid Dev settings... "
  cat <<EOF > "${LIQ_DB}/settings.sh" || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development settings.")
LIQ_PLAYGROUND="$LIQ_PLAYGROUND"
EOF
  echo "${green}success${reset}"
}

requirements-orgs() {
  findBase
}

orgs-affiliate() {
  eval "$(setSimpleOptions LEAVE: SELECT SENSITIVE: -- "$@")"

  local ORG_URL="${1:-}"

  if [[ -n "$LEAVE" ]]; then
    if [[ -z "$ORG_URL" ]]; then # which is really the nick name
      echoerrandexit "You must explicitly name the org when leaving. Try:\nliq orgs leave <org nick>"
    elif [[ ! -d "${LIQ_ORG_DB}/${ORG_URL}" ]]; then
      echoerrandexit "Did not find org with nick name '${ORG_URL}'. Try:\nliq orgs list"
    fi
    cd "${LIQ_ORG_DB}"
    if [[ "$(orgsCurrentOrg)" == "$ORG_URL" ]]; then
      rm -rf curr_org
    fi
    rm -rf "$ORG_URL"
    echo "Local org info removed."
    return
  fi

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg)"
  mkdir -p "${LIQ_ORG_DB}"
  cd "${LIQ_ORG_DB}"
  if [[ -n "$ORG_URL" ]]; then
    rm -rf .staging
    git clone --origin upstream --quiet "${ORG_URL}/org_settings.git" .staging \
      || { rm -rf .staging; echoerrandexit "Could not retrieve the public org repo."; }
    source .staging/settings.sh
    if [[ -d "${LIQ_ORG_DB}/${ORG_NICK_NAME}" ]]; then
      echo "Public repo for '${ORG_NICK_NAME}' already present."
      rm -rf .staging
    else
      mkdir -p "${LIQ_ORG_DB}/${ORG_NICK_NAME}"
      mv .staging "${LIQ_ORG_DB}/${ORG_NICK_NAME}/public"
    fi
  elif [[ -z "$ORG_URL" ]] && [[ -n "$REQUIRE_SENSITIVE" ]] && [[ -n "$CURR_ORG" ]]; then
    # setup ORG_URL from CURR_ORG for the 'add sensitive to current' use case
    source "${CURR_ORG}/public/settings.sh"
    ORG_URL="git@github.com:${ORG_GITHUB_NAME}"
  else
    echoerrandexit "Incompatable command options."
  fi

  if [[ -n "${SENSITIVE}" ]]; then
    git clone --origin upstream --quiet "${ORG_URL}/org_settings_sensitive.git" .staging \
      || { rm -rf .staging; echoerrandexit "Could not retrieve the sensitive org repo."; }
    mv .staging "${LIQ_ORG_DB}/${ORG_NICK_NAME}/sensitive"
  fi

  if [[ -n "${SELECT}" ]]; then orgs-select "$ORG_NICK_NAME"; fi
}

orgs-create() {
  local FIELDS="COMMON_NAME GITHUB_NAME LEGAL_NAME ADDRESS NAICS"
  local FIELDS_SENSITIVE="EIN"
  eval "$(setSimpleOptions NO_SUBSCRIBE:S ACTIVATE COMMON_NAME= GITHUB_NAME= LEGAL_NAME= ADDRESS= EIN= NAICS= -- "$@")"

  if [[ -n "$NO_SUBSCRIBE" ]] && [[ -n "$ACTIVATE" ]]; then
    echoerrandexit "The '--no-subscribe' and '--activate' options are incompatible."
  fi

  local FIELD FIELD_SET VERIFIED
  while [[ "${VERIFIED}" != true ]]; do
    for FIELD in $FIELDS $FIELDS_SENSITIVE; do
      local OPTS=''
      # if VERIFIED is set, but false, then we need to force require-answer to set the var
      [[ "$VERIFIED" == false ]] && OPTS='--force '
      [[ "$FIELD" == "ADDRESS" ]] && OPTS="${OPTS}--multi-line "
      require-answer ${OPTS} "${FIELD//_/ }: " $FIELD
    done
    verify() { VERIFIED=true; }
    no-verify() { VERIFIED=false; }
    echo
    echo "Verify the following:"
    for FIELD in $FIELDS $FIELDS_SENSITIVE; do
      echo "$FIELD: ${!FIELD}"
    done
    echo
    yesno "Are these values correct? (y/N) " N verify no-verify
  done

  cd ${LIQ_DB}
  mkdir -p orgs
  cd orgs
  local DIR_NAME
  DIR_NAME="$(echo "$COMMON_NAME" | tr ' -' '_' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_')"

  if [[ -d "$DIR_NAME" ]]; then
    echoerrandexit "Duplicate or name conflict; found existing org entry ($DIR_NAME)."
  fi

  mkdir "${DIR_NAME}"
  local REPO
  for REPO in public sensitive; do
    cd "${LIQ_DB}/orgs/${DIR_NAME}"
    mkdir "${REPO}"
    cd "${REPO}"
    git init .
  done

  prep-repo() {
    cd "${LIQ_DB}/orgs/${DIR_NAME}/${1}"
    git add settings.sh
    git commit -m "initial org settings"
  }

  cd "${LIQ_DB}/orgs/${DIR_NAME}/public"
  for FIELD in $FIELDS; do
    echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> settings.sh
  done
  echo "ORG_NICK_NAME='${DIR_NAME}'" >> settings.sh
  prep-repo public
  hub create -d "Public liq settings for ${LEGAL_NAME}." "${GITHUB_NAME}/org_settings"
  git push --set-upstream origin master

  cd "${LIQ_DB}/orgs/${DIR_NAME}/sensitive"
  for FIELD in $FIELDS_SENSITIVE; do
    echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> settings.sh
  done
  prep-repo sensitive
  hub create -p -d "Sensitive liq settings for ${LEGAL_NAME}." "${GITHUB_NAME}/org_settings_sensitive"
  git push --set-upstream origin master

  if [[ "$ACTIVATE" == true ]]; then
    cd "${LIQ_DB}/orgs"
    ln -s "$DIR_NAME" curr_org
  fi
  if [[ "$NO_SUBSCRIBE" == true ]]; then
    cd "${LIQ_DB}/orgs"
    rm -rf "$DIR_NAME"
  fi
}

orgs-list() {
  orgsOrgList
}

orgs-select() {
  eval "$(setSimpleOptions NONE -- "$@")"

  if [[ -n "$NONE" ]]; then
    rm "${CURR_ORG_DIR}"
    return
  fi

  local ORG_NAME="${1:-}"
  if [[ -z "$ORG_NAME" ]]; then
    local ORGS
    ORGS="$(orgsOrgList)"

    if test -z "${ORGS}"; then
      echoerrandexit "No org affiliations found. Try:\nliq orgs create\nor\nliq orgs affiliate <git url>"
    fi

    echo "Select org:"
    selectOneCancel ORG_NAME ORGS
    ORG_NAME="${ORG_NAME//[ *]/}"
  fi
  echo "blah: ${LIQ_ORG_DB}/${ORG_NAME}" >> log.tmp
  if [[ -d "${LIQ_ORG_DB}/${ORG_NAME}" ]]; then
    if [[ -L $CURR_ORG_DIR ]]; then rm $CURR_ORG_DIR; fi
    cd "${LIQ_ORG_DB}" && ln -s "./${ORG_NAME}" $(basename "${CURR_ORG_DIR}")
  else
    echoerrandexit "No such org '$ORG_NAME' defined."
  fi
}

orgs-show() {
  eval "$(setSimpleOptions SENSITIVE -- "$@")"

  local ORG_NAME="${1:-}"
  if [[ -z "$ORG_NAME" ]]; then
    ORG_NAME=$(orgsCurrentOrg)
    if [[ -z "$ORG_NAME" ]]; then
      echoerrandexit "No org name given and no org currently selected. Try one of:\nliq orgs show <org name>\nliq orgs select"
    fi
  fi

  if [[ ! -d "${LIQ_ORG_DB}/${ORG_NAME}" ]]; then
    echoerrandexit "No such org with local nick name '${ORG_NAME}'. Try:\nliq orgs list"
  fi

  cat "${LIQ_ORG_DB}/${ORG_NAME}/public/settings.sh"
  if [[ -n "$SENSITIVE" ]]; then
    cat "${LIQ_ORG_DB}/${ORG_NAME}/sensitive/settings.sh"
  fi
}
help-orgs() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}orgs${reset} <action>: Manages organizations and affiliations." || cat <<EOF
${PREFIX}${cyan_u}orgs${reset} <action>:
  ${underline}create${reset} [--no-subscribe|-S] [--activate|-a]:
    Interactively gathers any org info not specified via CLI options and creates a 'org-settings' and
    'org-settings-sensitive' repos under the indicated GitHub org or user name. The following options
    may be used to specify fields from the CLI. If all options are specified (even if blank), then the
    command will run non-interactively.
    * --common-name
    * --legal-name
    * --address (use $'\n' for linebreaks)
    * --github-name
    * --ein
    * --naics
  ${underline}affiliate${reset} [--sensitive] [--leave] [--select|-s] <org url>: Will attempt to retrieve
    the standord org repo at '<org url>/org_settings'. '--sentisive' will also attempt to retrieve the
    sensitive repo. '--select' will cause a successfully retrieved org to be activated. With '--leave',
    provide the org nick instead of URL and the local repos will be removed. This will also de-select
    the named org if it is the currently selected org.
  ${underline}select${reset} [--none] [<org nick>]: Selects/changes currently active org. If no name is
    given, then will enter interactive mode. '--none' de-activates the currently selected org.
  ${underline}list${reset}: Lists the currently affiliated orgs.
  ${underline}show${reset} [--sensitive] [<org nick>]: Displays info on the currently active or named org.

An org(anization) is the legal owner of work and all work is done in the context of an org. It's perfectly fine to create a 'personal' org representing yourself.
EOF
}
orgsCurrentOrg() {
  eval "$(setSimpleOptions REQUIRE REQUIRE_SENSITIVE:s -- "$@")"

  if [[ -n "$REQUIRE_SENSITIVE" ]]; then
    REQUIRE=true
  fi

  if [[ -L "${CURR_ORG_DIR}" ]]; then
    if [[ -n "$REQUIRE_SENSITIVE" ]]; then
      if [[ ! -d "${CURR_ORG_DIR}/sensitive" ]]; then
        echoerrandexit "Command requires access to the sensitive org settings. Try:\nliq orgs import --sensitive"
      fi
    fi
    CURR_ORG="$(readlink "${CURR_ORG_DIR}" | xargs basename)"
  elif [[ -n "$REQUIRE" ]]; then
    echoerrandexit "Command requires active org selection. Try:\nliq orgs select"
  fi

	echo "$CURR_ORG"
}

orgsOrgList() {
  eval "$(setSimpleOptions LIST_ONLY -- "$@")"

  local CURR_ORG ORG
  CURR_ORG=$(orgsCurrentOrg)

  for ORG in $(find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; | sort); do
    ( ( test -z "$LIST_ONLY" && test "$ORG" == "${CURR_ORG:-}" && echo -n '* ' ) || echo -n '  ' ) && echo "$ORG"
  done
}

requirements-packages() {
  requireCatalystfile
  # Requiring 'the' NPM package here (rather than based on command parameters)
  # is an artifact of the alpha-version limitation to a single package.
  requirePackage
}

packages-audit() {
  cd "${BASE_DIR}"
  npm audit
}

packages-build() {
  runPackageScript build
}

packages-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'liq go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

packages-link() {
  echoerrandexit "Linking currently disabled."
}

packages-lint() {
  local TMP
  TMP=$(setSimpleOptions FIX -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -z "$FIX" ]]; then
    runPackageScript lint
  else
    runPackageScript lint-fix
  fi
}

packages-version-check() {
  requireNpmCheck

  local TMP
  TMP=$(setSimpleOptions IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS= -- "$@") \
    || ( help-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  local IGNORED_PACKAGES IPACKAGE
  # the '@sh' breaks '-e'; https://github.com/stedolan/jq/issues/1792
  if echo "$PACKAGE" | jq -e --raw-output '.catalyst."version-check".ignore' > /dev/null; then
    IGNORED_PACKAGES=`echo "$PACKAGE" | jq --raw-output '.catalyst."version-check".ignore | @sh' | tr -d "'" | sort`
  fi
  local CMD_OPTS="$OPTIONS"
  if [[ -z "$CMD_OPTS" ]] && echo "$PACKAGE" | jq -e --raw-output '.catalyst."version-check".options' > /dev/null; then
    CMD_OPTS=`echo "$PACKAGE" | jq --raw-output '.catalyst."version-check".options'`
  fi

  if [[ -n "$UPDATE" ]] \
      && ( (( ${_OPTS_COUNT} > 2 )) || ( (( ${_OPTS_COUNT} == 2 )) && [[ -z $OPTIONS_SET ]]) ); then
    echoerrandexit "'--update' option may only be combined with '--options'."
  elif [[ -n "$IGNORE" ]] || [[ -n "$UNIGNORE" ]]; then
    if [[ -n "$IGNORE" ]] && [[ -n "$UNIGNORE" ]]; then
      echoerrandexit "Cannot 'ignore' and 'unignore' packages in same command."
    fi

    packagesVersionCheckManageIgnored
  elif [[ -n "$SHOW_CONFIG" ]]; then
    packagesVersionCheckShowConfig
  elif [[ -n "$OPTIONS_SET" ]] && (( $_OPTS_COUNT == 1 )); then
    packagesVersionCheckSetOptions
  else # actually do the check
    packagesVersionCheck
  fi
}
help-packages() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${red_b}(deprecated)${reset} ${cyan_u}packages${reset} <action>: Package configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}packages${reset} <action>:
  ${underline}build${reset} [<name>]: Builds all or the named (NPM) package in the current project.
  ${underline}audit${reset} [<name>]: Runs a security audit for all or the named (NPM) package in
    the current project.
  ${red_b}(deprecated)${reset} ${underline}version-check${reset} [-u|update] [<name>]: Runs version check with optional
    interactive update for all or named dependency packages.
    ${red}This will be reworked as 'dependencies'.${reset}
      [-i|--ignore|-I|--unignore] [<name>]: Configures dependency packages
        ignored during update checks.
      [-o|--options <option string>]: Sets options to use with 'npm-check'.
      [-c|--show-config]: Shows the current configuration used with 'npm-check'.
  ${underline}lint${reset} [-f|--fix] [<name>]: Lints all or the named (NPM) package in the current
    project.
  ${underline}deploy${reset} [<name>...]: Deploys all or named packages to the current environment.
  ${underline}link${reset} [-l|--list][-f|--fix][-u|--unlink]<package spec>...: Links (via npm) the
    named packages to the current package. '--list' lists the packages linked in
    the current project and takes no arguements. The '--unlink' version will
    unlink all Catalyst linked packages from the current package unless specific
    packages are specified. '--fix' will check and attempt to fix any broken
    package links in the current project and takes no arguments.

${red}Deprecated: these functions will migrate under 'project'.${reset}

${red_b}ALPHA NOTE:${reset} The 'test' action is likely to chaneg significantly in the future to
support the definition of test sets based on type (unit, integration, load,
etc.) and name.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
runPackageScript() {
  local TMP
  TMP=$(setSimpleOptions IGNORE_MISSING SCRIPT_ONLY -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  local ACTION="$1"; shift

  cd "${BASE_DIR}"
  if cat package.json | jq -e "(.scripts | keys | map(select(. == \"$ACTION\")) | length) == 1" > /dev/null; then
    npm run-script "${ACTION}"
  elif [[ -n "$SCRIPT_ONLY" ]] && [[ -z "$IGNORE_MISSING" ]]; then # SCRIPT_ONLY is a temp. workaround to implement future behaior. See note below.
    echoerrandexit "Did not find expected NPM script for '$ACTION'."
  elif [[ -z "$SCRIPT_ONLY" ]]; then
    # TODO: drop this; require that the package interface with catalyst-scripts
    # through the the 'package-scripts'. This will avoid confusion and also
    # allow "plain npm" to run more of what can be run. It will also allow users
    # to override the scripts if they really want to. (But we should catch) that
    # on an audit.
    local CATALYST_SCRIPTS=$(npm bin)/catalyst-scripts
    if [[ ! -x "$CATALYST_SCRIPTS" ]]; then
      # TODO: offer to install and re-run
      echoerr "This project does not appear to be using 'catalyst-scripts'. Try:"
      echoerr ""
      echoerrandexit "npm install --save-dev @liquid-labs/catalyst-scripts"
    fi
    # kill the debug trap because if the script exits with an error (as in a
    # failed lint), that's OK and the debug doesn't provide any useful info.
    "${CATALYST_SCRIPTS}" "${BASE_DIR}" $ACTION || true
  fi
}

requireNpmCheck() {
  # TODO: offer to install
  if ! which -s npm-check; then
    echoerr "'npm-check' not found; could not check package status. Install with:"
    echoerr ''
    echoerr '    npm install -g npm-check'
    echoerr ''
    exit 10
  fi
}

packagesVersionCheckManageIgnored() {
  local IPACKAGES
  if [[ -n "$IGNORE" ]]; then
    local LIVE_PACKAGES=`echo "$PACKAGE" | jq --raw-output '.dependencies | keys | @sh' | tr -d "'"`
    for IPACKAGE in $IGNORED_PACKAGES; do
      LIVE_PACKAGES=$(echo "$LIVE_PACKAGES" | sed -Ee 's~(^| +)'$IPACKAGE'( +|$)~~')
    done
    if (( $# == 0 )); then # interactive add
      PS3="Exclude package: "
      selectDoneCancel IPACKAGES LIVE_PACKAGES
    else
      IPACKAGES="$@"
    fi

    for IPACKAGE in $IPACKAGES; do
      if echo "$IGNORED_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
        echoerr "Package '$IPACKAGE' already ignored."
      elif ! echo "$LIVE_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
        echoerr "No such package '$IPACKAGE' in dependencies."
      else
        if [[ -z "$IGNORED_PACKAGES" ]]; then
          PACKAGE=`echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","ignore"]; ["'$IPACKAGE'"])'`
        else
          PACKAGE=`echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","ignore"]; getpath(["catalyst","version-check","ignore"]) + ["'$IPACKAGE'"])'`
        fi
        IGNORED_PACKAGES="${IGNORED_PACKAGES} ${IPACKAGE}"
      fi
    done
  elif [[ -n "$UNIGNORE" ]]; then
    if [[ -z "$IGNORED_PACKAGES" ]]; then
      if (( $# > 0 )); then
        echoerr "No packages currently ignored."
      else
        echo "No packages currently ignored."
      fi
      exit
    fi
    if (( $# == 0 )); then # interactive add
      PS3="Include package: "
      selectDoneCancelAll IPACKAGES IGNORED_PACKAGES
    else
      IPACKAGES="$@"
    fi

    for IPACKAGE in $IPACKAGES; do
      if ! echo "$IGNORED_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
        echoerr "Package '$IPACKAGE' is not currently ignored."
      else
        PACKAGE=`echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","ignore"]; getpath(["catalyst","version-check","ignore"]) | map(select(. != "'$IPACKAGE'")))'`
      fi
    done
  fi

  # TODO: cleanup empty bits
  echo "$PACKAGE" > "$PACKAGE_FILE"

  if [[ -n "$SHOW_CONFIG" ]]; then
    project-packages-version-check -c
  fi
}

packagesVersionCheckShowConfig() {
  if [[ -z "$IGNORED_PACKAGES" ]]; then
    echo "Ignored packages: none"
  else
    echo "Ignored packages:"
    echo "$IGNORED_PACKAGES" | tr " " "\n" | sed -E 's/^/  /'
  fi
  if [[ -z "$CMD_OPTS" ]]; then
    echo "Additional options: none"
  else
    echo "Additional options: $CMD_OPTS"
  fi
}

packagesVersionCheckSetOptions() {
  if [[ -n "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","options"]; "'$OPTIONS'")')
  elif [[ -z "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'del(.catalyst."version-check".options)')
  fi
  echo "$PACKAGE" > "$PACKAGE_FILE"
}

packagesVersionCheck() {
  for IPACKAGE in $IGNORED_PACKAGES; do
    CMD_OPTS="${CMD_OPTS} -i ${IPACKAGE}"
  done
  if [[ -n "$UPDATE" ]]; then
    CMD_OPTS="${CMD_OPTS} -u"
  fi
  npm-check ${CMD_OPTS} || true
}

packages-link-list() {
  echoerrandexit 'Package link functions currently disabled.'
}

requirements-policies() {
  :
}

policies-document() {
  local NODE_SCRIPT CURR_ORG TARGET_DIR
  NODE_SCRIPT="$(dirname $(real_path ${BASH_SOURCE[0]}))/index.js"
  CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
  TARGET_DIR="${LIQ_ORG_DB}/${CURR_ORG}/sensitive/policy"

  rm -rf "$TARGET_DIR"
  mkdir -p "$TARGET_DIR"
  node -e "require('$NODE_SCRIPT').refreshDocuments('${TARGET_DIR}', process.argv.slice(1))" $(policiesGetPolicyFiles)
}

policies-update() {
  local CURR_ORG POLICY
  CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
  cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"

  for POLICY in $(policiesGetPolicyPackages); do
    npm i "${POLICY}"
  done
}
help-policies() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}policies${reset} <action>: Manages organization policies." || cat <<EOF
${PREFIX}${cyan_u}policies${reset} <action>:
  ${underline}document${reset}: Refreshes (or generates) org policy documentation based on current data.
  ${underline}update${reset}: Updates organization policies.

Policies defines all manner of organizational operations. They are "organizational code".
EOF
}
policiesGetPolicyDirs() {
  (
    local CURR_ORG
    CURR_ORG="$(orgsCurrentOrg --require-sensitive)"
    cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"
    find "./node_modules/@liquid-labs" -maxdepth 1 -type d -name "policy-*" -exec echo "${PWD}/{}" \;
  )
}

policiesGetPolicyFiles() {
  local DIRS DIR
  DIRS="$(policiesGetPolicyDirs)"
  for DIR in $DIRS; do
    find $DIR -name "*.tsv"
  done
}

policiesGetPolicyPackages() {
  local DIR
  for DIR in $(policiesGetPolicyDirs); do
    cd "${DIR}"
    cat package.json | jq --raw-output '.name' | tr -d "'"
  done
}

requirements-project() {
  :
}

project-close() {
  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    findBase
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"

  cd "$LIQ_PLAYGROUND/${CURR_ORG}"
  if [[ -d "$PROJECT_NAME" ]]; then
    cd "$PROJECT_NAME"
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $({ git status --porcelain 2>/dev/null| grep '^??' || true; } | wc -l) == 0 )); then
        if [[ $(git rev-parse --verify master) == $(git rev-parse --verify upstream/master) ]]; then
          cd "${LIQ_PLAYGROUND}/${CURR_ORG}"
          rm -rf "$PROJECT_NAME" && echo "Removed project '$PROJECT_NAME'."
          # now check to see if we have an empty "org" dir
          local ORG_NAME
          ORG_NAME=$(dirname "${PROJECT_NAME}")
          if [[ "$ORG_NAME" != "." ]] && (( 0 == $(ls "$ORG_NAME" | wc -l) )); then
            rmdir "$ORG_NAME"
          fi
        else
          echoerrandexit "Not all changes have been pushed to master." 1
        fi
      else
        echoerrandexit "Found untracked files." 1
      fi
    else
      echoerrandexit "Found uncommitted changes.\n$(git status --porcelain)" 1
    fi
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
  # TODO: need to check whether the project is linked to other projects
}

project-create() {
  echoerrandexit "'create' needs to be reworked for forks."
  local TMP PROJ_STAGE __PROJ_NAME TEMPLATE_URL
  TMP=$(setSimpleOptions TYPE= TEMPLATE:T= ORIGIN= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  __PROJ_NAME="${1}"
  if [[ -z "$__PROJ_NAME" ]]; then
    echoerrandexit "Must specify project name (1st argument)."
  fi

  if [[ -n "$TYPE" ]] && [[ -n "$TEMPLATE" ]]; then
    echoerrandexit "You specify either project 'type' or 'template, but not both.'"
  elif [[ -z "$TYPE" ]] && [[ -z "$TEMPLATE" ]]; then
    echoerrandexit "You must specify one of 'type' or 'template'."
  elif [[ -n "$TEMPLATE" ]]; then
    # determine if package or URL
    : # TODO: we do this in import too; abstract?
  else # it's a type
    case "$TYPE" in
      bare)
        if [[ -z "$ORIGIN" ]]; then
          echoerrandexit "Creating a 'raw' project, '--origin' must be specified."
        fi
        TEMPLATE_URL="$ORIGIN";;
      *)
        echoerrandexit "Unknown 'type'. Try one of: bare"
    esac
  fi
  projectClone "$TEMPLATE_URL"
  cd "$PROJ_STAGE"
  # re-orient the origin from the template to the ORIGIN URL
  git remote set-url origin "${ORIGIN}"
  git remote set-url origin --push "${ORIGIN}"
  if [[ -f "package.json" ]]; then
    echowarn --no-fold "This project already has a 'project.json' file. Will continue as import.\nIn future, try:\nliq import $__PROJ_NAME"
  else
    local SCOPE
    SCOPE=$(dirname "$__PROJ_NAME")
    if [[ -n "$SCOPE" ]]; then
      npm init --scope "${SCOPE}"
    else
      npm init
    fi
    git add package.json
  fi
  cd
  projectMoveStaged "$__PROJ_NAME" "$PROJ_STAGE"
}

project-import() {
  local PROJ_SPEC __PROJ_NAME _PROJ_URL PROJ_STAGE
  eval "$(setSimpleOptions NO_FORK:F SET_NAME= SET_URL= -- "$@")"

  set-stuff() {
    # TODO: protect this eval
		echo "setting stuff: $SET_NAME='$_PROJ_NAME'" >> ~/log.tmp
    if [[ -n "$SET_NAME" ]]; then eval "$SET_NAME='$_PROJ_NAME'"; fi
    if [[ -n "$SET_URL" ]]; then eval "$SET_URL='$_PROJ_URL'"; fi
  }

  if [[ "$1" == *:* ]]; then # it's a URL
		echo "url" >> ~/log.tmp
    _PROJ_URL="${1}"
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
    if _PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'"); then
      set-stuff
      if projectCheckIfInPlayground "$_PROJ_NAME"; then return 0; fi
    else
      rm -rf "$PROJ_STAGE"
      echoerrandexit -F "The specified source is not a valid Liquid Dev package (no 'package.json'). Try:\nliq project create --type=bare --origin='$_PROJ_URL' <project name>"
    fi
  else # it's an NPM package
    _PROJ_NAME="${1}"
    set-stuff
    if projectCheckIfInPlayground "$_PROJ_NAME"; then
      _PROJ_URL="$(projectsGetUpstreamUrl "$_PROJ_NAME")"
      set-stuff
      return 0
    fi
    # Note: NPM will accept git URLs, but this saves us a step, let's us check if in playground earlier, and simplifes branching
    _PROJ_URL=$(npm view "$_PROJ_NAME" repository.url) \
      || echoerrandexit "Did not find expected NPM package '${_PROJ_NAME}'. Did you forget the '--url' option?"
    set-stuff
    _PROJ_URL=${_PROJ_URL##git+}
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
  fi

  projectMoveStaged "$_PROJ_NAME" "$PROJ_STAGE"

  echo "'$_PROJ_NAME' imported into playground."
}

project-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}

project-sync() {
  eval "$(setSimpleOptions FETCH_ONLY NO_WORK_MASTER_MERGE:M -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local CURR_BRANCH REMOTE_COMMITS MASTER_UPDATED
  CURR_BRANCH="$(workCurrentWorkBranch)"

  echo "Fetching remote histories..."
  git fetch upstream master:remotes/upstream/master
  if [[ "$CURR_BRANCH" != "master" ]]; then
    git fetch workspace master:remotes/workspace/master
    git fetch workspace "${WORK_BRANCH}:remotes/workspace/${WORK_BRANCH}"
  fi
  echo "Fetch done."

  if [[ "$FETCH_ONLY" == true ]]; then
    return 0
  fi

  cleanupMaster() {
    cd ${BASE_DIR}
    # heh, need this to always be 'true' or 'set -e' complains
    [[ ! -d _master ]] || git worktree remove _master
  }

  REMOTE_COMMITS=$(git rev-list --right-only --count master...upstream/master)
  if (( $REMOTE_COMMITS > 0 )); then
    echo "Syncing with upstream master..."
    cd "$BASE_DIR"
    if [[ "$CURR_BRANCH" != 'master' ]]; then
      (git worktree add _master master \
        || echoerrandexit "Could not create 'master' worktree.") \
      && { cd _master; git merge remotes/upstream/master; } || \
          { cleanupMaster; echoerrandexit "Could not merge upstream master to local master."; }
      MASTER_UPDATED=true
    else
      git pull upstream master \
        || echoerrandexit "There were problems merging upstream master to local master."
    fi
  fi
  echo "Upstream master synced."

  if [[ "$CURR_BRANCH" != "master" ]]; then
    REMOTE_COMMITS=$(git rev-list --right-only --count master...workspace/master)
    if (( $REMOTE_COMMITS > 0 )); then
      echo "Syncing with workspace master..."
      cd "$BASE_DIR/_master"
      git merge remotes/workspace/master || \
          { cleanupMaster; echoerrandexit "Could not merge upstream master to local master."; }
      MASTER_UPDATED=true
    fi
    echo "Workspace master synced."
    cleanupMaster

    REMOTE_COMMITS=$(git rev-list --right-only --count ${CURR_BRANCH}...workspace/${CURR_BRANCH})
    if (( $REMOTE_COMMITS > 0 )); then
      echo "Synching with workspace workbranch..."
      git pull workspace "${CURR_BRANCH}:remotes/workspace/${CURR_BRANCH}"
    fi
    echo "Workspace workbranch synced."

    if [[ -z "$NO_WORK_MASTER_MERGE" ]] && [[ "$MASTER_UPDATED" == true ]]; then
      echo "Merging master updates to work branch..."
      git merge master || echoerrandexit "Could not merge master updates to workbranch."
      echo "Master updates merged to workbranch."
    fi
  fi # on workbranach check
}

project-test() {
  local TMP
  # TODO https://github.com/Liquid-Labs/liq-cli/issues/27
  TMP=$(setSimpleOptions TYPES= NO_DATA_RESET:D GO_RUN= NO_START:S NO_SERVICE_CHECK:C -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -z "${NO_SERVICE_CHECK}" ]] \
     && ( [[ -z "${TEST_TYPES:-}" ]] \
       || echo "$TEST_TYPES" | grep -qE '(^|, *| +)int(egration)?(, *| +|$)' ); then
    requireEnvironment
    echo -n "Checking services... "
    if ! services-list --show-status --exit-on-stopped --quiet > /dev/null; then
      if [[ -z "${NO_START:-}" ]]; then
        services-start || echoerrandexit "Could not start services for testing."
      else
        echo "${red}necessary services not running.${reset}"
        echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\nliq packages test --types=unit\nliq services start"
      fi
    else
      echo "${green}looks good.${reset}"
    fi
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" runPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\nliq packages test --type=unit" $?
}
help-project() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}project${reset} <action>: Project configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}project${reset} <action>:
  ${underline}close${reset} [<project name>]: Closes (deletes from playground) either the
    current or named project after checking that all changes are committed and pushed. ${red_b}Alpha
    note:${reset} The tool does not currently check whether the project is linked with other projects.
  ${underline}import${reset} <package or URL>: Imports the indicated package into your
    playground. By default, the first arguments are understood as NPM package names and the URL
    will be retrieved via 'npm view'. If the '--url' option is specified, then the arguments are
    understood to be git repo URLs, which should contain a 'package.json' file in the repository
    root.
  ${underline}create${reset} [--type|-t <bare|lib|model|api|webapp>|| --template|-T <package name|git URL>] [--origin|-o <url>] <project name>:
    Creates a new Liquid project from one of the standard types or the given template URL. When the 'bare'
    type is specified, 'origin' must be specified. The project is initially cloned from the template, and then
    re-oriented to the project origin, unless the type is 'bare' in which case the project is cloned directly
    from the origin URL. Use 'liq project import' to import an existing project from a URL.
  ${underline}publish${reset}: Performs verification tests, updates package version, and publishes package.
  ${underline}sync${reset} [--fetch-only|-f] [--no-work-master-merge|-M]:
    Updates the remote master with new commits from upstream/master and, if currently on a work branch,
    workspace/master and workspace/<workbranch> and then merges those updates with the current workbranch (if any).
    '--fetch-only' will update the appropriate remote refs, and exit. --no-work-master-merge update the local master
    branch and pull the workspace workbranch, but skips merging the new master updates to the workbranch.
  ${underline}test${reset} [-t|--types <types>][-D|--no-data-reset][-g|--go-run <testregex>][--no-start|-S] [<name>]:
    Runs unit tests for all or the named packages in the current project.
    * 'types' may be 'unit' or 'integration' (=='int') or 'all', which is default.
      Multiple tests may be specified in a comma delimited list. E.g.,
      '-t=unit,int' is equivalent no type or '-t=""'.
    * '--no-start' will skip tryng to start necessary services.
    * '--no-data-reset' will cause the standard test DB reset to be skipped.
    * '--no-service-check' will skip checking service status. This is useful when
      re-running tests and the services are known to be running.
    * '--go-run' will only run those tests matching the provided regex (per go
      '-run' standards).
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
projectCheckIfInPlayground() {
  local PROJ_NAME="${1}"
  if [[ -d "${LIQ_PLAYGROUND}/$(orgsCurrentOrg --require)/${PROJ_NAME}" ]]; then
    echo "'$PROJ_NAME' is already in the playground."
    return 0
  else
    return 1
  fi
}

projectCheckGitAuth() {
  # if we don't supress the output, then we get noise even when successful
  ssh -qT git@github.com 2> /dev/null || if [ $? -ne 1 ]; then
    echoerrandexit "Could not connect to github; add your github key with 'ssh-add'."
  fi
}

projectsGetUpstreamUrl() {
  local PROJ_NAME="${1}"

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJ_NAME}"
  git config --get remote.upstream.url \
		|| echoerrandexit "Failed to get upstream remote URL for ${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJ_NAME}"
}

# expects STAGING and PROJ_STAGE to be set declared by caller(s)
projectResetStaging() {
  local PROJ_NAME="${1}"
  STAGING="${LIQ_PLAYGROUND}/$(orgsCurrentOrg --require)/.staging"
  rm -rf "${STAGING}"
  mkdir -p "${STAGING}"

  PROJ_STAGE="$PROJ_NAME"
  PROJ_STAGE="${PROJ_STAGE%.*}" # remove '.git' if present
  PROJ_STAGE="${STAGING}/${PROJ_STAGE}"
}

# Expects 'PROJ_STAGE' to be declared local by the caller.
projectClone() {
  local URL="${1}"

  projectCheckGitAuth

  local STAGING
  projectResetStaging $(basename "$URL")
  cd "$STAGING"

  git clone --quiet --origin upstream "${URL}" || echoerrandexit "Failed to clone."

  if [[ ! -d "$PROJ_STAGE" ]]; then
    echoerrandexit "Did not find expected project direcotry '$PROJ_STAGE' in staging."
  fi
}

projectHubWhoami() {
  local VAR_NAME="${1}"

  if [[ ! -f ~/.config/hub ]]; then
    echo "Need to establish GitHub connection..."
    hub api https://api.github.com/user > /dev/null
  fi
  local WHOAMI
  WHOAMI=$(cat ~/.config/hub | grep 'user:' | sed 's/^[[:space:]]*-[[:space:]]*user:[[:space:]]*//')
  eval $VAR_NAME=$WHOAMI
}

projectForkClone() {
  local URL="${1}"

  projectCheckGitAuth

  local PROJ_NAME ORG_URL GITHUB_NAME
  PROJ_NAME=$(basename "$URL")
  ORG_URL=$(dirname "$URL")
  projectHubWhoami GITHUB_NAME
  FORK_URL="$(echo "$ORG_URL" | sed 's|[a-zA-Z0-9-]*$||')/${GITHUB_NAME}/${PROJ_NAME}"

  local STAGING
  projectResetStaging $PROJ_NAME
  cd "$STAGING"

  echo -n "Checking for existing fork at '${FORK_URL}'... "
  git clone --dry-run --quiet --origin workspace "${FORK_URL}" \
  && { \
    # Be sure and exit on errors to avoid a failure here and then executing the || branch
    echo "found existing fork."
    cd $PROJ_STAGE || echoerrandexit "Did not find expected staging dir: $PROJ_STAGE"
    echo "Updating remotes..."
    git remote add upstream "$URL" || echoerrandexit "Problem setting upstream URL."
    git branch -u upstream/master master
  } \
  || { \
    echo "none found; cloning source."
    local GITHUB_NAME
    git clone --quiet --origin upstream "${URL}" || echoerrandexit "Could not clone source."
    cd $PROJ_STAGE
    echo "Creating fork..."
    hub fork --remote-name workspace
    git branch -u upstream/master master
  }
}

# Expects caller to have defined PROJ_NAME and PROJ_STAGE
projectMoveStaged() {
  local TRUNC_NAME CURR_ORG
  local PROJ_NAME="${1}"
  local PROJ_STAGE="${2}"
  TRUNC_NAME="$(dirname "$PROJ_NAME")"
  CURR_ORG=$(orgsCurrentOrg --require)
  mkdir -p "${LIQ_PLAYGROUND}/${CURR_ORG}/${TRUNC_NAME}"
  mv "$PROJ_STAGE" "$LIQ_PLAYGROUND/${CURR_ORG}/${TRUNC_NAME}" \
    || echoerrandexit "Could not moved staged '$PROJ_NAME' to playground. See above for details."
}

requirements-provided-services() {
  requireCatalystfile
  requirePackage
}

provided-services-add() {
  # TODO: check for global to allow programatic use
  local SERVICE_NAME="${1:-}"
  if [[ -z "$SERVICE_NAME" ]]; then
    require-answer "Service name: " SERVICE_NAME
  fi

  local SERVICE_DEF=$(cat <<EOF
{
  "name": "${SERVICE_NAME}",
  "interface-classes": [],
  "platform-types": [],
  "purposes": [],
  "ctrl-scripts": [],
  "params-req": [],
  "params-opt": [],
  "config-const": {}
}
EOF
)

  function selectOptions() {
    local OPTION OPTIONS
    local OPTIONS_NAME="$1"; shift
    PS3="$1"; shift
    local OPTS_ONLY="$1"; shift
    local ENUM_CHOICES="$@"

    if [[ -n "$OPTS_ONLY" ]]; then
      selectDoneCancel OPTIONS ENUM_CHOICES
    else
      selectDoneCancelAnyOther OPTIONS ENUM_CHOICES
    fi
    for OPTION in $OPTIONS; do
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"$OPTIONS_NAME\": (.\"$OPTIONS_NAME\" + [\"$OPTION\"]) }"`
    done
  }

  selectOptions 'interface-classes' 'Interface class: ' '' "$STD_IFACE_CLASSES"
  selectOptions 'platform-types' 'Platform type: ' '' "$STD_PLATFORM_TYPES"
  selectOptions 'purposes' 'Purpose: ' '' "$STD_ENV_PURPOSES"
  selectOptions 'ctrl-scripts' "Control script: " true `find "${BASE_DIR}/bin/" -type f -not -name '*~' -prune -execdir echo '{}' \;`

  defineParameters SERVICE_DEF

  PACKAGE=`echo "$PACKAGE" | jq ".catalyst + { \"provides\": (.catalyst.provides + [$SERVICE_DEF]) }"`
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

provided-services-delete() {
  if (( $# == 0 )); then
    echoerrandexit "Must specify service names to delete."
  fi

  local SERV_NAME
  for SERV_NAME in "$@"; do
    if echo "$PACKAGE" | jq -e "(.catalyst.provides | map(select(.name == \"$SERV_NAME\")) | length) == 0" > /dev/null; then
      echoerr "Did not find service '$SERV_NAME' to delete."
    fi
    PACKAGE=`echo "$PACKAGE" | jq "setpath([.catalyst.requires]; .catalyst.provides | map(select(.name != \"$SERV_NAME\")))"`
  done
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

provided-services-list() {
  echo $PACKAGE | jq --raw-output ".catalyst.provides | .[] | .\"name\""
}

provided-services-show() {
  while [[ $# -gt 0 ]]; do
    if ! echo $PACKAGE | jq -e "(.catalyst) and (.catalyst.provides) and (.catalyst.provides | .[] | select(.name == \"$1\"))" > /dev/null; then
      echoerr "No such service '$1'."
    else
      echo "$1:"
      echo
      echo $PACKAGE | jq ".catalyst.provides | .[] | select(.name == \"$1\")"
      if [[ $# -gt 1 ]]; then
        echo
        read -p "Hit enter to continue to '$2'..."
      fi
    fi
    shift
  done
}
help-provided-services() {
  local PREFIX="${1:-}"

handleSummary "${PREFIX}${red_b}(deprated)${reset} ${cyan_u}provided-services${reset} <action>: Manages package service declarations." || cat <<EOF
${PREFIX}${cyan_u}provided-services${reset} <action>:
  ${underline}list${reset} [<package name>...]: Lists the services provided by the named packages or
    all packages in the current repository.
  ${underline}add${reset} [<package name>]: Add a provided service.
  ${underline}delete${reset} [<package name>] <name>: Deletes a provided service.

${red_b}Deprated: These commands will migrate under 'project'.${reset}

The 'add' action works interactively. Non-interactive alternatives will be
provided in future versions.

The ${underline}package name${reset} parameter in the 'add' and 'delete' actions is optional if
there is a single package in the current repository.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
# source ./provided-services/lib.sh

requirements-required-services() {
  requirePackage
}

required-services-add() {
  local IFACE_CLASS
  if [[ $# -eq 0 ]]; then # interactive add
    local NEW_SERVICES="$STD_IFACE_CLASSES"
    local EXISTING_SERVICES=$(required-services-list)
    local EXISTING_SERVICE
    for EXISTING_SERVICE in $EXISTING_SERVICES; do
      NEW_SERVICES=`echo "$NEW_SERVICES" | sed -Ee "s/(^| +)${EXISTING_SERVICE}( +|\$)/\1\2/"`
    done
    local REQ_SERVICES
    PS3="Required service interface: "
    selectOneCancelOther REQ_SERVICES NEW_SERVICES
    for IFACE_CLASS in $REQ_SERVICES; do
      reqServDefine "$IFACE_CLASS"
    done
  else
    while (($# > 0)); do
      IFACE_CLASS="$1"; shift
      reqServDefine "$IFACE_CLASS"
    done
  fi
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

required-services-delete() {
  if [[ $# -eq 0 ]]; then # interactive delete
    local DEL
    while [[ $DEL != '...quit...' ]]; do
      local OPTIONS=`required-services-list`
      # TODO: rework to support canctel; add and use 'selectDone'?
      if [[ -z "$OPTIONS" ]]; then
        echo "Nothing left to delete."
        DEL='...quit...'
      else
        select DEL in '<done>' $OPTIONS; do
          case $DEL in
            '<done>')
              DEL='...quit...'
              break;;
            *)
              required-services-delete "$DEL"
              PACKAGE=`cat "$PACKAGE_FILE"`
              break;;
          esac
        done # select
      fi
    done # while
  else
    while (($# > 0)); do
      local IFACE_CLASS="$1"; shift
      if ! echo "$PACKAGE" | jq -e "(.catalyst.requires | map(select(.iface == \"$IFACE_CLASS\")) | length) > 0" > /dev/null; then
        echoerr "No such requirement '$IFACE_CLASS' found."
      else
        PACKAGE=`echo "$PACKAGE" | jq ".catalyst + { requires: [ .catalyst.requires | .[] | select(.iface != \"$IFACE_CLASS\") ] }"`
      fi
    done
  fi
  # cleanup .catalyst.requires if empty
  if echo "$PACKAGE" | jq -e "(.catalyst.requires | length) == 0" > /dev/null; then
    PACKAGE=`echo "$PACKAGE" | jq "del(.catalyst.requires)"`
  fi
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

required-services-list() {
  if echo "$PACKAGE" | jq -e "(.catalyst.requires | length) > 0" > /dev/null; then
    echo "$PACKAGE" | jq --raw-output ".catalyst.requires | .[] | .iface | @sh" | tr -d "'"
  fi
}
help-required-services() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${red_b}(deprated)${reset} ${cyan_u}required-services${reset} <action>: Configures runtime service requirements." || cat <<EOF
${PREFIX}${cyan_u}required-services${reset} <action>:"
  ${underline}list${reset} [<package name>...]: Lists the services required by the named packages or
    all packages in the current repository.
  ${underline}add${reset} [<package name>]: Add a required service.
  ${underline}delete${reset} [<package name>] <name>: Deletes a required service.

${red_b}Deprated: These commands will migrate under 'project'.${reset}

The 'add' action works interactively. Non-interactive alternatives will be
provided in future versions.

The ${underline}package name${reset} parameter in the 'add' and 'delete' actions is optional if
there is a single package in the current repository.
EOF

  test -n "${SUMMARY_ONLY:-}" || helperHandler "$PREFIX" helpHelperAlphaPackagesNote
}
reqServDefine() {
  local IFACE_CLASS="$1"
  local SERVICE_DEF=$(cat <<EOF
{
  "iface": "${IFACE_CLASS}",
  "params-req": [],
  "params-opt": [],
  "config-const": {}
}
EOF
)

  defineParameters SERVICE_DEF

  PACKAGE=`echo "$PACKAGE" | jq ".catalyst + { \"requires\" : ( .catalyst.requires + [ $SERVICE_DEF ] ) }"`
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

requirements-services() {
  requireEnvironment
}

services-list() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions SHOW_STATUS PORCELAIN EXIT_ON_STOPPED QUIET -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  local GET_STATUS=''
  if [[ -n "$SHOW_STATUS" ]] || [[ -n "$EXIT_ON_STOPPED" ]]; then
    # see https://unix.stackexchange.com/a/88338/84520
    GET_STATUS='local _SERV_STATUS; _SERV_STATUS=$(runServiceCtrlScript $SERV_SCRIPT status);'
  fi

  local OUTPUT='echo "$PROCESS_NAME";'
  if [[ -n "$QUIET" ]]; then
    OUTPUT=''
  else
    if [[ -n "$SHOW_STATUS" ]]; then
      if [[ -n "$PORCELAIN" ]]; then
        OUTPUT='echo "${PROCESS_NAME}:${_SERV_STATUS}";'
      else
        OUTPUT='( test "$_SERV_STATUS" == "running" && echo "${PROCESS_NAME} (${green}${_SERV_STATUS}${reset})" ) || echo "$PROCESS_NAME (${yellow}${_SERV_STATUS}${reset})";'
      fi
    fi
  fi

  local CHECK_EXIT=''
  if [[ -n "$EXIT_ON_STOPPED" ]]; then
    CHECK_EXIT='test "$_SERV_STATUS" == "running" || return 27;'
  fi

  local MAIN # see https://unix.stackexchange.com/a/88338/84520
  MAIN="${GET_STATUS}${OUTPUT}${CHECK_EXIT}"

  runtimeServiceRunner "$MAIN" '' "$@"
}

services-start() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions PASSTHRU= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  # TODO: check status before starting
  local MAIN # see https://unix.stackexchange.com/a/88338/84520
  MAIN=$(cat <<'EOF'
    # rm -f "${SERV_LOG}" "${SERV_ERR}"

    if services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}"; then
      echo "${PROCESS_NAME} already running." >&2
    else
      echo "Starting ${PROCESS_NAME}..."
      runServiceCtrlScript $SERV_SCRIPT start ${PASSTHRU} \
        || echoerrandexit "Attempt to start service '${PROCESS_NAME}' failed."
      sleep 1
      if [[ -f "${SERV_ERR}" ]] && [[ `wc -l "${SERV_ERR}" | awk '{print $1}'` -gt 0 ]]; then
        cat "${SERV_ERR}"
        echoerr "Possible errors while starting ${PROCESS_NAME}. See error log above."
      fi
      services-list -s "${PROCESS_NAME}"
    fi
EOF
)
  runtimeServiceRunner "$MAIN" '' "$@"
}

services-stop() {
  # TODO: check status before stopping
  local MAIN # see https://unix.stackexchange.com/a/88338/84520
  MAIN=$(cat <<'EOF'
    if ! services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}"; then
      echo "${PROCESS_NAME} already stopped." >&2
    else
      echo "Stopping ${PROCESS_NAME}..."
      runServiceCtrlScript $SERV_SCRIPT stop
      sleep 1
      services-list -s "${PROCESS_NAME}"
    fi
EOF
)
  local REVERSE_ORDER=true
  runtimeServiceRunner "$MAIN" '' "$@"
}

services-restart() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions NO_START:S -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  local MAIN # see https://unix.stackexchange.com/a/88338/84520
  MAIN=$(cat <<'EOF'
    echo "Restarting ${PROCESS_NAME}..."
    if services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}"; then
      runServiceCtrlScript $SERV_SCRIPT restart
    else
      if [[ -n "$NO_START" ]]; then
        echowarn "'${PROCESS_NAME}' currently stopped; skipping."
        # even from the 'eval', this will affect the outer loop and go onto the
        # next service (if any) to restart
        continue
      fi
      echowarn "'${PROCESS_NAME}' currently stopped; starting..."
      runServiceCtrlScript $SERV_SCRIPT start
    fi
    sleep 1
    services-list -s "${PROCESS_NAME}"
EOF
)
  runtimeServiceRunner "$MAIN" '' "$@"
}

# TODO: support remote logs!
logMain() {
  local DESC="$1"
  local SUFFIX="$2"
  local FILE_NAME # see https://unix.stackexchange.com/a/88338/84520
  FILE_NAME='${LIQ_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}.'${SUFFIX}

  cat <<EOF
    echo "${FILE_NAME}"
    if [[ -f "${FILE_NAME}" ]]; then
      if stat -f'%z' ${FILE_NAME} | grep -qE '^\s*0\s*\$'; then
        echo "Error log for '${green}\${PROCESS_NAME}${reset}' is empty."
        pressAnyKeyToContinue
        echo
      else
        ( echo -e "Local ${DESC} for '${green}\${PROCESS_NAME}${reset}:\n<hit 'q' to adavance to next logs, if any.>\n" && \
          # tail -f "${FILE_NAME}" )
          cat "${FILE_NAME}" ) | less -R
      fi
    else
      echo "No local logs for '${red}\${PROCESS_NAME}${reset}'."
      echo "If this is a remote service, logs may be available through the service platform."
      pressAnyKeyToContinue
      echo
    fi
EOF
}

services-log() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions CLEAR -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -n "$CLEAR" ]]; then
    runtimeServiceRunner 'rm -f "${LIQ_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}.log"' '' "$@"
  else
    runtimeServiceRunner "$(logMain log log)" '' "$@"
  fi
}

services-err-log() {
  runtimeServiceRunner "$(logMain 'error log' 'err')" '' "$@"
}

services-connect() {
  if (( $# != 1 )); then
    contextHelp
    echoerrandexit "Connect requires specification of a single service."
  fi

  local MAIN # see https://unix.stackexchange.com/a/88338/84520
  MAIN=$(cat <<'EOF'
    if runServiceCtrlScript --no-env $SERV_SCRIPT connect-check 2> /dev/null; then
      if [[ -n "$SERV_SCRIPTS_COOKIE" ]]; then
        echoerrandexit "Multilpe connection points found; try specifying service process."
      fi
      SERV_SCRIPTS_COOKIE='found'
      services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}" \
        || echoerrandexit "Can't connect to stopped '${SERV_IFACE}.${SCRIPT_NAME}'."
      runServiceCtrlScript $SERV_SCRIPT connect
    fi
EOF
)
  # After we've tried to connect with each process, check if anything worked
  local ALWAYS_RUN # see https://unix.stackexchange.com/a/88338/84520
  ALWAYS_RUN=$(cat <<'EOF'
    if (( $SERV_SCRIPT_COUNT == ( $SERV_SCRIPT_INDEX + 1 ) )) && [[ -z "$SERV_SCRIPTS_COOKIE" ]]; then
      echoerrandexit "${PROCESS_NAME}' does not support connections."
    fi
EOF
)

  runtimeServiceRunner "$MAIN" "$ALWAYS_RUN" "$@"
}
help-services() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}services${reset} <action>: Manages active runtime services." || cat <<EOF
${PREFIX}${cyan_u}services${reset} :
  ${underline}list${reset} [-s|--show-status] [<service spec>...] : Lists all or named runtime
    services for the current environment and their status.
  ${underline}start${reset} [<service spec>...] : Starts all or named services for the current
    environment.
  ${underline}stop${reset} [<service spec>...] : Stops all or named services for the current
    environment.
  ${underline}log${reset} [<service spec>...] : Displays logs for all or named services for the
    current environment.
  ${underline}err-log${reset} [<service spec>...] : Displays error logs for all or named services
    for the current environment.
  ${underline}connect${reset} [-c|--capabilities] <service spec> : Connects to the named service, if
    possible. The '--capabilities' option will print 'interactive', and/or
    'pipe', separated by newlines, to indicate the capabilities of the specified
    connection.

Where '${cyan}service spec${reset}' is either a service interface class or
<service iface>.<service name>. A service may be selected by it's major type, so
'sql' woud select environment services 'sql' and 'sql-mysql' (etc.). Thus,
'liq services connect sql' may be used to connect to both MySQL,
Postgres, etc. DBs.
EOF
}
# ctrlScriptEnv generates the environment settings and required parameters list
# for control scripts.
#
# The method will set 'EXPORT_PARAMS', which should be declared local by the
# caller.
#
# The method will normally echo an error and force an exit
# if a required parameter is not found. If '_SKIP_CURR_ENV_FILE' is set to any
# value, this check will be skipped and the variable will be set to blank. This
# is in support of internal flows which may which may define a subset of the
# required parameters in order to initiate an operation that only requires that
# subset.
ctrlScriptEnv() {
  check-param-err() {
    local REQ_PARAM="${1}"; shift
    local DESC="${1}"; shift

    if [[ -z "${!REQ_PARAM:-}" ]] && [[ -z "${_SKIP_CURR_ENV_FILE:-}" ]]; then
      echoerrandexit "No value for ${DESC} '$REQ_PARAM'. Try updating the environment:\nliq environment update -n"
    fi
  }

  EXPORT_PARAMS=PACKAGE_NAME$'\n'BASE_DIR$'\n'LIQ_ENV_LOGS$'\n'SERV_NAME$'\n'SERV_IFACE$'\n'PROCESS_NAME$'\n'SERV_LOG$'\n'SERV_ERR$'\n'PID_FILE$'\n'REQ_PARAMS

  local REQ_PARAM
  for REQ_PARAM in $REQ_PARAMS; do
    check-param-err "$REQ_PARAM" "service-source parameter"
    list-add-item EXPORT_PARAMS "${REQ_PARAM}"
  done

  local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
  local ADD_REQ_PARAMS=$((echo "$PACKAGE" | jq -e --raw-output ".catalyst.requires | .[] | select(.iface==\"$SERV_IFACE\") | .\"params-req\" | @sh" 2> /dev/null || echo '') | tr -d "'")
  for REQ_PARAM in $ADD_REQ_PARAMS; do
    check-param-err "$REQ_PARAM" "service-local parameter"
    list-add-item EXPORT_PARAMS "${REQ_PARAM}"
  done

  for REQ_PARAM in $(getConfigConstants "${SERV_IFACE}"); do
    # TODO: ideally we'd load constants from the package.json, not environment.
    check-param-err "$REQ_PARAM" "config const"
    list-add-item EXPORT_PARAMS "${REQ_PARAM}"
  done
}

runServiceCtrlScript() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions NO_ENV -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  local SERV_SCRIPT="$1"; shift

  if [[ -z $NO_ENV ]]; then
    local EXPORT_PARAMS
    local REQ_PARAMS
    REQ_PARAMS=$(getRequiredParameters "$SERVICE_KEY")
    ctrlScriptEnv

    # The script might be our own or an installed dependency.
    if [[ -e "${BASE_DIR}/bin/${SERV_SCRIPT}" ]]; then
      ( export $EXPORT_PARAMS; "${BASE_DIR}/bin/${SERV_SCRIPT}" "$@" )
    else
      ( export $EXPORT_PARAMS; cd "${BASE_DIR}"; npx --no-install $SERV_SCRIPT "$@" )
    fi
  else
    if [[ -e "${BASE_DIR}/bin/${SERV_SCRIPT}" ]]; then
      "${BASE_DIR}/bin/${SERV_SCRIPT}" "$@"
    else
      ( cd "${BASE_DIR}"; npx --no-install $SERV_SCRIPT "$@" )
    fi
  fi
}

testServMatch() {
  local KEY="$1"; shift
  if [[ -z "${1:-}" ]]; then
    # if there's nothing to match, then everything matches
    return 0
  fi
  local CANDIDATE
  for CANDIDATE in "$@"; do
    # Match on the interface class only; trim the script name.
    CANDIDATE=`echo $CANDIDATE | sed -Ee 's/\..+//'`
    # Unlike the 'provides' matching, we match only on major-interface types.
    KEY=`echo $KEY | sed -Ee 's/-.+//'`
    CANDIDATE=`echo $CANDIDATE | sed -Ee 's/-.+//'`
    if [[ "$KEY" ==  "$CANDIDATE" ]]; then
      return 0
    fi
  done
  return 1
}

testScriptMatch() {
  local KEY="$1"; shift
  if [[ -z "${1:-}" ]]; then
    # if there's nothing to match, then everything matches
    return 0
  fi
  local CANDIDATE
  for CANDIDATE in "$@"; do
    # If script bound and match or not script bound
    if [[ "$CANDIDATE" != *"."* ]] || [[ "$KEY" == `echo $CANDIDATE | sed -Ee 's/^[^.]+\.//'` ]]; then
      return 0
    fi
  done
  return 1
}

runtimeServiceRunner() {
  local _MAIN="$1"; shift
  local _ALWAYS_RUN="$1"; shift

  if [[ -z ${_SKIP_CURR_ENV_FILE:-} ]]; then
    source "${CURR_ENV_FILE}"
  fi
  declare -a ENV_SERVICES
  if [[ -n "${CURR_ENV_SERVICES:-}" ]]; then
    if [[ -z "${REVERSE_ORDER:-}" ]]; then
      ENV_SERVICES=("${CURR_ENV_SERVICES[@]}")
    else
      local I=$(( ${#CURR_ENV_SERVICES[@]} - 1 ))
      while (( $I >= 0 )); do
        ENV_SERVICES+=("${CURR_ENV_SERVICES[$I]}")
        I=$(( $I - 1 ))
      done
    fi
  fi
  local UNMATCHED_SERV_SPECS="$@"

  # TODO: Might be worth tweaking interactive-CLI by passing in vars indicating whether working on single or multiple, 'item' number and total, and whether current item is first, middle or last.
  local SERVICE_KEY
  for SERVICE_KEY in ${ENV_SERVICES[@]:-}; do
    local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
    local MAJOR_SERV_IFACE=`echo "$SERV_IFACE" | cut -d- -f1`
    local MINOR_SERV_IFACE=`echo "$SERV_IFACE" | cut -d- -f2`
    if testServMatch "$SERV_IFACE" "$@"; then
      local SERV_PACKAGE_NAME=`echo "$SERVICE_KEY" | cut -d: -f2`
      local SERV_NAME=`echo "$SERVICE_KEY" | cut -d: -f3`
      local SERV_PACKAGE
      getPackageDef SERV_PACKAGE "$SERV_PACKAGE_NAME"
      local SERV_SCRIPT
      local SERV_SCRIPTS=`echo "$SERV_PACKAGE" | jq --raw-output ".catalyst.provides | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-scripts\" | @sh" 2> /dev/null | tr -d "'"`
      [[ -n $SERV_SCRIPTS ]] || echoerrandexit "$SERV_PACKAGE_NAME package.json does not properly define 'catalyst.provides.$SERV_NAME.ctrl-scripts'."
      local SERV_SCRIPT_ARRAY=( $SERV_SCRIPTS )
      local SERV_SCRIPT_COUNT=${#SERV_SCRIPT_ARRAY[@]}
      # give the process scripts their proper, self-declared order
      if (( $SERV_SCRIPT_COUNT > 1 )); then
        for SERV_SCRIPT in $SERV_SCRIPTS; do
          local SCRIPT_ORDER # see https://unix.stackexchange.com/a/88338/84520
          SCRIPT_ORDER=$(runServiceCtrlScript --no-env $SERV_SCRIPT myorder)
          [[ -n $SCRIPT_ORDER ]] || echoerrandexit "Could not determine script run order."
          SERV_SCRIPT_ARRAY[$SCRIPT_ORDER]="$SERV_SCRIPT"
        done
      fi

      local SERV_SCRIPT_INDEX=0
      local SERV_SCRIPTS_COOKIE=''
      for SERV_SCRIPT in ${SERV_SCRIPT_ARRAY[@]}; do
        local SCRIPT_NAME # see https://unix.stackexchange.com/a/88338/84520
        SCRIPT_NAME=$(runServiceCtrlScript --no-env $SERV_SCRIPT name)
        local PROCESS_NAME="${SERV_IFACE}"
        if (( $SERV_SCRIPT_COUNT > 1 )); then
          PROCESS_NAME="${SERV_IFACE}.${SCRIPT_NAME}"
        fi
        local CURR_SERV_SPECS=''
        local SPEC_CANDIDATE
        for SPEC_CANDIDATE in "$@"; do
          if testServMatch "$SERV_IFACE" "$SPEC_CANDIDATE"; then
            list-add-item CURR_SERV_SPECS "$SPEC_CANDIDATE"
          fi
          # else it's a spec for another service interface
        done
        if testScriptMatch "$SCRIPT_NAME" "$CURR_SERV_SPECS"; then
          local SERV_OUT_BASE="${LIQ_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}"
          local SERV_LOG="${SERV_OUT_BASE}.log"
          local SERV_ERR="${SERV_OUT_BASE}.err"
          local PID_FILE="${SERV_OUT_BASE}.pid"
          eval "$_MAIN" || return $?

          # Again, notice that the service match is only on the major interface class.
          UNMATCHED_SERV_SPECS=`echo $UNMATCHED_SERV_SPECS | sed -Ee 's/(^| +)'${MAJOR_SERV_IFACE}'(-[^ ]+)?\.'${SCRIPT_NAME}'( +|$)//'`
        fi
        if [[ -n "${_ALWAYS_RUN:-}" ]]; then
          eval "$_ALWAYS_RUN"
        fi
        SERV_SCRIPT_INDEX=$(( $SERV_SCRIPT_INDEX + 1))
      done
      UNMATCHED_SERV_SPECS=`echo $UNMATCHED_SERV_SPECS | sed -Ee 's/(^| +)'$MAJOR_SERV_IFACE'(-[^ ]+)?( +|$)//'`
    fi
  done

  local UNMATCHED_SERV_SPEC
  for UNMATCHED_SERV_SPEC in $UNMATCHED_SERV_SPECS; do
    echoerr "Did not match service spec '$UNMATCHED_SERV_SPEC'."
  done
}

requirements-work() {
  findBase
}

work-backup() {
  eval "$(setSimpleOptions TEST -- "$@")"

  if [[ "$TEST" != true ]]; then
    local OLD_MSG
    OLD_MSG="$(git log -1 --pretty=%B)"
    git commit --amend -m "${OLD_MSG} [no ci]"
  fi
  # TODO: retrive and use workbranch name instead
  git push workspace HEAD
}

work-diff-master() {
  git diff $(git merge-base master HEAD)..HEAD "$@"
}

work-close() {
  eval "$(setSimpleOptions TEST NO_SYNC -- "$@")"
  source "${LIQ_WORK_DB}/curr_work"

  local PROJECTS
  if (( $# > 0 )); then
    PROJECTS="$@"
  else
    PROJECTS="$INVOLVED_PROJECTS"
  fi

  local PROJECT CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  # first, do the checks
  for PROJECT in $PROJECTS; do
    PROJECT=$(workConvertDot "$PROJECT")
    local CURR_BRANCH
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJECT}"
    CURR_BRANCH=$(workCurrentWorkBranch)

    if [[ "$CURR_BRANCH" != "$WORK_BRANCH" ]]; then
      echoerrandexit "Local project '$PROJECT' repo branch does not match expected work branch."
    fi

    requireCleanRepo "$PROJECT"
  done

  # now actually do the closures
  for PROJECT in $PROJECTS; do
    PROJECT=$(workConvertDot "$PROJECT")
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJECT}"
    local CURR_BRANCH
    CURR_BRANCH=$(git branch | (grep '*' || true) | awk '{print $2}')

    git checkout master
    git push workspace "${WORK_BRANCH}:${WORK_BRANCH}" \
      || echoerrandexit "Could not push '${WORK_BRANCH}' to workspace; refusing to close without backing up."
    git branch -qd "$WORK_BRANCH" \
      || ( echoerr "Could not delete local '${WORK_BRANCH}'. This can happen if the branch was renamed." \
          && false)
    list-rm-item INVOLVED_PROJECTS "$PROJECT" # this cannot be done in a subshell
    workUpdateWorkDb
		if [[ -z "$NO_SYNC" ]]; then
			project-sync
		fi
    # Notice we don't close the workspace branch. It may be involved in a PR and, generally, we don't care if the
    # workspace gets a little messy. TODO: reference workspace cleanup method here when we have one.
  done

  # If all involved projects are closed, then our work is done.
  if [[ -z "${INVOLVED_PROJECTS}" ]]; then
    rm "${LIQ_WORK_DB}/curr_work"
    rm "${LIQ_WORK_DB}/${WORK_BRANCH}"
  fi
}

work-edit() {
  # TODO: make editor configurable
  local EDITOR_CMD='atom'
  local OPEN_PROJ_CMD="${EDITOR_CMD} ."
  cd "${BASE_DIR}" && ${OPEN_PROJ_CMD}
}

work-ignore-rest() {
  pushd "${BASE_DIR}" > /dev/null
  touch .gitignore
  # first ignore whole directories
  for i in `git ls-files . --exclude-standard --others --directory`; do
    echo "${i}" >> .gitignore
  done
  popd > /dev/null
}

work-involve() {
  local PROJECT_NAME WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS CURR_ORG
  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "There is no active unit of work to involve. Try:\nliq work resume"
  fi

  CURR_ORG="$(orgsCurrentOrg --require)"

  if (( $# == 0 )) && [[ -n "$BASE_DIR" ]]; then
    requirePackage
    PROJECT_NAME=$(echo "$PACKAGE" | jq --raw-output '.name | @sh' | tr -d "'")
  else
    exactUserArgs PROJECT_NAME -- "$@"
    test -d "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJECT_NAME}" \
      || echoerrandexit "Invalid project name '$PROJECT_NAME'. Perhaps it needs to be imported? Try:\nliq playground import <git URL>"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local BRANCH_NAME=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
  requirePackage # used later if auto-linking

  cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJECT_NAME}"
  if git branch | grep -qE "^\*? *${BRANCH_NAME}\$"; then
    echowarn "Found existing work branch '${BRANCH_NAME}' in project ${PROJECT_NAME}. We will use it. Please fix manually if this is unexpected."
    git checkout -q "${BRANCH_NAME}" || echoerrandexit "There was a problem checking out the work branch. ($?)"
  else
    git checkout -qb "${BRANCH_NAME}" || echoerrandexit "There was a problem creating the work branch. ($?)"
    git push --set-upstream workspace ${BRANCH_NAME}
    echo "Created work branch '${BRANCH_NAME}' for project '${PROJECT_NAME}'."
  fi

  list-add-item INVOLVED_PROJECTS "${PROJECT_NAME}"
  workUpdateWorkDb

  local PRIMARY_PROJECT=$INVOLVED_PROJECTS
  if [[ "$PRIMARY_PROJECT" != "$PROJECT_NAME" ]]; then
    local NEW_PACKAGE_FILE
    while read NEW_PACKAGE_FILE; do
      local NEW_PACKAGE_NAME
      NEW_PACKAGE_NAME=$(cat "$NEW_PACKAGE_FILE" | jq --raw-output '.name | @sh' | tr -d "'")
      if echo "$PACKAGE" | jq -e ".dependencies and ((.dependencies | keys | any(. == \"${NEW_PACKAGE_NAME}\"))) or (.devDependencies and (.devDependencies | keys | any(. == \"${NEW_PACKAGE_NAME}\")))" > /dev/null; then
        :
        # Currently disabled
        # packages-link "${PROJECT_NAME}:${NEW_PACKAGE_NAME}"
      fi
    done < <(find "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJECT_NAME}" -name "package.json" -not -path "*node_modules/*")
  fi
}

work-issues() {
  local TMP
  TMP=$(setSimpleOptions LIST ADD= REMOVE= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current work selected; cannot list issues."
  fi
  source "${LIQ_WORK_DB}/curr_work"

  BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

  if [[ -n "$ADD" ]]; then
    local NEW_ISSUE NEW_ISSUES
    NEW_ISSUES="$(workProcessIssues "$ADD" "$BUGS_URL")"
    for NEW_ISSUE in $NEW_ISSUES; do
      list-add-item WORK_ISSUES "$NEW_ISSUE"
    done
  fi
  if [[ -n "$REMOVE" ]]; then
    local RM_ISSUE RM_ISSUES
    RM_ISSUES="$(workProcessIssues "$REMOVE" "$BUGS_URL")"
    for RM_ISSUE in $RM_ISSUES; do
      list-rm-item WORK_ISSUES "$RM_ISSUE"
    done
  fi
  if [[ -n "$LIST" ]] || [[ -z "$LIST" ]] && [[ -z "$ADD" ]] && [[ -z "$REMOVE" ]]; then
    echo "$WORK_ISSUES"
  fi
  if [[ -n "$ADD" ]] || [[ -n "$REMOVE" ]]; then
    workUpdateWorkDb
  fi
}

work-list() {
  local WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  # find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;
  for i in $(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;); do
    echo "${LIQ_WORK_DB}/${i}"
    source "${LIQ_WORK_DB}/${i}"
    echo -e "* ${yellow_b}${WORK_DESC}${reset}: started ${bold}${WORK_STARTED}${reset} by ${bold}${WORK_INITIATOR}${reset}"
  done
}

work-merge() {
  # TODO: https://github.com/Liquid-Labs/liq-cli/issues/57 support org-level config to default allow unforced merge
  eval "$(setSimpleOptions FORCE CLOSE PUSH_UPSTREAM -- "$@")"

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"

  if [[ "${PUSH_UPSTREAM}" == true ]] && [[ "$FORCE" != true ]]; then
    echoerrandexit "'work merge --push-upstream' is not allowed by default. You can use '--force', but generally you will either want to configure the project to enable non-forced upstream merges or try:\nliq work submit"
  fi

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "'merge' can only be perfomred on the current unit of work. Try:\nliq work select"
  fi

  local WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  source "${LIQ_WORK_DB}/curr_work"

  if [[ -z "$INVOLVED_PROJECTS" ]]; then
    echoerrandexit "No projects involved in the current unit of work '${WORK_BRANCH}'."
  fi
  if (( $# == 0 )) && ! yesno "Are you sure want to merge the entire unit of work? (y/N)" 'N'; then
    return
  fi

  local TO_MERGE="$@"
  if [[ -z "$TO_MERGE" ]]; then
    TO_MERGE="$INVOLVED_PROJECTS"
  fi

  local TM
  for TM in $TO_MERGE; do
    TM=$(workConvertDot "$TM")
    if ! echo "$INVOLVED_PROJECTS" | grep -qE '(^| +)'$TM'( +|$)'; then
      echoerrandexit "Project '$TM' not in the current unit of work."
    fi
    local CURR_BRANCH
    CURR_BRANCH=$(git branch | (grep '*' || true) | awk '{print $2}')
    if [[ "$CURR_BRANCH" != master ]] && [[ "$CURR_BRANCH" != "$WORK_BRANCH" ]]; then
      echoerrandexit "Project '$TM' is not currently on the expected workbranch '$WORK_BRANCH'. Please fix and re-run."
    fi
    requireCleanRepo "$TM"
  done

  for TM in $TO_MERGE; do
    TM=$(workConvertDot "$TM")
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${TM}"
    local SHORT_STAT=`git diff --shortstat master ${WORK_BRANCH}`
    local INS_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ insertion' | awk '{print $1}' || true`
    INS_COUNT=${INS_COUNT:-0}
    local DEL_COUNT=`echo "${SHORT_STAT}" | egrep -Eio -e '\d+ deletion' | awk '{print $1}' || true`
    DEL_COUNT=${DEL_COUNT:-0}
    local DIFF_COUNT=$(( $INS_COUNT - $DEL_COUNT ))

    # TODO: don't assume the merge closes anything; may be merging for different reasons. Accept '--no-close' option or
    # '--closes=x,y,z' where x etc. are alread associated to the unit of work
    local CLOSE_MSG BUGS_URL
    BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")
    if [[ -z "$WORK_ISSUES" ]]; then
      echowarn "No issues associated with this unit of work."
    elif [[ -n "$BUGS_URL" ]]; then
      local ISSUE
      for ISSUE in $WORK_ISSUES; do
        if [[ $ISSUE == $BUGS_URL* ]]; then
          local NUMBER=${ISSUE/$BUGS_URL/}
          NUMBER=${NUMBER/\//}
          list-add-item CLOSE_MSG "closes #${NUMBER}"
        fi
      done
    else
      echowarn "No issues URL associated with this project."
    fi

    cleanupMaster() {
      cd ${BASE_DIR}
      git worktree remove _master
    }

    cd ${BASE_DIR}
    # if [[ "${WORK_BRANCH}" != master ]]; then
    #  git checkout -q master \
    #    || echoerrandexit "Could not switch to master branch in project '$TM'."
    # fi
    (git worktree add _master master \
      || echoerrandexit "Could not create 'master' worktree.") \
    && (cd _master; git pull upstream master:master \
        || (cleanupMaster; echoerrandexit $echoerrandexit "Could not update local master from upstream for '$TM'.")) \
    && (cd _master; git merge --no-ff -qm "merge branch $WORK_BRANCH" "$WORK_BRANCH" -m "$CLOSE_MSG" \
        || (cleanupMaster; echoerrandexit "Problem merging '${WORK_BRANCH}' with 'master' for project '$TM'. ($?)")) \
    && (cleanupMaster || echoerr "There was a problem removing '_master' worktree.") \
    && ( (git push -q workspace master:master && echo "Work merged to 'master' and pushed to workspace/master.") \
        || echoerr "Local merge successful, but there was a problem pushing work to workspace/master; bailing out.")

    if [[ "$PUSH_UPSTREAM" == true ]]; then
      git push -q upstream master:master \
        || echoerrandexit "Failed to push local master to upstream master. Bailing out."
    fi

    if [[ "$CLOSE" == true ]]; then
      work-close "$TM"
    fi

    echo "$TM linecount change: $DIFF_COUNT"
  done
}

work-qa() {
  echo "Checking local repo status..."
  work-report
  echo "Checking package dependencies..."
  packages-version-check
  echo "Linting code..."
  packages-lint
  echo "Running tests..."
  packages-test
}

work-report() {
  local BRANCH_NAME
  statusReport() {
    local COUNT="$1"
    local DESC="$2"
    if (( $COUNT > 0 )); then
      echo "$1 files $2."
    fi
  }

  requireCatalystfile
  (cd "${BASE_DIR}"
   echo
   echo "${green}"`basename "$PWD"`; tput sgr0
   BRANCH_NAME=`git rev-parse --abbrev-ref HEAD 2> /dev/null || echo ''`
   if [[ $BRANCH_NAME == "HEAD" ]]; then
     echo "${red}NO WORKING BRANCH"
  else
    echo "On branch: ${green}${BRANCH_NAME}"
  fi
  tput sgr0
  # TODO: once 'git status' once and capture output
  statusReport `git status --porcelain | grep '^ M' | wc -l || true` 'modified'
  statusReport `git status --porcelain | grep '^R ' | wc -l || true` 'renamed'
  statusReport `git status --porcelain | grep '^RM' | wc -l || true` 'renamed and modifed'
  statusReport `git status --porcelain | grep '^D ' | wc -l || true` 'deleted'
  statusReport `git status --porcelain | grep '^ D' | wc -l || true` 'missing'
  statusReport `git status --porcelain | grep '^??' | wc -l || true` 'untracked'
  local TOTAL_COUNT=`git status --porcelain | wc -l | xargs || true`
  if (( $TOTAL_COUNT > 0 )); then
    echo -e "------------\n$TOTAL_COUNT total"
  fi
 )

  tput sgr0 # TODO: put this in the exit trap, too, I think.
}

work-resume() {
  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    requireCleanRepos
  fi

  local WORK_NAME
  workUserSelectOne WORK_NAME '' true "$@"

  requireCleanRepos "${WORK_NAME}"

  local CURR_WORK
  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
    if [[ "${CURR_WORK}" == "${WORK_NAME}" ]]; then
      echowarn "'$CURR_WORK' is already the current unit of work."
      exit 0
    fi
    workSwitchBranches master
    rm "${LIQ_WORK_DB}/curr_work"
  fi
  cd "${LIQ_WORK_DB}" && ln -s "${WORK_NAME}" curr_work
  source "${LIQ_WORK_DB}"/curr_work
  workSwitchBranches "$WORK_NAME"

  if [[ -n "$CURR_WORK" ]]; then
    echo "Switched from '$CURR_WORK' to '$WORK_NAME'."
  else
    echo "Resumed '$WORK_NAME'."
  fi
}

work-save() {
  local TMP
  TMP=$(setSimpleOptions ALL MESSAGE= DESCRIPTION= NO_BACKUP:B BACKUP_ONLY -- "$@")
  eval "$TMP"

  if [[ "$BACKUP_ONLY" == true ]] && [[ "$NO_BACKUP" == true ]]; then
    echoerrandexit "Incompatible options: '--backup-only' and '--no-backup'."
  fi

  if [[ "$BACKUP_ONLY" != true ]] && [[ -z "$MESSAGE" ]]; then
    echoerrandexit "Must specify '--message|-m' (summary) for save."
  fi

  if [[ "$BACKUP_ONLY" != true ]]; then
    local OPTIONS="-m '"${MESSAGE//\'/\'\"\'\"\'}"' "
    if [[ $ALL == true ]]; then OPTIONS="${OPTIONS}--all "; fi
    if [[ $DESCRIPTION == true ]]; then OPTIONS="${OPTIONS}-m '"${DESCRIPTION/'//\'/\'\"\'\"\'}"' "; fi
    # I have no idea why, but without the eval (even when "$@" dropped), this
    # produced 'fatal: Paths with -a does not make sense.' What' path?
    eval git commit ${OPTIONS} "$@"
  fi
  if [[ "$NO_BACKUP" != true ]]; then
    work-backup
  fi
}

work-stage() {
  local TMP
  TMP=$(setSimpleOptions ALL INTERACTIVE REVIEW DRY_RUN -- "$@")
  eval "$TMP"

  local OPTIONS
  if [[ $ALL == true ]]; then OPTIONS="--all "; fi
  if [[ $INTERACTIVE == true ]]; then OPTIONS="${OPTIONS}--interactive "; fi
  if [[ $REVIEW == true ]]; then OPTIONS="${OPTIONS}--patch "; fi
  if [[ $DRY_RUN == true ]]; then OPTIONS="${OPTIONS}--dry-run "; fi

  git add ${OPTIONS} "$@"
}

work-status() {
  eval "$(setSimpleOptions SELECT PR_READY NO_FETCH:F -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local WORK_NAME LOCAL_COMMITS REMOTE_COMMITS CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  workUserSelectOne WORK_NAME "$((test -n "$SELECT" && echo '') || echo "true")" '' "$@"

  if [[ -z "$NO_FETCH" ]]; then
    work-sync --fetch-only
  fi

  if [[ "$PR_READY" == true ]]; then
    TMP="$(git rev-list --left-right --count $WORK_NAME...workspace/$WORK_NAME)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    (( $LOCAL_COMMITS == 0 )) && (( $REMOTE_COMMITS == 0 ))
    return $?
  fi

  echo "Branch name: $WORK_NAME"
  echo
  source "${LIQ_WORK_DB}/${WORK_NAME}"
  if [[ -z "$INVOLVED_PROJECTS" ]]; then
    "Involved projects: <none>"
  else
    echo "Involved projects:"
    local IP
    for IP in $INVOLVED_PROJECTS; do
      echo "  $IP"
    done
  fi

  echo
  if [[ -z "$WORK_ISSUES" ]]; then
    "Issues: <none>"
  else
    echo "Issues:"
    local ISSUE
    for ISSUE in $WORK_ISSUES; do
      echo "  $ISSUE"
    done
  fi

  for IP in $INVOLVED_PROJECTS; do
    echo
    echo "Repo status for $IP:"
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/$IP"
    TMP="$(git rev-list --left-right --count master...upstream/master)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    if (( $LOCAL_COMMITS == 0 )) && (( $REMOTE_COMMITS == 0 )); then
      echo "  Local master up to date."
    elif (( $LOCAL_COMMITS == 0 )); then
      echo "  ${yellow_b}Local master behind upstream/master $REMOTE_COMMITS.${reset}"
    elif (( $REMOTE_COMMITS == 0 )); then
      echo "  ${yellow_b}Local master ahead upstream/master $LOCAL_COMMITS.${reset}"
    else
      echo "  ${yellow_b}Local master ahead upstream/master $LOCAL_COMMITS and behind $REMOTE_COMMITS.${reset}"
    fi

    local NEED_SYNC
    TMP="$(git rev-list --left-right --count $WORK_NAME...workspace/$WORK_NAME)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    if (( $REMOTE_COMMITS == 0 )) && (( $LOCAL_COMMITS == 0 )); then
      echo "  Local workbranch up to date with workspace."
      TMP="$(git rev-list --left-right --count master...$WORK_NAME)"
      local MASTER_COMMITS WORKBRANCH_COMMITS
      MASTER_COMMITS=$(echo $TMP | cut -d' ' -f1)
      WORKBRANCH_COMMITS=$(echo $TMP | cut -d' ' -f2)
      if (( $MASTER_COMMITS == 0 )) && (( $WORKBRANCH_COMMITS == 0 )); then
        echo "  Local workbranch and master up to date."
      elif (( $MASTER_COMMITS > 0 )); then
        echo "  ${yellow}Workbranch behind master $MASTER_COMMITS commits.${reset}"
        NEED_SYNC=true
      elif (( $WORKBRANCH_COMMITS > 0 )); then
        echo "  Local workbranch ahead of master $WORKBRANCH_COMMITS commits."
      fi
    elif (( $LOCAL_COMMITS == 0 )); then
      echo "  ${yellow}Local workbranch behind workspace by $REMOTE_COMMITS commits.${reset}"
      NEED_SYNC=true
    elif (( $REMOTE_COMMITS == 0 )); then
      echo "  ${yellow}Local workranch ahead of workspace by $LOCAL_COMMITS commits.${reset}"
      NEED_SYNC=true
    else
      echo "  ${yellow}Local workranch ahead of workspace by $LOCAL_COMMITS and behind ${REMOTE_COMMITS} commits.${reset}"
      NEED_SYNC=true
    fi
    if (( $REMOTE_COMMITS != 0 )) || (( $LOCAL_COMMITS != 0 )); then
      echo "  ${yellow}Unable to analyze master-workbranch drift due to above issues.${reset}" | fold -sw 82
    fi
    if [[ -n "$NEED_SYNC" ]]; then
      echo "  Consider running:"
      echo "    liq work sync"
    fi
    echo
    echo "  Local changes:"
    git status --short
  done
}

work-start() {
  local WORK_DESC WORK_STARTED WORK_INITIATOR WORK_BRANCH INVOLVED_PROJECTS WORK_ISSUES ISSUE TMP
  TMP=$(setSimpleOptions ISSUES= -- "$@")
  eval "$TMP"

  local CURR_PROJECT ISSUES_URL
  if [[ -n "$BASE_DIR" ]]; then
    CURR_PROJECT=$(cat "$BASE_DIR/package.json" | jq --raw-output '.name' | tr -d "'")
    BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")
  fi

  WORK_ISSUES="$(workProcessIssues "$ISSUES" "$BUGS_URL")"

  if [[ -z "$WORK_ISSUES" ]]; then
    echoerrandexit "Must specify at least 1 issue when starting a new unit of work."
  fi
  exactUserArgs WORK_DESC -- "$@"
  local WORK_DESC_SPEC='^[[:alnum:]][[:alnum:] -]+$'
  # TODO: require a minimum length of 5 alphanumeric characters.
  echo "$WORK_DESC" | grep -qE "$WORK_DESC_SPEC" \
    || echoerrandexit "Work description must begin with a letter or number, contain only letters, numbers, dashes and spaces, and have at least 2 characters (/$WORK_DESC_SPEC/)."

  WORK_STARTED=$(date "+%Y.%m.%d")
  WORK_INITIATOR=$(whoami)
  WORK_BRANCH=`workBranchName "${WORK_DESC}"`

  if [[ -f "${LIQ_WORK_DB}/${WORK_BRANCH}" ]]; then
    echoerrandexit "Unit of work '${WORK_BRANCH}' aready exists. Bailing out."
  fi

  # TODO: check that current work branch is clean before switching away from it
  # https://github.com/Liquid-Labs/liq-cli/issues/14

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    rm "${LIQ_WORK_DB}/curr_work"
  fi
  touch "${LIQ_WORK_DB}/${WORK_BRANCH}"
  cd ${LIQ_WORK_DB} && ln -s "${WORK_BRANCH}" curr_work
  workUpdateWorkDb

  if [[ -n "$CURR_PROJECT" ]]; then
    echo "Adding current project '$CURR_PROJECT' to unit of work..."
    work-involve "$CURR_PROJECT"
  fi
}

work-stop() {
  local TMP
  TMP=$(setSimpleOptions KEEP_CHECKOUT -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    local CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
    if [[ -z "$KEEP_CHECKOUT" ]]; then
      requireCleanRepos
      workSwitchBranches master
    else
      source "${LIQ_WORK_DB}/curr_work"
      echo "Current branch "$CURR_WORK" maintained for ${INVOLVED_PROJECTS}."
    fi
    rm "${LIQ_WORK_DB}/curr_work"
    echo "Paused work on '$CURR_WORK'. No current unit of work."
  else
    echoerrandexit "No current unit of work to stop."
  fi
}

work-sync() {
  eval "$(setSimpleOptions FETCH_ONLY -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ ! -f "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current unit of work. Try:\nliq project sync"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local IP OPTS
  if [[ -n "$FETCH_ONLY" ]]; then OPTS="--fetch-only "; fi
  for IP in $INVOLVED_PROJECTS; do
    echo "Syncing project '${IP}'..."
    project-sync ${OPTS} "${IP}"
  done
}

work-test() {
  eval "$(setSimpleOptions SELECT -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local WORK_NAME CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  workUserSelectOne WORK_NAME "$((test -n "$SELECT" && echo '') || echo "true")" '' "$@"
  source "${LIQ_WORK_DB}/${WORK_NAME}"

  local IP
  for IP in $INVOLVED_PROJECTS; do
    echo "Testing ${IP}..."
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${IP}"
    project-test "$@"
  done
}

work-submit() {
  eval "$(setSimpleOptions MESSAGE= NOT_CLEAN:C -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current unit of work. Try:\nliq work select."
  fi

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  source "${LIQ_WORK_DB}/curr_work"

  if [[ -z "$MESSAGE" ]]; then
    MESSAGE="$WORK_DESC"
  fi


  local TO_SUBMIT="$@"
  if [[ -z "$TO_SUBMIT" ]]; then
    TO_SUBMIT="$INVOLVED_PROJECTS"
  fi

  local IP
  for IP in $TO_SUBMIT; do
    IP=$(workConvertDot "$IP")
    if ! echo "$INVOLVED_PROJECTS" | grep -qE '(^| +)'$IP'( +|$)'; then
      echoerrandexit "Project '$IP' not in the current unit of work."
    fi

    if [[ "$NOT_CLEAN" != true ]]; then
      requireCleanRepo "${IP}"
    fi
    if ! work-status --pr-ready; then
      echoerrandexit "Local work branch not in sync with remote work branch. Try:\nliq work save --backup-only"
    fi
  done

  for IP in $TO_SUBMIT; do
    IP=$(workConvertDot "$IP")
    echo "Creating PR for ${IP}..."
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${IP}"

    local BUGS_URL
    BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

    local ISSUE PROJ_ISSUES OTHER_ISSUES CLOSES_MSG
    for ISSUE in $WORK_ISSUES; do
      if [[ $ISSUE == $BUGS_URL* ]]; then
        local NUMBER=${ISSUE/$BUGS_URL/}
        NUMBER=${NUMBER/\//}
        list-add-item PROJ_ISSUES "#${NUMBER}"
        list-add-item CLOSES_MSG "closes #${NUMBER}"
      else
        list-add-item OTHER_ISSUES "${ISSUE}"
      fi
    done

    local BASE_TARGET # this is the 'org' of the upsteram branch
    BASE_TARGET=$(git remote -v | grep '^upstream' | grep '(push)' | sed -E 's|.+[/:]([^/]+)/[^/]+$|\1|')

    local DESC
    DESC=$(cat <<EOF
Merge ${WORK_BRANCH} to master

$MESSAGE

$CLOSES_MSG

## Issues
$(( test -z "${PROJ_ISSUES:-}" && test -z "${OTHER_ISSUES:-}" \
    && echo 'none' ) \
  || ( for ISSUE in ${PROJ_ISSUES:-}; do echo "* $ISSUE"; done; \
       for ISSUE in ${OTHER_ISSUES:-}; do echo "* $ISSUE"; done; ))

EOF)
    hub pull-request --push --base=${BASE_TARGET}:master -m "${DESC}"
  done
}
help-work() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}work${reset} <action>: Manages the current unit of work." || cat <<EOF
${PREFIX}${cyan_u}work${reset} <action>:
  ${underline}save${reset} [-a|--all] [--backup-only|-b] [--message|-m=<version ][<path spec>...]:
    Save staged files to the local working branch. '--all' auto stages all known files (does not
    include new files) and saves them to the local working branch. '--backup-only' is useful if local commits
    have been made directly through 'git' and you want to push them.
  ${underline}stage${reset} [-a|--all] [-i|--interactive] [-r|--review] [-d|--dry-run] [<path spec>...]:
    Stages files for save.
  ${underline}status${reset} [-s|--select] [<name>]: Shows details for the current or named unit of work.
    Will enter interactive selection if no option and no current work or the
    '--select' option is given.
  ${underline}involve${reset} [-L|--no-link] [<repository name>]: Involves the current or named
    repository in the current unit of work. When involved, any packages in the
    newly involved project will be linked to the primary project in the unit of
    work. The '--no-link' option will suppress this behavior.
  ${underline}start${reset} <name>: Creates a new unit of work and adds the current repository (if any) to it.
  ${underline}stop${reset} [-k|--keep-checkout]: Stops working on the current unit of work. The
    master branch will be checked out for all involved projects unless
    '--keep-checkout' is used.
  ${underline}resume${reset} [<name>]: Resumes work on an existing unit of work.
  ${underline}edit${reset}: Opens a local project editor for all involved repositories.
  ${underline}report${reset}: Reports status of files in the current unit of work.
  ${underline}diff-master${reset}: Shows committed changes since branch from 'master' for all
    involved repositories.
  ${underline}ignore-rest${reset}: Adds any currently untracked files to '.gitignore'.
  ${underline}merge${reset}: Merges current work unit to master branches and updates mirrors.
  ${underline}qa${reset}: Checks the playground status and runs package audit, version check, and
    tests.
  ${underline}sync${reset} [--fetch-only|-f] [--no-work-master-merge|-M]:
    Synchronizes local project repos for all work. See 'liq help work sync' for details.
  ${underline}test${reset}: Runs tests for each involved project in the current unit of work. See
    'project test' for details on options for the 'test' action.
  ${underline}submit${reset} [<projects>]: Submits pull request for the current unit of work. With no
    projects specified, submits patches for all projects in the current unit of work.

A 'unit of work' is essentially a set of work branches across all involved projects. The first project involved in a unit of work is considered the primary project, which will effect automated linking when involving other projects.

${red_b}ALPHA Note:${reset} The 'stop' and 'resume' actions do not currently manage the work branches and only updates the 'current work' pointer.
EOF
}
workBranchName() {
  local WORK_DESC="${1:-}"
  requireArgs "$WORK_DESC" || exit $?
  requireArgs "$WORK_STARTED" || exit $?
  requireArgs "$WORK_INITIATOR" || exit $?
  echo "${WORK_STARTED}-${WORK_INITIATOR}-$(workSafeDesc "$WORK_DESC")"
}

workConvertDot() {
  local PROJ="${1}"
  if [[ "${PROJ}" == "." ]]; then
    PROJ=$(cat "$BASE_DIR/package.json" | jq --raw-output '.name' | tr -d "'")
  fi
  echo "$PROJ"
}

workCurrentWorkBranch() {
  git branch | (grep '*' || true) | awk '{print $2}'
}

workSafeDesc() {
  local WORK_DESC="${1:-}"
  requireArgs "$WORK_DESC" || exit $?
  echo "$WORK_DESC" | tr ' -' '_' | tr '[:upper:]' '[:lower:]'
}

workUpdateWorkDb() {
  cat <<EOF > "${LIQ_WORK_DB}/curr_work"
WORK_DESC="$WORK_DESC"
WORK_STARTED="$WORK_STARTED"
WORK_INITIATOR="$WORK_INITIATOR"
WORK_BRANCH="$WORK_BRANCH"
EOF
  echo "INVOLVED_PROJECTS='${INVOLVED_PROJECTS:-}'" >> "${LIQ_WORK_DB}/curr_work"
  echo "WORK_ISSUES='${WORK_ISSUES:-}'" >> "${LIQ_WORK_DB}/curr_work"
}

workUserSelectOne() {
  local _VAR_NAME="$1"; shift
  local _DEFAULT_TO_CURRENT="$1"; shift
  local _TRIM_CURR="$1"; shift
  local _WORK_NAME

  if (( $# > 0 )); then
    exactUserArgs _WORK_NAME -- "$@"
    if [[ ! -f "${LIQ_WORK_DB}/${_WORK_NAME}" ]]; then
      echoerrandexit "No such unit of work '$_WORK_NAME'. Try selecting in interactive mode:\nliq ${GROUP} ${ACTION}"
    fi
  elif [[ -n "$_DEFAULT_TO_CURRENT" ]] && [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    _WORK_NAME=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
  else
    local _OPTIONS
    if ls "${LIQ_WORK_DB}/"* > /dev/null 2>&1; then
      if [[ -n "$_TRIM_CURR" ]] && [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
        local _CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
        _OPTIONS=$(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -not -name "$_CURR_WORK" -type f -exec basename '{}' \; | sort || true)
      else
        _OPTIONS=$(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \; | sort || true)
      fi
    fi

    if [[ -z "$_OPTIONS" ]]; then
      echoerrandexit "No outstanding work to select."
    else
      selectOneCancel _WORK_NAME _OPTIONS
    fi
  fi

  eval "$_VAR_NAME='${_WORK_NAME}'"
}

workSwitchBranches() {
  # We expect that the name and existence of curr_work already checked.
  local _BRANCH_NAME="$1"
  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  source "${LIQ_WORK_DB}/curr_work"
  local IP
  for IP in $INVOLVED_PROJECTS; do
    echo "Updating project '$IP' to work branch '${_BRANCH_NAME}'"
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${IP}"
    git checkout "${_BRANCH_NAME}" \
      || echoerrandexit "Error updating '${IP}' to work branch '${_BRANCH_NAME}'. See above for details."
  done
}

workProcessIssues() {
  local CSV_ISSUES="${1}"
  local BUGS_URL="${2}"
  local ISSUES ISSUE
  list-from-csv ISSUES "$CSV_ISSUES"
  for ISSUE in $ISSUES; do
    if [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
      if [[ -z "$BUGS_URL" ]]; then
        echoerrandexit "Cannot ref issue number outside project context. Either issue in context or use full URL."
      fi
      list-replace-by-string ISSUES $ISSUE "$BUGS_URL/$ISSUE"
    fi
  done

  echo "$ISSUES"
}

# getActions() {
#  for d in `find "${SOURCE_DIR}/actions" -type d -maxdepth 1 -not -path "${SOURCE_DIR}/actions"`; do
#    for f in "${d}/"*.sh; do source "$f"; done
#  done
# }
# getActions
# process global overrides of the form 'key="value"'
while (( $# > 0 )) && [[ $1 == *"="* ]]; do
  eval ${1%=*}="'${1#*=}'"
  shift
done

# see note in lib/utils.sh:colorerr re. SAW_ERROR
# local SAW_ERROR=''
if [[ $# -lt 1 ]]; then
  help --summary-only
  echoerr "Invalid invocation. See help above."
  exit 1
fi

if (( $# == 0 )); then
  echoerrandexit "No arguments provided. Try:\nliq help"
fi
GROUP="${1:-}"; shift # or global command
case "$GROUP" in
  # global actions
  help)
    help "$@";;
  # components and actionsprojct
  *)
    if (( $# == 0 )); then
      help $GROUP
      echoerrandexit "\nNo action argument provided. See valid actions above."
		elif [[ $(type -t "requirements-${GROUP}" || echo '') != 'function' ]]; then
			exitUnknownGroup
    fi
    ACTION="${1:-}"; shift
    if [[ $(type -t "${GROUP}-${ACTION}" || echo '') == 'function' ]]; then
      # the only exception to requiring a playground configuration is the
      # 'playground init' command
      if [[ "$GROUP" != 'meta' ]] || [[ "$ACTION" != 'init' ]]; then
        # source is not like other commands (?) and the attempt to replace possible source error with friendlier
        # message fails. The 'or' never gets evaluated, even when source fails.
        source "${LIQ_SETTINGS}" \ #2> /dev/null \
          # || echoerrandexit "Could not source global Catalyst settings. Try:\nliq meta init"
      fi
      requirements-${GROUP}
      ${GROUP}-${ACTION} "$@"
    else
      exitUnknownAction
    fi;;
esac

exit 0
