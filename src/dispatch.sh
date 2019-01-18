GROUP="${1:-}"; shift # or global command
case "$GROUP" in
  # global actions
  help)
    global-help "${1-}";; # SUBGROUP may be empty
  # components and actionsprojct
  *)
    SUBGROUP="${1:-}"; shift
    case "$GROUP" in
      # THIS is the new style; once moved over we can drop the match and just run the test
      data|runtime|project)
        if [[ $(type -t ${GROUP}-${SUBGROUP}) == 'function' ]]; then
          ${GROUP}-${SUBGROUP} "$@"
        else
          exitUnknownSubgroup
        fi;;
      # TODO: Deprecated older, manual dispatch
      go)
        requireCatalystfile
        case "$SUBGROUP" in
          get-deps|build|test|start|stop|view-log)
            requireGlobals 'GOPATH' 'REL_GOAPP_PATH' || exit $?
            ${GROUP}-${SUBGROUP} "$@";;
          configure)
            ${GROUP}-${SUBGROUP} "$@";;
          *)
            exitUnknownSubgroup
        esac;;
      local)
        requireCatalystfile
        case "$SUBGROUP" in
          start|stop|restart|clear-logs)
            ${GROUP}-${SUBGROUP} "$@";;
          *) exitUnknownSubgroup;;
        esac;;
      project)
        case "$SUBGROUP" in
          setup-scripts|start|lint|lint-fix|test|npm-check|npm-update|qa|deploy|add-mirror|link|link-dev|ignore-rest)
            sourceCatalystfile
            ${GROUP}-${SUBGROUP} "$@";;
          setup|import|close)
            ${GROUP}-${SUBGROUP} "$@";;
          requires-service|provides-service)
            requireNpmPackage
            requireCatalystfile
            ${GROUP}-${SUBGROUP} "$@";;
          *) exitUnknownSubgroup;;
        esac;;
      work)
        case "$SUBGROUP" in
          diff-master|edit|merge|report|start)
            ${GROUP}-${SUBGROUP} "$@";;
          *) exitUnknownSubgroup
        esac;;
      workspace)
        case "$SUBGROUP" in
          report|branch|stash|merge|diff-master) # TODO: go ahead and implement 'ignore-rest'
            requireWorkspaceConfig
            ${GROUP}-${SUBGROUP} "$@";;
          init)
            ${GROUP}-${SUBGROUP} "$@";;
          *) exitUnknownSubgroup
        esac;;
      *)
        exitUnknownGlobal
    esac
esac
