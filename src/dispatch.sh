if (( $# == 0 )); then
  echoerrandexit "No arguments provided. Try:\ncatalyst help"
fi
GROUP="${1:-}"; shift # or global command
case "$GROUP" in
  # global actions
  help)
    help "$@";;
  # components and actionsprojct
  *)
    case "$GROUP" in
      # TODO: build this from constant def... something...
      data|environments|meta|packages|project|remotes|required-services|provided-services|services|work|playground)
        if (( $# == 0 )); then
          help $GROUP
          echoerrandexit "\nNo action argument provided. See valid actions above."
        fi
        ACTION="${1:-}"; shift
        if [[ $(type -t "${GROUP}-${ACTION}" || echo '') == 'function' ]]; then
          # the only exception to requiring a playground configuration is the
          # 'playground init' command
          if [[ "$GROUP" != 'playground' ]] || [[ "$GROUP" != 'init' ]]; then
            requireCatalystSettings
          fi
          requirements-${GROUP}
          ${GROUP}-${ACTION} "$@"
        else
          exitUnknownAction
        fi;;
      *)
        exitUnknownGroup
    esac
esac
