COMPONENT="${1:-}" # or global command
ACTION="${2:-}"

case "$COMPONENT" in
  # global actions
  help)
    global-help "${2:-}";;
  start)
    global-start;;
  stop)
    global-stop;;
  clear-all-logs)
    global-clear-all-logs;;
  *)
    ACTION="${2:-}"
    case "$COMPONENT" in
      api)
        sourceCatalystfile || (echoerr "Did not find 'Catalystfile'; run 'catalyst project init'." && exit 1)
        case "$ACTION" in
          get-deps|build|start|stop|view-log)
            ensureGlobals 'GOPATH' 'REL_GOAPP_PATH' || exit $?
            ${COMPONENT}-${ACTION} "${3:-}";;
          configure)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *)
            exitUnknownAction
        esac;;
      db)
        case "$ACTION" in
          start-proxy)
            db-start-proxy;;
          stop-proxy)
            db-stop-proxy;;
          view-proxy-log)
            db-view-proxy-log;;
          connect)
            db-connect;;
          rebuild)
            db-rebuild "$3";;
          *)
            exitUnknownAction
        esac;;
      project)
        case "$ACTION" in
          deploy|set-billing)
            sourceCatalystfile
            ${COMPONENT}-${ACTION} "${3:-}";;
          init)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *) exitUnknownAction
        esac;;
      webapp)
        case "$ACTION" in
          audit)
            webapp-audit;;
          build)
            webapp-build;;
          start)
            webapp-start;;
          stop)
            webapp-stop;;
          view-log)
            webapp-view-log;;
          *) exitUnknownAction
        esac;;
      work)
        case "$ACTION" in
          start|merge|diff-master)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *) exitUnknownAction
        esac;;
      *)
        exitUnknownGlobal
    esac
esac
