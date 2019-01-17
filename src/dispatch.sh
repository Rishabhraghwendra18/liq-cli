GROUP="${1:-}"; shift # or global command
case "$GROUP" in
  # global actions
  help)
    global-help "${1-}";; # SUBGROUP may be empty
  # components and actionsprojct
  *)
    SUBGROUP="${1:-}"; shift
    case "$GROUP" in
      environment)
        case "$SUBGROUP" in
          show|list|add|delete|select)
            requireCatalystfile
            requireNpmPackage
            ${GROUP}-${SUBGROUP} "$@";;
          *)
            exitUnknownSubgroup;;
          esac;;
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
          setup-scripts|build|start|lint|lint-fix|test|npm-check|npm-update|qa|deploy|add-mirror|link|link-dev|ignore-rest)
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
      runtime)
        if [[ $(type -t ${GROUP}-${SUBGROUP}) == 'function' ]]; then
          ${GROUP}-${SUBGROUP} "$@"
        else
          exitUnknownSubgroup
        fi;;
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
        case "$SUBGROUP" in
          start-proxy|stop-proxy|view-proxy-log|connect|rebuild)
            requireGlobals 'SQL_DIR' 'TEST_DATA_DIR' 'CLOUDSQL_CONNECTION_NAME' \
              'CLOUDSQL_CREDS' 'CLOUDSQL_DB_DEV' 'CLOUDSQL_DB_TEST'
            ${GROUP}-${SUBGROUP} "$@";;
          configure)
            ${GROUP}-${SUBGROUP} "$@";;
          *)
            exitUnknownSubgroup
        esac;;
      webapp)
        requireCatalystfile
        case "$SUBGROUP" in
          audit|build|start|stop|view-log)
            requireGlobals 'WEB_APP_DIR'
            ${GROUP}-${SUBGROUP} "$@";;
          configure)
            ${GROUP}-${SUBGROUP} "$@";;
          *) exitUnknownSubgroup
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
