COMPONENT="${1:-}" # or global command
ACTION="${2:-}"

case "$COMPONENT" in
  # global actions
  help)
    global-help "${2:-}";;
  *)
    ACTION="${2:-}"
    case "$COMPONENT" in
      api)
        requireCatalystfile
        case "$ACTION" in
          get-deps|build|start|stop|view-log)
            ensureGlobals 'GOPATH' 'REL_GOAPP_PATH' || exit $?
            ${COMPONENT}-${ACTION} "${3:-}";;
          configure)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *)
            exitUnknownAction
        esac;;
      sql)
        requireCatalystfile
        if [ ! -f ~/.my.cnf ]; then
          cat <<EOF
No '~/.my.cnf' file found; some 'db' actions won't work. File should contain:

[client]
user=the_user_name
password=the_password
EOF
        fi
        case "$ACTION" in
          start-proxy|stop-proxy|view-proxy-log|connect|rebuild)
            ensureGlobals 'SQL_DIR' 'TEST_DATA_DIR' 'CLOUDSQL_CONNECTION_NAME' \
              'CLOUDSQL_CREDS' 'CLOUDSQL_DB_DEV' 'CLOUDSQL_DB_TEST'
            ${COMPONENT}-${ACTION} "${3:-}";;
          configure)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *)
            exitUnknownAction
        esac;;
      local)
        requireCatalystfile
        case "$ACTION" in
          start|stop|restart|clear-logs)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *) exitUnknownAction
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
