source ./data/actions.sh
source ./data/lib.sh
source ./data/help.sh

source ./environments/actions.sh
source ./environments/help.sh

source ./meta/actions.sh
source ./meta/help.sh
source ./meta/lib.sh

source ./orgs/actions.sh
source ./orgs/help.sh
source ./orgs/lib.sh

source ./orgs/staff/actions.sh
source ./orgs/staff/lib.sh

source ./policies/actions.sh
source ./policies/help.sh
source ./policies/lib.sh

source ./projects/actions.sh
source ./projects/services.sh
source ./projects/help.sh
source ./projects/lib.sh
source ./projects/qa-lib.sh

# deprecated
source ./required-services/actions.sh
source ./required-services/help.sh
source ./required-services/lib.sh

source ./services/actions.sh
source ./services/help.sh
source ./services/lib.sh

source ./work/actions.sh
source ./work/help.sh
source ./work/lib.sh

# getActions() {
#  for d in `find "${SOURCE_DIR}/actions" -type d -maxdepth 1 -not -path "${SOURCE_DIR}/actions"`; do
#    for f in "${d}/"*.sh; do source "$f"; done
#  done
# }
# getActions
