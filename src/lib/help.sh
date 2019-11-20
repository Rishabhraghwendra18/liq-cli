CATALYST_COMMAND_GROUPS=(data environments meta orgs projects required-services services work)

help() {
  local TMP
  TMP=$(setSimpleOptions SUMMARY_ONLY -- "$@") \
    || ( help-runtime-services; echoerrandexit "Bad options." )
  eval "$TMP"

  local GROUP="${1:-}"
  local ACTION="${2:-}"

  if (( $# == 0 )); then
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
