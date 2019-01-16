#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

function importlibs() {
  local REAL_CLI_REL=`readlink "${BASH_SOURCE[0]}"`
  local REAL_CLI_REL_PATH=`dirname $REAL_CLI_REL`
  # Now we have the installed package location and can start sourcing our files.
  SOURCE_DIR="$( cd "`dirname ${BASH_SOURCE[0]}`/$REAL_CLI_REL_PATH" && pwd )"

  for f in "${SOURCE_DIR}/lib/"*.sh; do source "$f"; done
  for f in "${SOURCE_DIR}/actions/"*.sh; do source "$f"; done
}
importlibs
# process global overrides of the form 'key="value"'
while (( $# > 0 )) && [[ $1 == *"="* ]]; do
  eval ${1%=*}="'${1#*=}'"
  shift
done

# see note in lib/utils.sh:colorerr re. SAW_ERROR
# local SAW_ERROR=''
if [[ $# -lt 1 ]]; then
  print_usage
  echoerr "Invalid invocation. See usage above."
  exit 1
fi

ensureConfig
mkdir -p "${_CATALYST_ENV_LOGS}"

source "$SOURCE_DIR"/dispatch.sh

exit 0
