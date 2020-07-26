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
  if [[ -z "${!1:-}" ]]; then
    echo -n "0"
  else
    echo -e "${!1}" | wc -l | tr -d '[:space:]'
  fi
}

list-from-csv() {
  local LIST_VAR="${1}"
  local CSV="${2:-}"

  if [[ -z "$CSV" ]]; then
    CSV="${!LIST_VAR}"
    unset ${LIST_VAR}
  fi

  if [[ -n "$CSV" ]]; then
    local ADDR
    while IFS=',' read -ra ADDR; do
      for i in "${ADDR[@]}"; do
        i="$(echo "$i" | awk '{$1=$1};1')"
        list-add-item "$LIST_VAR" "$i"
      done
    done <<< "$CSV"
  fi
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

# Echoes the frist item in the named list matching the given prefix.
#
# Example:
# LIST="foo bar"$'\n'"foo baz"
# list-get-item-by-prefix LIST "foo " # echoes 'foo bar'
list-get-item-by-prefix() {
  local LIST_VAR="${1}"
  local PREFIX="${2}"

  local ITEM
  while read -r ITEM; do
    if [[ "${ITEM}" == "${PREFIX}"* ]] ; then
      echo -n "${ITEM%\\n}"
      return
    fi
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
    echo -n "$ITEM"
    CURR_INDEX=$(($CURR_INDEX + 1))
    if (( $CURR_INDEX < $COUNT )) ; then
      echo -ne "$JOIN_STRING"
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
    NEW_ITEMS="$(echo "${!LIST_VAR}" | sed -e '\#^'"${ITEM}"'$#d')"
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

field-to-label() {
  local FIELD="${1}"
  echo "${FIELD:0:1}$(echo "${FIELD:1}" | tr '[:upper:]' '[:lower:]' | tr '_' ' ')"
}

echo-label-and-values() {
  eval "$(setSimpleOptions STDERR:e -- "$@")"

  local FIELD="${1}"
  local VALUES="${2:-}"
  (( $# == 2 )) || VALUES="${!FIELD:-}"
  local OUT

  OUT="$(echo -n "$(field-to-label "$FIELD"): ")"
  if (( $(echo "${VALUES}" | wc -l) > 1 )); then
    OUT="${OUT}$(echo -e "\n${VALUES}" | sed '2,$ s/^/   /')" # indent
  else # just one line
    OUT="${OUT}$(echo "${VALUES}")"
  fi

  if [[ -z "$STDERR" ]]; then # echo to stdout
    echo -e "$OUT"
  else
    echo -e "$OUT" >&2
  fi
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
  eval "$(setSimpleOptions VERIFY PROMPTER= SELECTOR= DEFAULTER= -- "$@")"
  local FIELDS="${1}"

  local FIELD VERIFIED
  while [[ "${VERIFIED}" != true ]]; do
    # collect answers
    for FIELD in $FIELDS; do
      local LABEL
      LABEL="$(field-to-label "$FIELD")"

      local PROMPT DEFAULT SELECT_OPTS
      PROMPT="$({ [[ -n "$PROMPTER" ]] && $PROMPTER "$FIELD" "$LABEL"; } || echo "${LABEL}: ")"
      DEFAULT="$({ [[ -n "$DEFAULTER" ]] && $DEFAULTER "$FIELD"; } || echo '')"
      if [[ -n "$SELECTOR" ]] && SELECT_OPS="$($SELECTOR "$FIELD")" && [[ -n "$SELECT_OPS" ]]; then
        local FIELD_SET="${FIELD}_SET"
        if [[ -z ${!FIELD:-} ]] && [[ "${!FIELD_SET}" != 'true' ]] || [[ "$VERIFIED" == false ]]; then
          unset $FIELD
          PS3="${PROMPT}"
          selectDoneCancel "$FIELD" SELECT_OPS
          unset PS3
        fi
      else
        local OPTS=''
        # if VERIFIED is set, but false, then we need to force require-answer to set the var
        [[ "$VERIFIED" == false ]] && OPTS='--force '
        if [[ "${FIELD}" == *: ]]; then
          FIELD=${FIELD/%:/}
          OPTS="${OPTS}--multi-line "
        fi

        require-answer ${OPTS} "${PROMPT}" $FIELD "$DEFAULT"
      fi
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
        echo-label-and-values "${FIELD}" "${!FIELD:-}"
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
    list-add-item $_VAR_NAME "$_SELECTION"
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
        echo-label-and-values --stderr "Current selection" "${!_VAR_NAME}"
      else
        echo-label-and-values --stderr "Final selection" "${!_VAR_NAME:-}"
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
  # if we don't supress the output, then we get noise even when successful
  ssh -qT git@github.com 2> /dev/null || if [ $? -ne 1 ]; then
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
# Global constants.
LIQ_DB="${HOME}/.liquid-development"
LIQ_SETTINGS="${LIQ_DB}/settings.sh"
LIQ_ENV_DB="${LIQ_DB}/environments"
LIQ_ORG_DB="${LIQ_DB}/orgs"
LIQ_WORK_DB="${LIQ_DB}/work"
LIQ_EXTS_DB="${LIQ_DB}/exts"
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
CATALYST_COMMAND_GROUPS="help meta meta-exts orgs projects work work-links"

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
    for GROUP in $CATALYST_COMMAND_GROUPS; do
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
      HELP_SPEC="${HELP_SPEC}-${1}"
      shift
    done

    help-${HELP_SPEC} "liq "
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
    meta-lib-setup-liq-db > /dev/null
  else
    meta-lib-setup-liq-db
  fi
}

meta-bash-config() {
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
}

meta-next() {
  eval "$(setSimpleOptions TECH_DETAIL ERROR -- "$@")"

  local COLOR="green"
  [[ -z "$ERROR" ]] || COLOR="red"

  if [ ! -d "$HOME/.liquid-development" ]; then
    [[ -z "$TECH_DETAIL" ]] || TECH_DETAIL=" (expected ~/.liquid-development)"
    echofmt $COLOR "It looks like liq CLI hasn't been setup yet$TECH_DETAIL. Try:\nliq meta init"
  elif [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    source "${LIQ_WORK_DB}/curr_work"
    local PROJ DONE
    export DONE
    for PROJ in $INVOLVED_PROJECTS; do
      PROJ=${PROJ/@/}
      cd "$LIQ_PLAYGROUND/${PROJ}"
      if [[ -n "$(git status --porcelain)" ]]; then
        echofmt $COLOR "It looks like you were worknig on '${WORK_DESC}' and have uncommitted changes in '${PROJ}'. Try:\n\nliq work save -m 'commit message' --project $PROJ\n\nOr, to use 'liq work stage' with 'liq work save' to save sets of files with different messages.\n\nOr, to get an overview of all work status, try:\n\nliq work status."
        DONE=true
        break
      fi
    done
    if [[ "$DONE" != "true" ]]; then
      echofmt $COLOR "It looks like you were worknig on '${WORK_DESC}' and everything is committed. If ready to submit changes, try:\nliq work submit"
    fi
  elif requirePackage; then
    echofmt $COLOR "Looks like you're currently in project '$PACKAGE_NAME'. You could start working on an issue. Try:\nliq work start ..."
  else
    echofmt $COLOR "Choose a project and 'cd' there."
  fi

  [[ -z "$ERROR" ]] || exit 1
}
META_GROUPS="exts"

help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles liq self-config and meta operations." \
   || cat <<EOF
${PREFIX}${cyan_u}meta${reset} <action>:
  Manages local liq configurations and non-liq user resources.
$(_help-actions-list meta bash-config init next | indent)
$(_help-sub-group-list meta META_GROUPS)
EOF
}

help-meta-bash-config() {
  cat <<EOF | _help-func-summary bash-config
Prints bash configuration. Try:\neval "\$(liq meta bash-config)"
EOF
}

help-meta-init() {
  cat <<EOF | _help-func-summary init "[--silent|-s] [--playground|-p <absolute path>]"
Creates the Liquid Development DB (a local directory) and playground.
EOF
}

help-meta-next() {
  cat <<EOF | _help-func-summary next "[--tech-detail|-t] [--error|-e]"
Analyzes current state of play and suggests what to do next. '--tech-detail' may provide additional technical information for the curious or liq developers.

Regular users can ignore the '--error' option. It's an internal option allowing the 'next' action to be leveraged to for error information and hints when appropriate.
EOF
}
meta-lib-setup-liq-db() {
  # TODO: check LIQ_PLAYGROUND is set
  create-dir() {
    local DIR="${1}"
    echo -n "Creating Liquid Dev DB ('${DIR}')... "
    mkdir -p "$DIR" \
      || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development DB (${DIR})\nSee above for further details.")
    echo "${green}success${reset}"
  }
  create-dir "$LIQ_DB"
  create-dir "$LIQ_ENV_DB"
  create-dir "$LIQ_WORK_DB"
  create-dir "$LIQ_EXTS_DB"
  create-dir "$LIQ_ENV_LOGS"
  create-dir "$LIQ_PLAYGROUND"
  echo -n "Initializing Liquid Dev settings... "
  cat <<EOF > "${LIQ_DB}/settings.sh" || (echo "${red}failed${reset}"; echoerrandexit "Error creating Liquid Development settings.")
LIQ_PLAYGROUND="$LIQ_PLAYGROUND"
EOF
  echo "${green}success${reset}"
}
meta-exts() {
  local ACTION="${1}"; shift

  if [[ $(type -t "meta-exts-${ACTION}" || echo '') == 'function' ]]; then
    meta-exts-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" meta exts
  fi
}

meta-exts-install() {
  eval "$(setSimpleOptions LOCAL REGISTRY -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -n "$LOCAL" ]] && [[ -n "$REGISTRY" ]]; then
    echoerrandexit "The '--local' and '--registry' options are mutually exclusive."
  fi

  local PKGS="$@"
  PKGS="${PKGS//@/}"
  cd "${LIQ_EXTS_DB}"

  [[ -f 'exts.sh' ]] || touch './exts.sh'

  if [[ -n "${LOCAL}" ]]; then
    npm i "${LIQ_PLAYGROUND}/${PKGS}"
  else
    npm i "@${PKGS}"
  fi
  local PKG
  for PKG in ${PKGS//@/}; do
    local PKG_DIR
    PKG_DIR="$(npm explore @${PKG} -- pwd)"
    echo "source '${PKG_DIR}/dist/ext.sh'" >> './exts.sh'
    echo "source '${PKG_DIR}/dist/comp.sh'" >> './comps.sh'
  done
}

meta-exts-list() {
  ! [[ -f "${LIQ_EXTS_DB}/exts.sh" ]] \
    || cat "${LIQ_EXTS_DB}/exts.sh" | awk -F/ 'NF { print $(NF-3)"/"$(NF-2) }'
}

meta-exts-uninstall() {
  local PKGS="$@"
  PKGS="${PKGS//@/}"
  cd "${LIQ_EXTS_DB}"

  [[ -f 'exts.sh' ]] || touch './exts.sh'

  # npm uninstall "@${PKGS}"

  local NEW_EXTS NEW_COMPS PKG
  NEW_EXTS="$(cat './exts.sh')"
  NEW_COMPS="$(cat './comps.sh')"
  for PKG in ${PKGS//@/}; do
    NEW_EXTS="$(echo -n "$NEW_EXTS" \
      | { grep -Ev "${PKG}/dist/ext.sh'\$" || echowarn "No such extension found: '${PKG}'"; })"
    NEW_COMPS="$(echo -n "$NEW_COMPS" | { grep -Ev "${PKG}/dist/comp.sh'\$" || true; })"
  done

  echo "$NEW_EXTS" > './exts.sh'
  echo "$NEW_COMPS" > './comps.sh'
}
# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-meta-exts() {
  local SUMMARY="Manage liq extensions."

  handleSummary "${cyan_u}meta exts${reset} <action>: ${SUMMARY}" || cat <<EOF
${cyan_u}meta exts${reset} <action>:
  ${SUMMARY}
$(_help-actions-list meta-exts install list uninstall | indent)
EOF
}

help-meta-exts-install() {
  cat <<EOF | _help-func-summary install "[--local|-l] [--registry|-r] <pkg name[@version]...>"
Installs the named extension package. The '--local' option will use (aka, link to) the local package rather than installing via npm. The '--registry' option (which is the default) will install the package from the NPM registry.
EOF
}

help-meta-exts-list() {
  cat <<EOF | _help-func-summary list
Lists locally installed extensions.
EOF
}

help-meta-exts-uninstall() {
  cat <<EOF | _help-func-summary uninstall "<pkg name...>"
Removes the installed package. If the package is locally installed, the local package installation is untouched and it is simply no longer used by liq.
EOF
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
  eval "$(setSimpleOptions IMPORT_REFS:r -- "$@")"
  local PKG_NAME BASENAME ORG_NPM_NAME
  projects-import --set-name PKG_NAME "$@"
  # TODO: we can refine our logic here by indicating whether project is already imported or not.

  # TODO: check that the package is a 'base' org, and if not, skip and echowarn "This is not necessarily a problem."
  mkdir -p "${LIQ_ORG_DB}"
  projectsSetPkgNameComponents "$PKG_NAME"
  # If '--import-refs', then not surprising to find extant company.
  if [[ -L "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]] && [[ -z $IMPORT_REFS ]]; then
    echowarn "Found possible remnant file:\n${LIQ_ORG_DB}/${PKG_ORG_NAME}\n\nWill attempt to delete and continue. Refer to 'ls' output results below for more info."
    ls -l "${LIQ_ORG_DB}"
    rm "${LIQ_ORG_DB}/${PKG_ORG_NAME}"
    echo
  fi
  [[ -L "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]] \
    || ln -s "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}/${PKG_BASENAME}" "${LIQ_ORG_DB}/${PKG_ORG_NAME}"

  if [[ -n "$IMPORT_REFS" ]]; then
    local REF_REPO
    orgs-lib-source-settings "$(dirname "$PKG_NAME")"
    for REF_REPO in ORG_POLICY_REPO ORG_SENSITIVE_REPO ORG_STAFF_REPO; do
      if [[ -n ${!REF_REPO:-} ]]; then
        projects-import ${!REF_REPO}
      fi
    done
  fi
}

# see `liq help orgs list`
orgs-list() {
  find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; | sort
}

# see `liq help orgs show`
orgs-show() {
  eval "$(setSimpleOptions DIR PROJECT SETTINGS -- "$@")"
  findBase
  cd "${BASE_DIR}/.."
  local NPM_ORG
  NPM_ORG="$(basename "$PWD")"

  if ! [[ -e "${LIQ_ORG_DB}/${NPM_ORG}" ]]; then
    echoerrandexit "No base package found for '${NPM_ORG}'. Try:\nliq orgs import <base pkg|URL>"
  fi

  # Recall the org DB links the npm org name to the repo.
  { { [[ -n "$DIR" ]] && readlink "${LIQ_ORG_DB}/${NPM_ORG}"; } \
  || { [[ -n "$PROJECT" ]] && cat "${LIQ_ORG_DB}/${NPM_ORG}/package.json" | jq -r '.name'; } \
  || { [[ -n "$SETTINGS" ]] && cat "${LIQ_ORG_DB}/${NPM_ORG}/settings.sh"; } } || \
  { # the no specific format option
    cat <<EOF
Project: $(cat "${LIQ_ORG_DB}/${NPM_ORG}/package.json" | jq -r '.name')
Local dir:  $(readlink "${LIQ_ORG_DB}/${NPM_ORG}")
EOF
  }
}
ORGS_GROUPS=""

help-orgs() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages organizations and affiliations."

  handleSummary "${PREFIX}${cyan_u}orgs${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}orgs${reset} <action>:
$(echo "${SUMMARY} An org(anization) is the legal owner of work and all work is done in the context of an org. An org may represent a employer, an open source project, a department, or yourself. Certain policies and settings are defined at the org level which would then apply to all work done in that org.

* There is a 1-1 correspondance between the liq org, a GitHub organization (or individual), and—if publishing publicly—an npm package scope.
* The GitHub organization (or individual) must exist prior to creating an org." | fold -sw 80 | indent)
$(_help-actions-list orgs create close import list show | indent)
$(_help-sub-group-list orgs ORGS_GROUPS)
EOF
}

help-orgs-create() {
  cat <<EOF | _help-func-summary create "[--no-sensitive] [--no-staff] [-private-policy] <base org-package>"
Interactively gathers any org info not specified via CLI options and creates the indicated repos under the indicated GitHub org or user.

The following options may be used to specify fields from the CLI. If all required options are specified (even if blank), then the command will run non-interactively and optional fields will be set to default values unless specified:

* --common-name
* --legal-name
* --address (use $'\n' for linebreaks)
* --github-name
* (optional )--ein
* (optional) --naics
* (optional) --npm-registry$(

)
EOF
}

help-orgs-close() {
  cat <<EOF | _help-func-summary close "[--force] <name>..."
After checking that all changes are committed and pushed, closes the named org-project by deleting it from the local playground. '--force' will skip the 'up-to-date checks.
EOF
}

help-orgs-import() {
  cat <<EOF | _help-func-summary import "[--import-refs:r] <package or URL>"
Imports the 'base' org package into your playground. The '--import-refs' option will attempt to import any referenced repos. The access rights on referenced repos might be different than the base repo and could fail, in which case the script will attempt to move on to the next, if any.
EOF
}

help-orgs-list() {
  cat <<EOF | _help-func-summary list
Lists the currently affiliated orgs.
EOF
}

help-orgs-show() {
  cat <<EOF | _help-func-summary show "[--sensitive] [<org nick>]"
Displays info on the currently active or named org.
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
  orgs-lib-source-settings "${1:-}"

  echo "${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}"
}

# Sources the named base org settings or will infer org context. If the base org cannot be found, the execution will
# halt and the user will be advised to timport it.
orgs-lib-source-settings() {
  local NPM_ORG="${1:-}"

  if [[ -z "$NPM_ORG" ]]; then
    findBase
    NPM_ORG="$(cd "${BASE_DIR}/.."; basename "$PWD")"
  else
    NPM_ORG=${NPM_ORG/@/}
  fi

  if [[ -e "$LIQ_ORG_DB/${NPM_ORG}" ]]; then
    [[ -f "$LIQ_ORG_DB/${NPM_ORG}/settings.sh" ]] || echoerrandexit "Could not locate settings file for '${NPM_ORG}'."
    source "$LIQ_ORG_DB/${NPM_ORG}/settings.sh"
    
    ORG_CHART_TEMPLATE="${ORG_CHART_TEMPLATE/\~/$LIQ_PLAYGROUND}"
  else
    echoerrandexit "Did not find expected base org package. Try:\nliq orgs import <pkg || URL>"
  fi
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
  local PKG_ORG_NAME PKG_BASENAME
  # TODO: Support 'NPM_PASSTHRUOGH:P' which will use the NPM default values for version and license.
  eval "$(setSimpleOptions NEW= SOURCE= FOLLOW NO_FORK:F VERSION= LICENSE= DESCRIPTION= PUBLIC: ORG_BASE= -- "$@")"

  __PROJ_NAME="${1:-}"
  if [[ -z "${ORG_BASE}" ]]; then
    local ORG_BIT=$(dirname "${__PROJ_NAME/@/}")
    local ORG_LINK="${HOME}/.liquid-development/orgs/${ORG_BIT}"
    if [[ -L "$ORG_LINK" ]]; then
      ORG_BASE="$(cat "${ORG_LINK}/package.json" \
        | jq -r '.repository.url' \
        | sed -E -e 's|^[^/]*//[^/]+/||' -e 's/\.git$//')"
    else
      echoerrandexit "Could not determine org base through local checkouts; specify '--org-base <github org/repo>' for the project."
    fi
  fi

  # first, check that we can access GitHub
  check-git-access
  # TODO: check that the upstream and workspace projects don't already exist

  if [[ -n "$NEW" ]] && [[ -n "$SOURCE" ]]; then
    echoerrandexit "The '--new' and '--source' options are not compatible. Please refer to:\nliq help projects create"
  elif [[ -z "$NEW" ]] && [[ -z "$SOURCE" ]]; then
    echoerrandexit "You must specify one of the '--new' or '--source' options when creating a project.Please refer to:\nliq help projects create"
  fi

  if [[ -z "${__PROJ_NAME:-}" ]]; then
    if [[ -n "$SOURCE" ]]; then
      __PROJ_NAME=$(basename "$SOURCE" | sed -e 's/\.[a-zA-Z0-9]*$//')
      echo "Default project name to: ${__PROJ_NAME}"
    else
      echoerrandexit "Must specify project name for '--new' projects."
    fi
  fi

  projectsSetPkgNameComponents "${__PROJ_NAME}"
  if [[ "$PKG_ORG_NAME" == '.' ]]; then
    echoerrandexit "Must specify org scope in name when creating a project. E.g. 'my-org/my-project'."
  fi

  if [[ -e "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]]; then
    source "${LIQ_ORG_DB}/${PKG_ORG_NAME}/settings.sh"
  else
    echoerrandexit "Did not find base org repo for '$PKG_ORG_NAME'. Try:\nliq orgs import <base org pkg or URL>"
  fi

  local REPO_FRAG REPO_URL BUGS_URL README_URL
  REPO_FRAG="github.com/${ORG_GITHUB_NAME}/${PKG_BASENAME}"
  REPO_URL="git+ssh://git@${REPO_FRAG}.git"
  BUGS_URL="https://${REPO_FRAG}/issues"
  HOMEPAGE="https://${REPO_FRAG}#readme"

  update_pkg() {
    update_pkg_line ".name = \"@${ORG_NPM_SCOPE}/${PKG_BASENAME}\""
    [[ -n "$VERSION" ]] || VERSION='1.0.0-alpha.0'
    update_pkg_line ".version = \"${VERSION}\""
    [[ -n "$LICENSE" ]] \
      || { [[ -n "${ORG_DEFAULT_LICENSE:-}" ]] && LICENSE="$ORG_DEFAULT_LICENSE"; } \
      || LICENSE='UNLICENSED'
    update_pkg_line ".license = \"${LICENSE}\""
    update_pkg_line ".repository = { type: \"git\", url: \"${REPO_URL}\"}"
    update_pkg_line ".bugs = { url: \"${BUGS_URL}\"}"
    update_pkg_line ".homepage = \"${HOMEPAGE}\""
    if [[ -n "$DESCRIPTION" ]]; then
      update_pkg_line ".description = \"${DESCRIPTION}\""
    fi
  }

  update_pkg_line() {
    echo "$(cat package.json | jq "${1}")" > package.json
  }

  if [[ -n "$NEW" ]]; then
    local STAGING PROJ_STAGE
    projectResetStaging "$__PROJ_NAME"
    mkdir -p "${PROJ_STAGE}"
    cd "${PROJ_STAGE}"
    git init --quiet .
    npm init -y > /dev/null

    if [[ "$NEW" == "raw" ]]; then
      update_pkg
    else
      # TODO
      echoerr "Only the 'raw' type is currently supported in this alpha version."
    fi
    git add package.json
    git commit -m "packaage initialization"
  else
    projectClone "$SOURCE" 'source'
    cd "$PROJ_STAGE"
    git remote set-url --push source no_push

    echo "Setting up package.json..."
    # setup all the vars
    [[ -n "$VERSION" ]] || VERSION='1.0.0'

    [[ -f "package.json" ]] || echo '{}' > package.json

    update_pkg

    git add package.json
    git commit -m "setup and/or updated package.json"
  fi

  echo "Creating upstream repo..."
  local CREATE_OPTS="--remote-name upstream"
  if [[ -z "$PUBLIC" ]]; then CREATE_OPTS="${CREATE_OPTS} --private"; fi
  hub create --remote-name upstream ${CREATE_OPTS} -d "$DESCRIPTION" "${ORG_GITHUB_NAME}/${__PROJ_NAME}"
  local RETRY=4
  git push --all upstream || { echowarn "Upstream repo not yet available.";
    while (( $RETRY > 0 )); do
      echo "Waiting for upstream repo to stabilize..."
      local COUNTDOWN=3
      while (( $COUNTDOWN > 0 )); do
        echo -n "${COUNTDOWN}..."
        COUNTDOWN=$(( $COUNTDOWN - 1 ))
      done
      if (( $RETRY == 1 )); then
        git push --all upstream || echoerr "Could not push to upstream. Manually update."
      else
        { git push --all upstream && RETRY=0; } || RETRY=$(( $RETRY - 1 ))
      fi
    done;
  }

  if [[ -z "$NO_FORK" ]]; then
    echo "Creating fork..."
    hub fork --remote-name workspace
    git branch -u upstream/master master
  fi
  if [[ -z "$NEW" ]] && [[ -z "$FOLLOW" ]]; then
    echo "Un-following source repo..."
    git remote remove source
  fi

  echo "Adding basic liq data to package.json..."
  cat package.json | jq '. + { "liquidDev": { "orgBase": "git@github.com:'"${ORG_BASE}"'.git" } }' > package.new.json
  mv package.new.json package.json

  cd -
  projectMoveStaged "${PKG_ORG_NAME}/${PKG_BASENAME}" "$PROJ_STAGE"
  cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}/${PKG_BASENAME}"
  projects-setup
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

  fork_check() {
    local GIT_URL="${1:-}"
    local PRIVATE GIT_OWNER GIT REPO
    echo "URL: $GIT_URL"

    if [[ -z "$NO_FORK" ]]; then
      GIT_URL="$(echo "$GIT_URL" | sed -e 's/[^:]*://' -e 's/\.git$//')"
      echo "URL2: $GIT_URL"
      GIT_OWNER="$(basename "$(dirname "$GIT_URL")")"
      GIT_REPO="$(basename "$GIT_URL")"

      echo hub api -X GET "/repos/${GIT_OWNER}/${GIT_REPO}"
      PRIVATE="$(hub api -X GET "/repos/${GIT_OWNER}/${GIT_REPO}" | jq '.private')"
      if [[ "${PRIVATE}" == 'true' ]]; then
        NO_FORK='true'
      fi
    fi
  }

  if [[ "$1" == *:* ]]; then # it's a URL
    _PROJ_URL="${1}"
    fork_check "${_PROJ_URL}"
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
    fork_check "$_PROJ_URL"
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

projects-setup() {
  eval "$(setSimpleOptions PROJECT= SKIP_LABELS:L NO_DELETE_LABELS:D NO_UPDATE_LABELS:U SKIP_MILESTONES:M -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -z "$PROJECT" ]]; then
    requirePackage
    PROJECT="${PACKAGE_NAME}"
  fi
  PROJECT="${PROJECT/@/}"

  cd "${LIQ_PLAYGROUND}/${PROJECT}"
  if [[ -z "$PACKAGE_NAME" ]]; then
    requirePackage
  fi

  local GIT_BASE
  GIT_BASE="$(echo "${PACKAGE}" | jq -r '.repository.url')"
  if [[ "${GIT_BASE}" == *'github.com'*'git' ]]; then # it's a git URL
    GIT_BASE="$(echo "${GIT_BASE}" | awk -F/ '{ print $4"/"$5 }')"
    GIT_BASE="${GIT_BASE:0:$(( ${#GIT_BASE} - 4 ))}" # remove '.git'
  else
    echoerrandexit "'repository.url' from 'package.json' in unknown format; only github currently supported."
  fi

  [[ -n "$SKIP_LABELS" ]] || projects-lib-setup-labels-sync

  [[ -n "$SKIP_MILESTONES" ]] || {
    # Expects PACKAGE_NAME
    local CURR_MILESTONES EXPECTED_MILESTONES TYPICAL_MILESTONES
    CURR_MILESTONES="$(hub api "/repos/${GIT_BASE}/milestones" | jq -r ".[].title")"

    if [[ -n "$CURR_MILESTONES" ]]; then
      echo -e "Current milestones:\n$(echo "${CURR_MILESTONES}" | awk '{print "* "$0}')"
      echo
    else
      echo "No existing milestones found."
    fi

    local EXPECTED_MILESTONES_PRESENT=false
    local MILESTONES_SYNCED=true
    check-and-add-milestone() {
      local TITLE="${1}"
      local PRE_PROMPT="${2}"
      local DEFAULT="${3}"
      if [[ -z "$(list-get-index CURR_MILESTONES "${TITLE}")" ]]; then
        echowarn "${PRE_PROMPT}"
        if yes-no "Add it?" "${DEFAULT}"; then
          echo "Attempting to add milestone '${TITLE}'..."
          # hup api -X POST "/repos/${GIT_BASE}/milestones" -f title="${TITLE}"
        else
          MILESTONES_SYNCED=false
        fi
      fi
    }

    semver-to-milestone() {
      sed -E -e 's/([[:digit:]]+\.[[:digit:]]+)\.[[:digit:]]+/\1/' -e 's/\.[[:digit:]]+$//'
    }

    EXPECTED_MILESTONES="backlog"

    local CURR_VERSION CURR_PREID
    if npm search "${PACKAGE_NAME}" --parseable | grep -q "${PACKAGE_NAME}"; then
      CURR_VERSION="$(npm info "${PACKAGE_NAME}" version)"
    else
      # The package is not-published/not-findable.
      echowarn "Package '${PACKAGE_NAME}' not publised or not findable. Consider publishing."
      echowarn "Current version will be read locally."
      CURR_VERSION="$(echo "$PACKAGE" | jq -r '.version')"
    fi

    if [[ "${CURR_VERSION}" == *"-"* ]]; then # it's a pre-release version
      local NEXT_VER NEXT_PREID
      CURR_PREID="$(echo "${CURR_VERSION}" | cut -d- -f2 | cut -d. -f1)"
      if [[ "${CURR_PREID}" == 'alpha' ]]; then
        list-add-item EXPECTED_MILESTONES \
          "$(semver "$CURR_VERSION" --increment prerelease --preid beta | semver-to-milestone)"
      elif [[ "${CURR_PREID}" == 'rc' ]] || [[ "${CURR_PREID}" == 'beta' ]]; then
         # a released ver
        list-add-item EXPECTED_MILESTONES "$(semver "$CURR_VERSION" --increment | semver-to-milestone)"
      else
        echowarn "Unknown pre-release type '${CURR_PREID}'; defaulting to 'beta' as next target release. Consider updating released version to standard 'alpha', 'beta', or 'rc' types."
        list-add-item EXPECTED_MILESTONES \
          "$(semver "$CURR_VERSION" --increment prerelease --preid beta | semver-to-milestone)"
      fi
    else # it's a released version tag
      list-add-item TYPICAL_MILESTONES \
        "$(semver "$CURR_VERSION" --increment premajor --preid alpha | semver-to-milestone)"
      list-add-item TYPICAL_MILESTONES "$(semver "$CURR_VERSION" --increment minor | semver-to-milestone)"
    fi

    local TEST_MILESTONE
    if [[ -n "${EXPECTED_MILESTONES}" ]]; then
      while read -r TEST_MILESTONE; do
        check-and-add-milestone "${TEST_MILESTONE}" "Expected milestone '${TEST_MILESTONE}' is missing." Y
        [[ "${MILESTONES_SYNCED}" != true ]] || EXPECTED_MILESTONES_PRESENT=true
      done <<< "${EXPECTED_MILESTONES}"
    fi
    if [[ -n "${TYPICAL_MILESTONES}" ]]; then
      while read -r TEST_MILESTONE; do
        check-and-add-milestone "${TEST_MILESTONE}" "Potential next milestone '${TEST_MILESTONE}' not present." Y
      done <<< "${TYPICAL_MILESTONES}"
    fi

    [[ "${EXPECTED_MILESTONES_PRESENT}" != true ]] || echo "All expected milestones are present."
    [[ "${EXPECTED_MILESTONES_PRESENT}" == true ]] || echowarn "Expected milestones are missing."
  } # end SKIP_MILESTONES check
}

# see: liq help projects sync
projects-sync() {
  eval "$(setSimpleOptions FETCH_ONLY NO_WORK_MASTER_MERGE:M PROJECT= -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -z "$PROJECT" ]]; then
    [[ -n "${BASE_DIR:-}" ]] || findBase
    PROJECT="$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name' | tr -d "'")"
  fi
  PROJECT=${PROJECT/@/}
  local PROJ_DIR="${LIQ_PLAYGROUND}/${PROJECT}"

  if [[ -z "$NO_WORK_MASTER_MERGE" ]] && [[ -z "$FETCH_ONLY" ]]; then
    requireCleanRepo "$PROJECT"
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
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    # heh, need this to always be 'true' or 'set -e' complains
    [[ ! -d _master ]] || git worktree remove _master
  }

  REMOTE_COMMITS=$(git rev-list --right-only --count master...upstream/master)
  if (( $REMOTE_COMMITS > 0 )); then
    echo "Syncing with upstream master..."
    cd "${PROJ_DIR}"
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
      cd "${PROJ_DIR}/_master"
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
      if git diff-index --quiet HEAD "${PROJ_DIR}" \
         && git diff --quiet HEAD "${PROJ_DIR}"; then
        echowarn "Hmm... expected to see changes from master, but none appeared. It's possible the changes have already been incorporated/recreated without a merge, so this isn't necessarily an issue, but you may want to double check that everything is as expected."
      else
        if ! git diff-index --quiet HEAD "${PROJ_DIR}/dist" || ! git diff --quiet HEAD "${PROJ_DIR}/dist"; then # there are changes in ./dist
          echowarn "Backing out merge updates to './dist'; rebuild to generate current distribution:\nliq projects build $PROJECT"
          git checkout -f HEAD -- ./dist
        fi
        if git diff --quiet "${PROJ_DIR}"; then # no conflicts
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
    if type -t projects-services-list | grep -q 'function'; then
      requireEnvironment
      echo -n "Checking services... "
      if ! projects-services-list --show-status --exit-on-stopped --quiet > /dev/null; then
        if [[ -z "${NO_START:-}" ]]; then
          services-start || echoerrandexit "Could not start services for testing."
        else
          echo "${red}necessary services not running.${reset}"
          echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\nliq projects test --types=unit\nliq services start"
        fi
      else
        echo "${green}looks good.${reset}"
      fi
    fi # check if runtime extesions present
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" projectsRunPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\nliq projects test --type=unit" $?
}
PROJECTS_GROUPS=""

help-projects() {
  local PREFIX="${1:-}"

  local SUMMARY="Project configuration and tools."

  handleSummary "${PREFIX}${cyan_u}projects${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}projects${reset} <action>:
  ${SUMMARY}
$(_help-actions-list projects build close create import publish qa sync test | indent)
$(_help-sub-group-list projects PROJECTS_GROUPS)
EOF
}

help-projects-build() {
  cat <<EOF | _help-func-summary build "[<name>...]"
Builds the current or specified project(s).
EOF
}

help-projects-close() {
  cat <<EOF | _help-func-summary close "[<name>...]"
Closes (deletes from playground) either the current or named project after checking that all changes are committed and pushed. '--force' will skip the 'up-to-date checks.
EOF
}

help-projects-create() {
  cat <<EOF | _help-func-summary create "[[--new <type>] || [--source|-s <pkg|URL>] [--follow|-f]] [--no-fork|-F] [--version|-v <semver> ] [--license|-l <license name>] [--description|-d <desc>] [--public] [<project name>]"
Note, 'project name' should be a bare name. The scope is determined by the current org settings. An explicit name is required for '--new' projects. If no name is given for '--source' projects, then the base source name is used.

Creates a new Liquid project in one of two modes. If '--new' is specified, then the indicated type will be used to initiate a 'create' script. There are various '@liquid-labs/create-*' projects which may be used, and third-party or private scripts may developed as well. This essentially calls 'npm init <type>' and then sets up the GitHub repository and working repo (unless --no-fork is specified).

The 'raw' type is a built-in type that initiates a completly raw repo with just minimal 'package.json' defintion. The package attributes will be configured based on parameters with the version defaulting to '1.0.0-alpha.0' and 'license' defaulting to 'UNLICENSED'.

If '--source' is specified, will first clone the source repo as a starting point. This can be used to "convert" non-Liquid projects (from GitHub or other sources) as well as to create re-named duplicates of Liquid projects If set to '--follow' the source, then this effectively sets up a 'source' remote conceptually upstream from 'upstream' and future invocations of 'project sync' will attempt to merge changes from 'source' to 'upstream'. This can later be managed using the 'projects remotes' sub-group.

Regardless, the following 'package.json' fields will be set according to the following:
* the package will be scoped accourding to the org scope.
* 'project name' will be used to create a git repository under the org scope.
* the 'repository' and 'bugs' fields will be set to match.
* the 'homepage' will be set to the repo 'README.md' (#readme).
* version to '--version', otherwise '1.0.0'.
* license to the '--license', otherwise org's default license, otherwise 'UNLICENSED'.

Any compatible create script must conform to the above, though additional rules and/or interactions may added. Note, just because no option is given to change some of the above parameters they can, of course, be modified post-create (though they are "very standard" for Liquid projects).

Use 'liq projects import' to import an existing project from a URL.
EOF
}

help-projects-deploy() {
  cat <<EOF | _help-func-summary deploy "[<name>...]"
Deploys the current or named project(s).
EOF
}

help-projects-import() {
  cat <<EOF | _help-func-summary import "[--no-install] <package or URL>"
Imports the indicated package into your playground. The newly imported package will be installed unless '--no-install' is given.
EOF
}

help-projects-publish() {
  cat <<EOF | _help-func-summary publish
Performs verification tests, updates package version, and publishes package.
EOF
}

help-projects-qa() {
  cat <<EOF | _help-func-summary qa "[--update|-u] [--audit|-a] [--lint|-l] [--version-check|-v]"
Performs NPM audit, eslint, and NPM version checks. By default, all three checks are performed, but options can be used to select specific checks. The '--update' option instruct to the selected options to attempt updates/fixes.
EOF
}

help-projects-sync() {
  cat <<EOF | _help-func-summary sync "[--fetch-only|-f] [--no-work-master-merge|-M]"
Updates the remote master with new commits from upstream/master and, if currently on a work branch, workspace/master and workspace/<workbranch> and then merges those updates with the current workbranch (if any). '--fetch-only' will update the appropriate remote refs, and exit. --no-work-master-merge update the local master branch and pull the workspace workbranch, but skips merging the new master updates to the workbranch.
EOF
}

help-projects-test() {
  cat <<EOF | _help-func-summary test "[-t|--types <types>][-D|--no-data-reset][-g|--go-run <testregex>][--no-start|-S] [<name>]"
Runs unit tests the current or named projects.
* 'types' may be 'unit' or 'integration' (=='int') or 'all', which is default. Multiple tests may be specified in a comma delimited list. E.g., '-t=unit,int' is equivalent no type or '-t=""'.
* '--no-start' will skip tryng to start necessary services.
* '--no-data-reset' will cause the standard test DB reset to be skipped.
* '--no-service-check' will skip checking service status. This is useful when re-running tests and the services are known to be running.
* '--go-run' will only run those tests matching the provided regex (per go '-run' standards).
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

  check-git-access

  local STAGING
  projectResetStaging $(basename "$URL")
  cd "$STAGING"

  echo "Cloning '${ORIGIN_NAME}'..."
  git clone --quiet --origin "$ORIGIN_NAME" "${URL}" || echoerrandexit "Failed to clone."

  if [[ ! -d "$PROJ_STAGE" ]]; then
    echoerrandexit "Did not find expected project direcotry '$PROJ_STAGE' in staging after cloning repo."
  fi
}

# Returns true if the current working project has the dependency as either dep, dev, or peer.
projects-lib-has-any-dep() {
  local PROJ="${1}"
  local DEP="${2}"

  cat "${LIQ_PLAYGROUND}/${PROJ/@/}/package.json" | jq -r '.dependencies + .devDependencies + .peerDependencies + {} | keys' | grep -qE '"@?'${DEP}'"'
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

  check-git-access

  local PROJ_NAME ORG_URL GITHUB_NAME
  PROJ_NAME=$(basename "$URL")
  ORG_URL=$(dirname "$URL")
  projectHubWhoami GITHUB_NAME
  FORK_URL="$(echo "$ORG_URL" | sed 's|[a-zA-Z0-9-]*$||')/${GITHUB_NAME}/${PROJ_NAME}"

  local STAGING
  projectResetStaging $PROJ_NAME
  cd "$STAGING"

  echo -n "Checking for existing fork at '${FORK_URL}'... "
  git clone --quiet --origin workspace "${FORK_URL}" 2> /dev/null \
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
    hub fork --remote-name workspace > /dev/null
    git branch --quiet -u upstream/master master
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
# Expects:
# * NO_DELETE_LABELS, PROJECT, NO_UPDATE_LABELS from options, and
# * GIT_BASE and PACKAGE to be set.
projects-lib-setup-labels-sync() {
  local ORG_BASE ORG_PROJECT
  ORG_BASE="$(echo "${PACKAGE}" | jq -r '.liquidDev.orgBase' )"
  if [[ "${ORG_BASE}" == *'github.com'*'git' ]]; then # it's a git URL; convert to project name
    # separate the path element from the URL
    ORG_PROJECT="$(echo "${ORG_BASE}" | cut -d: -f2 )"
    ORG_PROJECT="${ORG_PROJECT:0:$(( ${#ORG_PROJECT} - 4 ))}" # remove '.git'
    local ORG_BIT PROJ_BIT
    # TODO: our defacto conventions are all over the place
    ORG_BIT="$(echo "${ORG_PROJECT}" | cut -d/ -f1 | tr '[:upper:]' '[:lower:]')"
    PROJ_BIT="$(echo "${ORG_PROJECT}" | cut -d/ -f2)"
    ORG_PROJECT="${ORG_BIT}/${PROJ_BIT}"
  else
    echoerrandexit "'liquidDev.orgBase' from 'package.json' in unknown format."
  fi

  if ! [[ -d "${LIQ_PLAYGROUND}/${ORG_PROJECT}" ]]; then
    # TODO: support '--import-org'
    echoerrandexit "Org def project '${ORG_PROJECT}' not found locally. Try:\nliq projects import ${ORG_BASE}"
  fi
  source "${LIQ_PLAYGROUND}/${ORG_PROJECT}/settings.sh"
  if [[ -z "${PROJECT_LABELS:-}" ]]; then
    echo "No project labels defined; using default label set..."
    PROJECT_LABELS=$(cat <<EOF
bounty:This task offers a bounty:209020
bug:Something is broken:d73a4a
enhancement:New feature or request:a2eeef
good first issue:Good for newcomers:7050ff
needs spec:The task as-is is not fully specified:ff4040
optimization:Make better without changing behavior:00dd70
EOF
    )
  fi

  local CURR_LABEL_DATA CURR_LABELS TEST_LABEL INDEX PROJECT_LABEL_NAMES
  PROJECT_LABEL_NAMES="$(echo "${PROJECT_LABELS}" | awk -F: '{print $1}')"
  CURR_LABEL_DATA="$(hub api "/repos/${GIT_BASE}/labels")"
  CURR_LABELS="$(echo "$CURR_LABEL_DATA" | jq -r '.[].name' )"

  local NON_STD_LABELS="${CURR_LABELS}"
  while read -r TEST_LABEL; do
    INDEX=$(list-get-index NON_STD_LABELS "${TEST_LABEL}")
    if [[ -n "${INDEX}" ]]; then
      list-rm-item NON_STD_LABELS "${TEST_LABEL}"
    fi
  done <<< "${PROJECT_LABEL_NAMES}"

  MISSING_LABELS="${PROJECT_LABEL_NAMES}"
  while read -r TEST_LABEL; do
    INDEX=$(list-get-index MISSING_LABELS "${TEST_LABEL}")
    if [[ -n "${INDEX}" ]]; then
      list-rm-item MISSING_LABELS "${TEST_LABEL}"
    fi
  done <<< "${CURR_LABELS}"

  local LABELS_SYNCED=true
  if [[ -n "${NON_STD_LABELS}" ]]; then
    if [[ -z "${NO_DELETE_LABELS}" ]]; then
      while read -r TEST_LABEL; do
        echo "Removing non-standard label '${TEST_LABEL}'..."
        hub api -X DELETE "/repos/${GIT_BASE}/labels/${TEST_LABEL}"
      done <<< "${NON_STD_LABELS}"
    else
      echowarn "The following non-standard labels where found in ${PROJECT}:\n$(echo "${NON_STD_LABELS}" | awk '{ print "* "$0 }')\n\nInclude the '--delete' option to attempt removal."
      LABELS_SYNCED=false
    fi
  fi # non-standard label check; potential deletion

  local LABEL_SPEC NAME COLOR DESC
  set-spec() {
    NAME="$(echo "${LABEL_SPEC}" | awk -F: '{print $1}')"
    DESC="$(echo "${LABEL_SPEC}" | awk -F: '{print $2}')"
    COLOR="$(echo "${LABEL_SPEC}" | awk -F: '{print $3}')"
  }

  local LABELS_CREATED
  if [[ -n "${MISSING_LABELS}" ]]; then
    while read -r TEST_LABEL; do
      LABEL_SPEC="$(list-get-item-by-prefix PROJECT_LABELS "${TEST_LABEL}:")"
      set-spec
      echo "Adding label '${TEST_LABEL}'..."
      hub api -X POST "/repos/${GIT_BASE}/labels" \
        -f name="${NAME}" \
        -f description="${DESC}" \
        -f color="${COLOR}" > /dev/null
      list-add-item LABELS_CREATED "${NAME}"
    done <<< "$MISSING_LABELS"
  fi # missing labels creation

  if [[ -z "$NO_UPDATE_LABELS" ]] && [[ "${LABELS_SYNCED}" == true ]]; then
    [[ "${LABELS_SYNCED}" != true ]] || echo "Label names synchronized."
    echo "Checking label definitions..."
    LABELS_SYNCED=false
    while read -r LABEL_SPEC; do
      set-spec
      local CURR_DESC CURR_COLOR
      CURR_DESC="$(echo "$CURR_LABEL_DATA" | jq -r "map(select(.name == \"${NAME}\"))[0].description")"
      CURR_COLOR="$(echo "$CURR_LABEL_DATA" | jq -r "map(select(.name == \"${NAME}\"))[0].color")"
      if { [[ "${CURR_COLOR}" != "${COLOR}" ]] || [[ "$CURR_DESC" != "${DESC}" ]]; } \
         && [[ -z $(list-get-index LABELS_CREATED "${NAME}") ]]; then
        echo "Updating label definition for '${NAME}'..."
        hub api -X PATCH "/repos/${GIT_BASE}/labels/${NAME}" -f description="${DESC}" -f color="${COLOR}" > /dev/null
        LABELS_SYNCED=true
      fi
    done <<< "${PROJECT_LABELS}"

    [[ "$LABELS_SYNCED" == true ]] && echo "Label definitions updated." || echo "Labels already up-to-date."
  else
    [[ "${LABELS_SYNCED}" != true ]] || [[ -n "$NO_UPDATE_LABELS" ]] || echo "Labels not synchronized; skipping update."
    [[ -z "${NO_UPDATE_LABELS}" ]] || echo "Skipping update."
  fi # labels definition check and update
}

# TODO: deprecated
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

requirements-work() {
  :
}

work-backup() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

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
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  git diff $(git merge-base master HEAD)..HEAD "$@"
}

work-close() {
  eval "$(setSimpleOptions POP TEST NO_SYNC -- "$@")"
  source "${LIQ_WORK_DB}/curr_work"
  findBase

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
			projects-sync --project="${PROJECT}"
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
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.
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
  findBase
  pushd "${BASE_DIR}" > /dev/null
  touch .gitignore
  # first ignore whole directories
  for i in `git ls-files . --exclude-standard --others --directory`; do
    echo "${i}" >> .gitignore
  done
  popd > /dev/null
}

work-involve() {
  findBase # this will be optional once we support '--project'

  eval "$(setSimpleOptions NO_LINK:L -- "$@")"
  local PROJECT_NAME WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "There is no active unit of work to involve. Try:\nliq work resume"
  fi

  check-git-access

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

  local OTHER_PROJECTS="${INVOLVED_PROJECTS}" # save this for use in linking later...
  list-add-item INVOLVED_PROJECTS "@${PROJECT_NAME}" # do include the '@' here for display
  workUpdateWorkDb

  # Now, let's see about automatic linking!
  local PRIMARY_PROJECT=$INVOLVED_PROJECTS
  # if this is the first/primary project, no need to worry about linking
  if [[ "$PRIMARY_PROJECT" != "$PROJECT_NAME" ]] && [[ -z "${NO_LINK}" ]]; then
    # first, link this project to other projects
    local LINKS
    work-links-add --set-links LINKS "${PROJECT_NAME}"
    # now link other, already involved projects to this project
    cd "${LIQ_PLAYGROUND}/${PROJECT_NAME}"
    local SOURCE_PROJ
    for SOURCE_PROJ in $OTHER_PROJECTS; do
      if projects-lib-has-any-dep "${PROJECT_NAME}" "${SOURCE_PROJ}"; then
        if [[ -n "$(list-get-index LINKS "${SOURCE_PROJ}")" ]]; then
          echowarn "Project '${SOURCE_PROJ}' linked to '${PROJECT_NAME}', but '${PROJECT_NAME}' also depends on '${SOURCE_PROJ}'; skipping the link back-link to avoid circular reference."
        else
          work-links-add --projects="${PROJECT_NAME}" "${SOURCE_PROJ}"
        fi
      fi
    done
  fi
}

work-issues() {
  findBase

  eval "$(setSimpleOptions LIST ADD= REMOVE= -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current work selected; cannot list issues."
  fi
  source "${LIQ_WORK_DB}/curr_work"

  BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

  if [[ -n "$ADD" ]]; then
    local NEW_ISSUE NEW_ISSUES
    work-lib-process-issues NEW_ISSUES "$ADD" "$BUGS_URL"
    for NEW_ISSUE in $NEW_ISSUES; do
      list-add-item WORK_ISSUES "$NEW_ISSUE"
    done
  fi
  if [[ -n "$REMOVE" ]]; then
    local RM_ISSUE RM_ISSUES
    work-lib-process-issues RM_ISSUES "$REMOVE" "$BUGS_URL"
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

# see liq help work list
work-list() {
  local WORK_DESC WORK_STARTED WORK_INITIATOR INVOLVED_PROJECTS
  # find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;
  for i in $(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \;); do
    echo "${LIQ_WORK_DB}/${i}"
    source "${LIQ_WORK_DB}/${i}"
    echo -e "* ${yellow_b}${WORK_DESC}${reset}: started ${bold}${WORK_STARTED}${reset} by ${bold}${WORK_INITIATOR}${reset}"
  done
}

# see liq help work merge
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
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

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
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

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
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  eval "$(setSimpleOptions POP -- "$@")"
  local WORK_NAME
  if [[ -z "$POP" ]]; then
    # if no args, gives list of availabale work units; otherwise interprets argument as a work name
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
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

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
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  eval "$(setSimpleOptions ALL INTERACTIVE REVIEW DRY_RUN -- "$@")"

  local OPTIONS
  if [[ $ALL == true ]]; then OPTIONS="--all "; fi
  if [[ $INTERACTIVE == true ]]; then OPTIONS="${OPTIONS}--interactive "; fi
  if [[ $REVIEW == true ]]; then OPTIONS="${OPTIONS}--patch "; fi
  if [[ $DRY_RUN == true ]]; then OPTIONS="${OPTIONS}--dry-run "; fi

  git add ${OPTIONS} "$@"
}

work-status() {
  check-git-access

  eval "$(setSimpleOptions PR_READY: NO_FETCH:F LIST_PROJECTS:p LIST_ISSUES:i -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local WORK_NAME LOCAL_COMMITS REMOTE_COMMITS
  WORK_NAME="${1:-}"
  # Set WORK_NAME to curr work if present
  [[ -n "${WORK_NAME}" ]] || ! [[ -f "${LIQ_WORK_DB}/curr_work" ]] \
    || WORK_NAME="$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))"
  [[ -n "${WORK_NAME}" ]] || echoerrandexit "No current work. You must specify work to show status."

  if [[ "$PR_READY" == true ]]; then
    git fetch workspace "${WORK_NAME}:remotes/workspace/${WORK_NAME}"
    TMP="$(git rev-list --left-right --count $WORK_NAME...workspace/$WORK_NAME)"
    LOCAL_COMMITS=$(echo $TMP | cut -d' ' -f1)
    REMOTE_COMMITS=$(echo $TMP | cut -d' ' -f2)
    (( $LOCAL_COMMITS == 0 )) && (( $REMOTE_COMMITS == 0 ))
    return $?
  fi

  source "${LIQ_WORK_DB}/${WORK_NAME}"
  if [[ -n "$LIST_PROJECTS" ]]; then
    echo "$INVOLVED_PROJECTS"
    return $?
  elif [[ -n "$LIST_ISSUES" ]]; then
    echo "$WORK_ISSUES"
    return $?
  fi

  if [[ -z "$NO_FETCH" ]]; then
    work-sync --fetch-only
  fi

  echo "Branch name: $WORK_NAME"
  echo
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
# alias TODO: I think I might like 'show' better after all
work-show() { work-status "$@"; }

work-start() {
  check-git-access

  findBase

  eval "$(setSimpleOptions ISSUES= PUSH DESCRIPTION= -- "$@")"

  local CURR_PROJECT ISSUES_URL BUGS_URL WORK_ISSUES
  if [[ -n "$BASE_DIR" ]]; then
    CURR_PROJECT=$(cat "$BASE_DIR/package.json" | jq --raw-output '.name' | tr -d "'")
    BUGS_URL=$(cat "$BASE_DIR/package.json" | jq --raw-output '.bugs.url' | tr -d "'")
  fi


  work-lib-process-issues WORK_ISSUES "$ISSUES" "$BUGS_URL"

  if [[ -z "$WORK_ISSUES" ]]; then
    echoerrandexit "Must specify at least 1 issue when starting a new unit of work."
  fi

  if [[ -z "$DESCRIPTION" ]]; then
    local PRIMARY_ISSUE
    # The issues have been normalized, so his is always a URL
    PRIMARY_ISSUE=$(list-get-item WORK_ISSUES 0 | sed -Ee 's|.+/([[:digit:]]+)$|\1|')

    DESCRIPTION="$(hub issue show $PRIMARY_ISSUE | head -n 1 | sed -E 's/^# *//')" \
      || echoerrandexit "Error trying to extract issue description from: ${BUGS_URL}/${PRIMARY_ISSUE}\nThe primary issues must be part of the current project."
  fi

  WORK_STARTED=$(date "+%Y.%m.%d")
  WORK_INITIATOR=$(whoami)
  WORK_BRANCH=`work-lib-branch-name "${DESCRIPTION}"`

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
  local WORK_DESC="$DESCRIPTION"
  workUpdateWorkDb

  if [[ -n "$CURR_PROJECT" ]]; then
    (
      cd "${LIQ_PLAYGROUND}/${CURR_PROJECT/@/}"
      echo "Adding current project '$CURR_PROJECT' to unit of work..."
      work-involve "$CURR_PROJECT"
    )
  fi
}

work-stop() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  eval "$(setSimpleOptions KEEP_CHECKOUT -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    local CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
    if [[ -z "$KEEP_CHECKOUT" ]]; then
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
    (
      cd "${LIQ_PLAYGROUND}/${IP/@/}"
      echo "Syncing project '${IP}'..."
      projects-sync ${OPTS} "${IP}"
    )
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
  eval "$(setSimpleOptions MESSAGE= NOT_CLEAN:C NO_CLOSE:X NO_BROWSE:B FORCE -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  findBase
  check-git-access

  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "No current unit of work. Try:\nliq work select."
  fi

  source "${LIQ_WORK_DB}/curr_work"

  if [[ -z "$MESSAGE" ]]; then
    MESSAGE="$WORK_DESC" # sourced from current work
  fi

  local TO_SUBMIT="$@"
  if [[ -z "$TO_SUBMIT" ]]; then
    TO_SUBMIT="$INVOLVED_PROJECTS"
  fi

  local IP
  # preflilght check
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

  # OK, let's do it
  for IP in $TO_SUBMIT; do
    IP=$(workConvertDot "$IP")
    cd "${LIQ_PLAYGROUND}/${IP/@/}"
    echo "Preparing PR for ${IP}..."

    local DESC="Merge ${WORK_BRANCH} to master

## Summary

${MESSAGE}

## Issues

"

    local PROJ_ISSUES=''
    local OTHER_ISSUES=''

    # get IP bugs URL in order to figure out what tasks are directly related to this project.
    local BUGS_URL
    BUGS_URL=$(cat "${LIQ_PLAYGROUND}/${IP/@/}/package.json" | jq --raw-output '.bugs.url' | tr -d "'")

    local ISSUE
    for ISSUE in $WORK_ISSUES; do
      if [[ $ISSUE == $BUGS_URL* ]]; then
        local NUMBER=${ISSUE/$BUGS_URL/}
        NUMBER=${NUMBER/\//}
        list-add-item PROJ_ISSUES "#${NUMBER}"
      else
        local LABEL="$(echo "$ISSUE" | awk -F/ '{ print $4"/"$5"#"$7 }')"
        list-add-item OTHER_ISSUES "[${LABEL}](${ISSUE})"
      fi
    done

    if [[ -n "$PROJ_ISSUES" ]]; then
      if [[ -z "$NO_CLOSE" ]];then
        DESC="${DESC}"$'\n'"$( for ISSUE in $PROJ_ISSUES; do echo "* closes $ISSUE"; done)"
      else
        DESC="${DESC}"$'\n'"$( for ISSUE in $PROJ_ISSUES; do echo "* driven by $ISSUE"; done)"
      fi
    fi
    if [[ -n "$OTHER_ISSUES" ]]; then
      DESC="${DESC}"$'\n'"$( for ISSUE in ${OTHER_ISSUES}; do echo "* involved with $ISSUE"; done)"
    fi

    # check for the 'work-policy-review' extension point
    if [[ $(type -t "work-policy-review" || echo '') == 'function' ]]; then
      DESC="${DESC}$(work-policy-review "$TO_SUBMIT")"
    fi

    local BASE_TARGET # this is the 'org' of the upsteram branch
    BASE_TARGET=$(git remote -v | grep '^upstream' | grep '(push)' | sed -E 's|.+[/:]([^/]+)/[^/]+$|\1|')
    local PULL_OPTS="--push --base=${BASE_TARGET}:master "
    if [[ -z "$NO_BROWSE" ]]; then
      PULL_OPTS="$PULL_OPTS --browse"
    fi
    if [[ -n "$FORCE" ]]; then
      PULL_OPTS="$PULL_OPTS --force"
    fi
    echo "Submitting PR for '$IP'..."
    echo "hub pull-request $PULL_OPTS -m '${DESC}'"
    hub pull-request $PULL_OPTS -m "${DESC}"
  done # TO_SUBMIT processing loop
}
WORK_GROUPS="links"

help-work() {
  local PREFIX="${1:-}"

  local SUMMARY="Manages the current unit of work."

  handleSummary "${PREFIX}${cyan_u}work${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}work${reset} <action>:
$(echo "${SUMMARY} A 'unit of work' is essentially a set of work branches across all involved projects. The first project involved in a unit of work is considered the primary project, which will effect automated linking when involving other projects.

${red_b}ALPHA Note:${reset} The 'stop' and 'resume' actions do not currently manage the work branches and only updates the 'current work' pointer." | fold -sw 82 | indent)
$(_help-actions-list work diff-master edit ignore-rest involve issues list merge report qa resume save stage start status stop submit sync test | indent)
$(_help-sub-group-list work WORK_GROUPS)
EOF
}

help-work-diff-master() {
  cat <<EOF | _help-func-summary diff-master "[--mine|-m]"
Shows committed changes since branch from 'master' for all involved repositories.
EOF
}

help-work-edit() {
  cat <<EOF | _help-func-summary edit
Opens a local project editor for all involved repositories.
EOF
}

help-work-ignore-rest() {
  cat <<EOF | _help-func-summary ignore-rest
Adds any currently untracked files to '.gitignore'.
EOF
}

help-work-involve() {
  cat <<EOF | _help-func-summary involve "[--no-link|-L] [<repository name>]"
Involves the current or named repository in the current unit of work. The newly involved project will be linked to other involved projects with a dependincy, and vice-a-versa, unless this would result in a circular reference in which case the 'back link' (from the prior involved project to the newly added project) is skipped and a warning is given. The '--no-link' option will suppress the linking behavior.
EOF
}

help-work-issues() {
  cat <<EOF | _help-func-summary issues "[--list|--add|--remove]"
Manages issues associated with the current unit of work. TODO: this should be re-worked as sub-group.
EOF
}

help-work-list() {
  cat <<EOF | _help-func-summary list
Lists the current, local, unclosed units of work.
EOF
}

help-work-merge() {
  cat <<EOF | _help-func-summary merge
Merges current work unit to master branches and updates mirrors.
EOF
}

help-work-report() {
  cat <<EOF | _help-func-summary report
Reports status of files in the current unit of work.
EOF
}

help-work-qa() {
  cat <<EOF | _help-func-summary qa
Checks the playground status and runs package audit, version check, and tests.
EOF
}

help-work-resume() {
  cat <<EOF | _help-func-summary resume "[--pop] [<name>]"
alias: ${underline}join${reset}

Resume work or join an existing unit of work. If the '--pop' option is specified, then arguments will be ignored and the last 'pushed' unit of work (see 'liq work start --push') will be resumed.
EOF
}

help-work-save() {
  cat <<EOF | _help-func-summary save "[-a|--all] [--backup-only|-b] [--message|-m=<version ][<path spec>...]"
Save staged files to the local working branch. '--all' auto stages all known files (does not include new files) and saves them to the local working branch. '--backup-only' is useful if local commits have been made directly through 'git' and you want to push them.
EOF
}

help-work-stage() {
  cat <<EOF | _help-func-summary stage "[-a|--all] [-i|--interactive] [-r|--review] [-d|--dry-run] [<path spec>...]"
Stages files for save.
EOF
}

help-work-start() {
  cat <<EOF | _help-func-summary start "[--issues|-i <# or URL>] [--description|-d <work desc>] [--push|-p]"
Creates a new unit of work and adds the current repository (if any) to it. You must specify at least one issue. Use a comma separated list to specify mutliple issues. The first issue must be in the current working project and by default the 'work description' is extracted from the issue summary/title. If '--description' is specified, then that description is used instead of the first issue title. The '--push' option will record the current unit of work which can then be recovered with 'liq work resume --pop'.
EOF
}

help-work-status() {
  cat <<EOF | _help-func-summary status "[--list-projects|-p] [--list-issues|-i] [--no-fetch|-F] [--pr-ready] [<name>]"
Shows details for the current or named unit of work. Will enter interactive selection if no option and no current work or the '--select' option is given. The '--list-projects' and '--list-issues' options are meant to be used on their own and will just list the involved projects or associated issues respectively. '--no-fetch' skips updating the local repositories. '--pr-ready' suppresses all output and just return (bash) true or false.
EOF
}

help-work-stop() {
  cat <<EOF | _help-func-summary stop "[-k|--keep-checkout]"
Stops working on the current unit of work. The master branch will be checked out for all involved projects unless '--keep-checkout' is used.
EOF
}

help-work-submit() {
  cat <<EOF | _help-func-summary submit "[--message|-m <summary message>][--not-clean|-C] [--no-close|-X][<projects>]"
Submits pull request for the current unit of work. With no projects specified, submits patches for all projects in the current unit of work. By default, PR will claim to close related issues unless '--no-close' is included.
EOF
}

help-work-sync() {
  cat <<EOF | _help-func-summary sync "[--fetch-only|-f] [--no-work-master-merge|-M]"
Synchronizes local project repos for all work. See 'liq help work sync' for details.
EOF
}

help-work-test() {
  cat <<EOF | _help-func-summary test
Runs tests for each involved project in the current unit of work. See 'project test' for details on options for the 'test' action.
EOF
}
work-lib-branch-name() {
  local WORK_DESC="${1:-}"
  requireArgs "$WORK_DESC" || exit $?
  requireArgs "$WORK_STARTED" || exit $?
  requireArgs "$WORK_INITIATOR" || exit $?
  echo "${WORK_STARTED}-${WORK_INITIATOR}-$(work-lib-safe-desc "$WORK_DESC")"
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

work-lib-safe-desc() {
  local WORK_DESC="${1:-}"
  requireArgs "$WORK_DESC" || exit $?
  # 1) change all spaces and hyphens to underscores.
  # 2) lower case everything.
  # 3) Remove any non-alphanumeric characters except '_'.
  # 4) Extract the first four words.
  # 5) Remove any trailing underscore.
  echo "$WORK_DESC" \
    | tr ' -' '_' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -Ee 's/[^[:alnum:]_]//g' \
      -e 's/(([[:alnum:]]+(_|$)){1,4}).*/\1/' \
      -e 's/_$//'
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

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    requireCleanRepos
    source "${LIQ_WORK_DB}/curr_work"
    echo "Resetting current work unit repos to 'master'..."
    local IP
    for IP in $INVOLVED_PROJECTS; do
      IP="${IP/@/}"
      git checkout master
    done
  fi

  if [[ "$_BRANCH_NAME" != "master" ]]; then
    requireCleanRepos "${_BRANCH_NAME}"
    ( # we don't want overwrite the sourced vars
      source "${LIQ_WORK_DB}/${_BRANCH_NAME}"

      for IP in $INVOLVED_PROJECTS; do
        IP=${IP/@/}
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
  fi
}

work-lib-process-issues() {
  local VAR="${1}"
  local CSV_ISSUES="${2}"
  local BUGS_URL="${3}"
  local ISSUES ISSUE
  list-from-csv "${VAR}" "$CSV_ISSUES"
  for ISSUE in ${!VAR}; do
    if [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
      if [[ -z "$BUGS_URL" ]]; then
        echoerrandexit "Cannot ref issue number outside project context. Either issue in context or use full URL."
      fi
      list-replace-by-string ${VAR} $ISSUE "$BUGS_URL/$ISSUE"
    fi
  done
}

work-links() {
  local ACTION="${1}"; shift

  if [[ $(type -t "work-links-${ACTION}" || echo '') == 'function' ]]; then
    work-links-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" work links
  fi
}

# See 'liq help work links add'. Also supports the internal option '--set-links <var name>' which will set the value of the indicataed variable with a lost of the packages linked.
work-links-add() {
  eval "$(setSimpleOptions IMPORT PROJECTS= FORCE: SET_LINKS:= -- "$@")"
  local SOURCE_PROJ="${1}"
  local LINKS_MADE

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set # sets PROJECTS

  # preflight checks
  for TARGET_PROJ in $PROJECTS; do
    [[ -d "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}" ]] || echoerrandexit "No such target project: ${TARGET_PROJ}"
  done

  # ensure the source project is present
  local SOURCE_PROJ_DIR="${LIQ_PLAYGROUND}/${SOURCE_PROJ//@/}"
  if ! [[ -d "${SOURCE_PROJ_DIR}" ]]; then
    if [[ -n "${IMPORT}" ]]; then
      projects-import "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
    fi
  fi
  # publish the source
  cd "${SOURCE_PROJ_DIR}"
  echo "Publishing '${SOURCE_PROJ_DIR}' locally..."
  yalc publish

  # link to targets
  for TARGET_PROJ in $PROJECTS; do
    cd "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}"
    echo -n "Checking '${TARGET_PROJ}'... "
    if [[ -n "${FORCE}" ]] || projects-lib-has-any-dep "${TARGET_PROJ/@/}" "${SOURCE_PROJ}"; then
      echo "linking..."
      yalc add "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
      list-add-item LINKS_MADE "${TARGET_PROJ}"
    else
      echo "skipping (no dependency)."
    fi
  done

  if [[ -n "${SET_LINKS}" ]]; then
    eval "${SET_LINKS}=\"${LINKS_MADE}\""
  fi
}

work-links-list() {
  eval "$(setSimpleOptions PROJECTS= -- "$@")"

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set # sets PROJECTS

  for TARGET_PROJ in $PROJECTS; do
    cd "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}" # TODO: regularize reference style
    echo -n "${TARGET_PROJ/@/}: " # TODO: regularize reference style
    local YALC_CHECK="$(yalc check || true)"
    if [[ -z "$YALC_CHECK" ]]; then
      echo "none"
    else
      echo
      echo "$YALC_CHECK" | awk -F: '{print $2}' | tr "'" '"' | jq -r '.[]' | sed -E 's/^/- /'
    fi
    echo
  done
}

# see liq help work links remove
work-links-remove() {
  eval "$(setSimpleOptions NO_UPDATE:U PROJECTS= -- "$@")"
  local SOURCE_PROJ="${1}"

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set # sets PROJECTS

  for TARGET_PROJ in $PROJECTS; do
    cd "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}"
    if { yalc check || true; } | grep -q "${SOURCE_PROJ}"; then
      yalc remove "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
      if [[ -z "${NO_UPDATE}" ]]; then
        npm i "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
      fi
    fi
  done

  echo "Successfully unlinked '${SOURCE_PROJ}'."
}
help-work-links() {
  local PREFIX="${1:-}"

  local SUMMARY="Manage working links between projects."

  handleSummary "${PREFIX}${cyan_u}work links${reset} <action>: ${SUMMARY}" || cat <<EOF
${PREFIX}${cyan_u}projects issues${reset} <action>:
  ${SUMMARY}
$(_help-actions-list work-links add list remove | indent)
EOF
}

help-work-links-add() {
  cat <<EOF | _help-func-summary add "[--import|-i] [--projects|-p <target proj>...] [--force|-f] <source proj>"
Links the source project to all projects in the current unit of work or the specified target projects that have a dependency on the source project. The source project must be present in the playground, unless '--import' is specified, in which case it will be imported if not present.

The '--force' option will add the dependency even if the target project is not already dependent. E.g., for use when the work adds the dependency and the source project is also being updated or is newly created.

If '--projects' is specified (as a space or comma separated list), then only those project, which must be in the working set, is linked to the local source project.
EOF
}

help-work-links-list() {
  cat <<EOF | _help-func-summary list "[--projects|-p <target proj>...]"
List all the for each each project in the currrent unit of work or, if specified, the '--projects' option (a (as a space or comma separated list).
EOF
}

help-work-links-remove() {
  cat <<EOF | _help-func-summary remove "[--no-update|-U] [--projects|-p <target proj>...] <source proj>"
Removes the source project link to all projects in the current unit of work. Exits in error if there are no linkes with the source project. By default, the source project package will be updated after being removed unless '--no-update' is specified.

If '--projects' is specified (as a space or comma separated list), then only those project, which must be in the working set, are de-linked from the source project.
EOF
}
work-links-lib-working-set() {
  if [[ -n "${PROJECTS}" ]]; then
    PROJECTS="$(echo "${PROJECTS}" | tr ',' ' ')"
  else
    source "${LIQ_WORK_DB}/curr_work"
    PROJECTS="${INVOLVED_PROJECTS}"
  fi
}
# process global overrides of the form 'key="value"'
while (( $# > 0 )) && [[ $1 == *"="* ]]; do
  eval ${1%=*}="'${1#*=}'"
  shift
done

if [[ -f "${LIQ_EXTS_DB}/exts.sh" ]]; then
  source "${LIQ_EXTS_DB}/exts.sh"
fi

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
