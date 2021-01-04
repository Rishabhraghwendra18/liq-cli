# Global constants.
LIQ_DB_BASENAME=".liq"
LIQ_DB="${HOME}/${LIQ_DB_BASENAME}"
LIQ_SETTINGS="${LIQ_DB}/settings.sh"
LIQ_ENV_DB="${LIQ_DB}/environments"
LIQ_ORG_DB="${LIQ_DB}/orgs"
LIQ_WORK_DB="${LIQ_DB}/work"
LIQ_EXTS_DB="${LIQ_DB}/exts"
LIQ_ENV_LOGS="${LIQ_DB}/logs"

LIQ_DIST_DIR="$(dirname "$(real_path "${0}")")"

# defined in $CATALYST_SETTING; during load in dispatch.sh
LIQ_PLAYGROUND=''

_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='

# Global variables.
CURR_ENV_FILE='' # set by 'requireEnvironment'
CURR_ENV='' # set by 'requireEnvironment'
# 'requireEnvironment' calls 'requirePackage'
PACKAGE='' # set by 'requirePackage'
PACKAGE_NAME='' # set by 'requirePackage'
PACKAGE_FILE='' # set by 'requirePackage', 'requireNpmPackage'

BASE_DIR=''
WORKSPACE_DIR=''

COMPONENT=''
ACTION=''

INVOLVED_PROJECTS='' # defined in the $LIQ_WORK_DB files

# Configurable globals.
ORIGIN_URL='' # can be set externally to avoid interactive questions on 'project init'

STD_ENV_PURPOSES=dev$'\n'test$'\n'pre-production$'\n'production
STD_IFACE_CLASSES=http$'\n'html$'\n'rest$'\n'sql
STD_PLATFORM_TYPES=local$'\n'gcp$'\n'aws

# Standard locations, relative to org repo.
RECORDS_PATH="records"
AUDITS_PATH="${RECORDS_PATH}/audits"
AUDITS_ACTIVE_PATH="${AUDITS_PATH}/active"
AUDITS_COMPLETE_PATH="${AUDITS_PATH}/complete"
KEYS_PATH="${RECORDS_PATH}/keys"
KEYS_ACTIVE_PATH="${KEYS_PATH}/active"
KEYS_EXPIRED_PATH="${KEYS_PATH}/expired"
