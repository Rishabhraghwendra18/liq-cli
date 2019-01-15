COMPONENT="${1:-}"; shift # or global command

case "$COMPONENT" in
  # global actions
  help)
    global-help "${1-}";; # ACTION may be empty
  # components and actionsprojct
  *)
    ACTION="${1:-}"; shift
    case "$COMPONENT" in
      environment)
        case "$ACTION" in
          show|list|add|delete|select)
            requireCatalystfile
            requireNpmPackage
            ${COMPONENT}-${ACTION} "$@";;
          *)
            exitUnknownAction;;
          esac;;
      go)
        requireCatalystfile
        case "$ACTION" in
          get-deps|build|test|start|stop|view-log)
            requireGlobals 'GOPATH' 'REL_GOAPP_PATH' || exit $?
            ${COMPONENT}-${ACTION} "$@";;
          configure)
            ${COMPONENT}-${ACTION} "$@";;
          *)
            exitUnknownAction
        esac;;
      local)
        requireCatalystfile
        case "$ACTION" in
          start|stop|restart|clear-logs)
            ${COMPONENT}-${ACTION} "$@";;
          *) exitUnknownAction;;
        esac;;
      project)
        case "$ACTION" in
          setup-scripts|build|start|lint|lint-fix|test|npm-check|npm-update|qa|deploy|add-mirror|link|link-dev|ignore-rest)
            sourceCatalystfile
            ${COMPONENT}-${ACTION} "$@";;
          setup|import|close)
            ${COMPONENT}-${ACTION} "$@";;
          requires-service|provides-service)
            requireNpmPackage
            requireCatalystfile
            shift; shift # TODO: shift on initial grab; use '"$@"' for all
            ${COMPONENT}-${ACTION} "$@";;
          *) exitUnknownAction;;
        esac;;
      runtime)
        case "$ACTION" in
          services)
            requireNpmPackage
            requireCatalystfile
            ${COMPONENT}-${ACTION} "$@";;
          *) exitUnknownAction;;
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
            ${COMPONENT}-${ACTION} "$@";;
          configure)
            ${COMPONENT}-${ACTION} "$@";;
          *)
            exitUnknownAction
        esac;;
      webapp)
        requireCatalystfile
        case "$ACTION" in
          audit|build|start|stop|view-log)
            requireGlobals 'WEB_APP_DIR'
            ${COMPONENT}-${ACTION} "$@";;
          configure)
            ${COMPONENT}-${ACTION} "$@";;
          *) exitUnknownAction
        esac;;
      work)
        case "$ACTION" in
          diff-master|edit|merge|report|start)
            ${COMPONENT}-${ACTION} "$@";;
          *) exitUnknownAction
        esac;;
      workspace)
        case "$ACTION" in
          report|branch|stash|merge|diff-master) # TODO: go ahead and implement 'ignore-rest'
            requireWorkspaceConfig
            ${COMPONENT}-${ACTION} "$@";;
          init)
            ${COMPONENT}-${ACTION} "$@";;
          *) exitUnknownAction
        esac;;
      *)
        exitUnknownGlobal
    esac
esac
