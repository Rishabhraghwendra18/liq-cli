_catalyst()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
      catalyst)
        global_actions="help"
        components="go local project sql webapp work"
        opts="${global_actions} ${components}";;
      go)
        opts="configure build get-deps start stop view-log";;
      local)
        opts="start stop restart clear-logs";;
      project)
        opts="init deploy set-billing";;
      sql)
        opts="configure start-proxy stop-proxy view-proxy-log connect rebuild";;
      webapp)
        opts="configure audit build start stop view-log";;
      work)
        opts="edit start merge diff-master ignore-rest";;
      *)
      ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _catalyst catalyst
