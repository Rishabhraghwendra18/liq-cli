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
      environment)
        case "$ACTION" in
          show|list|add|delete|select|set-billing)
            ${COMPONENT}-${ACTION} "${3:-}";;
          *)
            exitUnknownAction
          esac;;
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
          setup-scripts|build|start|lint|lint-fix|test|npm-check|npm-update|qa|deploy|add-mirror|link|link-dev|ignore-rest)
            sourceCatalystfile
            ${COMPONENT}-${ACTION} "${3:-}" "${4:-}";;
          setup|import|close)
            ${COMPONENT}-${ACTION} "${3:-}";;
          requires-service|provides-service)
            requireNpmPackage
            shift; shift # TODO: shift on initial grab; use '"$@"' for all
            ${COMPONENT}-${ACTION} "$@";;
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
          diff-master|edit|merge|report|start)
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
