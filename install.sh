#!/usr/bin/env bash

COMPLETION_PATH="/usr/local/etc/bash_completion.d"

cp ./src/completion.sh "${COMPLETION_PATH}/gcproj"
source ./src/lib/utils.sh
addLineIfNotPresentInFile ~/.bash_profile "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/gcproj'"
which -s gcproj || echo "You must open a new shell or 'source ${COMPLETION_PATH}/gcproj' to enable completion."
