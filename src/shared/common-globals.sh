###
# Shared globals
#
# These globals are available in both liq and completion.
###

# Key used in npm 'package.json' data to key into liq specific data.
export LIQ_NPM_KEY="liq"
export LIQ_DB_BASENAME=".${LIQ_NPM_KEY}"
export LIQ_DB="${HOME}/${LIQ_DB_BASENAME}"
export LIQ_SETTINGS="${LIQ_DB}/settings.sh"
export LIQ_ENV_DB="${LIQ_DB}/environments"
export LIQ_ORG_DB="${LIQ_DB}/orgs"
export LIQ_WORK_DB="${LIQ_DB}/work"
export LIQ_EXTS_DB="${LIQ_DB}/exts"
export LIQ_ENV_LOGS="${LIQ_DB}/logs"
export LIQ_PLAYGROUND="${LIQ_DB}/playground"
export LIQ_CACHE="${LIQ_DB}/cache"
