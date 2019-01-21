data-reset-sql() {
  echo "Dropping..."
  colorerr "cat '$(dirname ${BASH_SOURCE[0]})/../../../../tools/data/drop_all.sql' | runtime-services-connect sql"
}

data-build-sql() {
  echo -n "Creating schema; "
  source "${CURR_ENV_FILE}"
  local SQL_VARIANT=`echo "${CURR_ENV_SERVICES[@]}" | sed -Ee 's/.*(^| *)(sql(-[^:]+)?).*/\2/'`
  local SCHEMA_FILES=`findDataFiles "$SQL_VARIANT" "schema"`
  local SCHEMA_FILE_COUNT=$(echo "$SCHEMA_FILES" | wc -l | tr -d ' ')
  echo "loading $SCHEMA_FILE_COUNT schema files..."
  cat $SCHEMA_FILES | runtime-services-connect sql
}

data-rebuild-sql() {
  data-sql-dropall
  data-sql-load-schema
  exit
  echo "Loading test data..."
  colorerr "cat '${TEST_DATA_DIR}/test-data.sql' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
}
