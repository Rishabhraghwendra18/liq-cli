print_usage() {
  echo "Usage:"
  echo
  echo "catalyst help"
  echo "catalyst <module> <action> [<action args...>]"
  echo
  echo "go:"
  print_go_usage "  "
  echo "local:"
  print_local_usage "  "
  echo "project:"
  print_project_usage "  "
  echo "sql:"
  print_sql_usage "  "
  echo "webapp:"
  print_webapp_usage "  "
  echo "work:"
  print_work_usage "  "
  echo "environment:"
  print_environment_usage "  "
}
