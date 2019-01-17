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

data-sql-dropall() {
  echo "Dropping..."
  # colorerr "cat '$(dirname ${BASH_SOURCE[0]})/../../../../tools/data/drop_all.sql' | catalyst runtime services connect sql"
  cat "$(dirname ${BASH_SOURCE[0]})/../../../../tools/data/drop_all.sql" | runtime-services-connect sql
}

data-sql-load-schema() {
  echo -n "Creating schema; "
  source "${CURR_ENV_FILE}"
  local SQL_VARIANT=`echo "${CURR_ENV_SERVICES[@]}" | sed -Ee 's/.*(^| *)(sql(-[^:]+)?).*/\2/'`
  local SCHEMA_FILES=`findDataFiles "$SQL_VARIANT" "schema"`
  local SCHEMA_FILE_COUNT=$(echo "$SCHEMA_FILES" | wc -l | tr -d ' ')
  echo "loading $SCHEMA_FILE_COUNT schema files..."
  cat $SCHEMA_FILES | runtime-services-connect sql
}

data-sql-rebuild() {
  data-sql-dropall
  data-sql-load-schema
  exit
  for i in `ls ${SQL_DIR}/schema-* | sort -n -t '-' -k 2`; do
    local FILE=`basename "$i"`
    echo "loading '$FILE'..."
    colorerr "cat '$i' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
  done
  echo "Loading test data..."
  colorerr "cat '${TEST_DATA_DIR}/test-data.sql' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
}
