source ./_utils.sh
# traps—which define log modes-must come before globals—which sets the default log mode.
if [[ -z "${LIQ_NO_TRAP:-}" ]]; then
source ./traps.sh

log-start
fi
source ./global-vars.sh
source ./help.sh
source ./options.sh
