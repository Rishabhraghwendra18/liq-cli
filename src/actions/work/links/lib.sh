work-links-lib-working-set() {
  if [[ "${PROJECT}" ]]; then
    change-working-project # effectively checks for existence
    INVOLVED_PROJECTS="${PROJECT}"
  else
    source "${LIQ_WORK_DB}/curr_work"
  fi
}
