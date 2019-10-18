#!/usr/bin/env bash

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
# Usage:
#   local TMP
#   TMP=$(setSimpleOptions SHORT LONG= SPECIFY_SHORT:X LONG_SPEC:S= -- "$@") \
#     || ( contextHelp; echoerrandexit "Bad options."; )
#   eval "$TMP"
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
  echo "set -- \"$@\""
  echo 'if [[ -z "$1" ]]; then shift; fi'
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

echo "uname: $(uname)"

COMPLETION_PATH="/usr/local/etc/bash_completion.d"

BREW_UPDATED=''
brewInstall() {
  local EXEC="$1"
  local INSTALL_TEST="$2"
  local POST_INSTALL="${3:-}"
  if ! $INSTALL_TEST; then
    if ! which -s brew; then
      echoerr "Required executable '${EXEC}' not found."
      echoerr "Install Homebrew and re-run installation, or install '${EXEC}' manually."
      echoerrandexit https://brew.sh/
    fi
    # else
    doInstall() {
      test -n "${BREW_UPDATED}" \
        || brew update \
        || echoerrandexit "'brew update' exited with errors. Please update Homebrew and re-run Catalyst CLI installation."
      BREW_UPDATED=true
      brew install $EXEC \
        || (echo "First install attempt failed. Re-running often fixes brew install issue; trying again..."; brew install $EXEC) \
        || echoerrandexit "'brew install ${EXEC}' exited with errors. Otherwise, please install '${EXEC}' and re-run Catalyst CLI installation."
      if test -n "$POST_INSTALL"; then eval "$POST_INSTALL"; fi
    }
    giveFeedback() {
      echo "Catalyst CLI requires '${EXEC}'. Please install with Homebrew (recommended) or manually."
      exit
    }
    yesno \
      "Catalyst CLI requires command '${EXEC}'. OK to attempt install via Homebrew? (Y/n) " \
      Y \
      doInstall \
      giveFeedback
  fi
}

if [[ $(uname) == 'Darwin' ]]; then
  brewInstall jq 'which -s jq'
  # Without the 'eval', the tick quotes are treated as part of the filename.
  # Without the tickquotes we're vulnerable to spaces in the path.
  brewInstall gnu-getopt \
    "eval test -f '$(brew --prefix gnu-getopt)/bin/getopt'" \
    "addLineIfNotPresentInFile ~/.bash_profile 'alias gnu-getopt=\"\$(brew --prefix gnu-getopt)/bin/getopt\"'"
fi

cp ./src/completion.sh "${COMPLETION_PATH}/liq"
addLineIfNotPresentInFile ~/.bash_profile "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
# TODO: accept '-e' option which exchos the source command so user can do 'eval ./install.sh -e'
# TODO: only echo if lines added (here or in POST_INSTALL)
echo "You must open a new shell or 'source ~/.bash_profile' to enable completion updates."
