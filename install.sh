#!/usr/bin/env bash

source ./src/lib/utils.sh

COMPLETION_PATH="/usr/local/etc/bash_completion.d"

if ! which -s jq; then
  if ! which -s brew; then
    echoerr "Required executable 'jq' not found."
    echoerr "Install Homebrew and re-run installation, or install 'jq' manually."
    echoerrandexit https://brew.sh/
  fi
  # else
  doInstall() {
    brew update || echoerrandexit "'brew update' exited with errors. Please update Homebrew and re-run Catalyst CLI installation."
    brew install jq || echoerrandexit "'brew install jq' exited with errors. Please install 'qj' and re-run Catalyst CLI installation."
  }
  yesno \
    "Catalyst CLI requires command 'jq'. OK to attempt install via Homebrew? (Y/n)" \
    Y \
    doInstall \
    giveFeedback
fi
cp ./src/completion.sh "${COMPLETION_PATH}/catalyst"
addLineIfNotPresentInFile ~/.bash_profile "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/catalyst'"
# TODO: accept '-e' option which exchos the source command so user can do 'eval ./install.sh -e'
echo "You must open a new shell or 'source ${COMPLETION_PATH}/catalyst' to enable completion updates."
