CATALYST_COMMAND_GROUPS="help meta meta-exts orgs projects work work-links"

# display help on help
help-help() {
  PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}help${reset} [<group> [<sub-group|action>...]]: Displays summary of groups or information on the specified topic." || cat <<EOF
${PREFIX}${cyan_u}help${reset} [--all|-a] [--summary-only|-s] [<group> [<action>]]:
  Displays liq help. With no arguments, defaults to a summary listing of the available groups. The '--all' option will print the full help for each group, even with no args. If a group or action is specified, then only help for that group and or group+action is displayed. In this case, '--all' is the default and '--summary-only' will cause a one-line summary to be displayed.
EOF
}

# Display help information. Takes zero or more arguments specifying the topic. A topic must be a liq command group,
# sub-group, or command. Most of the work is done by deferring help functions for the specified topic.
help() {
  eval "$(setSimpleOptions ALL SUMMARY_ONLY -- "$@")" \
    || { echoerr "Bad options."; help-help; exit 1; }

  if (( $# == 0 )); then
    # If displaying all, only display summary.
    if [[ -z "$ALL" ]]; then SUMMARY_ONLY=true; fi

    cat <<EOF
Usage:
  liq <resource/group> <action> [...options...] [...selectors...]
  liq ${cyan_u}help${reset} [<group or resource> [<action>]
EOF

    # This bits is what generates the list of locally installed groups, and printing their info.
    local GROUP
    for GROUP in $CATALYST_COMMAND_GROUPS; do
      echo
      help-${GROUP}
    done
  else
    if ! type -t help-${1} | grep -q 'function'; then
      exitUnknownHelpTopic "$1" ""
    fi
    local HELP_SPEC="${1}"; shift
    while (( $# > 0)); do
      if ! type -t help-${HELP_SPEC}-${1} | grep -q 'function'; then
        exitUnknownHelpTopic "$1" "$HELP_SPEC"
      fi
      HELP_SPEC="${HELP_SPEC}-${1}"
      shift
    done

    help-${HELP_SPEC} "liq "
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

# display a helpful error message for invalid topics.
exitUnknownHelpTopic() {
  local BAD_SPEC="${1:-}"; shift
  help $*
  echo
  echoerrandexit "No such command or group: $BAD_SPEC"
}
