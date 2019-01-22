data-reset-sql() {
  echo "Dropping..."
  colorerr "cat '$(dirname ${BASH_SOURCE[0]})/../../../../tools/data/drop_all.sql' | services-connect sql"
}

data-build-sql() {
  echo -n "Creating schema; "
  source "${CURR_ENV_FILE}"
  local SQL_VARIANT=`echo "${CURR_ENV_SERVICES[@]}" | sed -Ee 's/.*(^| *)(sql(-[^:]+)?).*/\2/'`
  local SCHEMA_FILES
  findDataFiles "$SQL_VARIANT" "schema" SCHEMA_FILES
  local SCHEMA_FILE_COUNT=$(echo "$SCHEMA_FILES" | wc -l | tr -d ' ')
  echo "loading $SCHEMA_FILE_COUNT schema files..."
  cat $SCHEMA_FILES | services-connect sql
  echo "Memorializing schema definations..."
  local SCHEMA_HASH=$(cat $SCHEMA_FILES | shasum -a 256 | sed -Ee 's/ *- *$//')
  local SCHEMA_VER_SPEC=()
  local PACKAGE_ROOT
  for PACKAGE_ROOT in $SCHEMA_FILES; do
    # TODO: this breaks if 'data' appears twice in the path. We want a reluctant match, but sed doesn't support it. I guess flip to Perl?
    PACKAGE_ROOT=$(echo "$PACKAGE_ROOT" | sed -Ee 's|/data/.+||')
    local PACK_DEF=$(cat "${PACKAGE_ROOT}/package.json")
    local PACK_NAME=$(echo "$PACK_DEF" | jq --raw-output '.name' | tr -d "'")
    if ! echo "${SCHEMA_VER_SPEC[@]:-}" | grep -q "$PACK_NAME"; then
      local PACK_VER=$(echo "$PACK_DEF" | jq --raw-output '.version' | tr -d "'")
      SCHEMA_VER_SPEC+=("${PACK_NAME}:${PACK_VER}")
    fi
  done
  SCHEMA_VER_SPEC=$(echo "${SCHEMA_VER_SPEC[@]}" | sort)
  echo "INSERT INTO catalystdb (schema_hash, version_spec) VALUES('$SCHEMA_HASH', '${SCHEMA_VER_SPEC[@]}')" | services-connect sql
}

data-rebuild-sql() {
  # TODO: break out the file search and do it first to avoid dropping when the build is sure to fail.
  data-reset-sql
  data-build-sql
  exit
  echo "Loading test data..."
  colorerr "cat '${TEST_DATA_DIR}/test-data.sql' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
}
