# Global constants.
_CATALYST_DB="${HOME}/.catalyst"
CATALYST_SETTINGS="${_CATALYST_DB}/settings.sh"
_CATALYST_ENVS="${_CATALYST_DB}/environments"
CATALYST_WORK_DB="${_CATALYST_DB}/work"

# defined in $CATALYST_SETTING; set by 'requireCatalystSettings'
CATALYST_PLAYGROUND=''


_CATALYST_ENV_LOGS="${_CATALYST_DB}/environments/logs"
_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_WORKSPACE_DB='.catalyst'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='

GNU_GETOPT="$(brew --prefix gnu-getopt)/bin/getopt"

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

INVOLVED_PROJECTS='' # defined in the $CATALYST_WORK_DB files

# Configurable globals.
ORIGIN_URL='' # can be set externally to avoid interactive questions on 'project init'

CAT_REQ_SERVICES_KEY='_catalystRequiresService'
STD_ENV_PUPRPOSES='dev test pre-production production'
