#!/usr/bin/env bash

source ./src/lib/_utils.sh

COMPLETION_PATH="/usr/local/etc/bash_completion.d"

BREW_UPDATED=''
brewInstall() {
  local EXEC="$1"
  local POST_INSTALL="${2:-}"
  if ! which -s $EXEC; then
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

brewInstall jq
brewInstall gnu-getopt "addLineIfNotPresentInFile ~/.bash_profile 'alias gnu-getopt=\"\$(brew --prefix gnu-getopt)/bin/getopt\"'"

cp ./src/completion.sh "${COMPLETION_PATH}/catalyst"
addLineIfNotPresentInFile ~/.bash_profile "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/catalyst'"
# TODO: accept '-e' option which exchos the source command so user can do 'eval ./install.sh -e'
# TODO: only echo if lines added (here or in POST_INSTALL)
echo "You must open a new shell or 'source ~/.bash_profile' to enable completion updates."
