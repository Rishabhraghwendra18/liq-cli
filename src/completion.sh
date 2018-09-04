_catalyst()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
      catalyst)
        global_actions="help start stop clear-all-logs"
        components="api db project webapp work"
        opts="${global_actions} ${components}";;
      api)
        opts="configure build get-deps start stop view-log";;
      db)
        opts="start-proxy stop-proxy view-proxy-log connect rebuild";;
      project)
        opts="init deploy set-billing";;
      webapp)
        opts="audit build start stop view-log";;
      work)
        opts="start merge diff-master";;
      *)
      ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _catalyst catalyst
