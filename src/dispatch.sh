case "$COMPONENT" in
  # global actions
  init)
    global-init;;
  help)
    print_usage;;
  start)
    global-start;;
  stop)
    global-stop;;
  deploy)
    global-deploy;;
  clear-all-logs)
    global-clear-all-logs;;
  *)
    ACTION="${2:-}"
    case "$COMPONENT" in
      api)
        case "$ACTION" in
          get-deps)
            api-get-deps;;
          build)
            api-build;;
          start)
            api-start;;
          stop)
            api-stop;;
          view-log)
            api-view-log;;
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
