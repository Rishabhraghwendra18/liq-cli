# Works out the proper name of a work (or release) branch. The '--release' option will add a '-release-' indicator to
# the branch name and also use the 'WORK_DESC' without transformation. Otherwise, 'WORK_DESC' is treated as an
# arbitrary user string and transformed to be branch name friendly.
#
# DEPRECATED-ish: for workb ranch naming, use work-lib-workbranch-name. This is still used for release branches, but (TODO) should be replaced at some point.
work-lib-branch-name() {
  eval "$(setSimpleOptions RELEASE: -- "$@")"

  local WORK_DESC="${1:-}"
  requireArgs "${WORK_DESC}" || exit $?
  [[ -n "${WORK_STARTED:-}" ]] || {
    declare -p WORK_STARTED >/dev/null || echoerrandexit "Variable 'WORK_STARTED' (which receives the start date) neither set nor declared."
    # else, let's fall back to a default
    WORK_STARTED=$(date "+%Y.%m.%d")
  }
  [[ -n "${WORK_INITIATOR:-}" ]] || {
    declare -p WORK_INITIATOR >/dev/null || echoerrandexit "Variable 'WORK_INITIATOR' (which receives the email of the initiator) neither set nor declared."
    WORK_INITIATOR=$(git config --get user.email)
  }

  local RELEASE_TAG=""
  [[ -z "${RELEASE}" ]] || RELEASE_TAG="release-"

  local BRANCH_NAME="${WORK_STARTED}-${WORK_INITIATOR}-${RELEASE_TAG}"
  if [[ -n "${RELEASE}" ]]; then # use literal WORK_DESK
    BRANCH_NAME="${BRANCH_NAME}${WORK_DESC}"
  else # safe-ify WORK_DESC
    BRANCH_NAME="${BRANCH_NAME}$(work-lib-safe-desc "$WORK_DESC")"
  fi
  echo "${BRANCH_NAME}"
}

# Works out the proper name of a work branch. Sets 'WORK_DESC', 'WORK_STARTED', 'WORK_INITIATOR', and 'WORK_BRANCH'
work-lib-work-branch-name() {
  local WORK_DESC="${1:-}"
  requireArgs "${WORK_DESC}" || exit $?
  [[ -n "${WORK_STARTED:-}" ]] || {
    declare -p WORK_STARTED >/dev/null || echoerrandexit "Variable 'WORK_STARTED' (which receives the start date) neither set nor declared."
    # else, let's fall back to a default
    WORK_STARTED=$(date "+%Y.%m.%d")
  }
  [[ -n "${WORK_INITIATOR:-}" ]] || {
    declare -p WORK_INITIATOR >/dev/null || echoerrandexit "Variable 'WORK_INITIATOR' (which receives the email of the initiator) neither set nor declared."
    WORK_INITIATOR=$(git config --get user.email)
  }
  declare -p WORK_BRANCH >/dev/null || echoerrandexit "Variable 'WORK_BRANCH' is not declared as expected."

  WORK_BRANCH="${WORK_STARTED}-${WORK_INITIATOR}-$(work-lib-safe-desc "${WORK_DESC}")"
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

work-lib-safe-desc() {
  local WORK_DESC="${1:-}"
  requireArgs "$WORK_DESC" || exit $?
  # 1) change all spaces and hyphens to underscores.
  # 2) lower case everything.
  # 3) Remove any non-alphanumeric characters except '_'.
  # 4) Extract the first four words.
  # 5) Remove any trailing underscore.
  echo "$WORK_DESC" \
    | tr ' -' '_' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -Ee 's/[^[:alnum:]_]//g' \
      -e 's/(([[:alnum:]]+(_|$)){1,4}).*/\1/' \
      -e 's/_$//'
}

# Runs submitter through interactive submit checks specified by company policy. Expects the CWD to be that of or within
# the project being submitted.
workSubmitChecks() {
  local RESULT_VAR="${1}"

  local POLICY_DIR CC_TYPE CHECKS_FILE QUESTION RECORD

  requirePackage
  local CC_QUERY=".${LIQ_NPM_KEY}.changeControl.type"
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
      echofmt "(Your explanation may use markdown format, but it is not required.)"
      echo
    fi

    require-answer --multi-line "${yellow}Please provide a complete description as to why the exception is necessary:${reset} " REASON "$DEF_REASON"
    require-answer --multi-line "${yellow}Please describe the steps ALREADY TAKEN (such as creating a task to revisit the issue, etc.) to mitigate and/or address this exception in a timely manner:${reset} " MITIGATION "$DEF_MITIGATION"

    DEF_REASON="${REASON}"
    DEF_MITIGATION="${MITIGATION}"

    echofmt --warn "You will now be asked to review and confirm your answers. (Hit enter to continue.)"
    read
    echofmt --info "Reason for the exception:"
    echo "${REASON}"
    echo "(Hit enter to continue)"
    read
    echofmt --info "Steps taken to mitigate exception:"
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

  # We setup named pipes that we use to feed the embedded reads without them stepping on each other.
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
        echofmt --warn "${QUESTION_COUNT}) $QUESTION"
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
export WORK_DESC='${WORK_DESC//\'/}'
export WORK_STARTED='$WORK_STARTED'
export WORK_INITIATOR='$WORK_INITIATOR'
export WORK_BRANCH='$WORK_BRANCH'
EOF
  # These are handled separate because they can potentially be multi-line (I am guessing)
  echo "export INVOLVED_PROJECTS='${INVOLVED_PROJECTS:-}'" >> "${LIQ_WORK_DB}/curr_work"
  echo "export WORK_ISSUES='${WORK_ISSUES:-}'" >> "${LIQ_WORK_DB}/curr_work"
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
    if ls "${LIQ_WORK_DB}/"* > /dev/null 2> /dev/null; then
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
  eval "$(setSimpleOptions DIRTY_OK: -- "$@")"
  local _BRANCH_NAME="$1"

  if [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    [[ -n "${DIRTY_OK}" ]] || requireCleanRepos
    source "${LIQ_WORK_DB}/curr_work"
    echo "Resetting current work unit repos to 'master'..."
    local IP
    for IP in $INVOLVED_PROJECTS; do
      IP="${IP/@/}"
      git checkout master
    done
  fi

  if [[ "$_BRANCH_NAME" != "master" ]]; then
    [[ -n "${DIRTY_OK}" ]] || requireCleanRepos
    ( # we don't want overwrite the sourced vars
      source "${LIQ_WORK_DB}/${_BRANCH_NAME}"

      for IP in $INVOLVED_PROJECTS; do
        IP=${IP/@/}
        if [[ ! -d "${LIQ_PLAYGROUND}/${IP}" ]]; then
          echoerr "Project @${IP} is not locally available. Try:\nliq projects import ${IP}\nliq work resume ${WORK_NAME}"
          continue
        fi

        echo "Updating project '$IP' to branch '${_BRANCH_NAME}'"
        cd "${LIQ_PLAYGROUND}/${IP}"
        if git show-ref --verify --quiet "refs/heads/${_BRANCH_NAME}"; then
          git checkout "${_BRANCH_NAME}" \
            || echoerrandexit "Error updating '${IP}' to work branch '${_BRANCH_NAME}'. See above for details."
        else # the branch is not locally availble, but lets check the workspace
          echo "Work branch not locally available, checking workspace..."
          git fetch --quiet workspace
          if git show-ref --verify --quiet "refs/remotes/workspace/${_BRANCH_NAME}"; then
            git checkout --track "workspace/${_BRANCH_NAME}" \
              || echoerrandexit "Found branch on workspace, but there were problems checking it out."
          else
            echoerrandexit "Could not find the indicated work branch either localaly or on workspace. It is possible the work has been completed or dropped."
            # TODO: long term, we want to be able to resurrect old branches, and we'd offer that as a 'try' option here.
          fi
        fi
      done
    ) # source-isolating subshel
  fi
}

work-lib-process-issues() {
  local VAR="${1}"
  local CSV_ISSUES="${2}"
  local BUGS_URL="${3}"
  local ISSUES ISSUE
  list-from-csv "${VAR}" "${CSV_ISSUES}"
  for ISSUE in ${!VAR}; do
    if [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
      if [[ -z "$BUGS_URL" ]]; then
        echoerrandexit "Cannot ref issue number outside project context. Either issue in context or use full URL."
      fi
      list-replace-by-string ${VAR} $ISSUE "$BUGS_URL/$ISSUE"
    fi
  done
}
