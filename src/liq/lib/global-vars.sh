###
# Global constants.
###
source ../../shared/common-globals.sh

# Really just a constant at this point, but at some point may allow override at org and project levels.
export PRODUCTION_TAG=production

# Global context variables.
CURR_ENV_FILE='' # set by 'requireEnvironment'
CURR_ENV='' # set by 'requireEnvironment'
CURR_ORG='' # set by post-options-liq-orgs
CURR_ORG_PATH='' # set by post-options-liq-orgs
# 'requireEnvironment' calls 'requirePackage'
PACKAGE='' # set by 'requirePackage'
PACKAGE_NAME='' # set by 'requirePackage'
PACKAGE_FILE='' # set by 'requirePackage', 'requireNpmPackage'

BASE_DIR=''
WORKSPACE_DIR=''

COMPONENT=''
ACTION=''

INVOLVED_PROJECTS='' # defined in the $LIQ_WORK_DB files

LOG_STYLE=${LOG_MODE_USER_DEBUG} # used by 'traps'
LOG_MULTILINE_COMMAND="" # used by 'traps'

# Configurable globals.
ORIGIN_URL='' # can be set externally to avoid interactive questions on 'project init'

STD_ENV_PURPOSES=dev$'\n'test$'\n'pre-production$'\n'production
STD_IFACE_CLASSES=http$'\n'html$'\n'rest$'\n'sql
STD_PLATFORM_TYPES=local$'\n'gcp$'\n'aws

# Standard locations, relative to org repo.
export RECORDS_PATH="records"
export AUDITS_PATH="${RECORDS_PATH}/audits"
export AUDITS_ACTIVE_PATH="${AUDITS_PATH}/active"
export AUDITS_COMPLETE_PATH="${AUDITS_PATH}/complete"
export KEYS_PATH="${RECORDS_PATH}/keys"
export KEYS_ACTIVE_PATH="${KEYS_PATH}/active"
export KEYS_EXPIRED_PATH="${KEYS_PATH}/expired"

# This is used as a jumping off point for running node scripts.
export LIQ_DIST_DIR="$(dirname "$(real_path "${0}")")"
