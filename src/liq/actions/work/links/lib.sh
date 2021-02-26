work-links-lib-working-set() {
  if [[ -n "${PROJECTS}" ]]; then
    PROJECTS="$(echo "${PROJECTS}" | tr ',' ' ')"
  else
    source "${LIQ_WORK_DB}/curr_work"
    PROJECTS="${INVOLVED_PROJECTS}"
  fi
}
