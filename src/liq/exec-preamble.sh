import strict

import colors
import echoerr
import echofmt
import lists
import options
import prompt
import real_path
import select
source ./lib/inc.sh
source ./actions/inc.sh
source ./dispatch.sh

# process global overrides of the form 'key="value"'
### DEPRECATED
# The use case here is to override the default variables. We should instead adopt a 'if-not-set-set' approach in the
# var inits.
# while (( $# > 0 )) && [[ $1 == *"="* ]]; do
#  eval ${1%=*}="'${1#*=}'"
#  shift
# done

liq-init-exts() {
  if [[ -f "${LIQ_EXTS_DB}/exts.sh" ]]; then
    source "${LIQ_EXTS_DB}/exts.sh"
  fi

  if [[ $# -lt 1 ]]; then
    help --summary-only
    echoerr "Invalid invocation. See help above."
    exit 1
  fi
}
