CATALYST_COMMAND_GROUPS=(help data environments meta orgs orgs-staff projects required-services services work)

help-help() {
  PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}help${reset} [<group> [<action>]]: Displays help summary or—with group—details." || cat <<EOF
${PREFIX}${cyan_u}help${reset} [--all|-a] [--summary-only|-s] [<group> [<action>]]:
  Displays liq help. With no arguments, defaults to a summary listing of the available groups. The '--all' option will print the full help for each group, even with no args. If a group or action is specified, then only help for that group and or group+action is displayed. In this case, '--all' is the default and '--summary-only' will cause a one-line summary to be displayed.

  Note, to display help for a sub-group, a '-' must be used between the parent and child group like: 'help orgs-staff'.
EOF
}

help() {
  eval "$(setSimpleOptions ALL SUMMARY_ONLY -- "$@")" \
    || { echoerr "Bad options."; help-help; exit 1; }

  local GROUP="${1:-}"
  local ACTION="${2:-}"
  local SUMMARY_ONLY

  if (( $# == 0 )); then
    # If displaying all, only display summary.
    if [[ -z "$ALL" ]]; then SUMMARY_ONLY=true; fi

    cat <<EOF
Usage:
  liq <resource/group> <action> [...options...] [...selectors...]
  liq ${cyan_u}help${reset} [<group or resource> [<action>]
EOF

    local GROUP
    for GROUP in ${CATALYST_COMMAND_GROUPS[@]}; do
      echo
      help-${GROUP}
    done
  elif (( $# == 1 )); then
    if type -t help-${GROUP} | grep -q 'function'; then
      help-${GROUP} "liq "
    else
      exitUnknownGroup
    fi
  elif (( $# == 2 )); then
    if type -t help-${GROUP}-${ACTION} | grep -q 'function'; then
      help-${GROUP}-${ACTION} "liq ${GROUP} "
    else
      exitUnknownAction
    fi
  else
    echo "Usage:"
    echo "liq ${cyan_u}help${reset} [<group or resource> [<action>]"
    echoerrandexit "To many arguments in help."
  fi
}

helperHandler() {
  local PREFIX="$1"; shift
  if [[ -n "$PREFIX" ]]; then
    local HELPER
    for HELPER in "$@"; do
      echo
      $HELPER
    done
  fi
}

handleSummary() {
  local SUMMARY="${1}"; shift

  if [[ -n "${SUMMARY_ONLY:-}" ]]; then
    echo "$SUMMARY"
    return 0
  else
    return 1
  fi
}
