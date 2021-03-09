source ./_utils.sh
source ./global-vars.sh
source ./help.sh
source ./options.sh
if [[ -z "${LIQ_NO_TRAP:-}" ]]; then
source ./traps.sh
fi
