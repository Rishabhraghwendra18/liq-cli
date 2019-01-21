# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

# TODO: we could generate this from the usage docs... make the spec central!
_catalyst()
{
    local cur prev opts
    local global_actions="help"
    local groups="data environments packages project provided-services required-services services work workspace"
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
      catalyst)
        opts="${global_actions} ${groups}";;
      # globals
      help)
        opts="${groups}";;
      # command groups
      data)
        opts="build clear load rebuild reset";;
      environments)
        opts="add delete deselect list select set show";;
      packages)
        opts="audit build deploy lint link qa test version-check";;
      project)
        opts="init publish  ignore-rest";;



      services)
        opts="list start stop restart log err-log connect";;
      work)
        opts="diff-master edit merge report start";;
      workspace)
        opts="init close import    branch stash merge diff-master";;
      *)
      ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _catalyst catalyst
