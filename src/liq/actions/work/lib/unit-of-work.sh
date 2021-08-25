work-lib-require-unit-of-work() {
  if [[ ! -L "${LIQ_WORK_DB}/curr_work" ]]; then
    echoerrandexit "An active/current unit of work is requried. Try:\nliq work resume # or start"
  fi

  source "${LIQ_WORK_DB}/curr_work"
}
