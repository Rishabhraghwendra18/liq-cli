# TODO: link the references once we support.
# Performs all checks and sets up variables ahead of any state changes. Refer to input confirmation, defaults, and user confirmation functions.
# outer vars: inherited
function policy-audit-start-prep() {
  policy-audit-start-confirm-and-normalize-input-valid "$@"
  policy-audit-set-defaults
  policy-audit-start-user-confirm-audit-settings
}

# TODO: link the references once we support.
# Initialize an audit. Refer to folder and questions initializers.
# outer vars: FILE_NAME
function policy-audit-initialize-records() {
  local RECORDS_FOLDER
  policies-audits-initialize-folder
  policies-audits-initialize-audits-json
  policies-audits-initialize-questions
}

# Internal help functions.

# Lib internal helper. See 'liq help policy audit start' for description of proper input.
# outer vars: CHANGE_CONTROL FULL DOMAIN
function policy-audit-start-confirm-and-normalize-input-valid() {
  if [[ -n $CHANGE_CONTROL ]] || [[ -n $FULL ]]; then
    echoerrandexit "Specify only one of '--change-control' or '--full'."
  fi

  DOMAIN="${1:-}"

  if [[ -z $DOMAIN ]]; then # do menu select
    # TODO
    echoerrandexit "Interactive domain not yet supported."
  else
    case "$DOMAIN" in
      code|c)
        DOMAIN='code';;
      network|n)
        DOMAIN='network';;
      *)
        echoerrandexit "Unrecognized domain reference: '$DOMAIN'. Try one of:\n* code\n*network";;
    esac
  fi
}

# Lib internal helper. Sets the outer vars SCOPE, TIME, OWNER, and FILE_NAME.
# outer vars: FULL SCOPE TIME OWNER FILE_NAME
function policy-audit-set-defaults() {
  local FILE_SCOPE FILE_TIME FILE_OWNER
  if [[ -n $FULL ]]; then
    SCOPE='full'
  else
    SCOPE="change control"
    FILE_SCOPE="change_control"
  fi

  TIME="$(TZ=UTC date +%Y-%m-%d-%H%M.%S)"
  FILE_TIME="$(echo $TIME | sed 's/\.[[:digit:]]*$//')"
  OWNER="$(git config user.email)"
  FILE_OWNER=$(echo $OWNER | sed -e 's/@.+$//')

  FILE_NAME="${FILE_TIME}-${DOMAIN}-${SCOPE}-${FILE_OWNER}"
}

# Lib internal helper. Confirms audit settings unless explicitly told not to.
# outer vars: NO_CONFIRM SCOPE DOMAIN OWNER TIME
function policy-audit-start-user-confirm-audit-settings() {
  echofmt reset "Starting audit with:\n\n* scope: ${bold}${SCOPE}${reset}\n* domain: ${bold}${DOMAIN}${reset}\n* owner: ${bold}${OWNER}${reset}\n"
  if [[ -z $NO_CONFIRM ]]; then
    # TODO: update 'yes-no' to use 'echofmt'? also fix echofmt to take '--color'
    if ! yes-no "confirm? (y/N) " N; then
      echowarn "Audit canceled."
      exit 0
    fi
  fi
}

# Lib internal helper. Determines and creates the RECORDS_FOLDER
# outer vars: RECORDS_FOLDER
function policies-audits-initialize-folder() {
  RECORDS_FOLDER="$(orgsPolicyRepo)/records/${FILE_NAME}"
  if [[ -d "${RECORDS_FOLDER}" ]]; then
    echoerrandexit "Looks like the audit has already started. You can't start more than one audit per clock-minute."
  fi
  echo "Creating records folder..."
  mkdir -p "$RECORDS_FOLDER"
}

# Lib internal helper. Initializes the 'audit.json' data record.
# outer vars: RECORDS_FOLDER TIME DOMAIN SCOPE OWNER
function policies-audits-initialize-audits-json() {
  local AUDIT_SH="${RECORDS_FOLDER}/audit.sh"
  local PARAMETERS_SH="${RECORDS_FOLDER}/parameters.sh"
  local DESCRIPTION
  DESCRIPTION="$(tr '[:lower:]' '[:upper:]' <<< ${SCOPE:0:1})${SCOPE:1} ${DOMAIN} audit started on ${TIME:0:10} at ${TIME:11:4} UTC by ${OWNER}."

  if [[ -f "${AUDIT_SH}" ]]; then
    echoerrandexit "Found existing 'audit.json' file while trying to initalize audit. Bailing out..."
  fi

  echofmt reset "Initializing audit data records..."
  # TODO: extract and use 'double-quote-escape' for description
  cat <<EOF > "${AUDIT_SH}"
START="${TIME}"
DESCRIPTION="${DESCRIPTION}"
DOMAIN="${DOMAIN}"
SCOPE="${SCOPE}"
OWNER="${OWNER}"
EOF
  touch "${PARAMETERS_SH}"
}

# Lib internal helper. Determines applicable questions and generates initial TSV record.
function policies-audits-initialize-questions() {
  echo "Gathering relevant policy statements..."
  local FILES
  FILES="$(policiesGetPolicyFiles --find-options "-path '*/policy/${DOMAIN}/standards/*items.tsv'")"

  # TODO: continue
  echo -e "\nbookmark output; found:"
  while read -e FILE; do
    npx liq-standards-filter-abs --settings "$(orgsPolicyRepo)/settings.sh" "$FILE"
  done <<< "$FILES"

  echoerrandexit "Implement..."
}
