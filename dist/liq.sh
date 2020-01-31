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

# Echos the number of items in the list.
#
# Takes single argument, the list var name.
#
# Example:
# list-add-item A B C
# list-count MY_LIST # echos '3'
list-count() {
  if [[ -z "${!1}" ]]; then
    echo -n "0"
  else
    echo -e "${!1}" | wc -l | tr -d '[:space:]'
  fi
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
  done <<< "${!LIST_VAR:-}"
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

# Joins a list with a given string and echos the result. We use 'echo -e' for the join string, so '\n', '\t', etc. will
# work.
#
# Takes (1) the list variable name, (2) the join string
#
# Example:
# list-add-item MY_LIST A B C
# list-join MY_LIST '||' # echos 'A||B||C'
list-join() {
  local LIST_VAR="${1}"
  local JOIN_STRING="${2}"

  local CURR_INDEX=0
  local COUNT
  COUNT="$(list-count $LIST_VAR)"
  while read -r ITEM; do
    echo "$ITEM"
    CURR_INDEX=$(($CURR_INDEX + 1))
    if (( $CURR_INDEX < $COUNT )) ; then
      echo -e "$JOIN_STRING"
    fi
  done <<< "${!LIST_VAR}"
}

list-replace-by-string() {
  local LIST_VAR="${1}"
  local TEST_ITEM="${2}"
  local NEW_ITEM="${3}"

  local ITEM INDEX NEW_LIST
  INDEX=0
  for ITEM in ${!LIST_VAR:-}; do
    if [[ "$(list-get-item $LIST_VAR $INDEX)" == "$TEST_ITEM" ]]; then
      list-add-item NEW_LIST "$NEW_ITEM"
    else
      list-add-item NEW_LIST "$ITEM"
    fi
    INDEX=$(($INDEX + 1))
  done
  eval $LIST_VAR='"'"$NEW_LIST"'"'
}

list-quote() {
  local LIST_VAR="${1}"

  while read -r ITEM; do
    echo -n "'$(echo "$ITEM" | sed -e "s/'/'\"'\"'/")' "
  done <<< "${!LIST_VAR:-}"
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
    local VAR_NAME LOWER_NAME SHORT_OPT LONG_OPT IS_PASSTHRU
    IS_PASSTHRU=''
    if [[ "$VAR_SPEC" == *'^' ]]; then
      IS_PASSTHRU=true
      VAR_SPEC=${VAR_SPEC/%^/}
    fi
    local OPT_ARG=''
    if [[ "$VAR_SPEC" == *'=' ]]; then
      OPT_ARG=':'
      VAR_SPEC=${VAR_SPEC/%=/}
    fi

    if [[ "$VAR_SPEC" == '--' ]]; then
      break
    elif [[ "$VAR_SPEC" == *':'* ]]; then
      VAR_NAME=$(echo "$VAR_SPEC" | cut -d: -f1)
      SHORT_OPT=$(echo "$VAR_SPEC" | cut -d: -f2)
    else # each input is a variable name
      VAR_NAME="$VAR_SPEC"
      SHORT_OPT=$(echo "${VAR_NAME::1}" | tr '[:upper:]' '[:lower:]')
    fi

    VAR_NAME=$(echo "$VAR_NAME" | tr -d "=")
    LOWER_NAME=$(echo "$VAR_NAME" | tr '[:upper:]' '[:lower:]')
    LONG_OPT="$(echo "${LOWER_NAME}" | tr '_' '-')"

    if [[ -n "${SHORT_OPT}" ]]; then
      SHORT_OPTS="${SHORT_OPTS:-}${SHORT_OPT}${OPT_ARG}"
    fi

    LONG_OPTS=$( ( test ${#LONG_OPTS} -gt 0 && echo -n "${LONG_OPTS},") || true && echo -n "${LONG_OPT}${OPT_ARG}")

    LOCAL_DECLS="${LOCAL_DECLS:-}local ${VAR_NAME}='';"
    local CASE_SELECT="-${SHORT_OPT}|--${LONG_OPT}]"
    if [[ "$IS_PASSTHRU" == true ]]; then # handle passthru
      CASE_HANDLER=$(cat <<EOF
        ${CASE_HANDLER}
          ${CASE_SELECT}
          list-add-item _PASSTHRU "\$1"
EOF
      )
      if [[ -n "$OPT_ARG" ]]; then
        CASE_HANDLER=$(cat <<EOF
          ${CASE_HANDLER}
            list-add-item _PASSTHRU "\$2"
            shift
EOF
        )
      fi
      CASE_HANDLER=$(cat <<EOF
        ${CASE_HANDLER}
          shift;;
EOF
      )
    else # non-passthru vars
      local VAR_SETTER="${VAR_NAME}=true;"
      if [[ -n "$OPT_ARG" ]]; then
        LOCAL_DECLS="${LOCAL_DECLS}local ${VAR_NAME}_SET='';"
        VAR_SETTER=${VAR_NAME}'="${2}"; '${VAR_NAME}'_SET=true; shift;'
      fi
      if [[ -z "$SHORT_OPT" ]]; then
        CASE_SELECT="--${LONG_OPT}]"
      fi
      CASE_HANDLER=$(cat <<EOF
      ${CASE_HANDLER}
        ${CASE_SELECT}
          $VAR_SETTER
          _OPTS_COUNT=\$(( \$_OPTS_COUNT + 1))
          shift;;
EOF
      )
    fi
  done # main while loop
  CASE_HANDLER=$(cat <<EOF
    case "\${1}" in
      $CASE_HANDLER
    esac
EOF
)
  # replace the ']'; see 'Bash Bug?' above
  CASE_HANDLER=$(echo "$CASE_HANDLER" | perl -pe 's/\]$/)/')

  echo "$LOCAL_DECLS"

  cat <<EOF
local TMP # see https://unix.stackexchange.com/a/88338/84520
local _PASSTHRU=""
TMP=\$(${GNU_GETOPT} -o "${SHORT_OPTS}" -l "${LONG_OPTS}" -- "\$@") \
  || exit \$?
eval set -- "\$TMP"
local _OPTS_COUNT=0
while true; do
  $CASE_HANDLER
done
shift
if [[ -n "\$_PASSTHRU" ]]; then
  eval set -- \$(list-quote _PASSTHRU) "\$@"
fi
EOF
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

# Prompts the user for input and saves it to a var.
# Arg 1: The prompt.
# Arg 2: The name of the var to save the answer to. (BUG: Don't use 'VAR'. 'ANSWER' is always safe.)
# Arg 3 (opt): Default value to use if the user just hits enter.
#
# The defult value will be added to the prompt.
# If '--multi-line' is specified, the user may enter multiple lines, and end input with a line containing a single '.'.
# Instructions to this effect will emitted. Also, in this mode, spaces in the answer will be preserved, while in
# 'single line' mode, leading and trailing spaces will be removed.
get-answer() {
  eval "$(setSimpleOptions MULTI_LINE -- "$@")"
  local PROMPT="$1"
  local VAR="$2" # TODO: if name is 'VAR', then this breaks...
  local DEFAULT="${3:-}"

  if [[ -n "${DEFAULT}" ]]; then
    if [[ -z "$MULTI_LINE" ]]; then
      PROMPT="${PROMPT} (${DEFAULT}) "
    else
      PROMPT="${PROMPT}"$'\n''(Hit "<PERIOD><ENTER>" for default:'$'\n'"$DEFAULT"$'\n'')'
    fi
  fi

  if [[ -z "$MULTI_LINE" ]]; then
    read -r -p "$PROMPT" $VAR
    if [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
      # MacOS dosen't support 'declare -g' :(
      eval $VAR='"$DEFAULT"'
    fi
  else
    local LINE
    echo "$PROMPT"
    echo "(End multi-line input with single '.')"
    unset $VAR LINE
    while true; do
      IFS= read -r LINE
      if [[ "$LINE" == '.' ]]; then
        if [[ -z "${!VAR:-}" ]] && [[ -n "$DEFAULT" ]]; then
          eval $VAR='"$DEFAULT"'
        fi
        break
      else
        list-add-item $VAR "$LINE"
      fi
    done
  fi
}

# Functions as 'get-answer', but will continually propmt the user if no answer is given.
# '--force' causes the default to be set to the previous answer and the query to be run again. This is mainly useful
# internally and direct calls should generally note have cause to use this option. (TODO: let's rewrite this to 'unset'
# the vars (?) and avoid the need for force?)
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

# Produces a 'yes/no' prompt, accepting 'y', 'yes', 'n', or 'no' (case insensitive). Unlike other prompts, this function
# returns true or false, making it convenient for boolean tests.
yes-no() {
  default-yes() { return 0; }
  default-no() { return 1; } # bash false-y

  local PROMPT="$1"
  local DEFAULT="${2:-}"
  local HANDLE_YES="${3:-default-yes}"
  local HANDLE_NO="${4:-default-no}" # default to noop

  local ANSWER=''
  read -p "$PROMPT" ANSWER
  if [[ -z "$ANSWER" ]] && [[ -n "$DEFAULT" ]]; then
    case "$DEFAULT" in
      Y*|y*)
        $HANDLE_YES; return $?;;
      N*|n*)
        $HANDLE_NO; return $?;;
      *)
        echo "You must choose an answer."
        yes-no "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO
    esac
  else
    case "$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]')" in
      y|yes)
        $HANDLE_YES; return $?;;
      n|no)
        $HANDLE_NO; return $?;;
      *)
        echo "Did not understand response, please answer 'y(es)' or 'n(o)'."
        yes-no "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO;;
    esac
  fi
}

gather-answers() {
  eval "$(setSimpleOptions VERIFY PROMPTER= DEFAULTER= -- "$@")"
  local FIELDS="${1}"

  local FIELD VERIFIED
  while [[ "${VERIFIED}" != true ]]; do
    # collect answers
    for FIELD in $FIELDS; do
      local OPTS=''
      # if VERIFIED is set, but false, then we need to force require-answer to set the var
      [[ "$VERIFIED" == false ]] && OPTS='--force '
      if [[ "${FIELD}" == *: ]]; then
        FIELD=${FIELD/%:/}
        OPTS="${OPTS}--multi-line "
      fi
      local LABEL="$FIELD"
      $(tr '[:lower:]' '[:upper:]' <<< ${foo:0:1})${foo:1}
      LABEL="${LABEL:0:1}$(echo "${LABEL:1}" | tr '[:upper:]' '[:lower:]' | tr '_' ' ')"
      local PROMPT DEFAULT
      PROMPT="$({ [[ -n "$PROMPTER" ]] && $PROMPTER "$FIELD" "$LABEL"; } || echo "${LABEL}: ")"
      DEFAULT="$({ [[ -n "$DEFAULTER" ]] && $DEFAULTER "$FIELD"; } || echo '')"
      require-answer ${OPTS} "${PROMPT}" $FIELD "$DEFAULT"
    done

    # verify, as necessary
    if [[ -z "${VERIFY}" ]]; then
      VERIFIED=true
    else
      verify() { VERIFIED=true; }
      no-verify() { VERIFIED=false; }
      echo
      echo "Verify the following:"
      for FIELD in $FIELDS; do
        FIELD=${FIELD/:/}
        echo "$FIELD: ${!FIELD}"
      done
      echo
      yes-no "Are these values correct? (y/N) " N verify no-verify
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

# Prints line with any standard format. First arg is the format name, everything else, along with any options, are
# passed through to echo.
echofmt() {
  eval "$(setSimpleOptions NO_NEWLINE -- "$@")"
  local COLOR="${1}"; shift
  [[ -n "${!COLOR}" ]]
  OPTS="-e"
  if [[ -n "$NO_NEWLINE" ]]; then OPTS="$OPTS -n"; fi
  echo ${OPTS} "${!COLOR}$*${reset}" | fold -sw 82
}

# Prints the line in green. Any options are passed through to echo.
echogreen() {
  echofmt green "$@"
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
# Global constants.
LIQ_DB="${HOME}/.liquid-development"
LIQ_SETTINGS="${LIQ_DB}/settings.sh"
LIQ_ENV_DB="${LIQ_DB}/environments"
LIQ_ORG_DB="${LIQ_DB}/orgs"
LIQ_WORK_DB="${LIQ_DB}/work"
LIQ_ENV_LOGS="${LIQ_DB}/logs"

LIQ_DIST_DIR="$(dirname "$(real_path "${0}")")"

# defined in $CATALYST_SETTING; during load in dispatch.sh
LIQ_PLAYGROUND=''

_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='

# Global variables.
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

# Standard locations, relative to org repo.
RECORDS_PATH="records"
AUDITS_PATH="${RECORDS_PATH}/audits"
AUDITS_ACTIVE_PATH="${AUDITS_PATH}/active"
AUDITS_COMPLETE_PATH="${AUDITS_PATH}/complete"
KEYS_PATH="${RECORDS_PATH}/keys"
KEYS_ACTIVE_PATH="${KEYS_PATH}/active"
KEYS_EXPIRED_PATH="${KEYS_PATH}/expired"
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
CATALYST_COMMAND_GROUPS=(help data environments meta orgs orgs-staff policies policies-audits projects projects-issues required-services services work)

# display help on help
help-help() {
  PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}help${reset} [<group> [<sub-group|action>...]]: Displays summary of groups or information on the specified topic." || cat <<EOF
${PREFIX}${cyan_u}help${reset} [--all|-a] [--summary-only|-s] [<group> [<action>]]:
  Displays liq help. With no arguments, defaults to a summary listing of the available groups. The '--all' option will print the full help for each group, even with no args. If a group or action is specified, then only help for that group and or group+action is displayed. In this case, '--all' is the default and '--summary-only' will cause a one-line summary to be displayed.
EOF
}

# Display help information. Takes zero or more arguments specifying the topic. A topic must be a liq command group,
# sub-group, or command. Most of the work is done by deferring help functions for the specified topic.
help() {
  eval "$(setSimpleOptions ALL SUMMARY_ONLY -- "$@")" \
    || { echoerr "Bad options."; help-help; exit 1; }

  if (( $# == 0 )); then
    # If displaying all, only display summary.
    if [[ -z "$ALL" ]]; then SUMMARY_ONLY=true; fi

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
  else
    if ! type -t help-${1} | grep -q 'function'; then
      exitUnknownHelpTopic "$1" ""
    fi
    local HELP_SPEC="${1}"; shift
    while (( $# > 0)); do
      if ! type -t help-${HELP_SPEC}-${1} | grep -q 'function'; then
        exitUnknownHelpTopic "$1" "$HELP_SPEC"
      fi
      HELP_SPEC="${HELP_SPEC}-${1}"; shift
    done

    local CONTEXT="liq "
    CONTEXT="liq $(echo "$HELP_SPEC" | sed -e 's/-[^-]*$//' | sed -e 's/-/ /g')"
    help-${HELP_SPEC} "$CONTEXT"
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

handleSummary() {
  local SUMMARY="${1}"; shift

  if [[ -n "${SUMMARY_ONLY:-}" ]]; then
    echo "$SUMMARY"
    return 0
  else
    return 1
  fi
}

# display a helpful error message for invalid topics.
exitUnknownHelpTopic() {
  local BAD_SPEC="${1:-}"; shift
  help $*
  echo
  echoerrandexit "No such command or group: $BAD_SPEC"
}
function dataSQLCheckRunning() {
  eval "$(setSimpleOptions NO_CHECK -- "$@")"
  
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
          yes-no "Found existing dump for '$OUTPUT_SET_NAME'. Would you like to replace? (y\N) " \
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
  # search Catalyst projects in dependencies (i.e., ./node_modules)
  for CAT_PACKAGE in `getCatPackagePaths`; do
    if [[ -d "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
      FIND_RESULTS="$(find "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" -type f)"
      list-add-item _FILES "$FIND_RESULTS"
    fi
  done
  # search our own project
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
if the current project requires 'sql-mysql', the data commands will work and
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

  yes-no "Would you like to select the newly added '${ENV_NAME}'? (Y\n) " \
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
  local SERVICES SERVICE_PROJECTS PROVIDER_OPTIONS CAT_PACKAGE_PATH
  for CAT_PACKAGE_PATH in "${BASE_DIR}" $CAT_PACKAGE_PATHS; do
    local NPM_PACKAGE=$(cat "${CAT_PACKAGE_PATH}/package.json")
    local PACKAGE_NAME=$(echo "$NPM_PACKAGE" | jq --raw-output ".name")
    local SERVICE
    for SERVICE in $((echo "$NPM_PACKAGE" | jq --raw-output ".catalyst.provides | .[] | select((.\"interface-classes\" | .[] | select(. == \"$REQ_SERVICE\")) | length > 0) | .name | @sh" 2>/dev/null || echo '') | tr -d "'"); do
      SERVICES=$((test -n "$SERVICE" && echo "$SERVICES '$SERVICE'") || echo "'$SERVICE'")
      SERVICE_PROJECTS=$((test -n "$SERVICE_PROJECTS" && echo "$SERVICE_PROJECTS '$PACKAGE_NAME'") || echo "'$PACKAGE_NAME'")
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
    yes-no \
      "Confirm deletion of current environment '${CURR_ENV}': (y/N) " \
      N \
      onDeleteCurrent \
      onDeleteCancel
  elif [[ -f "${LIQ_ENV_DB}/${PACKAGE_NAME}/${ENV_NAME}" ]]; then
    yes-no \
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
    || ( help-environments-update; echoerrandexit "Bad options." )
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
  eval "$(setSimpleOptions PLAYGROUND= SILENT -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

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
}

meta-bash-config() {
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
}
help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles liq self-config and meta operations." \
   || cat <<EOF
The meta group manages local liq configurations and non-liq user resources.

${PREFIX}${cyan_u}meta${reset} <action>:
   ${underline}init${reset} [--silent|-s] [--playground|-p <absolute path>]: Creates the Liquid
     Development DB (a local directory) and playground.
   ${underline}bash-config${reset}: Prints bash configuration. Try: eval \`liq meta bash-config\`

   ${bold}Sub-resources${reset}:
     * $( SUMMARY_ONLY=true; help-meta-keys )
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
meta-keys() {
  local ACTION="${1}"; shift

  if [[ $(type -t "meta-keys-${ACTION}" || echo '') == 'function' ]]; then
    meta-keys-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" meta keys
  fi
}

meta-keys-create() {
  eval "$(setSimpleOptions IMPORT USER= FULL_NAME= -- "$@")"

  if [[ -z "$USER" ]]; then
    USER="$(git config user.email)"
    if [[ -z "$USER" ]]; then
      echoerrandexit "Must set git 'user.email' or specify '--user' to create key."
    fi
  fi

  if [[ -z "${FULL_NAME}" ]]; then
    FULL_NAME="$(git config user.email)"
    if [[ -z "$FULL_NAME" ]]; then
      echoerrandexit "Must set git 'user.name' or specify '--full-name' to create key."
    fi
  fi

  # Does the key already exist?
  if gpg2 --list-secret-keys "$USER" 2> /dev/null; then
    echoerrandexit "Key for '${USER}' already exists in default secret keyring. Bailing out..."
  fi

  local BITS=4096
  local ALGO=rsa
  local EXPIRY_YEARS=5
  gpg2 --batch --gen-key <<<"%echo Generating ${ALGO}${BITS} key for '${USER}'; expires in ${EXPIRY_YEARS} years.
Key-Type: RSA
Key-Length: 4096
Name-Real: ${FULL_NAME}
Name-Comment: General purpose key.
Name-Email: ${USER}
Expire-Date: ${EXPIRY_YEARS}y
%ask-passphrase
%commit"
}
# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-meta-keys() {
  handleSummary "${cyan_u}keys${reset} <action>: Manage user keys." || cat <<EOF
${cyan_u}meta keys${reset} <action>:
$(help-meta-keys-create | sed -e 's/^/  /')
EOF
} #$'' HACK to reset Atom Beutifier

help-meta-keys-create() {
  cat <<EOF
${underline}create${reset} [--import|-i] [--user|-u <email>] [--full-name|-f <full name>] :
  Creates a PGP key appropriate for use with liq. The user (email) and their full name will be extracted from the
  git config 'user.email' and 'user.name' if not specified. In general, you should configure the git parameters
  because that's what will be used by other liq funcitons.
EOF
}
meta-keys-user-has-key() {
  local USER
  USER="$(git config user.email)"
  if [[ -z "$USER" ]]; then
    echoerrandexit "git 'user.email' not set; needed for digital signing."
  fi

  if ! command -v gpg2 > /dev/null; then
    echoerrandexit "'gpg2' not found in path; please install. This is needed for digital signing."
  fi

  if ! gpg2 --list-secret-keys "$USER" > /dev/null; then
    echoerrandexit "No PGP key found for '$USER'. Either update git 'user.email' configuration, or add a key. To add a key, use:\nliq meta keys create"
  fi
}

requirements-orgs() {
  :
}

# see `liq help orgs close`
orgs-close() {
  eval "$(setSimpleOptions FORCE -- "$@")"

  if (( $# < 1 )); then
    echoerrandexit "Must specify 'org package' explicitly to close."
  fi

  local ORG_PROJ TO_DELETE OPTS
  if [[ -n "$FORCE" ]]; then OPTS='--force'; fi
  for ORG_PROJ in "$@"; do
    projectsSetPkgNameComponents "$ORG_PROJ"
    local IS_BASE_ORG=false
    if [[ "${LIQ_ORG_DB}/${PKG_ORG_NAME}" -ef "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}/${PKG_BASENAME}" ]]; then
      IS_BASE_ORG=true
    fi
    projects-close $OPTS "${PKG_ORG_NAME}/${PKG_BASENAME}"
    if [[ "$IS_BASE_ORG" == true ]]; then
      rm "${LIQ_ORG_DB}/${PKG_ORG_NAME}"
    fi
  done
}

# see `liq help orgs create`
orgs-create() {
  local FIELDS="COMMON_NAME GITHUB_NAME LEGAL_NAME ADDRESS:"
  local OPT_FIELDS="NAICS NPM_REGISTRY DEFAULT_LICENSE"
  local FIELDS_SENSITIVE="EIN"
  eval "$(setSimpleOptions COMMON_NAME= GITHUB_NAME= LEGAL_NAME= ADDRESS= NAICS= NPM_REGISTRY:r= DEFAULT_LICENSE= EIN= NO_SENSITIVE:X NO_STAFF:S PRIVATE_POLICY -- "$@")"

  local ORG_PKG="${1}"; shift

  # because some fields are optional, but may be set, we can't just rely on 'gather-answers' to skip interactive bit
  local FULLY_DEFINED=true
  for FIELD in $FIELDS; do
    FIELD=${FIELD/:/}
    [[ -n "${!FIELD}" ]] || FULLY_DEFINED=false
  done

  defaulter() {
    local FIELD="${1}"

    case "$FIELD" in
      "NPM_REGISTRY")
        echo "https://registry.npmjs.org/";;
    esac
  }

  if [[ "$FULLY_DEFINED" == true ]]; then
    NPM_REGISTRY=$(defaulter NPM_REGISTRY)
  else
    # TODO: we need to mark fields as optional for gather-answers or provide func equivalent
    local GATHER_FIELDS
    if [[ -n "$NO_SENSITIVE" ]]; then
      GATHER_FIELDS="$FIELDS $OPT_FIELDS"
    else
      GATHER_FIELDS="$FIELDS $OPT_FIELDS $FIELDS_SENSITIVE"
    fi
    gather-answers --defaulter=defaulter --verify "$GATHER_FIELDS"
  fi

  projectsSetPkgNameComponents "${ORG_PKG}"

  cd "${LIQ_PLAYGROUND}"
  mkdir -p "${PKG_ORG_NAME}"
  cd "${PKG_ORG_NAME}"

  if [[ -L "${PKG_BASENAME}" ]]; then
    echoerrandexit "Duplicate or name conflict; found existing locol org package ($ORG_PKG)."
  fi
  mkdir "${PKG_BASENAME}"
  cd "${PKG_BASENAME}"

  commit-settings() {
    local REPO_TYPE="${1}"; shift
    local FIELD

    echofmt "Initializing ${REPO_TYPE} repository..."
    git init --quiet .

    for FIELD in "$@"; do
      FIELD=${FIELD/:/}
      echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> settings.sh
    done

    git add settings.sh
    git commit -m "initial org settings"
    git push --set-upstream upstream master
  }

  local SENSITIVE_REPO POLICY_REPO STAFF_REPO
  # TODO: give option to use package or repo; these have different implications
  if [[ -z "$NO_SENSITIVE" ]]; then
    SENSITIVE_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}-sensitive"
  fi
  if [[ -z "$NO_STAFF" ]]; then
    STAFF_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}-staff"
  fi
  if [[ -n "$PRIVATE_POLICY" ]]; then
    POLICY_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}-policy"
  else
    POLICY_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}"
  fi
  hub create --remote-name upstream -d "Public settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}"
  commit-settings "base" $FIELDS $OPT_FIELDS SENSITIVE_REPO POLICY_REPO STAFF_REPO

  if [[ -z "$NO_SENSITIVE" ]]; then
    cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}"
    mkdir "${PKG_BASENAME}-sensitive"
    cd "${PKG_BASENAME}-sensitive"

    hub create --remote-name upstream --private -d "Sensitive settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}-sensitive"
    commit-settings "sensitive" "$FIELDS_SENSITIVE"
  fi

  if [[ -z "$NO_STAFF" ]]; then
    cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}"
    mkdir "${PKG_BASENAME}-staff"
    cd "${PKG_BASENAME}-staff"

    hub create --remote-name upstream --private -d "Staff settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}-staff"
    commit-settings "staff" ""
  fi

  if [[ -n "$PRIVATE_POLICY" ]]; then
    cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}"
    mkdir "${PKG_BASENAME}-policy"
    cd "${PKG_BASENAME}-policy"

    hub create --remote-name upstream --private -d "Policy settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}-policy"
    commit-settings "policy" ""
  fi
}

# see `liq help orgs import`
orgs-import() {
  local PKG_NAME BASENAME ORG_NPM_NAME
  projects-import --set-name PKG_NAME "$@"

  # TODO: check that the package is a 'base' org, and if not, skip and echowarn "This is not necessarily a problem."
  mkdir -p "${LIQ_ORG_DB}"
  projectsSetPkgNameComponents "$PKG_NAME"
  if [[ -L "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]]; then
    echowarn "Found likely remnant file: ${LIQ_ORG_DB}/${PKG_ORG_NAME}\nWill attempt to delete and continue. Refer to 'ls' output results below for more info."
    ls -l "${LIQ_ORG_DB}"
    rm "${LIQ_ORG_DB}/${PKG_ORG_NAME}"
    echo
  fi
  ln -s "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}/${PKG_BASENAME}" "${LIQ_ORG_DB}/${PKG_ORG_NAME}"
}

# see `liq help orgs list`
orgs-list() {
  find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; | sort
}

# see `liq help orgs show`
orgs-show() {
  findBase
  cd "${BASE_DIR}/.."
  local NPM_ORG
  NPM_ORG="$(basename "$PWD")"

  if [[ -e "${LIQ_ORG_DB}/${NPM_ORG}" ]]; then
    cat "${LIQ_ORG_DB}/${NPM_ORG}/settings.sh"
  else
    echowarn "No base package found for '${NPM_ORG}'. Try:\nliq orgs import <base pkg|URL>"
  fi
}
help-orgs() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages organizations and affiliations."

  handleSummary "${PREFIX}${cyan_u}orgs${reset} <action>: $SUMMARY" || cat <<EOF
${PREFIX}${cyan_u}orgs${reset} <action>:
  An org(anization) is the legal owner of work and all work is done in the context of an org. An org may represent a employer, an open source project, a department, or yourself. Certain policies and settings are defined at the org level which would then apply to all work done in that org.

  * There is a 1-1 correspondance between the liq org, a GitHub organization (or individual), and—if publishing publicly—an npm package scope.
  * The GitHub organization (or individual) must exist prior to creating an org.

  $(help-orgs-create | sed -e 's/^/  /')

  $(help-orgs-import | sed -e 's/^/  /')
  ${underline}list${reset}: Lists the currently affiliated orgs.
  ${underline}show${reset} [--sensitive] [<org nick>]: Displays info on the currently active or named org.
EOF
}

help-orgs-close() {
  cat <<EOF
${underline}close${reset} [--force] <name>...: Closes (deletes from playground) the named org-project after
  checking that all changes are committed and pushed. '--force' will skip the 'up-to-date checks.
EOF
}

help-orgs-create() {
  cat <<EOF
${underline}create${reset} [--no-sensitive] [--no-staff] [-private-policy] <base org-package>:
  Interactively gathers any org info not specified via CLI options and creates the indicated repos under the indicated
  GitHub org or user.

  The following options may be used to specify fields from the CLI. If all required options are specified (even if
  blank), then the command will run non-interactively and optional fields will be set to default values unless
  specified:
  * --common-name
  * --legal-name
  * --address (use $'\n' for linebreaks)
  * --github-name
  * (optional )--ein
  * (optional) --naics
  * (optional) --npm-registry
EOF
}

help-orgs-import() {
  cat <<EOF
${underline}import${reset} <package or URL>: Imports the 'base' org package into your playground.
EOF
}
# sources the current org settings, if any
sourceCurrentOrg() {
  local REL_DIR
  if [[ -d org_settings ]]; then
    REL_DIR="."
  elif [[ -n "$BASE_DIR" ]]; then
    REL_DIR="$BASE_DIR/.."
  else
    echoerrandexit "Cannot get current organization outside of project context."
  fi

  source "${REL_DIR}/org_settings/settings.sh"
  if [[ -d "${REL_DIR}/org_settings_sensitive" ]]; then
    source "${REL_DIR}/org_settings_sensitive/settings.sh"
  fi
}

# Retrieves the policy dir for the named NPM org or will infer from context. Org base and, when private, policy projects
# must be locally available.
orgsPolicyRepo() {
  orgsSourceOrg "${1:-}"

  echo "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}"
}

# Sources the named base org settings or will infer org context. If the base org cannot be found, the execution will
# halt and the user will be advised to import it.
orgsSourceOrg() {
  local NPM_ORG="${1:-}"

  if [[ -z "$NPM_ORG" ]]; then
    findBase
    NPM_ORG="$(cd "${BASE_DIR}/.."; basename "$PWD")"
  fi

  if [[ -e "$LIQ_ORG_DB/${NPM_ORG}" ]]; then
    source "$LIQ_ORG_DB/${NPM_ORG}/settings.sh"
  else
    echoerrandexit "Did not find expected base org package. Try:\nliq orgs import <pkg || URL>"
  fi
}

orgs-staff() {
  local ACTION="${1}"; shift
  local CMD="orgs-staff-${ACTION}"

  if [[ $(type -t "${CMD}" || echo '') == 'function' ]]; then
    ${CMD} "$@"
  else
    exitUnknownHelpTopic "$ACTION" orgs staff
  fi
}

orgs-staff-add() {
  local FIELDS="EMAIL FAMILY_NAME GIVEN_NAME START_DATE"
  local FIELDS_SPEC="${FIELDS}"
  FIELDS_SPEC="$(echo "$FIELDS_SPEC" | sed -e 's/ /= /g')="
  eval "$(setSimpleOptions $FIELDS_SPEC NO_CONFIRM:C -- "$@")"

  orgsStaffRepo

  local ALL_SPECIFIED FIELD
  ALL_SPECIFIED=true
  for FIELD in $FIELDS; do
    if [[ -z "${!FIELD}" ]]; then ALL_SPECIFIED=''; break; fi
  done

  if [[ -z "$ALL_SPECIFIED" ]] || [[ -z "$NO_CONFIRM" ]]; then
    prompter() {
      local FIELD="$1"
      local LABEL="$2"
      if [[ "$FIELD" == 'START_DATE' ]]; then
        echo "$LABEL (YYYY-MM-DD): "
      else
        echo "$LABEL: "
      fi
    }

    echo "Adding staff member to ${ORG_COMMON_NAME}..."
    local OPTS='--prompter=prompter'
    if [[ -z "$NO_CONFIRM" ]]; then OPTS="${OPTS} --verify"; fi
    gather-answers ${OPTS} "$FIELDS"
  fi

  local STAFF_FILE="${ORG_STAFF_REPO}/staff.tsv"
  [[ -f "$STAFF_FILE" ]] || touch "$STAFF_FILE"

  trap - ERR # TODO: document why this is here...
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "try {
      const { Staff } = require('${LIQ_DIST_DIR}');
      const staff = new Staff('${STAFF_FILE}');
      staff.add({ email: '${EMAIL}',
                  familyName: '${FAMILY_NAME}',
                  givenName: '${GIVEN_NAME}',
                  startDate: '${START_DATE}'});
      staff.write();
    } catch (e) { console.error(e.message); process.exit(1); }
    console.log(\"Staff memebr '${EMAIL}' added.\");" 2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done)
  orgsStaffCommit
}

orgs-staff-list() {
  eval "$(setSimpleOptions ENUMERATE -- "$@")"
  orgsStaffRepo
  local STAFF_FILE="${ORG_STAFF_REPO}/staff.tsv"
  if [[ -z "$ENUMERATE" ]]; then
    column -s $'\t' -t "${STAFF_FILE}"
  else
    (echo -e "Entry #\t$(head -n 1 "${STAFF_FILE}")"; tail +2 "${STAFF_FILE}" | cat -ne ) \
      | column -s $'\t' -t
  fi
}

orgs-staff-remove() {
  local EMAIL="${1}"
  orgsStaffRepo
  local STAFF_FILE="${ORG_STAFF_REPO}/staff.tsv"

  trap - ERR
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "
    const { Staff } = require('${LIQ_DIST_DIR}');
    const staff = new Staff('${STAFF_FILE}');
    if (staff.remove('${EMAIL}')) { staff.write(); }
    else { console.error(\"No such staff member '${EMAIL}'.\"); process.exit(1); }
    console.log(\"Staff member '${EMAIL}' removed.\");" 2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done)
  orgsStaffCommit
}
help-orgs-staff() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}orgs staff${reset} <action>: Manages organizations staff." || cat <<EOF
${PREFIX}${cyan_u}orgs staff${reset} <action>:
  ${underline}add${reset} [--email|-e <email>] [--family-name|-f <name>] [--given-name|-g <name>] [--start-date|-s <YYY-MM-DD>]:
  ${underline}list${reset}
  ${underline}remove${reset}
EOF
}
# Commits the org staff data.
orgsStaffCommit() {
  orgsStaffRepo
  cd "${ORG_STAFF_REPO}" \
    && git add staff.tsv \
    && git commit -am "Added staff member '${EMAIL}'." \
    && git push
}

# Verifies the existence of and provides 'ORG_STAFF_REPO' as a global var (and the rest of the org vars as a side
# effect). Will exit and report error if the base org project is not locally available or 'ORG_STAFF_REPO' is not
# defined.
orgsStaffRepo() {
  orgsSourceOrg || echoerrandexit "Could not locate local base org project."
  [[ -n "$ORG_STAFF_REPO" ]] || echoerrandexit "'ORG_STAFF_REPO' not defined in base org project."
}

requirements-policies() {
  :
}

# see ./help.sh for behavior
policies-document() {
  local TARGET_DIR NODE_SCRIPT
  TARGET_DIR="$(orgsPolicyRepo "${1:-}")/policy"
  NODE_SCRIPT="$(dirname $(real_path ${BASH_SOURCE[0]}))/index.js"

  rm -rf "$TARGET_DIR"
  mkdir -p "$TARGET_DIR"
  # argv[1] because the 0th arg is the 'node' executable.
  node -e "require('$NODE_SCRIPT').refreshDocuments('${TARGET_DIR}', process.argv[1].split(\"\\n\"))" "$(policiesGetPolicyFiles)"
}

# see ./help.sh for behavior
policies-update() {
  local POLICY
  for POLICY in $(policiesGetPolicyProjects "$@"); do
    npm i "${POLICY}"
  done
}
help-policies() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}policies${reset} <action>: Manages organization policies." || cat <<EOF
Policies defines all manner of organizational operations. They are "organizational code".

${PREFIX}${cyan_u}policies${reset} <action>:
  ${underline}document${reset}: Refreshes (or generates) org policy documentation based on current data.
  ${underline}update${reset}: Updates organization policies.

${bold}Sub-resources${reset}:
  * $( SUMMARY_ONLY=true; help-policies-audits )
EOF
}
# Retrieves the policy directories from the current org. Currenly requires sensitive until we think through the
# implication of having 'partial' policy access and whether that's ever useful.
#
# Returns one file per line, suitable for use with:
#
# while read VAR; do ... ; done < <(policiesGetPolicyDirs)
policiesGetPolicyDirs() {
  find "$(orgsPolicyRepo "$@")/node_modules/@liquid-labs" -maxdepth 1 -type d -name "policy-*"
}

# Will search policy dirs for TSV files. '--find-options' will be passed verbatim to find (see code). This function uses eval and it is unsafe to incorporate raw user input into the '--find-options' parameter.
policiesGetPolicyFiles() {
  eval "$(setSimpleOptions FIND_OPTIONS= -- "$@")"

  local DIR
  for DIR in $(policiesGetPolicyDirs); do
    # Not sure why the eval is necessary, but it is... (MacOS/Bash 3.x, 2020-01)
    eval find $DIR $FIND_OPTIONS -name '*.tsv'
  done
}

# Gets the installed policy projects. Note that we get installed rather than declared as policies are often an
# 'optional' dependency, so this is considered slightly more robust.
policiesGetPolicyProjects() {
  local DIR
  for DIR in $(policiesGetPolicyDirs); do
    cat "${DIR}/package.json" | jq --raw-output '.name' | tr -d "'"
  done
}

policies-audits() {
  local ACTION="${1}"; shift

  if [[ $(type -t "policies-audits-${ACTION}" || echo '') == 'function' ]]; then
    policies-audits-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" policies audits
  fi
}

policies-audits-process() {
  echoerrandexit "Audit processing not yet implemented."
}

policies-audits-start() {
  eval "$(setSimpleOptions SCOPE= NO_CONFIRM:C -- "$@")"

  local SCOPE TIME OWNER AUDIT_PATH FILES
  policy-audit-start-prep "$@"
  policies-audits-setup-work
  policy-audit-initialize-records

  echofmt reset "Would you like to begin processing the audit now? If not, the session will and your previous work will be resumed."
  if yes-no "Begin processing? (y/N)" N; then
    policies-audits-process
  else
    policies-audits-finalize-session "${AUDIT_PATH}" "${TIME}" "$(policies-audits-describe)"
  fi
}
# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-policies-audits() {
  handleSummary "${cyan_u}audits${reset} <action>: Manage audits." || cat <<EOF
${cyan_u}policies audits${reset} <action>:
$(help-policies-audits-start | sed -e 's/^/  /')
EOF
} #$'' HACK to reset Atom Beutifier

help-policies-audits-start() {
  cat <<EOF
${underline}start${reset} [--scope|-s <scope>] [--no-confirm|-C] [<domain>] :
  Initiates an audit. An audit scope is either 'change' (default), 'process' or 'full'.

  Currently supported domains are 'code' and 'network'. If domain isn't specified, then the user will be given an
  interactive list.

  By default, a summary of the audit will be displayed to the user for confirmation. This can be supressed with
  the '--no-confirm' option.
EOF
}
# Generates a human readable description string based on audit parameters. The '--short' option guarantees a name compatible with branch naming conventions and suitable for use with 'liq work start'.
# outer vars: SCOPE DOMAIN TIME OWNER
function policies-audits-describe() {
  eval "$(setSimpleOptions SHORT SET_SCOPE:c= SET_DOMAIN:d= SET_TIME:t= SET_OWNER:o= -- "$@")"
  [[ -n $SET_SCOPE ]] || SET_SCOPE="$SCOPE"
  [[ -n $SET_DOMAIN ]] || SET_DOMAIN="$DOMAIN"
  [[ -n $SET_TIME ]] || SET_TIME="$TIME"
  [[ -n $SET_OWNER ]] || SET_OWNER="$OWNER"

  if [[ -z $SHORT ]]; then
    echo "$(tr '[:lower:]' '[:upper:]' <<< ${SET_SCOPE:0:1})${SET_SCOPE:1} ${SET_DOMAIN} audit starting $(date -ujf %Y%m%d%H%M%S ${SET_TIME} +"%Y-%m-%d %H:%M UTC") by ${SET_OWNER}."
  else
    echo "$(tr '[:lower:]' '[:upper:]' <<< ${SET_SCOPE:0:1})${SET_SCOPE:1} ${SET_DOMAIN} audit $(date -ujf %Y%m%d%H%M%S ${SET_TIME} +"%Y-%m-%d %H%M UTC")"
  fi
}

# Finalizes the session by signing the log, committing the updates, and summarizing the session. Takes the records folder, key time, and commit message as first, second, and third arguments.
function policies-audits-finalize-session() {
  local AUDIT_PATH="${1}"
  local TIME="${2}"
  local MESSAGE="${3}"

  policies-audits-sign-log "${AUDIT_PATH}"
  (
    cd "${AUDIT_PATH}"
    work-stage .
    work-save -m "${MESSAGE}"
    work-submit --no-close
    policies-audits-summarize-since "${AUDIT_PATH}" ${TIME}
    work-resume --pop
  )
}
# Gets the current time (resolution: 1 second) in UTC for use by log functions.
policies-audits-now() { date -u +%Y%m%d%H%M%S; }

# Adds log entry. Takes a single argument, the message to add to the log entry.
# outer vars: AUDIT_PATH
policies-audits-add-log-entry() {
  local MESSAGE="${1}"

  if [[ -z "${AUDIT_PATH}" ]]; then
    echoerrandexit "Could not update log; 'AUDIT_PATH' not set."
  fi

  local USER
  USER="$(git config user.email)"
  if [[ -z "$USER" ]]; then
    echoerrandexit "Must set git 'user.email' for use by audit log."
  fi

  echo "$(policies-audits-now) UTC ${USER} ${MESSAGE}" >> "${AUDIT_PATH}/refs/history.log"
}

# Signs the log. Takes the records folder as first argument.
policies-audits-sign-log() {
  local AUDIT_PATH="${1}"
  local USER SIGNED_AT
  USER="$(git config user.email)"
  SIGNED_AT=$(policies-audits-now)

  echo "Signing current log file..."

  mkdir -p "${AUDIT_PATH}/sigs"
  gpg2 --output "${AUDIT_PATH}/sigs/history-${SIGNED_AT}-zane.sig" \
    -u ${USER} \
    --detach-sig \
    --armor \
    "${AUDIT_PATH}/refs/history.log"
}

# Gets all entries since the indicated time (see policies-audits-now for format). Takes records folder and the key time as the first and second arguments.
policies-audits-summarize-since() {
  local AUDIT_PATH="${1}"
  local SINCE="${2}"

  local ENTRY_TIME LINE LINE_NO
  LINE_NO=1
  for ENTRY_TIME in $(awk '{print $1}' "${AUDIT_PATH}/refs/history.log"); do
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
  done <<< "$(tail +${LINE_NO} "${AUDIT_PATH}/refs/history.log")"
  echo
}
# TODO: link the references once we support.
# Performs all checks and sets up variables ahead of any state changes. Refer to input confirmation, defaults, and user confirmation functions.
# outer vars: inherited
function policy-audit-start-prep() {
  meta-keys-user-has-key
  policy-audit-start-confirm-and-normalize-input "$@"
  policy-audit-derive-vars
  policy-audit-start-user-confirm-audit-settings
}

function policies-audits-setup-work() {
  (
    local MY_GITHUB_NAME ISSUE_URL ISSUE_NUMBER
    projectHubWhoami MY_GITHUB_NAME
    cd $(orgsPolicyRepo) # TODO: create separately specified records repo
    ISSUE_URL="$(hub issue create -m "$(policies-audits-describe)" -a "$MY_GITHUB_NAME" -l audit)"
    ISSUE_NUMBER="$(basename "$ISSUE_URL")"

    work-start --push -i $ISSUE_NUMBER "$(policies-audits-describe --short)"
  )
}

# TODO: link the references once we support.
# Initialize an audit. Refer to folder and questions initializers.
# outer vars: TIME inherited
function policy-audit-initialize-records() {
  policies-audits-initialize-folder
  policies-audits-initialize-audits-json
  policies-audits-initialize-questions
}

# Internal help functions.

# Lib internal helper. See 'liq help policy audit start' for description of proper input.
# outer vars: CHANGE_CONTROL FULL DOMAIN SCOPE
function policy-audit-start-confirm-and-normalize-input() {
  DOMAIN="${1:-}"

  if [[ -z $SCOPE ]]; then
    SCOPE='change'
  elif [[ $SCOPE != 'change' ]] && [[ $SCOPE != 'full' ]] && [[ $SCOPE != 'process' ]]; then
    echoerrandexit "Invalid scope '$SCOPE'. Scope may be 'change', 'process', or 'full'."
  fi

  if [[ -z $DOMAIN ]]; then # do menu select
    # TODO
    echoerrandexit "Interactive domain not yet supported."
  elif [[ $DOMAIN != 'code' ]] && [[ $DOMAIN != 'network' ]]; then
    echoerrandexit "Unrecognized domain reference: '$DOMAIN'. Try one of:\n* code\n*network"
  fi
}

# Lib internal helper. Sets the outer vars SCOPE, TIME, OWNER, and AUDIT_PATH
# outer vars: FULL SCOPE TIME OWNER AUDIT_PATH
function policy-audit-derive-vars() {
  local FILE_OWNER FILE_NAME

  TIME="$(policies-audits-now)"
  OWNER="$(git config user.email)"
  FILE_OWNER=$(echo "${OWNER}" | sed -e 's/@.*$//')

  FILE_NAME="${TIME}-${DOMAIN}-${SCOPE}-${FILE_OWNER}"
  AUDIT_PATH="$(orgsPolicyRepo)/${AUDITS_ACTIVE_PATH}/${FILE_NAME}"
}

# Lib internal helper. Confirms audit settings unless explicitly told not to.
# outer vars: NO_CONFIRM SCOPE DOMAIN OWNER TIME
function policy-audit-start-user-confirm-audit-settings() {
  echofmt reset "Starting audit with:\n\n* scope: ${bold}${SCOPE}${reset}\n* domain: ${bold}${DOMAIN}${reset}\n* owner: ${bold}${OWNER}${reset}\n"
  if [[ -z $NO_CONFIRM ]]; then
    # TODO: update 'yes-no' to use 'echofmt'? also fix echofmt to take '--color'
    if ! yes-no "confirm? (y/N) " N; then
      echowarn "Audit canceled."
      exit 0
    fi
  fi
}

# Lib internal helper. Determines and creates the AUDIT_PATH
# outer vars: AUDIT_PATH
function policies-audits-initialize-folder() {
  if [[ -d "${AUDIT_PATH}" ]]; then
    echoerrandexit "Looks like the audit has already started. You can't start more than one audit per second."
  fi
  echo "Creating records folder..."
  mkdir -p "${AUDIT_PATH}"
  mkdir "${AUDIT_PATH}/refs"
  mkdir "${AUDIT_PATH}/sigs"
}

# Lib internal helper. Initializes the 'audit.json' data record.
# outer vars: AUDIT_PATH TIME DOMAIN SCOPE OWNER
function policies-audits-initialize-audits-json() {
  local AUDIT_SH="${AUDIT_PATH}/audit.sh"
  local PARAMETERS_SH="${AUDIT_PATH}/parameters.sh"
  local DESCRIPTION
  DESCRIPTION=$(policies-audits-describe)

  if [[ -f "${AUDIT_SH}" ]]; then
    echoerrandexit "Found existing 'audit.json' file while trying to initalize audit. Bailing out..."
  fi

  echofmt reset "Initializing audit data records..."
  # TODO: extract and use 'double-quote-escape' for description
  cat <<EOF > "${AUDIT_SH}"
START="${TIME}"
DESCRIPTION="${DESCRIPTION}"
DOMAIN="${DOMAIN}"
SCOPE="${SCOPE}"
OWNER="${OWNER}"
EOF
  touch "${PARAMETERS_SH}"
  echo "${TIME} UTC ${OWNER} : initiated audit" > "${AUDIT_PATH}/refs/history.log"
}

# Lib internal helper. Determines applicable questions and generates initial TSV record.
# outer vars: inherited
function policies-audits-initialize-questions() {
  policies-audits-create-combined-tsv
  local ACTION_SUMMARY
  policies-audits-create-final-audit-statements ACTION_SUMMARY
  policies-audits-add-log-entry "${ACTION_SUMMARY}"
}

# Lib internal helper. Creates the 'ref/combined.tsv' file containing the list of policy items included based on org (absolute) parameters.
# outer vars: DOMAIN AUDIT_PATH
policies-audits-create-combined-tsv() {
  echo "Gathering relevant policy statements..."
  local FILES
  FILES="$(policiesGetPolicyFiles --find-options "-path '*/policy/${DOMAIN}/standards/*items.tsv'")"

  while read -e FILE; do
    npx liq-standards-filter-abs --settings "$(orgsPolicyRepo)/settings.sh" "$FILE" >> "${AUDIT_PATH}/refs/combined.tsv"
  done <<< "$FILES"
}

# Lib internal helper. Analyzes 'ref/combined.tsv' against parameter setting to generate the final list of statements included in the audit. This may involve an interactive question / answer loop (with change audits). Echoes a summary of actions (including any parameter values used) suitable for logging.
# outer vars: SCOPE AUDIT_PATH
policies-audits-create-final-audit-statements() {
  local SUMMAR_VAR="${1}"

  local STATEMENTS LINE
  if [[ $SCOPE == 'full' ]]; then # all statments included
    STATEMENTS="$(while read -e LINE; do echo "$LINE" | awk -F '\t' '{print $3}'; done \
                  < "${AUDIT_PATH}/refs/combined.tsv")"
    eval "$SUMMARY_VAR='Initialized audit statements using with all policy standards.'"
  elif [[ $SCOPE == 'process' ]]; then # only IS_PROCESS_AUDIT statements included
    STATEMENTS="$(while read -e LINE; do
                    echo "$LINE" | awk -F '\t' '{ if ($6 == "IS_PROCESS_AUDIT") print $3 }'
                  done < "${AUDIT_PATH}/refs/combined.tsv")"
    eval "$SUMMARY_VAR='Initialized audit statements using with all process audit standards.'"
  else # it's a change audit and we want to ask about the nature of the change
    local ALWAYS=1
    local IS_FULL_AUDIT=0
    local IS_PROCESS_AUDIT=0
    local PARAMS PARAM PARAM_SETTINGS AND_CONDITIONS CONDITION
    echofmt reset "\nYou will now be asked a series of questions in order to determine the nature of the change. This will determine which policy statements need to be reviewed."
    read -n 1 -s -r -p "Press any key to continue..."
    echo; echo

    exec 10< "${AUDIT_PATH}/refs/combined.tsv"
    while read -u 10 -e LINE; do
      local INCLUDE=true
      # we read each set of 'and' conditions
      AND_CONDITIONS="$(echo "$LINE" | awk -F '\t' '{print $6}' | tr ',' '\n' | tr -d ' ')"
      IFS=$'\n' #
      for CONDITION in $AND_CONDITIONS; do # evaluate each condition sequentially until failure or end
        PARAMS="$(echo "$CONDITION" | tr -C '[:alpha:]_' '\n')"
        for PARAM in $PARAMS; do # define undefined params of clause
          if [[ -z "${!PARAM:-}" ]]; then
            function set-yes() { eval $PARAM=1; }
            function set-no() { eval $PARAM=0; }
            local PROMPT
            PROMPT="${PARAM:0:1}$(echo ${PARAM:1} | tr '[:upper:]' '[:lower:]' | tr '_' ' ')? (y/n) "
            yes-no "$PROMPT" "" set-yes set-no
            echo
            PARAM_SETTINGS="${PARAM_SETTINGS} ${PARAM}='${!PARAM}'"
          fi
        done # define clause params
        if ! env -i -S "$(for PARAM in $PARAMS; do echo "$PARAM=${!PARAM} "; done)" perl -e '
            use strict; use warnings;
            my $condition="$ARGV[0]";
            while (my ($k, $v) = each %ENV) { $condition =~ s/$k/$v/g; }
            $condition =~ /[0-9<>=]+/ or die "Invalid audit condition: $condition";
            eval "$condition" or exit 1;' $CONDITION; then
          INCLUDE=false
          break # stop processing conditions
        fi
      done # evaluate each condition
      unset IFS
      if [[ $INCLUDE == true ]]; then
        list-add-item STATEMENTS "$(echo "$LINE" | awk -F '\t' '{print $3}')"
      fi
    done
    exec 10<&-

    eval "$SUMMAR_VAR='Initialized audit statements using parameters:${PARAM_SETTINGS}.'"
  fi

  local STATEMENT
  echo -e "Statement\tReviewer\tAffirmed\tComments" > "${AUDIT_PATH}/reviews.tsv"
  while read -e STATEMENT; do
    echo -e "$STATEMENT\t\t\t" >> "${AUDIT_PATH}/reviews.tsv"
  done <<< "$STATEMENTS"
}

requirements-projects() {
  :
}

# see: liq help projects build
projects-build() {
  findBase
  cd "$BASE_DIR"
  projectsRunPackageScript build
}

# see: liq help projects close
projects-close() {
  eval "$(setSimpleOptions FORCE -- "$@")"

  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    findBase
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi
  PROJECT_NAME="${PROJECT_NAME/@/}"

  deleteLocal() {
    cd "${LIQ_PLAYGROUND}" \
      && rm -rf "$PROJECT_NAME" && echo "Removed project '@${PROJECT_NAME}'."
    # now check to see if we have an empty "org" dir
    local ORG_NAME
    ORG_NAME=$(dirname "${PROJECT_NAME}")
    if [[ "$ORG_NAME" != "." ]] && (( 0 == $(ls "$ORG_NAME" | wc -l) )); then
      rmdir "$ORG_NAME"
    fi
  }

  cd "$LIQ_PLAYGROUND"
  if [[ -d "$PROJECT_NAME" ]]; then
    if [[ "$FORCE" == true ]]; then
      deleteLocal
      return
    fi

    cd "$PROJECT_NAME"
    # Are remotes setup as expected?
    if ! git remote | grep -q '^upstream$'; then
      echoerrandexit "Did not find expected 'upstream' remote. Verify everything saved+pushed and try:\nliq projects close --force '${PROJECT_NAME}'"
    fi
    requireCleanRepo --check-all-branches "$PROJECT_NAME" # exits if not clean + branches saved to remotes
    deleteLocal # didn't exit? OK to delete
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
  # TODO: need to check whether the project is linked to other projects
}

# see: liq help projects create
projects-create() {
  eval "$(setSimpleOptions NEW= SOURCE= FOLLOW NO_FORK:F VERSION= LICENSE= DESCRIPTION= PUBLIC: -- "$@")"

  # TODO: check that the upstream and workspace projects don't already exist

  if [[ -n "$NEW" ]] && [[ -n "$SOURCE" ]]; then
    echoerrandexit "The '--new' and '--source' options are not compatible. Please refer to:\nliq help projects create"
  elif [[ -z "$NEW" ]] && [[ -z "$SOURCE" ]]; then
    echoerrandexit "You must specify one of the '--new' or '--source' options when creating a project.Please refer to:\nliq help projects create"
  fi

  __PROJ_NAME="${1:-}"
  if [[ -z "${__PROJ_NAME:-}" ]]; then
    if [[ -n "$SOURCE" ]]; then
      __PROJ_NAME=$(basename "$SOURCE" | sed -e 's/\.[a-zA-Z0-9]*$//')
      echo "Default project name to: ${__PROJ_NAME}"
    else
      echoerrandexit "Must specify project name for '--new' projects."
    fi
  else # check that project name includes org
    projectsSetPkgNameComponents "${__PROJ_NAME}"
    if [[ "$PKG_ORG_NAME" == '.' ]]; then
      echoerrandexit "Must specify NPM org scope when creating new projects."
    else
      if [[ -e "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]]; then
        echoerrandexit "Did not find base org repo for '$PKG_ORG_NAME'. Try:\nliq orgs import <base org pkg or URL>"
      else
        source "${LIQ_ORG_DB}/${PKG_ORG_NAME}/settings.sh"
      fi
    fi
  fi

  local REPO_FRAG REPO_URL BUGS_URL README_URL
  REPO_FRAG="github.com/${ORG_GITHUB_NAME}/${__PROJ_NAME}"
  REPO_URL="git+ssh://git@${REPO_FRAG}.git"
  BUGS_URL="https://${REPO_FRAG}/issues"
  HOMEPAGE="https://${REPO_FRAG}#readme"

  if [[ -n "$NEW" ]]; then
    cd "$PROJ_STAGE"
    git init .
    npm init "$NEW"
    # The init script is responsible for setting up package.json
  else
    projectClone "$SOURCE" 'source'
    cd "$PROJ_STAGE"
    git remote set-url --push source no_push

    echo "Setting up package.json..."
    # setup all the vars
    [[ -n "$VERSION" ]] || VERSION='1.0.0'
    [[ -n "$LICENSE" ]] \
      || { [[ -n "${ORG_DEFAULT_LICENSE:-}" ]] && LICENSE="$ORG_DEFAULT_LICENSE"; } \
      || LICENSE='UNLICENSED'

    [[ -f "package.json" ]] || echo '{}' > package.json

    update_pkg() {
      echo "$(cat package.json | jq "${1}")" > package.json
    }

    update_pkg ".name = \"@${ORG_NPM_SCOPE}/${__PROJ_NAME}\""
    update_pkg ".version = \"${VERSION}\""
    update_pkg ".license = \"${LICENSE}\""
    update_pkg ".repository = { type: \"git\", url: \"${REPO_URL}\"}"
    update_pkg ".bugs = { url: \"${BUGS_URL}\"}"
    update_pkg ".homepage = \"${HOMEPAGE}\""
    if [[ -n "$DESCRIPTION" ]]; then
      update_pkg ".description = \"${DESCRIPTION}\""
    fi

    git add package.json
    git commit -m "setup and/or updated package.json"
  fi

  echo "Creating upstream repo..."
  local CREATE_OPTS="--remote-name upstream"
  if [[ -z "$PUBLIC" ]]; then CREATE_OPTS="${CREATE_OPTS} --private"; fi
  hub create ${CREATE_OPTS} -d "$DESCRIPTION" "${ORG_GITHUB_NAME}/${__PROJ_NAME}"
  git push --all upstream

  if [[ -z "$NO_FORK" ]]; then
    echo "Creating fork..."
    hub fork --remote-name workspace
    git branch -u upstream/master master
  fi
  if [[ -z "$FOLLOW" ]]; then
    echo "Un-following source repo..."
    git remote remove source
  fi

  cd -
  projectMoveStaged "$__PROJ_NAME" "$PROJ_STAGE"
}

# see: liq help projects deploy
projects-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'liq go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

# see: liq help projects import; The '--set-name' and '--set-url' options are for internal use and each take a var name
# which will be 'eval'-ed to contain the project name and URL.
projects-import() {
  local PROJ_SPEC __PROJ_NAME _PROJ_URL PROJ_STAGE
  eval "$(setSimpleOptions NO_FORK:F NO_INSTALL SET_NAME= SET_URL= -- "$@")"

  set-stuff() {
    # TODO: protect this eval
    if [[ -n "$SET_NAME" ]]; then eval "$SET_NAME='$_PROJ_NAME'"; fi
    if [[ -n "$SET_URL" ]]; then eval "$SET_URL='$_PROJ_URL'"; fi
  }

  if [[ "$1" == *:* ]]; then # it's a URL
    _PROJ_URL="${1}"
    # We have to grab the project from the repo in order to figure out it's (npm-based) name...
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
    _PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'")
    if [[ -n "$_PROJ_NAME" ]]; then
      set-stuff
      if projectCheckIfInPlayground "$_PROJ_NAME"; then
        echo "Project '$_PROJ_NAME' is already in the playground. No changes made."
        return 0
      fi
    else
      rm -rf "$PROJ_STAGE"
      echoerrandexit -F "The specified source is not a valid Liquid Dev package (no 'package.json'). Try:\nliq projects create --type=bare --origin='$_PROJ_URL' <project name>"
    fi
  else # it's an NPM package
    _PROJ_NAME="${1}"
    set-stuff
    if projectCheckIfInPlayground "$_PROJ_NAME"; then
      echo "Project '$_PROJ_NAME' is already in the playground. No changes made."
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
  if [[ -z "$NO_INSTALL" ]]; then
    cd "${LIQ_PLAYGROUND}/${_PROJ_NAME/@/}"
    echo "Installing project..."
    npm install || echoerrandexit "Installation failed."
    echo "Install complete."
  fi
}

# see: liq help projects publish
projects-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}

# see: liq help projects qa
projects-qa() {
  eval "$(setSimpleOptions UPDATE^ OPTIONS=^ AUDIT LINT LIQ_CHECK VERSION_CHECK -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  findBase
  cd "$BASE_DIR"

  local RESTRICTED=''
  if [[ -n "$AUDIT" ]] || [[ -n "$LINT" ]] || [[ -n "$LIQ_CHECK" ]] || [[ -n "$VERSION_CHECK" ]]; then
    RESTRICTED=true
  fi

  local FIX_LIST
  if [[ -z "$RESTRICTED" ]] || [[ -n "$AUDIT" ]]; then
    projectsNpmAudit "$@" || list-add-item FIX_LIST '--audit'
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$LINT" ]]; then
    projectsLint "$@" || list-add-item FIX_LIST '--lint'
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$LIQ_CHECK" ]]; then
    projectsLiqCheck "$@" || true # Check provides it's own instrucitons.
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$VERSION_CHECK" ]]; then
    projectsVersionCheck "$@" || list-add-item FIX_LIST '--version-check'
  fi
  if [[ -n "$FIX_LIST" ]]; then
    echowarn "To attempt automated fixes, try:\nliq projects qa --update $(list-join FIX_LIST ' ')"
  fi
}

# see: liq help projects sync
projects-sync() {
  eval "$(setSimpleOptions FETCH_ONLY NO_WORK_MASTER_MERGE:M -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  [[ -n "${BASE_DIR:-}" ]] || findBase
  local PROJ_NAME
  PROJ_NAME="$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name' | tr -d "'")"

  if [[ -z "$NO_WORK_MASTER_MERGE" ]] && [[ -z "$FETCH_ONLY" ]]; then
    requireCleanRepo "$PROJ_NAME"
  fi

  local CURR_BRANCH REMOTE_COMMITS MASTER_UPDATED
  CURR_BRANCH="$(workCurrentWorkBranch)"

  echo "Fetching remote histories..."
  git fetch upstream master:remotes/upstream/master
  if [[ "$CURR_BRANCH" != "master" ]]; then
    git fetch workspace master:remotes/workspace/master
    git fetch workspace "${CURR_BRANCH}:remotes/workspace/${CURR_BRANCH}"
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

    if [[ -z "$NO_WORK_MASTER_MERGE" ]] \
         && ( [[ "$MASTER_UPDATED" == true ]] || ! git merge-base --is-ancestor master $CURR_BRANCH ); then
      echo "Merging master updates to work branch..."
      git merge master --no-commit --no-ff || true # might fail with conflicts, and that's OK
      if git diff-index --quiet HEAD "${BASE_DIR}" && git diff --quiet HEAD "${BASE_DIR}"; then
        echowarn "Hmm... expected to see changes from master, but none appeared. It's possible the changes have already been incorporated/recreated without a merge, so this isn't necessarily an issue, but you may want to double check that everything is as expected."
      else
        if ! git diff-index --quiet HEAD "${BASE_DIR}/dist" || ! git diff --quiet HEAD "${BASE_DIR}/dist"; then # there are changes in ./dist
          echowarn "Backing out merge updates to './dist'; rebuild to generate current distribution:\nliq projects build $PROJ_NAME"
          git checkout -f HEAD -- ./dist
        fi
        if git diff --quiet "${BASE_DIR}"; then # no conflicts
          git add -A
          git commit -m "Merge updates from master to workbranch."
          work-save --backup-only
          echo "Master updates merged to workbranch."
        else
          echowarn "Merge was successful, but conflicts exist. Please resolve and then save changes:\nliq work save"
        fi
      fi
    fi
  fi # on workbranach check
}

# see: liq help projects test
projects-test() {
  eval "$(setSimpleOptions TYPES= NO_DATA_RESET:D GO_RUN= NO_START:S NO_SERVICE_CHECK:C -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

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
        echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\nliq projects test --types=unit\nliq services start"
      fi
    else
      echo "${green}looks good.${reset}"
    fi
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" projectsRunPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\nliq projects test --type=unit" $?
}
projects-services() {
  local ACTION="${1}"; shift

  if [[ $(type -t "projects-services-${ACTION}" || echo '') == 'function' ]]; then
    projects-services-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" projects services
  fi
}

projects-services-add() {
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

projects-services-delete() {
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

projects-services-list() {
  echo $PACKAGE | jq --raw-output ".catalyst.provides | .[] | .\"name\""
}

projects-services-show() {
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
help-projects() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}projects${reset} <action>: Project configuration and tools." || cat <<EOF
${PREFIX}${cyan_u}projects${reset} <action>:
$(help-projects-build | sed -e 's/^/  /')
$(help-projects-close | sed -e 's/^/  /')
$(help-projects-create | sed -e 's/^/  /')
$(help-projects-import | sed -e 's/^/  /')
$(help-projects-publish | sed -e 's/^/  /')
$(help-projects-qa | sed -e 's/^/  /')
$(help-projects-sync | sed -e 's/^/  /')
$(help-projects-test | sed -e 's/^/  /')
  ${underline}services${reset}: sub-resource for managing services provided by the package.
    ${underline}add${reset} [<service name>]: Add a provided service to the current project.
    ${underline}list${reset} [<project name>...]: Lists the services provided by the current or named projects.
    ${underline}delete${reset} [<project name>] <name>: Deletes a provided service.
    ${underline}show${reset} [<service name>...]: Show service details.
EOF
}

help-projects-build() {
  cat <<EOF
${underline}build${reset} [<name>...]: Builds the current or specified project(s).
EOF
}

help-projects-close() {
  cat <<EOF
${underline}close${reset} --force [<name>...]: Closes (deletes from playground) either the current or named
  project after checking that all changes are committed and pushed. '--force' will skip the 'up-to-date
  checks.
EOF
}

help-projects-create() {
  cat <<EOF
${underline}create${reset} [[--new <type>] || [--source|-s <pkg|URL>] [--follow|-f]] [--no-fork|-F] [--version|-v <semver> ] [--license|-l <license name>] [--description|-d <desc>] [--public] [<project name>]:
  Note, 'project name' should be a bare name. The scope is determined by the current org settings. An
  explicit name is required for '--new' projects. If no name is given for '--source' projects, then
  the base source name is used.

  Creates a new Liquid project in one of two modes. If '--new' is specified, then the indicated type
  will be used to initiate a 'create' script. There are various '@liquid-labs/create-*' projects
  which may be used, and third-party or private scripts may developed as well. This essentially
  calls 'npm init <type>' and then sets up the GitHub repository and working repo (unless --no-fork
  is specified).

  If '--source' is specified, will first clone the source repo as a starting point. This can be used
  to "convert" non-Liquid projects (from GitHub or other sources) as well as to create re-named
  duplicates of Liquid projects If set to '--follow' the source, then this effectively sets up a
  'source' remote conceptually upstream from 'upstream' and future invocations of 'project sync' will
  attempt to merge changes from 'source' to 'upstream'. This can later be managed using the 'projects
  remotes' sub-group.

  Regardless, the following 'package.json' fields will be set according to the following:
  * the package will be scoped accourding to the org scope.
  * 'project name' will be used to create a git repository under the org scope.
  * the 'repository' and 'bugs' fields will be set to match.
  * the 'homepage' will be set to the repo 'README.md' (#readme).
  * version to '--version', otherwise '1.0.0'.
  * license to the '--license', otherwise org's default license, otherwise 'UNLICENSED'.

  Any compatible create script must conform to the above, though additional rules and/or interactions
  may added. Note, just because no option is given to change some of the above parameters they can, of
  course, be modified post-create (though they are "very standard" for Liquid projects).

  Use 'liq projects import' to import an existing project from a URL.
EOF
}

help-projects-deploy() {
  cat <<EOF
${underline}deploy${reset} [<name>...]: Deploys the current or named project(s).
EOF
}

help-projects-import() {
  cat <<EOF
${underline}import${reset} [--no-install] <package or URL>: Imports the indicated package into your playground. The
  newly imported package will be installed unless '--no-install' is given.
EOF
}

help-projects-publish() {
  cat <<EOF
${underline}publish${reset}: Performs verification tests, updates package version, and publishes package.
EOF
}

help-projects-qa() {
  cat <<EOF
${underline}qa${reset} [--update|-u] [--audit|-a] [--lint|-l] [--version-check|-v]:
  Performs NPM audit, eslint, and NPM version checks. By default, all three checks are performed, but options
  can be used to select specific checks. The '--update' option instruct to the selected options to attempt
  updates/fixes.
EOF
}

help-projects-sync() {
  cat <<EOF
${underline}sync${reset} [--fetch-only|-f] [--no-work-master-merge|-M]:
  Updates the remote master with new commits from upstream/master and, if currently on a work branch,
  workspace/master and workspace/<workbranch> and then merges those updates with the current workbranch (if any).
  '--fetch-only' will update the appropriate remote refs, and exit. --no-work-master-merge update the local master
  branch and pull the workspace workbranch, but skips merging the new master updates to the workbranch.
EOF
}

help-projects-test() {
  cat <<EOF
${underline}test${reset} [-t|--types <types>][-D|--no-data-reset][-g|--go-run <testregex>][--no-start|-S] [<name>]:
  Runs unit tests the current or named projects.
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
}
projectCheckIfInPlayground() {
  local PROJ_NAME="${1/@/}"
  if [[ -d "${LIQ_PLAYGROUND}/${PROJ_NAME}" ]]; then
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
  local PROJ_NAME="${1/@/}"

  cd "${LIQ_PLAYGROUND}/${PROJ_NAME}"
  git config --get remote.upstream.url \
		|| echoerrandexit "Failed to get upstream remote URL for ${LIQ_PLAYGROUND}/${PROJ_NAME}"
}

# expects STAGING and PROJ_STAGE to be set declared by caller(s)
projectResetStaging() {
  local PROJ_NAME="${1}"
  STAGING="${LIQ_PLAYGROUND}/.staging"
  rm -rf "${STAGING}"
  mkdir -p "${STAGING}"

  PROJ_STAGE="$PROJ_NAME"
  PROJ_STAGE="${PROJ_STAGE%.*}" # remove '.git' if present
  PROJ_STAGE="${STAGING}/${PROJ_STAGE}"
}

# Expects 'PROJ_STAGE' to be declared local by the caller.
projectClone() {
  local URL="${1}"
  local ORIGIN_NAME="${2:-upstream}"

  projectCheckGitAuth

  local STAGING
  projectResetStaging $(basename "$URL")
  cd "$STAGING"

  echo "Cloning '${ORIGIN_NAME}'..."
  git clone --quiet --origin "$ORIGIN_NAME" "${URL}" || echoerrandexit "Failed to clone."

  if [[ ! -d "$PROJ_STAGE" ]]; then
    echoerrandexit "Did not find expected project direcotry '$PROJ_STAGE' in staging after cloning repo."
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
  git clone --quiet --origin workspace "${FORK_URL}" \
  && { \
    # Be sure and exit on errors to avoid a failure here and then executing the || branch
    echo "found existing fork."
    cd $PROJ_STAGE || echoerrandexit "Did not find expected staging dir: $PROJ_STAGE"
    echo "Updating remotes..."
    git remote add upstream "$URL" || echoerrandexit "Problem setting upstream URL."
    git fetch upstream || echoerrandexit "Could not fetch upstream data."
    git branch -u upstream/master master || echoerrandexit "Failed to configure upstream master."
    git pull || echoerrandexit "Failed to pull from upstream master."
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
  local NPM_ORG
  local PROJ_NAME="${1}"
  local PROJ_STAGE="${2}"
  NPM_ORG="$(dirname "$PROJ_NAME")"
  NPM_ORG="${NPM_ORG/@/}"
  mkdir -p "${LIQ_PLAYGROUND}/${NPM_ORG}"
  mv "$PROJ_STAGE" "$LIQ_PLAYGROUND/${NPM_ORG}" \
    || echoerrandexit "Could not moved staged '$PROJ_NAME' to playground. See above for details."
}

projectsRunPackageScript() {
  eval "$(setSimpleOptions IGNORE_MISSING SCRIPT_ONLY -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

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

# Accepts single NPM package name and exports 'PKG_ORG_NAME' and 'PKG_BASENAME'.
projectsSetPkgNameComponents() {
  PKG_ORG_NAME="$(dirname ${1/@/})"
  PKG_BASENAME="$(basename "$1")"
}
_QA_OPTIONS_SPEC="UPDATE OPTIONS="

## Main lib functions

# Assumes we are already in the BASE_DIR of the target project.
projectsNpmAudit() {
  eval "$(setSimpleOptions $_QA_OPTIONS_SPEC -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -n "$UPDATE" ]]; then
    npm audit fix
  else npm audit; fi
}

# Assumes we are already in the BASE_DIR of the target project.
projectsLint() {
  eval "$(setSimpleOptions $_QA_OPTIONS_SPEC -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -z "$UPDATE" ]]; then
    projectsRunPackageScript lint
  else projectsRunPackageScript lint-fix; fi
}

# Runs checks that 'package.json' conforms to Liquid Project standards. This is very much non-exhaustive.
projectsLiqCheck() {
  findBase
  if ! [[ -f "${BASE_DIR}/package.json" ]]; then
    echoerr "No 'package.json' found."
    return 1
  fi
  local ORG_BASE

  ORG_BASE="$(cat "${BASE_DIR}/package.json" | jq ".liquidDev.orgBase" | tr -d '"')"
  # no idea why, but this is outputting 'null' on blanks, even though direct testing doesn't
  ORG_BASE=${ORG_BASE/null/}
  if [[ -z "$ORG_BASE" ]]; then
    # TODO: provide reference to docs.
    echoerr "Did not find '.liquidDev.orgBase' in 'package.json'. Add this to your 'package.json' to define the NPM package name or URL pointing to the base, public org repository."
  fi
}

projectsVersionCheck() {
  projectsRequireNpmCheck
  # we are temporarily disabling the config manegement options
  # see https://github.com/Liquid-Labs/liq-cli/issues/94
  # IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS=
  eval "$(setSimpleOptions $_QA_OPTIONS_SPEC IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS= -- "$@")" \
    || ( help-projects; echoerrandexit "Bad options." )

  local IGNORED_PACKAGES=""
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
      echoerrandexit "Cannot 'ignore' and 'unignore' projects in same command."
    fi

    projectsVersionCheckManageIgnored
  elif [[ -n "$SHOW_CONFIG" ]]; then
    projectsVersionCheckShowConfig
  elif [[ -n "$OPTIONS_SET" ]] && (( $_OPTS_COUNT == 1 )); then
    projectsVersionCheckSetOptions
  else # actually do the check
    projectsVersionCheckDo
  fi
}

## helper functions

projectsRequireNpmCheck() {
  # TODO: offer to install
  if ! which -s npm-check; then
    echoerr "'npm-check' not found; could not check package status. Install with:"
    echoerr ''
    echoerr '    npm install -g npm-check'
    echoerr ''
    exit 10
  fi
}

projectsVersionCheckManageIgnored() {
  local IPACKAGES IPACKAGE
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
        echoerr "No projects currently ignored."
      else
        echo "No projects currently ignored."
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
    projectsVersionCheck -c
  fi
}

projectsVersionCheckShowConfig() {
  if [[ -z "$IGNORED_PACKAGES" ]]; then
    echo "Ignored projects: none"
  else
    echo "Ignored projects:"
    echo "$IGNORED_PACKAGES" | tr " " "\n" | sed -E 's/^/  /'
  fi
  if [[ -z "$CMD_OPTS" ]]; then
    echo "Additional options: none"
  else
    echo "Additional options: $CMD_OPTS"
  fi
}

projectsVersionCheckSetOptions() {
  if [[ -n "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","options"]; "'$OPTIONS'")')
  elif [[ -z "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'del(.catalyst."version-check".options)')
  fi
  echo "$PACKAGE" > "$PACKAGE_FILE"
}

projectsVersionCheckDo() {
  for IPACKAGE in $IGNORED_PACKAGES; do
    CMD_OPTS="${CMD_OPTS} -i ${IPACKAGE}"
  done
  if [[ -n "$UPDATE" ]]; then
    CMD_OPTS="${CMD_OPTS} -u"
  fi
  npm-check ${CMD_OPTS} || true
}

projects-issues() {
  local ACTION="${1}"; shift

  if [[ $(type -t "projects-issues-${ACTION}" || echo '') == 'function' ]]; then
    projects-issues-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" projects issues
  fi
}

# see 'liq help org issues show'
projects-issues-show() {
  eval "$(setSimpleOptions MINE -- "$@")"

  findBase

  local URL
  URL=$(cat "$BASE_DIR/package.json" | jq -r '.bugs.url' )

  if [[ -n "$MINE" ]]; then
    local MY_GITHUB_NAME
    projectHubWhoami MY_GITHUB_NAME
    open "${URL}/assigned/${MY_GITHUB_NAME}"
  else
    open "${URL}"
  fi
}
help-projects-issues() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}projects issues${reset} <action>: Manage organization issues." || cat <<EOF
${PREFIX}${cyan_u}projects issues${reset} <action>:
$(help-projects-issues-show | sed -e 's/^/  /')
EOF
}

help-projects-issues-show() {
  cat <<EOF
${underline}show${reset} [--mine|-m]:
  Displays the open issues for the current project. With '--mine', will attempt to get the user's GitHub name
  and show them their own issues.
EOF
}

# deprecated
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
${PREFIX}${cyan_u}required-services${reset} <action>:
  ${underline}list${reset} [<project name>...]: Lists the services required by the named current or named project.
  ${underline}add${reset} [<package name>]: Add a required service.
  ${underline}delete${reset} [<package name>] <name>: Deletes a required service.

${red_b}Deprated: These commands will migrate under 'project'.${reset}

The 'add' action works interactively. Non-interactive alternatives will be
provided in future versions.

The ${underline}package name${reset} parameter in the 'add' and 'delete' actions is optional if
there is a single package in the current repository.
EOF
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
  eval "$(setSimpleOptions POP TEST NO_SYNC -- "$@")"
  source "${LIQ_WORK_DB}/curr_work"

  local PROJECTS
  if (( $# > 0 )); then
    PROJECTS="$@"
  else
    PROJECTS="$INVOLVED_PROJECTS"
  fi

  local PROJECT
  # first, do the checks
  for PROJECT in $PROJECTS; do
    PROJECT=$(workConvertDot "$PROJECT")
    PROJECT="${PROJECT/@/}"
    local CURR_BRANCH
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    CURR_BRANCH=$(workCurrentWorkBranch)

    if [[ "$CURR_BRANCH" != "$WORK_BRANCH" ]]; then
      echoerrandexit "Local project '$PROJECT' repo branch does not match expected work branch."
    fi

    requireCleanRepo "$PROJECT"
  done

  # now actually do the closures
  for PROJECT in $PROJECTS; do
    PROJECT=$(workConvertDot "$PROJECT")
    PROJECT="${PROJECT/@/}"
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    local CURR_BRANCH
    CURR_BRANCH=$(git branch | (grep '*' || true) | awk '{print $2}')

    git checkout master
    git push workspace "${WORK_BRANCH}:${WORK_BRANCH}" \
      || echoerrandexit "Could not push '${WORK_BRANCH}' to workspace; refusing to close without backing up."
    git branch -qd "$WORK_BRANCH" \
      || ( echoerr "Could not delete local '${WORK_BRANCH}'. This can happen if the branch was renamed." \
          && false)
    list-rm-item INVOLVED_PROJECTS "@${PROJECT}" # this cannot be done in a subshell
    workUpdateWorkDb
		if [[ -z "$NO_SYNC" ]]; then
			projects-sync
		fi
    # Notice we don't close the workspace branch. It may be involved in a PR and, generally, we don't care if the
    # workspace gets a little messy. TODO: reference workspace cleanup method here when we have one.
  done

  # If all involved projects are closed, then our work is done.
  if [[ -z "${INVOLVED_PROJECTS}" ]]; then
    rm "${LIQ_WORK_DB}/curr_work"
    rm "${LIQ_WORK_DB}/${WORK_BRANCH}"

    if [[ -n "$POP" ]]; then
      work-resume --pop
    fi
  fi
}

# Helps get users find the right command.
work-commit() {
  # The command generator is a bit hackish; do we have a library that handles the quotes correctly?
  echoerrandexit "Invalid action 'commit'; do you want to 'save'?\nRefer to:\nliq help work save\nor try:\nliq work save $(for i in "$@"; do if [[ "$i" == *' '* ]]; then echo -n "'$i' "; else echo -n "$i "; fi; done)"
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
  local PROJECT_NAME WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "There is no active unit of work to involve. Try:\nliq work resume"
  fi

  if (( $# == 0 )) && [[ -n "$BASE_DIR" ]]; then
    requirePackage
    PROJECT_NAME=$(echo "$PACKAGE" | jq --raw-output '.name | @sh' | tr -d "'")
    PROJECT_NAME=${PROJECT_NAME/@/}
  else
    exactUserArgs PROJECT_NAME -- "$@"
    PROJECT_NAME=${PROJECT_NAME/@/}
    test -d "${LIQ_PLAYGROUND}/${PROJECT_NAME}" \
      || echoerrandexit "Invalid project name '$PROJECT_NAME'. Perhaps it needs to be imported? Try:\nliq playground import <git URL>"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local BRANCH_NAME=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
  requirePackage # used later if auto-linking

  cd "${LIQ_PLAYGROUND}/${PROJECT_NAME}"
  if git branch | grep -qE "^\*? *${BRANCH_NAME}\$"; then
    echowarn "Found existing work branch '${BRANCH_NAME}' in project ${PROJECT_NAME}. We will use it. Please fix manually if this is unexpected."
    git checkout -q "${BRANCH_NAME}" || echoerrandexit "There was a problem checking out the work branch. ($?)"
  else
    git checkout -qb "${BRANCH_NAME}" || echoerrandexit "There was a problem creating the work branch. ($?)"
    git push --set-upstream workspace ${BRANCH_NAME}
    echo "Created work branch '${BRANCH_NAME}' for project '${PROJECT_NAME}'."
  fi

  list-add-item INVOLVED_PROJECTS "@${PROJECT_NAME}" # do include the '@' here for display
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
        # projects-link "${PROJECT_NAME}:${NEW_PACKAGE_NAME}"
      fi
    done < <(find "${LIQ_PLAYGROUND}/${PROJECT_NAME}" -name "package.json" -not -path "*node_modules/*")
  fi
}

work-issues() {
  eval "$(setSimpleOptions LIST ADD= REMOVE= -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

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
  if (( $# == 0 )) && ! yes-no "Are you sure want to merge the entire unit of work? (y/N)" 'N'; then
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
    TM=${TM/@/}
    cd "${LIQ_PLAYGROUND}/${TM}"
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

  source "${LIQ_WORK_DB}/curr_work"
  for PROJECT in $INVOLVED_PROJECTS; do
    PROJECT="${PROJECT/@/}"
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    projects-qa "$@"
  done
} # work merge

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

# See 'liq help work resume'
work-resume() {
  eval "$(setSimpleOptions POP -- "$@")"
  local WORK_NAME
  if [[ -z "$POP" ]]; then
    workUserSelectOne WORK_NAME '' true "$@"

    if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
      if [[ "${LIQ_WORK_DB}/curr_work" -ef "${LIQ_WORK_DB}/${WORK_NAME}" ]]; then
        echowarn "'$WORK_NAME' is already the current unit of work."
        exit 0
      fi
    fi
  elif [[ -f "${LIQ_WORK_DB}/prev_work00" ]]; then
    local PREV_WORK
    PREV_WORK="$(ls ${LIQ_WORK_DB}/prev_work?? | sort --reverse | head -n 1)"
    mv "$PREV_WORK" "${LIQ_WORK_DB}/curr_work"
    WORK_NAME="$(source ${LIQ_WORK_DB}/curr_work; echo "$WORK_BRANCH")"
  else
    echoerrandexit "No previous unit of work found."
  fi

  requireCleanRepos "${WORK_NAME}"

  workSwitchBranches "$WORK_NAME"
  (
    cd "${LIQ_WORK_DB}"
    rm -f curr_work
    ln -s "${WORK_NAME}" curr_work
  )

  echo "Resumed '$WORK_NAME'."
}

# Alias for 'work-resume'
work-join() { work-resume "$@"; }

work-save() {
  eval "$(setSimpleOptions ALL MESSAGE= DESCRIPTION= NO_BACKUP:B BACKUP_ONLY -- "$@")"

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
  eval "$(setSimpleOptions ALL INTERACTIVE REVIEW DRY_RUN -- "$@")"

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

  local WORK_NAME LOCAL_COMMITS REMOTE_COMMITS
  workUserSelectOne WORK_NAME "$((test -n "$SELECT" && echo '') || echo "true")" '' "$@"

  if [[ "$PR_READY" == true ]]; then
    git fetch workspace "${WORK_NAME}:remotes/workspace/${WORK_NAME}"
    TMP="$(git rev-list --left-right --count $WORK_NAME...workspace/$WORK_NAME)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    (( $LOCAL_COMMITS == 0 )) && (( $REMOTE_COMMITS == 0 ))
    return $?
  fi

  if [[ -z "$NO_FETCH" ]]; then
    work-sync --fetch-only
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
    IP="${IP/@/}"
    echo
    echo "Repo status for $IP:"
    cd "${LIQ_PLAYGROUND}/$IP"
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
  findBase

  eval "$(setSimpleOptions ISSUES= PUSH -- "$@")"

  local CURR_PROJECT ISSUES_URL BUGS_URL WORK_ISSUES
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
    || echoerrandexit "Work description must begin with a letter or number, contain only letters, numbers, dashes and spaces, and have at least 2 characters (/$WORK_DESC_SPEC/). Got: \n${WORK_DESC}"

  WORK_STARTED=$(date "+%Y.%m.%d")
  WORK_INITIATOR=$(whoami)
  WORK_BRANCH=`workBranchName "${WORK_DESC}"`

  if [[ -f "${LIQ_WORK_DB}/${WORK_BRANCH}" ]]; then
    echoerrandexit "Unit of work '${WORK_BRANCH}' aready exists. Bailing out."
  fi

  # TODO: check that current work branch is clean before switching away from it
  # https://github.com/Liquid-Labs/liq-cli/issues/14

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    if [[ -n "$PUSH" ]]; then
      local PREV_WORK LAST NEXT
      LAST='-1' # starts us at 0 after the undconditional +1
      if [[ -f ${LIQ_WORK_DB}/prev_work00 ]]; then
        for PREV_WORK in $(ls ${LIQ_WORK_DB}/prev_work?? | sort); do
          LAST=${i:$((${#i} - 2))}
        done
      fi
      NEXT=$(( $LAST + 1 ))
      if (( $NEXT > 99 )); then
        echoerrandexit "There are already 100 'pushed' units of work; limit reached."
      fi
      mv "${LIQ_WORK_DB}/curr_work" "${LIQ_WORK_DB}/prev_work$(printf '%02d' "${NEXT}")"
    else
      rm "${LIQ_WORK_DB}/curr_work"
    fi
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
  eval "$(setSimpleOptions KEEP_CHECKOUT -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

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
    echoerrandexit "No current unit of work. Try:\nliq projects sync"
  fi

  source "${LIQ_WORK_DB}/curr_work"
  local IP OPTS
  if [[ -n "$FETCH_ONLY" ]]; then OPTS="--fetch-only "; fi
  for IP in $INVOLVED_PROJECTS; do
    echo "Syncing project '${IP}'..."
    projects-sync ${OPTS} "${IP}"
  done
}

work-test() {
  eval "$(setSimpleOptions SELECT -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local WORK_NAME
  workUserSelectOne WORK_NAME "$((test -n "$SELECT" && echo '') || echo "true")" '' "$@"
  source "${LIQ_WORK_DB}/${WORK_NAME}"

  local IP
  for IP in $INVOLVED_PROJECTS; do
    IP="${IP/@/}"
    echo "Testing ${IP}..."
    cd "${LIQ_PLAYGROUND}/${IP}"
    projects-test "$@"
  done
}

work-submit() {
  eval "$(setSimpleOptions MESSAGE= NOT_CLEAN:C NO_CLOSE:X NO_BROWSE:B -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current unit of work. Try:\nliq work select."
  fi

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
    # TODO: This is incorrect, we need to check IP; https://github.com/Liquid-Labs/liq-cli/issues/121
    # TODO: might also be redundant with 'requireCleanRepo'...
    if ! work-status --pr-ready; then
      echoerrandexit "Local work branch not in sync with remote work branch. Try:\nliq work save --backup-only"
    fi
  done

  for IP in $TO_SUBMIT; do
    IP=$(workConvertDot "$IP")
    IP="${IP/@/}"
    cd "${LIQ_PLAYGROUND}/${IP}"
    orgsSourceOrg
    ( # we source the policy in a subshell because the vars are not reliably refreshed, and so we need them isolated.
      # TODO: also, if the policy repo is the main repo and there are multiple orgs in[olved], this will overwrite
      # basic org settings... is that a problem?
      source "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}/settings.sh" # this is used in the submission checks

      local SUBMIT_CERTS
      echo "Checking for submission controls..."
      workSubmitChecks SUBMIT_CERTS

      echo "Creating PR for ${IP}..."

      local BUGS_URL
      BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

      local ISSUE=''
      local PROJ_ISSUES=''
      local OTHER_ISSUES=''
      for ISSUE in $WORK_ISSUES; do
        if [[ $ISSUE == $BUGS_URL* ]]; then
          local NUMBER=${ISSUE/$BUGS_URL/}
          NUMBER=${NUMBER/\//}
          list-add-item PROJ_ISSUES "#${NUMBER}"
        else
          list-add-item OTHER_ISSUES "${ISSUE}"
        fi
      done

      local BASE_TARGET # this is the 'org' of the upsteram branch
      BASE_TARGET=$(git remote -v | grep '^upstream' | grep '(push)' | sed -E 's|.+[/:]([^/]+)/[^/]+$|\1|')

      local DESC
      # recall, the first line is used in the 'summary' (title), the rest goes in the "description"
      DESC=$(cat <<EOF
Merge ${WORK_BRANCH} to master

## Summary

$MESSAGE

## Submission Certifications

${SUBMIT_CERTS}

## Issues
EOF)
      # populate issues lists
      if [[ -n "$PROJ_ISSUES" ]]; then
        if [[ -z "$NO_CLOSE" ]];then
          DESC="${DESC}"$'\n'$'\n'"$( for ISSUE in $PROJ_ISSUES; do echo "* closes $ISSUE"; done)"
        else
          DESC="${DESC}"$'\n'$'\n'"$( for ISSUE in $PROJ_ISSUES; do echo "* driven by $ISSUE"; done)"
        fi
      fi
      if [[ -n "$OTHER_ISSUES" ]]; then
        DESC="${DESC}"$'\n'$'\n'"$( for ISSUE in ${OTHER_ISSUES}; do echo "* involved with $ISSUE"; done)"
      fi

      local PULL_OPTS="--push --base=${BASE_TARGET}:master "
      if [[ -z "$NO_BROWSE" ]]; then
        PULL_OPTS="$PULL_OPTS --browse"
      fi
      hub pull-request $PULL_OPTS -m "${DESC}"
    ) # end policy-subshell
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
    repository in the current unit of work. When involved, any projects in the
    newly involved project will be linked to the primary project in the unit of
    work. The '--no-link' option will suppress this behavior.
  ${underline}issues${reset} [--list|--add|--remove]: Manages issues associated with the current unit of work.
    TODO: this should be re-worked as sub-group.
  ${underline}start${reset} [--issues <# or URL>] [--push] <name>:
    Creates a new unit of work and adds the current repository (if any) to it. You must specify at least one issue.
    Use a comma separated list to specify mutliple issues. The '--push' option will record the current unit of work
    which can then be recovered with 'liq work resume --pop'.
  ${underline}stop${reset} [-k|--keep-checkout]: Stops working on the current unit of work. The
    master branch will be checked out for all involved projects unless
    '--keep-checkout' is used.
  ${underline}resume${reset} [--pop] [<name>]:
    alias: ${underline}join${reset}
    Resume work or join an existing unit of work. If the '--pop' option is specified, then arguments will be
    ignored and the last 'pushed' unit of work (see 'liq work start --push') will be resumed.
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
  ${underline}submit${reset} [--message|-m <summary message>][--not-clean|-C] [--no-close|-X][<projects>]:
    Submits pull request for the current unit of work. With no projects specified, submits patches for all
    projects in the current unit of work. By default, PR will claim to close related issues unless
    '--no-close' is included.

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

# Runs submitter through interactive submit checks specified by company policy. Expects the CWD to be that of or within
# the project being submitted.
workSubmitChecks() {
  local RESULT_VAR="${1}"

  local POLICY_DIR CC_TYPE CHECKS_FILE QUESTION RECORD

  requirePackage
  local CC_QUERY='.liquidDev.changeControl.type'
  CC_TYPE="$(echo "$PACKAGE" | jq --raw-output "$CC_QUERY" | tr -d "'")"
  if [[ -z "$CC_TYPE" ]] || [[ "$CC_TYPE" == 'null' ]]; then
    echoerrandexit "Package '$PACKAGE_NAME' does not define '$CC_QUERY'; bailing out."
  fi

  local FIRST_REASON=true
  local HAS_EXCEPTIONS=''
  local DEF_REASON DEF_MITIGATION
  # you would think we wou we would declare these in 'getReasons', but bash is funny with vars, and the inner-function
  # locals (appearently) have strange effects and even 'unset'-ing them doesn't clear the vars as they appear to the
  # 'require-answer' function.
  local REASON MITIGATION
  getReasons() {
    unset REASON MITIGATION

    if [[ -n "${FIRST_REASON:-}" ]]; then
      echo
      yes-no "By continuing, you are submitting these changes with an explicit exception. Do you wish to continue? (yes/no) " \
        || { echo "Submission cancelled."; exit 0; }
      unset FIRST_REASON

      echo
      echofmt "reset" "(Your explanation may use markdown format, but it is not required.)"
      echo
    fi

    require-answer --multi-line "${yellow}Please provide a complete description as to why the exception is necessary:${reset} " REASON "$DEF_REASON"
    require-answer --multi-line "${yellow}Please describe the steps ALREADY TAKEN (such as creating a task to revisit the issue, etc.) to mitigate and/or address this exception in a timely manner:${reset} " MITIGATION "$DEF_MITIGATION"

    DEF_REASON="${REASON}"
    DEF_MITIGATION="${MITIGATION}"

    echofmt yellow "You will now be asked to review and confirm your answers. (Hit enter to continue.)"
    read
    echofmt green_b "Reason for the exception:"
    echo "${REASON}"
    echo "(Hit enter to continue)"
    read
    echofmt green_b "Steps taken to mitigate exception:"
    echo "${MITIGATION}"
    echo

    if yes-no "Are these statements true and complete? (yes/no) "; then
      RECORD="${RECORD}"$'\n'' '$'\n'"**_Reason given for excepion:_**"$'\n'"$REASON"$'\n'' '$'\n'"**_Steps taken to mitigate:_**"$'\n'"$MITIGATION"
    else
      getReasons
    fi
  }

  submitQuery() {
    local ANSWER
    require-answer "confirmed/no/cancel: " ANSWER
    ANSWER="$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]')"
    case "$ANSWER" in
      confirmed)
        RECORD="$RECORD"$'\n'"**_Answer:_** $ANSWER";;
      no)
        HAS_EXCEPTIONS=false
        RECORD="$RECORD"$'\n'"**_Answer:_** $ANSWER"
        getReasons;;
      cancel)
        echo "Submission cancelled."
        exit 0;;
      *)
        echoerr "You must fully spell out 'confirmed', 'no', or 'cancel'."
        submitQuery;;
    esac
  }

  # We setup named pipes that we use to feed the embedded reads without them stepping on each other.
  local POLICY_DIRS=/tmp/policy_dirs
  rm -f $POLICY_DIRS
  policiesGetPolicyDirs > $POLICY_DIRS
  exec 10< $POLICY_DIRS

  while read -u 10 POLICY_DIR; do
    local CHECKS_FILES=/tmp/checks_files
    rm -f $CHECKS_FILES
    find "${POLICY_DIR}" -path "*/policy/change-control/${CC_TYPE}/*" -name "*submit-checks.tsv" > $CHECKS_FILES
    exec 11< $CHECKS_FILES

    while read -u 11 CHECKS_FILE; do
      local QUESTIONS=/tmp/questions
      rm -f $QUESTIONS
      tail +2 "${CHECKS_FILE}" | perl -e '
        use strict; use warnings;
        while (<>) {
          if (!/^\s*$/) {
            my ($question, $absCondition) = split(/\t/, "$_");
            chomp($question);
            my $include = 1;
            if ($absCondition) {
              my @conditions = split(/\s*,\s*/, $absCondition);

              while (@conditions && $include) {
                my $condition = shift @conditions;
                $condition =~ s/HAS_TECHNICAL_OPS/$ENV{"HAS_TECHNICAL_OPS"}/;
                $condition =~ s/DEVELOPS_APPS/$ENV{"DEVELOPS_APPS"}/;
                $condition =~ s/GEN_SEC_LVL/$ENV{"GEN_SEC_LVL"}/;
                $condition =~ s/SEC_TRIVIAL/1/;

                eval "$condition" or $include = 0;
              }
            }

            print "$question\n" if $include;
          }
        }' > $QUESTIONS
      exec 12< $QUESTIONS

      local QUESTION_COUNT=1
      while read -u 12 QUESTION; do
        echo
        echofmt yellow "${QUESTION_COUNT}) $QUESTION"
        if [[ -z "$RECORD" ]]; then
          RECORD="### $QUESTION"
        else
          RECORD="$RECORD"$'\n'$'\n'"### $QUESTION"
        fi

        submitQuery
        QUESTION_COUNT=$(( $QUESTION_COUNT + 1 ))
      done
      exec 12<&-
      rm "$QUESTIONS"
    done
    exec 11<&-
    rm "$CHECKS_FILES"
  done
  exec 10<&-
  rm "$POLICY_DIRS"

  if [[ -z "$HAS_EXCEPTIONS" ]]; then
    RECORD="**All certifications satisfied.**"$'\n'$'\n'"${RECORD}"
  else
    RECORD="**EXCEPTIONS PRESENT.**"$'\n'$'\n'"${RECORD}"
  fi

  eval $RESULT_VAR='"${RECORD}"'
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
  local _BRANCH_NAME="$1"
  ( # the following source is probably OK, expected, and/or redundant in many cases, but just in case, we protect with
    # a subshell
    source "${LIQ_WORK_DB}/${_BRANCH_NAME}"
    local IP
    for IP in $INVOLVED_PROJECTS; do
      IP="${IP/@/}"

      if [[ ! -d "${LIQ_PLAYGROUND}/${IP}" ]]; then
        echoerr "Project @${IP} is not locally available. Try:\nliq projects import ${IP}\nliq work resume ${WORK_NAME}"
        continue
      fi

      echo "Updating project '$IP' to branch '${_BRANCH_NAME}'"
      cd "${LIQ_PLAYGROUND}/${IP}"
      if git show-ref --verify --quiet "refs/heads/${_BRANCH_NAME}"; then
        git checkout "${_BRANCH_NAME}" \
          || echoerrandexit "Error updating '${IP}' to work branch '${_BRANCH_NAME}'. See above for details."
      else # the branch is not locally availble, but lets check the workspace
        echo "Work branch not locally available, checking workspace..."
        git fetch --quiet workspace
        if git show-ref --verify --quiet "refs/remotes/workspace/${_BRANCH_NAME}"; then
          git checkout --track "workspace/${_BRANCH_NAME}" \
            || echoerrandexit "Found branch on workspace, but there were problems checking it out."
        else
          echoerrandexit "Could not find the indicated work branch either localaly or on workspace. It is possible the work has been completed or dropped."
          # TODO: long term, we want to be able to resurrect old branches, and we'd offer that as a 'try' option here.
        fi
      fi
    done
  ) # source-isolating subshel
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
			exitUnknownHelpTopic "$GROUP"
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
      exitUnknownHelpTopic "$ACTION" "$GROUP"
    fi;;
esac

exit 0
