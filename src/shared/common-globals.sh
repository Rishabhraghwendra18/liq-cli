###
# Shared globals
#
# These globals are available in both liq and completion.
###

# Key used in npm 'package.json' data to key into liq specific data.
LIQ_NPM_KEY="liq"
LIQ_DB_BASENAME=".${LIQ_NPM_KEY}"
LIQ_DB="${HOME}/${LIQ_DB_BASENAME}"
LIQ_SETTINGS="${LIQ_DB}/settings.sh"
LIQ_ENV_DB="${LIQ_DB}/environments"
LIQ_ORG_DB="${LIQ_DB}/orgs"
LIQ_WORK_DB="${LIQ_DB}/work"
LIQ_EXTS_DB="${LIQ_DB}/exts"
LIQ_ENV_LOGS="${LIQ_DB}/logs"
LIQ_PLAYGROUND="${LIQ_DB}/playground"
