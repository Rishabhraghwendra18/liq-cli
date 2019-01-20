CATALYST_COMMAND_GROUPS=(data packages provided-services remotes required-services services work workspace)

help() {
  local TMP
  TMP=$(setSimpleOptions SUMMARY_ONLY -- "$@") \
    || ( usage-runtime-services; echoerrandexit "Bad options." )
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
      usage-${GROUP}
    done

    echo
    usageHelperAlphaPackagesNote
  elif (( $# == 1 )); then
    if type -t usage-${GROUP} | grep -q 'function'; then
      usage-${GROUP} "catalyst "
    else
      exitUnknownGroup
    fi
  elif (( $# == 2 )); then
    if type -t usage-${GROUP}-${ACTION} | grep -q 'function'; then
      usage-${GROUP}-${ACTION} "catalyst ${GROUP} "
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

usageHelperAlphaPackagesNote() {
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
