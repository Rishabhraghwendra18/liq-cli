source ./data/actions.sh
source ./data/lib.sh
source ./data/help.sh

source ./environments/actions.sh
source ./environments/help.sh

source ./meta/inc.sh

source ./orgs/actions.sh
source ./orgs/help.sh
source ./orgs/lib.sh

source ./orgs/audits/inc.sh

source ./orgs/policies/actions.sh
source ./orgs/policies/help.sh
source ./orgs/policies/lib.sh

source ./orgs/staff/actions.sh
source ./orgs/staff/help.sh
source ./orgs/staff/lib.sh

source ./projects/inc.sh

# deprecated
source ./required-services/actions.sh
source ./required-services/help.sh
source ./required-services/lib.sh

source ./services/actions.sh
source ./services/help.sh
source ./services/lib.sh

source ./work/inc.sh

# getActions() {
#  for d in `find "${SOURCE_DIR}/actions" -type d -maxdepth 1 -not -path "${SOURCE_DIR}/actions"`; do
#    for f in "${d}/"*.sh; do source "$f"; done
#  done
# }
# getActions
