# See 'liq help policy audit start' for description of proper input.
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

# Sets the outer vars SCOPE, TIME, AUTHOR, and FILE_NAME.
# outer vars: FULL SCOPE TIME AUTHOR FILE_NAME
function policy-audit-set-defaults() {
  local FILE_SCOPE FILE_TIME FILE_AUTHOR
  if [[ -n $FULL ]]; then
    SCOPE='full'
  else
    SCOPE="change control"
    FILE_SCOPE="change_control"
  fi

  TIME="$(date +%Y-%m-%d-%H%M.%S)"
  FILE_TIME="$(echo $TIME | sed 's/\.[[:digit:]]*$//')"
  AUTHOR="$(git config user.email)"
  FILE_AUTHOR=$(echo $AUTHOR | sed -e 's/@.+$//')

  FILE_NAME="${FILE_TIME}-${DOMAIN}-${SCOPE}-${FILE_AUTHOR}"
}

# Confirms audit settings unless explicitly told not to.
# outer vars: NO_CONFIRM SCOPE DOMAIN AUTHOR TIME
function policy-audit-start-user-confirm-audit-settings() {
  echofmt reset "Starting audit with:\n\n* scope: ${bold}${SCOPE}${reset}\n* domain: ${bold}${DOMAIN}${reset}\n* author: ${bold}${AUTHOR}${reset}\n"
  if [[ -z $NO_CONFIRM ]]; then
    # TODO: update 'yes-no' to use 'echofmt'? also fix echofmt to take '--color'
    if ! yes-no "confirm? (y/N) " N; then
      echowarn "Audit canceled."
      exit 0
    fi
  fi
}

# TODO: link the references once we support.
# Refer to input confirmation, defaults, and user confirmation functions.
# outer vars: inherited
function policy-audit-start-prep() {
  policy-audit-start-confirm-and-normalize-input-valid "$@"
  policy-audit-set-defaults
  policy-audit-start-user-confirm-audit-settings
}

# Determines and creates the RECORDS_FOLDER
# outer vars: RECORDS_FOLDER
function policies-audits-initialize-folder() {
  RECORDS_FOLDER="$(orgsPolicyRepo)/records/${FILE_NAME}"
  if [[ -d "$RECORDS_FOLDER" ]]; then
    echoerrandexit "Looks like the audit has already started. You can't start more than one audit per clock-minute."
  fi
  echo "Creating records folder..."
  mkdir -p "$RECORDS_FOLDER"
}

# Determines applicable questions and generates initial TSV record.
function policies-audits-initialize-questions() {
  FILES="$(policiesGetPolicyFiles --find-options "-path './policies/$DOMAIN/standards/*items.tsv'")"

  # TODO: continue
  echo "bookmark output; found:"
  while read -e FILE; do
    echo "$FILE"
  done <<< "$FILES"

  echoerrandexit "Implement..."
}

# TODO: link the references once we support.
# Initialize an audit. Refer to folder and questions initializers.
# outer vars: FILE_NAME
function policy-audit-initialize-records() {
  local RECORDS_FOLDER
  policies-audits-initialize-folder
  policies-audits-initialize-questions
}
