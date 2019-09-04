updateWorkDb() {
  if [[ -z "$INVOLVED_PROJECTS" ]]; then
    echo "INVOLVED_PROJECTS=''" > "${LIQ_WORK_DB}/curr_work"
  else
    echo "INVOLVED_PROJECTS='$( echo "$INVOLVED_PROJECTS" | sed -Ee 's/^ +//' )'" > "${LIQ_WORK_DB}/curr_work"
  fi
}

workUserSelectOne() {
  local _VAR_NAME="$1"; shift
  local _DEFAULT_TO_CURRENT="$1"; shift
  local _TRIM_CURR="$1"; shift
  local _WORK_NAME

  if (( $# > 0 )); then
    exactUserArgs _WORK_NAME -- "$@"
    if [[ ! -f "${LIQ_WORK_DB}/${_WORK_NAME}" ]]; then
      echoerrandexit "No such unit of work '$_WORK_NAME'. Try selecting in interactive mode:\ncatalyst ${GROUP} ${ACTION}"
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
  source "${LIQ_WORK_DB}/curr_work"
  local IP
  for IP in $INVOLVED_PROJECTS; do
    echo "Updating project '$IP' to work branch '${_BRANCH_NAME}'"
    cd "${LIQ_PLAYGROUND}/${IP}"
    git checkout "${_BRANCH_NAME}" \
      || echoerrandexit "Error updating '${IP}' to work branch '${_BRANCH_NAME}'. See above for details."
  done
}
