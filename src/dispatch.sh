if (( $# == 0 )); then
  echoerrandexit "No arguments provided. Try:\nliq help"
fi
GROUP="${1:-}"; shift # or global command
case "$GROUP" in
  # global actions
  help)
    help "$@";;
  # components and actionsprojct
  *)
    if (( $# == 0 )); then
      help $GROUP
      echoerrandexit "\nNo action argument provided. See valid actions above."
		elif [[ $(type -t "requirements-${GROUP}" || echo '') != 'function' ]]; then
			exitUnknownGroup
    fi
    ACTION="${1:-}"; shift
    if [[ $(type -t "${GROUP}-${ACTION}" || echo '') == 'function' ]]; then
      # the only exception to requiring a playground configuration is the
      # 'playground init' command
      if [[ "$GROUP" != 'meta' ]] || [[ "$ACTION" != 'init' ]]; then
        # source is not like other commands (?) and the attempt to replace possible source error with friendlier
        # message fails. The 'or' never gets evaluated, even when source fails.
        source "${LIQ_SETTINGS}" \ #2> /dev/null \
          # || echoerrandexit "Could not source global Catalyst settings. Try:\nliq meta init"
      fi
      requirements-${GROUP}
      ${GROUP}-${ACTION} "$@"
    else
      exitUnknownAction
    fi;;
esac
