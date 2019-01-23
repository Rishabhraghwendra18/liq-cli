updateWorkDb() {
  if [[ -z "$INVOLVED_PROJECTS" ]]; then
    echo "INVOLVED_PROJECTS=''" > "${CATALYST_WORK_DB}/curr_work"
  else
    echo "INVOLVED_PROJECTS='$( echo "$INVOLVED_PROJECTS" | sed -Ee 's/^ +//' )'" > "${CATALYST_WORK_DB}/curr_work"
  fi
}
