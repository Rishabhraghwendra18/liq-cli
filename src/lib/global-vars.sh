# Global constants.
_CATALYST_DB="${HOME}/.catalyst"
_CATALYST_ENVS="${_CATALYST_DB}/environments"
_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_WORKSPACE_CONFIG='.catalyst-workspace' #TODO: move under _WORKSPACE_DB
_WORKSPACE_DB='.catalyst'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='

# Global variables.

CURR_ENV_FILE='' # set by 'requireEnvironment'
CURR_ENV='' # set by 'requireEnvironment'
# 'requireEnvironment' calls 'requirePackage'
PACKAGE='' # set by 'requirePackage'
PACKAGE_NAME='' # set by 'requirePackage'
PACKAGE_FILE='' # set by 'requirePackage', 'requireNpmPackage'

SOURCE_DIR="$SOURCE_DIR" # TODO: huh?
BASE_DIR=''
WORKSPACE_DIR=''

COMPONENT=''
ACTION=''

# Configurable globals.
ORIGIN_URL='' # can be set externally to avoid interactive questions on 'project init'
