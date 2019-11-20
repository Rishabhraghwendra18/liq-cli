# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

# TODO: we could generate this from the help docs... make the spec central!
_liq()
{
    local CUR # the current token; this may be blank and used to expand partials; provided my complete routine
    local PREV # the last completed token; provided by complete routine
    local OPTS # the options, set by this func, for completion
    local GLOBAL_ACTIONS="help"
    # Using 'GROUPS' was causing errors; set by some magic.
    local ACTION_GROUPS="data environments orgs policies projects remotes required-services services work"
    COMPREPLY=()
    # local WORD_COUNT=${#COMP_WORDS[@]}
    # TODO: instead of simple 'CUR/PREV', use the above to see where in the
    # command we are. This will allow us to implement 'exhaustive' completion.
    # Switch on what we need: group, action, action OPTS, or action args.
    CUR="${COMP_WORDS[COMP_CWORD]}"
    PREV="${COMP_WORDS[COMP_CWORD-1]}"
    GROUP="${COMP_WORDS[1]}"
    ACTION="${COMP_WORDS[2]}"

    if (( ${#COMP_WORDS[@]} <= 3 )); then
      case "${PREV}" in
        liq)
          OPTS="${GLOBAL_ACTIONS} ${ACTION_GROUPS}";;
        # globals
        help)
          OPTS="${ACTION_GROUPS}";;
        # groups
        data)
          OPTS="build clear load rebuild reset";;
        environments)
          OPTS="add delete deselect list select set show update";;
        meta)
          OPTS="init bash-config";;
        orgs)
          OPTS="affiliate create list show select";;
				policies)
					OPTS="document";;
        projects)
          OPTS="build close init publish qa sync test services";;
        remotes)
          OPTS="add delete set-main";;
        required-services) # deprecated
          OPTS="list add delete";;
        services)
          OPTS="connect err-log list log restart start stop";;
        work)
          OPTS="diff-master edit ignore-rest involve merge qa report resume save stage start status stop sync";;
      esac

      COMPREPLY=( $(compgen -W "${OPTS}" -- ${CUR}) )
    else
      case "${GROUP}" in
        work)
          case "${ACTION}" in
            stage)
              COMPREPLY=( $(compgen -o nospace -W "$(for d in ${CUR}*; do [[ -d "$d" ]] && echo $d/ || echo $d; done)" -- ${CUR}) )
            ;;
          esac ;;# work-actions
        projects)
          case "${ACTION}" in
            services)
              OPTS="add list delete show"
              COMPREPLY=( $(compgen -W "${OPTS}" -- ${CUR}) );;
          esac ;; # packages-actions
      esac
    fi

    return 0
}

complete -F _liq liq
