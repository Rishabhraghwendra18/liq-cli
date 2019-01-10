# Global constants.
_CATALYST_DB="${HOME}/.catalyst"
_CURR_ENV_FILE="${_CATALYST_DB}/curr_env"
_CATALYST_ENVS="${_CATALYST_DB}/environments"
_PROJECT_CONFIG='.catalyst-project' #TODO: current file '.catalyst' and the code doesn't make reference to this constant; convert that to 'catalyst-project'
_PROJECT_PUB_CONFIG='.catalyst-pub'
_WORKSPACE_CONFIG='.catalyst-workspace' #TODO: move under _WORKSPACE_DB
_WORKSPACE_DB='.catalyst'
_ORG_ID_URL='https://console.cloud.google.com/iam-admin/settings'
_BILLING_ACCT_URL='https://console.cloud.google.com/billing?folder=&organizationId='

# Global variables.
SOURCE_DIR="$SOURCE_DIR"
BASE_DIR=''
WORKSPACE_DIR=''

COMPONENT=''
ACTION=''

# environment globals
if [ -f "${_CURR_ENV_FILE}" ]; then
  source "$_CURR_ENV_FILE"
  source "$_CATALYST_ENVS/${CURR_ENV}"
else
  CURR_ENV=''
  CURR_ENV_TYPE=''
  CURR_ENV_PURPOSE=''
  # CURR_ENV_GCP_ORG_ID=''
  # CURR_ENV_GCP_BILLING_ID=''
  # CURR_ENV_GCP_PROJ_ID=''
fi

# Configurable globals.
ORIGIN_URL='' # can be set externally to avoid interactive questions on 'project init'
