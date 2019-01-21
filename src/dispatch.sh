GROUP="${1:-}"; shift # or global command
case "$GROUP" in
  # global actions
  help)
    help "$@";;
  # components and actionsprojct
  *)
    ACTION="${1:-}"; shift
    case "$GROUP" in
      # TODO: build this from constant def... something...
      data|environments|packages|project|remotes|required-services|provided-services|services|work|workspace)
        if [[ $(type -t ${GROUP}-${ACTION}) == 'function' ]]; then
          requirements-${GROUP}
          ${GROUP}-${ACTION} "$@"
        else
          exitUnknownAction
        fi;;
      *)
        exitUnknownGroup
    esac
esac
