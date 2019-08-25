# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

# TODO: we could generate this from the help docs... make the spec central!
_catalyst()
{
    local cur prev opts
    local global_actions="help"
    local groups="data environments packages project provided-services remotes required-services services work playground"
    COMPREPLY=()
    # local WORD_COUNT=${#COMP_WORDS[@]}
    # TODO: instead of simple 'cur/prev', use the above to see where in the
    # command we are. This will allow us to implement 'exhaustive' completion.
    # Switch on what we need: group, action, action opts, or action args.
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
        opts="add delete deselect list select set show update";;
      meta)
        opts="bash-config";;
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
        opts="diff-master edit ignore-rest involve merge qa report resume start stop";;
      playground)
        opts="init close import";;
      *)
      ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _catalyst catalyst
