# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

# TODO: we could generate this from the usage docs... make the spec central!
_catalyst()
{
    local cur prev opts
    local global_actions="help"
    local groups="data environments packages project provided-services remotes required-services services work workspace"
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
        opts="audit build deploy lint link test version-check";;
      project)
        opts="init publish";;
      provided-services)
        opts="list add delete";;
      remotes)
        opts="add delete set-main";;
      required-services)
        opts="list add delete";;
      services)
        opts="connect err-log list log restart start stop";;
      work)
        opts="diff-master edit ignore-rest involve merge qa report start";;
      workspace)
        opts="init close import";;
      *)
      ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _catalyst catalyst
