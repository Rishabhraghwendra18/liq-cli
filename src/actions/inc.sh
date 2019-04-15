source ./data/actions.sh
source ./data/lib.sh
source ./data/usage.sh

source ./environments/actions.sh
source ./environments/usage.sh

source ./packages/actions.sh
source ./packages/lib.sh
source ./packages/usage.sh

source ./project/actions.sh
source ./project/lib.sh
source ./project/usage.sh

source ./provided-services/actions.sh
# source ./provided-services/lib.sh
source ./provided-services/usage.sh

source ./remotes/actions.sh
# source ./remotes/lib.sh
source ./remotes/usage.sh

source ./required-services/actions.sh
source ./required-services/lib.sh
source ./required-services/usage.sh

source ./services/actions.sh
source ./services/lib.sh
source ./services/usage.sh

source ./work/actions.sh
source ./work/lib.sh
source ./work/usage.sh

source ./workspace/actions.sh
# source ./workspace/lib.sh
source ./workspace/usage.sh

# getActions() {
#  for d in `find "${SOURCE_DIR}/actions" -type d -maxdepth 1 -not -path "${SOURCE_DIR}/actions"`; do
#    for f in "${d}/"*.sh; do source "$f"; done
#  done
# }
# getActions
