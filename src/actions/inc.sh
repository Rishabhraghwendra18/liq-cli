source ./data/actions.sh
source ./data/lib.sh
source ./data/help.sh

source ./environments/actions.sh
source ./environments/help.sh

source ./meta/actions.sh
source ./meta/help.sh

source ./packages/actions.sh
source ./packages/lib.sh
source ./packages/help.sh

source ./project/actions.sh
source ./project/lib.sh
source ./project/help.sh

source ./provided-services/actions.sh
# source ./provided-services/lib.sh
source ./provided-services/help.sh

source ./remotes/actions.sh
# source ./remotes/lib.sh
source ./remotes/help.sh

source ./required-services/actions.sh
source ./required-services/lib.sh
source ./required-services/help.sh

source ./services/actions.sh
source ./services/lib.sh
source ./services/help.sh

source ./work/actions.sh
source ./work/lib.sh
source ./work/help.sh

source ./playground/actions.sh
# source ./playground/lib.sh
source ./playground/help.sh

# getActions() {
#  for d in `find "${SOURCE_DIR}/actions" -type d -maxdepth 1 -not -path "${SOURCE_DIR}/actions"`; do
#    for f in "${d}/"*.sh; do source "$f"; done
#  done
# }
# getActions
