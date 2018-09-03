#!/usr/bin/env bash

COMPLETION_PATH="/usr/local/etc/bash_completion.d"

cp ./src/completion.sh "${COMPLETION_PATH}/catalyst"
source ./src/lib/utils.sh
addLineIfNotPresentInFile ~/.bash_profile "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/catalyst'"
which -s catalyst || echo "You must open a new shell or 'source ${COMPLETION_PATH}/catalyst' to enable completion."
