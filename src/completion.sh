_gcproj()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
        gcproj)
            global_actions="help init deploy start stop clear-all-logs"
            components="api db webapp work"
            opts="${global_actions} ${components}";;
        api)
            opts="build get-deps start stop view-log";;
        db)
            opts="start-proxy stop-proxy view-proxy-log connect rebuild";;
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

complete -F _gcproj gcproj
