# TODO: link the references once we support.
# Performs all checks and sets up variables ahead of any state changes. Refer to input confirmation, defaults, and user confirmation functions.
# outer vars: inherited
function policy-audit-start-prep() {
  meta-keys-user-has-key
  policy-audit-start-confirm-and-normalize-input "$@"
  policy-audit-derive-vars
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
# outer vars: CHANGE_CONTROL FULL DOMAIN SCOPE
function policy-audit-start-confirm-and-normalize-input() {
  DOMAIN="${1:-}"

  if [[ -z $SCOPE ]]; then
    SCOPE='change'
  elif [[ $SCOPE != 'change' ]] && [[ $SCOPE != 'full' ]] && [[ $SCOPE != 'process' ]]; then
    echoerrandexit "Invalid scope '$SCOPE'. Scope may be 'change', 'process', or 'full'."
  fi

  if [[ -z $DOMAIN ]]; then # do menu select
    # TODO
    echoerrandexit "Interactive domain not yet supported."
  elif [[ $DOMAIN != 'code' ]] && [[ $DOMAIN != 'network' ]]; then
    echoerrandexit "Unrecognized domain reference: '$DOMAIN'. Try one of:\n* code\n*network"
  fi
}

# Lib internal helper. Sets the outer vars SCOPE, TIME, OWNER, and FILE_NAME.
# outer vars: FULL SCOPE TIME OWNER FILE_NAME
function policy-audit-derive-vars() {
  local FILE_OWNER

  TIME="$(date -u +%Y%m%d%H%M)"
  OWNER="$(git config user.email)"
  FILE_OWNER=$(echo "${OWNER}" | sed -e 's/@.*$//')

  FILE_NAME="${TIME}-${DOMAIN}-${SCOPE}-${FILE_OWNER}"
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
  echo "${TIME} UTC ${OWNER} : initiated audit" > "${RECORDS_FOLDER}/history.log"
}

# Lib internal helper. Determines applicable questions and generates initial TSV record.
# outer vars: RECORDS_FOLDER
function policies-audits-initialize-questions() {
  echo "Gathering relevant policy statements..."
  local FILES
  FILES="$(policiesGetPolicyFiles --find-options "-path '*/policy/${DOMAIN}/standards/*items.tsv'")"

  while read -e FILE; do
    npx liq-standards-filter-abs --settings "$(orgsPolicyRepo)/settings.sh" "$FILE" >> "${RECORDS_FOLDER}/_combined.tsv"
  done <<< "$FILES"

  local STATEMENTS LINE
  if [[ $SCOPE == 'full' ]]; then # all statments included
    STATEMENTS="$(while read -e LINE; do echo "$LINE" | awk -F '\t' '{print $3}'; done \
                  < "${RECORDS_FOLDER}/_combined.tsv")"
  elif [[ $SCOPE == 'process' ]]; then # only IS_PROCESS_AUDIT statements included
    STATEMENTS="$(while read -e LINE; do
                    echo "$LINE" | awk -F '\t' '{ if ($6 == "IS_PROCESS_AUDIT") print $3 }'
                  done < "${RECORDS_FOLDER}/_combined.tsv")"
  else # it's a change audit and we want to ask about the nature of the change
    local ALWAYS=1
    local IS_FULL_AUDIT=0
    local IS_PROCESS_AUDIT=0
    local PARAMS PARAM AND_CONDITIONS CONDITION
    echofmt reset "\nYou will now be asked a series of questions in order to determine the nature of the change. This will determine which policy statements need to be reviewed."
    read -n 1 -s -r -p "Press any key to continue..."
    echo; echo

    exec 10< "${RECORDS_FOLDER}/_combined.tsv"
    local PARAM_SETTINGS
    while read -u 10 -e LINE; do
      local INCLUDE=true
      # we read each set of 'and' conditions
      AND_CONDITIONS="$(echo "$LINE" | awk -F '\t' '{print $6}' | tr ',' '\n' | tr -d ' ')"
      IFS=$'\n' #
      for CONDITION in $AND_CONDITIONS; do # evaluate each condition sequentially until failure or end
        PARAMS="$(echo "$CONDITION" | tr -C '[:alpha:]_' '\n')"
        for PARAM in $PARAMS; do # define undefined params of clause
          if [[ -z "${!PARAM:-}" ]]; then
            function set-yes() { eval $PARAM=1; }
            function set-no() { eval $PARAM=0; }
            local PROMPT
            PROMPT="${PARAM:0:1}$(echo ${PARAM:1} | tr '[:upper:]' '[:lower:]' | tr '_' ' ')? (y/n) "
            yes-no "$PROMPT" "" set-yes set-no
            echo
            PARAM_SETTINGS="${PARAM_SETTINGS} ${PARAM}='${!PARAM}'"
          fi
        done # define clause params
        if ! env -i -S "$(for PARAM in $PARAMS; do echo "$PARAM=${!PARAM} "; done)" perl -e '
            use strict; use warnings;
            my $condition="$ARGV[0]";
            while (my ($k, $v) = each %ENV) { $condition =~ s/$k/$v/g; }
            $condition =~ /[0-9<>=]+/ or die "Invalid audit condition: $condition";
            eval "$condition" or exit 1;' $CONDITION; then
          INCLUDE=false
          break # stop processing conditions
        fi
      done # evaluate each condition
      unset IFS
      if [[ $INCLUDE == true ]]; then
        list-add-item STATEMENTS "$(echo "$LINE" | awk -F '\t' '{print $3}')"
      fi
    done
    exec 10<&-
  fi

  local STATEMENT
  echo -e "Statement\tReviewer\tAffirmed\tComments" > "${RECORDS_FOLDER}/reviews.tsv"
  while read -e STATEMENT; do
    echo -e "$STATEMENT\t\t\t" >> "${RECORDS_FOLDER}/reviews.tsv"
  done <<< "$STATEMENTS"

  policies-audits-add-log-entry "Initialization complete. Audit parameters:${PARAM_SETTINGS}"

  # TODO: continue
  cat "${RECORDS_FOLDER}/reviews.tsv"
  echoerrandexit "Implement..."
}
