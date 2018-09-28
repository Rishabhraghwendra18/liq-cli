# Global variables.
SOURCE_DIR="$SOURCE_DIR"
BASE_DIR=''
WORKSPACE_DIR=''

COMPONENT=''
ACTION=''

# project globals

ORGANIZATION_ID=''
BILLING_ACCOUNT_ID=''
PROJECT_ID=''

# Configurable globals.
ORIGIN_URL='' # can be set externally to avoid interactive questions on 'project init'

# Global constants.

_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_WORKSPACE_CONFIG='.catalyst-workspace' #TODO: move under _WORKSPACE_DB
_WORKSPACE_DB='.catalyst'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='
