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
  local POLICY_DIR CC_TYPE CHECKS_FILE QUESTION

  requirePackage
  CC_TYPE="$(echo "$PACKAGE" | jq --raw-output '.liquidDev.changeControl.type' | tr -d "'")"

  while read POLICY_DIR; do
    while read CHECKS_FILE; do
      while read QUESTION; do
        echo
        echocolor yellow "$QUESTION"
      done < <(tail +2 "${CHECKS_FILE}" | perl -e '
        while (<>) {
          use strict; use warnings;
          if (!/^\s*$/) {
            my ($question, $absCondition) = split(/\t/, "$_");
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
        }')
    done < <(find "${POLICY_DIR}" -path "*/policy/change-control/${CC_TYPE}/*" -name "*submit-checks.tsv")
  done < <(policiesGetPolicyDirs)
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
