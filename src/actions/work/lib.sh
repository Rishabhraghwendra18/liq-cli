workBranchName() {
  local WORK_DESC="${1:-}"
  requireArgs "$WORK_DESC" || exit $?
  requireArgs "$WORK_STARTED" || exit $?
  requireArgs "$WORK_INITIATOR" || exit $?
  echo "${WORK_STARTED}-${WORK_INITIATOR}-$(workSafeDesc "$WORK_DESC")"
}

workConvertDot() {
  local PROJ="${1}"
  if [[ "${PROJ}" == "." ]]; then
    PROJ=$(cat "$BASE_DIR/package.json" | jq --raw-output '.name' | tr -d "'")
  fi
  echo "$PROJ"
}

workCurrentWorkBranch() {
  git branch | (grep '*' || true) | awk '{print $2}'
}

workSafeDesc() {
  local WORK_DESC="${1:-}"
  requireArgs "$WORK_DESC" || exit $?
  echo "$WORK_DESC" | tr ' -' '_' | tr '[:upper:]' '[:lower:]'
}

# Runs submitter through interactive submit checks specified by company policy. Expects the CWD to be that of or within
# the project being submitted.
workSubmitChecks() {
  local RESULT_VAR="${1}"

  local POLICY_DIR CC_TYPE CHECKS_FILE QUESTION RECORD

  requirePackage
  local CC_QUERY='.liquidDev.changeControl.type'
  CC_TYPE="$(echo "$PACKAGE" | jq --raw-output "$CC_QUERY" | tr -d "'")"
  if [[ -z "$CC_TYPE" ]] || [[ "$CC_TYPE" == 'null' ]]; then
    echoerrandexit "Package '$PACKAGE_NAME' does not define '$CC_QUERY'; bailing out."
  fi

  local FIRST_REASON=true
  local HAS_EXCEPTIONS=''
  local DEF_REASON DEF_MITIGATION
  # you would think we wou we would declare these in 'getReasons', but bash is funny with vars, and the inner-function
  # locals (appearently) have strange effects and even 'unset'-ing them doesn't clear the vars as they appear to the
  # 'require-answer' function.
  local REASON MITIGATION
  getReasons() {
    unset REASON MITIGATION

    if [[ -n "${FIRST_REASON:-}" ]]; then
      echo
      yes-no "By continuing, you are submitting these changes with an explicit exception. Do you wish to continue? (yes/no) " \
        || { echo "Submission cancelled."; exit 0; }
      unset FIRST_REASON

      echo
      echofmt "reset" "(Your explanation may use markdown format, but it is not required.)"
      echo
    fi

    require-answer --multi-line "${yellow}Please provide a complete description as to why the exception is necessary:${reset} " REASON "$DEF_REASON"
    require-answer --multi-line "${yellow}Please describe the steps ALREADY TAKEN (such as creating a task to revisit the issue, etc.) to mitigate and/or address this exception in a timely manner:${reset} " MITIGATION "$DEF_MITIGATION"

    DEF_REASON="${REASON}"
    DEF_MITIGATION="${MITIGATION}"

    echofmt yellow "You will now be asked to review and confirm your answers. (Hit enter to continue.)"
    read
    echofmt green_b "Reason for the exception:"
    echo "${REASON}"
    echo "(Hit enter to continue)"
    read
    echofmt green_b "Steps taken to mitigate exception:"
    echo "${MITIGATION}"
    echo

    if yes-no "Are these statements true and complete? (yes/no) "; then
      RECORD="${RECORD}"$'\n'' '$'\n'"**_Reason given for excepion:_**"$'\n'"$REASON"$'\n'' '$'\n'"**_Steps taken to mitigate:_**"$'\n'"$MITIGATION"
    else
      getReasons
    fi
  }

  submitQuery() {
    local ANSWER
    require-answer "confirmed/no/cancel: " ANSWER
    ANSWER="$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]')"
    case "$ANSWER" in
      confirmed)
        RECORD="$RECORD"$'\n'"**_Answer:_** $ANSWER";;
      no)
        HAS_EXCEPTIONS=false
        RECORD="$RECORD"$'\n'"**_Answer:_** $ANSWER"
        getReasons;;
      cancel)
        echo "Submission cancelled."
        exit 0;;
      *)
        echoerr "You must fully spell out 'confirmed', 'no', or 'cancel'."
        submitQuery;;
    esac
  }

  local POLICY_DIRS=/tmp/policy_dirs
  rm -f $POLICY_DIRS
  policiesGetPolicyDirs > $POLICY_DIRS
  exec 10< $POLICY_DIRS

  while read -u 10 POLICY_DIR; do
    local CHECKS_FILES=/tmp/checks_files
    rm -f $CHECKS_FILES
    find "${POLICY_DIR}" -path "*/policy/change-control/${CC_TYPE}/*" -name "*submit-checks.tsv" > $CHECKS_FILES
    exec 11< $CHECKS_FILES

    while read -u 11 CHECKS_FILE; do
      local QUESTIONS=/tmp/questions
      rm -f $QUESTIONS
      tail +2 "${CHECKS_FILE}" | perl -e '
        use strict; use warnings;
        while (<>) {
          if (!/^\s*$/) {
            my ($question, $absCondition) = split(/\t/, "$_");
            chomp($question);
            my $include = 1;
            if ($absCondition) {
              my @conditions = split(/\s*,\s*/, $absCondition);

              while (@conditions && $include) {
                my $condition = shift @conditions;
                $condition =~ s/HAS_TECHNICAL_OPS/$ENV{"HAS_TECHNICAL_OPS"}/;
                $condition =~ s/DEVELOPS_APPS/$ENV{"DEVELOPS_APPS"}/;
                $condition =~ s/GEN_SEC_LVL/$ENV{"GEN_SEC_LVL"}/;
                $condition =~ s/SEC_TRIVIAL/1/;

                eval "$condition" or $include = 0;
              }
            }

            print "$question\n" if $include;
          }
        }' > $QUESTIONS
      exec 12< $QUESTIONS

      local QUESTION_COUNT=1
      while read -u 12 QUESTION; do
        echo
        echofmt yellow "${QUESTION_COUNT}) $QUESTION"
        if [[ -z "$RECORD" ]]; then
          RECORD="### $QUESTION"
        else
          RECORD="$RECORD"$'\n'$'\n'"### $QUESTION"
        fi

        submitQuery
        QUESTION_COUNT=$(( $QUESTION_COUNT + 1 ))
      done
      exec 12<&-
      rm "$QUESTIONS"
    done
    exec 11<&-
    rm "$CHECKS_FILES"
  done
  exec 10<&-
  rm "$POLICY_DIRS"

  if [[ -z "$HAS_EXCEPTIONS" ]]; then
    RECORD="**All certifications satisfied.**"$'\n'$'\n'"${RECORD}"
  else
    RECORD="**EXCEPTIONS PRESENT.**"$'\n'$'\n'"${RECORD}"
  fi

  eval $RESULT_VAR='"${RECORD}"'
}

workUpdateWorkDb() {
  cat <<EOF > "${LIQ_WORK_DB}/curr_work"
WORK_DESC="$WORK_DESC"
WORK_STARTED="$WORK_STARTED"
WORK_INITIATOR="$WORK_INITIATOR"
WORK_BRANCH="$WORK_BRANCH"
EOF
  echo "INVOLVED_PROJECTS='${INVOLVED_PROJECTS:-}'" >> "${LIQ_WORK_DB}/curr_work"
  echo "WORK_ISSUES='${WORK_ISSUES:-}'" >> "${LIQ_WORK_DB}/curr_work"
}

workUserSelectOne() {
  local _VAR_NAME="$1"; shift
  local _DEFAULT_TO_CURRENT="$1"; shift
  local _TRIM_CURR="$1"; shift
  local _WORK_NAME

  if (( $# > 0 )); then
    exactUserArgs _WORK_NAME -- "$@"
    if [[ ! -f "${LIQ_WORK_DB}/${_WORK_NAME}" ]]; then
      echoerrandexit "No such unit of work '$_WORK_NAME'. Try selecting in interactive mode:\nliq ${GROUP} ${ACTION}"
    fi
  elif [[ -n "$_DEFAULT_TO_CURRENT" ]] && [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    _WORK_NAME=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
  else
    local _OPTIONS
    if ls "${LIQ_WORK_DB}/"* > /dev/null 2>&1; then
      if [[ -n "$_TRIM_CURR" ]] && [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
        local _CURR_WORK=$(basename $(readlink "${LIQ_WORK_DB}/curr_work"))
        _OPTIONS=$(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -not -name "$_CURR_WORK" -type f -exec basename '{}' \; | sort || true)
      else
        _OPTIONS=$(find "${LIQ_WORK_DB}" -maxdepth 1 -not -name "*~" -type f -exec basename '{}' \; | sort || true)
      fi
    fi

    if [[ -z "$_OPTIONS" ]]; then
      echoerrandexit "No outstanding work to select."
    else
      selectOneCancel _WORK_NAME _OPTIONS
    fi
  fi

  eval "$_VAR_NAME='${_WORK_NAME}'"
}

workSwitchBranches() {
  # We expect that the name and existence of curr_work already checked.
  local _BRANCH_NAME="$1"
  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  source "${LIQ_WORK_DB}/curr_work"
  local IP
  for IP in $INVOLVED_PROJECTS; do
    echo "Updating project '$IP' to work branch '${_BRANCH_NAME}'"
    cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${IP}"
    git checkout "${_BRANCH_NAME}" \
      || echoerrandexit "Error updating '${IP}' to work branch '${_BRANCH_NAME}'. See above for details."
  done
}

workProcessIssues() {
  local CSV_ISSUES="${1}"
  local BUGS_URL="${2}"
  local ISSUES ISSUE
  list-from-csv ISSUES "$CSV_ISSUES"
  for ISSUE in $ISSUES; do
    if [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
      if [[ -z "$BUGS_URL" ]]; then
        echoerrandexit "Cannot ref issue number outside project context. Either issue in context or use full URL."
      fi
      list-replace-by-string ISSUES $ISSUE "$BUGS_URL/$ISSUE"
    fi
  done

  echo "$ISSUES"
}
