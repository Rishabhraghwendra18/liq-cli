#!/usr/bin/env bash

import echoerr

echo "Starting liq install..."

source ../liq/lib/_utils.sh

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
    yes-no \
      "Catalyst CLI requires command '${EXEC}'. OK to attempt install via Homebrew? (Y/n) " \
      Y \
      doInstall \
      giveFeedback
  fi
}

APT_UPDATED=false
function apt-install() {
  local EXEC="$1"
  local INSTALL_TEST="$2"

  if ! ${INSTALL_TEST}; then
    echo "Installing '${EXEC}'..."
    if [[ "${APT_UPDATED}"  == 'false' ]]; then
      sudo apt-get -q update || echoerrandexit "Could not install '${EXEC}' while performing 'apt-get update'."
      APT_UPDATED=false
    fi
    sudo apt-get -qqy "${EXEC}" || echoerrandexit "Could not install  '${EXEC}' while performing 'apt-get install'."
  else
    echo "Found '${EXEC}'..."
  fi
}

function npm-install() {
  local PKG="${1}"
  local INSTALL_TEST="${2}"

  if ! ${INSTALL_TEST}; then
    npm install -g ${PKG}
  fi
}

if [[ $(uname) == 'Darwin' ]]; then
  brewInstall jq 'which -s jq'
  # Without the 'eval', the tick quotes are treated as part of the filename.
  # Without the tickquotes we're vulnerable to spaces in the path.
  brewInstall gnu-getopt \
    "eval test -f '$(brew --prefix gnu-getopt)/bin/getopt'" \
    "addLineIfNotPresentInFile ~/.bash_profile 'alias gnu-getopt=\"\$(brew --prefix gnu-getopt)/bin/getopt\"'"
else
  apt-install jq 'which jq' # '-s' is not supported on linux and a /dev/null redirect doesn't interpret correctly (?)
  apt-install node 'which node'
fi

npm-install yalc 'which yalc'

declare COMPLETION_SEUTP
for i in /etc/bash_completion.d /usr/local/etc/bash_completion.d; do
  if [[ -e "${i}" ]]; then
    COMPLETION_PATH="${i}"
    COMPLETION_SETUP=true
    break
  fi
done
[[ -n "${COMPLETION_SETUP}" ]] || echowarn "Could not setup completion; did not find expected completion paths."
cp ./dist/completion.sh "${COMPLETION_PATH}/liq"

COMPLETION_SETUP=false
for i in /etc/bash.bashrc "${HOME}/.bash_profile" "${HOME}/.profile"; do
  if [[ -e "${i}" ]]; then
    addLineIfNotPresentInFile "${i}" "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
    COMPLETION_SETUP=true
    break
  fi
done

if [[ "${COMPLETION_SETUP}" == 'false' ]]; then
  echoerr "Completion support not set up; could not find likely bash profile/rc."
fi
# TODO: accept '-e' option which exchos the source command so user can do 'eval ./install.sh -e'
# TODO: only echo if lines added (here or in POST_INSTALL)
[[ -z "${PS1}" ]] || echo "You must open a new shell or 'source ~/.bash_profile' to enable completion updates."
