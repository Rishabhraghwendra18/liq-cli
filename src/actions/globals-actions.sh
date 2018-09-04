global-help() {
  local HELP_COMPONENT="${1:-}"
  if [[ -z "$HELP_COMPONENT" ]]; then
    print_usage
  else
    print_${HELP_COMPONENT}_usage
  fi
}
