runtime-services() {
  if [[ $# -eq 0 ]]; then
    runtime-services-list
  elif [[ "$1" == "-s" ]]; then
    shift
    runtime-services-start "$@"
  elif [[ "$1" == "-S" ]]; then
    shift
    runtime-services-stop "$@"
  elif [[ "$1" == "-r" ]]; then
    shift
    runtime-services-restart "$@"
  else
    runtime-services-detail "$@"
  fi
}

runtime-services-list() {
  echo "TODO"
}

runtime-services-start() {
  echo "TODO"
}

runtime-services-stop() {
  echo "TODO"
}

runtime-services-restart() {
  echo "TODO"
}

runtime-services-detail() {
  echo "TODO"
}
