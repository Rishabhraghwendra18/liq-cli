_catalyst()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
      catalyst)
        global_actions="help"
        components="go local project sql webapp work workspace"
        opts="${global_actions} ${components}";;
      go)
        opts="configure build get-deps start stop view-log";;
      local)
        opts="start stop restart clear-logs";;
      project)
        opts="import setup setup-scripts build start lint lint-fix test npm-check npm-update qa link link-dev close deploy add-mirror set-billing ignore-rest";;
      sql)
        opts="configure start-proxy stop-proxy view-proxy-log connect rebuild";;
      webapp)
        opts="configure audit build start stop view-log";;
      work)
        opts="diff-master edit merge report start";;
      workspace)
        opts="init branch stash merge diff-master";;
      *)
      ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _catalyst catalyst
