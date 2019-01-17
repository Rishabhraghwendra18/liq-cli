data-sql() {
  requireEnvironment

  if [[ $# -eq 0 ]]; then
    usage-data-sql
    echoerrandexit "Missing action argument. See usage above."
  else
    local ACTION="$1"; shift
    if type -t ${GROUP}-${SUBGROUP}-${ACTION} | grep -q 'function'; then
      ${GROUP}-${SUBGROUP}-${ACTION} "$@"
    else
      exitUnknownAction
    fi
  fi
}

data-sql-rebuild() {
  echo "Dropping..."
  # colorerr "cat '$(dirname ${BASH_SOURCE[0]})/../../../../tools/data/drop_all.sql' | catalyst runtime services connect sql"
  cat "$(dirname ${BASH_SOURCE[0]})/../../../../tools/data/drop_all.sql" | catalyst runtime services connect sql
  exit
  echo "Setting schema..."
  for i in `ls ${SQL_DIR}/schema-* | sort -n -t '-' -k 2`; do
    local FILE=`basename "$i"`
    echo "loading '$FILE'..."
    colorerr "cat '$i' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
  done
  echo "Loading test data..."
  colorerr "cat '${TEST_DATA_DIR}/test-data.sql' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
}
