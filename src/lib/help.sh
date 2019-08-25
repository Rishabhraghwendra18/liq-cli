CATALYST_COMMAND_GROUPS=(data environments meta packages playground project provided-services remotes required-services services work)

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
  catalyst <resource/group> <action> [...options...] [...selectors...]
  catalyst ${cyan_u}help${reset} [<group or resource> [<action>]
EOF

    local GROUP
    for GROUP in ${CATALYST_COMMAND_GROUPS[@]}; do
      echo
      help-${GROUP}
    done

    if [[ -z "$SUMMARY_ONLY" ]]; then
      echo
      helpHelperAlphaPackagesNote
    fi
  elif (( $# == 1 )); then
    if type -t help-${GROUP} | grep -q 'function'; then
      help-${GROUP} "catalyst "
    else
      exitUnknownGroup
    fi
  elif (( $# == 2 )); then
    if type -t help-${GROUP}-${ACTION} | grep -q 'function'; then
      help-${GROUP}-${ACTION} "catalyst ${GROUP} "
    else
      exitUnknownAction
    fi
  else
    echo "Usage:"
    echo "catalyst ${cyan_u}help${reset} [<group or resource> [<action>]"
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

helpHelperAlphaPackagesNote() {
cat <<EOF
${red_b}Alpha note:${reset} There is currently no support for multiple packages in a single
repository and the 'package.json' file is assumed to be in the project root.
EOF
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
