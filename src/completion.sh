# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

# TODO: we could generate this from the usage docs... make the spec central!
_catalyst()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
      # the command
      catalyst)
        global_actions="help"
        components="data environment go local project runtime work workspace"
        opts="${global_actions} ${components}";;
      # the groups
      data)
        opts="dropall load-schema load-data";;
      environment)
        opts="add delete list select show";;
      go)
        opts="configure build get-deps start stop view-log";;
      local)
        opts="start stop restart clear-logs";;
      project)
        opts="requires-service provides-service import setup setup-scripts build start lint lint-fix test npm-check npm-update qa link link-dev close deploy add-mirror set-billing ignore-rest";;
      runtime)
        opts="environments services";;
      work)
        opts="diff-master edit merge report start";;
      workspace)
        opts="init branch stash merge diff-master";;
      # the sub-groups
      services)
        opts="list start stop restart log err-log connect";;
      *)
      ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _catalyst catalyst
