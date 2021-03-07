###
# Global constants.
###
source ../../shared/common-globals.sh

LIQ_DIST_DIR="$(dirname "$(real_path "${0}")")"

# Really just a constant at this point, but at some point may allow override at org and project levels.
PRODUCTION_TAG=production

_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='

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
