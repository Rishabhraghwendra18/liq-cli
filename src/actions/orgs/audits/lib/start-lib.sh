# TODO: link the references once we support.
# Performs all checks and sets up variables ahead of any state changes. Refer to input confirmation, defaults, and user confirmation functions.
# outer vars: inherited
function policy-audit-start-prep() {
  meta-keys-user-has-key
  policy-audit-start-confirm-and-normalize-input "$@"
  policy-audit-derive-vars
  policy-audit-start-user-confirm-audit-settings
}

function orgs-audits-setup-work() {
  (
    local MY_GITHUB_NAME ISSUE_URL ISSUE_NUMBER
    projectHubWhoami MY_GITHUB_NAME
    cd $(orgsPolicyRepo) # TODO: create separately specified records repo
    ISSUE_URL="$(hub issue create -m "$(orgs-audits-describe)" -a "$MY_GITHUB_NAME" -l audit)"
    ISSUE_NUMBER="$(basename "$ISSUE_URL")"

    work-start --push -i $ISSUE_NUMBER "$(orgs-audits-describe --short)"
  )
}

# TODO: link the references once we support.
# Initialize an audit. Refer to folder and questions initializers.
# outer vars: TIME inherited
function policy-audit-initialize-records() {
  orgs-audits-initialize-folder
  orgs-audits-initialize-audits-json
  orgs-audits-initialize-questions
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

# Lib internal helper. Sets the outer vars SCOPE, TIME, OWNER, and AUDIT_PATH
# outer vars: FULL SCOPE TIME OWNER AUDIT_PATH
function policy-audit-derive-vars() {
  local FILE_OWNER FILE_NAME

  TIME="$(orgs-audits-now)"
  OWNER="$(git config user.email)"
  FILE_OWNER=$(echo "${OWNER}" | sed -e 's/@.*$//')

  FILE_NAME="${TIME}-${DOMAIN}-${SCOPE}-${FILE_OWNER}"
  AUDIT_PATH="$(orgsPolicyRepo)/${AUDITS_ACTIVE_PATH}/${FILE_NAME}"
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

# Lib internal helper. Determines and creates the AUDIT_PATH
# outer vars: AUDIT_PATH
function orgs-audits-initialize-folder() {
  if [[ -d "${AUDIT_PATH}" ]]; then
    echoerrandexit "Looks like the audit has already started. You can't start more than one audit per second."
  fi
  echo "Creating records folder..."
  mkdir -p "${AUDIT_PATH}"
  mkdir "${AUDIT_PATH}/refs"
  mkdir "${AUDIT_PATH}/sigs"
}

# Lib internal helper. Initializes the 'audit.json' data record.
# outer vars: AUDIT_PATH TIME DOMAIN SCOPE OWNER
function orgs-audits-initialize-audits-json() {
  local AUDIT_SH="${AUDIT_PATH}/audit.sh"
  local PARAMETERS_SH="${AUDIT_PATH}/parameters.sh"
  local DESCRIPTION
  DESCRIPTION=$(orgs-audits-describe)

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
  echo "${TIME} UTC ${OWNER} : initiated audit" > "${AUDIT_PATH}/refs/history.log"
}

# Lib internal helper. Determines applicable questions and generates initial TSV record.
# outer vars: inherited
function orgs-audits-initialize-questions() {
  orgs-audits-create-combined-tsv
  local ACTION_SUMMARY
  orgs-audits-create-final-audit-statements ACTION_SUMMARY
  orgs-audits-add-log-entry "${ACTION_SUMMARY}"
}

# Lib internal helper. Creates the 'ref/combined.tsv' file containing the list of policy items included based on org (absolute) parameters.
# outer vars: DOMAIN AUDIT_PATH
orgs-audits-create-combined-tsv() {
  echo "Gathering relevant policy statements..."
  local FILES
  FILES="$(policiesGetPolicyFiles --find-options "-path '*/policy/${DOMAIN}/standards/*items.tsv'")"

  while read -e FILE; do
    npx liq-standards-filter-abs --settings "$(orgsPolicyRepo)/settings.sh" "$FILE" >> "${AUDIT_PATH}/refs/combined.tsv"
  done <<< "$FILES"
}

# Lib internal helper. Analyzes 'ref/combined.tsv' against parameter setting to generate the final list of statements included in the audit. This may involve an interactive question / answer loop (with change audits). Echoes a summary of actions (including any parameter values used) suitable for logging.
# outer vars: SCOPE AUDIT_PATH
orgs-audits-create-final-audit-statements() {
  local SUMMAR_VAR="${1}"

  local STATEMENTS LINE
  if [[ $SCOPE == 'full' ]]; then # all statments included
    STATEMENTS="$(while read -e LINE; do echo "$LINE" | awk -F '\t' '{print $3}'; done \
                  < "${AUDIT_PATH}/refs/combined.tsv")"
    eval "$SUMMARY_VAR='Initialized audit statements using with all policy standards.'"
  elif [[ $SCOPE == 'process' ]]; then # only IS_PROCESS_AUDIT statements included
    STATEMENTS="$(while read -e LINE; do
                    echo "$LINE" | awk -F '\t' '{ if ($6 == "IS_PROCESS_AUDIT") print $3 }'
                  done < "${AUDIT_PATH}/refs/combined.tsv")"
    eval "$SUMMARY_VAR='Initialized audit statements using with all process audit standards.'"
  else # it's a change audit and we want to ask about the nature of the change
    local ALWAYS=1
    local IS_FULL_AUDIT=0
    local IS_PROCESS_AUDIT=0
    local PARAMS PARAM PARAM_SETTINGS AND_CONDITIONS CONDITION
    echofmt reset "\nYou will now be asked a series of questions in order to determine the nature of the change. This will determine which policy statements need to be reviewed."
    read -n 1 -s -r -p "Press any key to continue..."
    echo; echo

    exec 10< "${AUDIT_PATH}/refs/combined.tsv"
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

    eval "$SUMMAR_VAR='Initialized audit statements using parameters:${PARAM_SETTINGS}.'"
  fi

  local STATEMENT
  echo -e "Statement\tReviewer\tAffirmed\tComments" > "${AUDIT_PATH}/reviews.tsv"
  while read -e STATEMENT; do
    echo -e "$STATEMENT\t\t\t" >> "${AUDIT_PATH}/reviews.tsv"
  done <<< "$STATEMENTS"
}
