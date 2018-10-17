COMPONENT="${1:-}" # or global command
ACTION="${2:-}"

case "$COMPONENT" in
  # global actions
  help)
    global-help "${2:-}";;
  # components and actionsprojct
  *)
    ACTION="${2:-}"
    case "$COMPONENT" in
      go)
        requireCatalystfile
        case "$ACTION" in
          get-deps|build|test|start|stop|view-log)
            requireGlobals 'GOPATH' 'REL_GOAPP_PATH' || exit $?
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
          build|start|lint|lint-fix|npm-check|qa|deploy|add-mirror|set-billing|link|link-dev)
            sourceCatalystfile
            ${COMPONENT}-${ACTION} "${3:-}" "${4:-}";;
          init|import|close)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *) exitUnknownAction
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
            requireGlobals 'SQL_DIR' 'TEST_DATA_DIR' 'CLOUDSQL_CONNECTION_NAME' \
              'CLOUDSQL_CREDS' 'CLOUDSQL_DB_DEV' 'CLOUDSQL_DB_TEST'
            ${COMPONENT}-${ACTION} "${3:-}";;
          configure)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *)
            exitUnknownAction
        esac;;
      webapp)
        requireCatalystfile
        case "$ACTION" in
          audit|build|start|stop|view-log)
            requireGlobals 'WEB_APP_DIR'
            ${COMPONENT}-${ACTION} "${3:-}";;
          configure)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *) exitUnknownAction
        esac;;
      work)
        case "$ACTION" in
          report|edit|start|merge|diff-master|ignore-rest)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *) exitUnknownAction
        esac;;
      workspace)
        case "$ACTION" in
          report|branch|stash|merge|diff-master) # TODO: go ahead and implement 'ignore-rest'
            requireWorkspaceConfig
            ${COMPONENT}-${ACTION} "${3:-}";;
          init)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *) exitUnknownAction
        esac;;
      *)
        exitUnknownGlobal
    esac
esac
