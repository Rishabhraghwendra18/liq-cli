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

  TIME="$(date +%Y-%m-%d-%H%m.%S)"
  FILE_TIME="$(echo $TIME | sed -e 's/.\d+$//')"
  AUTHOR="$(git config user.email)"
  FILE_AUTHOR=$(echo $TIME | sed -e 's/@.+$//')

  FILE_NAME="${FILE_TIME}-${DOMAIN}-${SCOPE}-${FILE_AUTHOR}"
}

# Confirms audit settings unless explicitly told not to.
# outer vars: NO_CONFIRM SCOPE DOMAIN AUTHOR
function policy-audit-start-user-confirm-audit-settings() {
  if [[ -z $NO_CONFIRM ]]; then
    # TODO: update 'yes-no' to use 'echofmt' ?
    echofmt reset "Starting audit with:\n\n* scope: ${bold}${SCOPE}${reset}\n* domain: ${bold}${DOMAIN}${reset}\n* author: ${bold}${AUTHOR}${reset}\n"
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
