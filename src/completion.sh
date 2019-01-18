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
        components="data go local project runtime work workspace"
        opts="${global_actions} ${components}";;
      # the groups
      data)
        opts="dropall load-schema load-data";;
      go)
        opts="configure build get-deps start stop view-log";;
      local)
        opts="start stop restart clear-logs";;

      # primary group
      project)
        opts="packages requires-service provides-service import setup setup-scripts lint lint-fix test npm-check npm-update qa link link-dev close deploy add-mirror set-billing ignore-rest";;
      # project sub-groups
      packages)
        opts="build audit version-check";;

      # primary group
      runtime)
        opts="environments services";;
      # runtime sub-groups
      services)
        opts="list start stop restart log err-log connect";;
      environments)
        opts="add delete deselect list select set show";;
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
