function dataSQLCheckRunning() {
  local TMP
  TMP=$(setSimpleOptions NO_CHECK -- "$@") \
    || ( help-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"
  if [[ -z "$NO_CHECK" ]] && ! services-list --exit-on-stopped -q sql; then
    services-start sql
  fi

  echo "$@"
}

function dataSqlGetSqlVariant() {
  echo "${CURR_ENV_SERVICES[@]:-}" | sed -Ee 's/.*(^| *)(sql(-[^:]+)?).*/\2/'
}

data-build-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  echo -n "Creating schema; "
  source "${CURR_ENV_FILE}"
  local SQL_VARIANT=$(dataSqlGetSqlVariant)
  local SCHEMA_FILES SCHEMA_FILE_COUNT
  findDataFiles SCHEMA_FILES SCHEMA_FILE_COUNT "$SQL_VARIANT" "schema"
  echo "Loading $SCHEMA_FILE_COUNT schema files..."
  cat $SCHEMA_FILES | services-connect sql
  echo "Memorializing schema definations..."
  local SCHEMA_HASH=$(cat $SCHEMA_FILES | shasum -a 256 | sed -Ee 's/ *- *$//')
  local SCHEMA_VER_SPEC=()
  local PACKAGE_ROOT
  for PACKAGE_ROOT in $SCHEMA_FILES; do
    # TODO: this breaks if 'data' appears twice in the path. We want a reluctant match, but sed doesn't support it. I guess flip to Perl?
    PACKAGE_ROOT=$(echo "$PACKAGE_ROOT" | sed -Ee 's|/data/.+||')
    local PACK_DEF=
    PACK_DEF=$(cat "${PACKAGE_ROOT}/package.json")
    local PACK_NAME=
    PACK_NAME=$(echo "$PACK_DEF" | jq --raw-output '.name' | tr -d "'")
    if ! echo "${SCHEMA_VER_SPEC[@]:-}" | grep -q "$PACK_NAME"; then
      local PACK_VER=$(echo "$PACK_DEF" | jq --raw-output '.version' | tr -d "'")
      SCHEMA_VER_SPEC+=("${PACK_NAME}:${PACK_VER}")
    fi
  done
  SCHEMA_VER_SPEC=$(echo "${SCHEMA_VER_SPEC[@]}" | sort)
  echo "INSERT INTO catalystdb (schema_hash, version_spec) VALUES('$SCHEMA_HASH', '${SCHEMA_VER_SPEC[@]}')" | services-connect sql
}

data-dump-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  local DATE_FMT='%Y-%m-%d %H:%M:%S %z'
  local MAIN=$(cat <<'EOF'
    if runServiceCtrlScript --no-env $SERV_SCRIPT dump-check 2> /dev/null; then
      if [[ -n "$SERV_SCRIPTS_COOKIE" ]]; then
        echoerrandexit "Multilpe dump providers found; try specifying service process."
      fi
      SERV_SCRIPTS_COOKIE='found'
      if [[ -n "$OUT_FILE" ]]; then
        mkdir -p "$(dirname "${OUT_FILE}")"
        echo "-- start $(date +'%Y-%m-%d %H:%M:%S %z')" > "${OUT_FILE}"
        runServiceCtrlScript $SERV_SCRIPT dump >> "${OUT_FILE}"
        echo "-- end $(date +'%Y-%m-%d %H:%M:%S %z')" >> "${OUT_FILE}"
      else
        echo "-- start $(date +"${DATE_FMT}")"
        runServiceCtrlScript $SERV_SCRIPT dump
        echo "-- end $(date +"${DATE_FMT}")"
      fi
    fi
EOF
)
  # After we've tried to connect with each process, check if anything worked
  local ALWAYS_RUN=$(cat <<'EOF'
    if (( $SERV_SCRIPT_COUNT == ( $SERV_SCRIPT_INDEX + 1 ) )) && [[ -z "$SERV_SCRIPTS_COOKIE" ]]; then
      echoerrandexit "${PROCESS_NAME}' does not support data dumps."
    fi
EOF
)

  runtimeServiceRunner "$MAIN" "$ALWAYS_RUN" sql
}

data-load-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  if [[ ! -d "${BASE_DIR}/data/sql/${SET_NAME}" ]]; then
    echoerrandexit "No such set '$SET_NAME' found."
  fi

  local DATA_FILES DATA_FILES_COUNT
  findDataFiles DATA_FILES DATA_FILES_COUNT "sql" "$SET_NAME"
  echo "Loading ${DATA_FILES_COUNT} data files..."
  cat $DATA_FILES | services-connect sql
}

data-rebuild-sql() {
  dataSQLCheckRunning "$@" > /dev/null
  # TODO: break out the file search and do it first to avoid dropping when the build is sure to fail.
  data-reset-sql --no-check
  data-build-sql --no-check
}

data-reset-sql() {
  dataSQLCheckRunning "$@" > /dev/null

  echo "Dropping..."
  # https://stackoverflow.com/a/36023359/929494
  cat <<'EOF' | services-connect sql > /dev/null
DO $$ DECLARE
    r RECORD;
BEGIN
    -- if the schema you operate on is not "current", you will want to
    -- replace current_schema() in query with 'schematodeletetablesfrom'
    -- *and* update the generate 'DROP...' accordingly.
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
EOF
  # for MySQL
  # relative to dist
  # colorerr "cat '$(dirname $(real_path ${BASH_SOURCE[0]}))/../tools/data/drop_all.sql' | services-connect sql"
}

data-test-sql() {
  echo "Checking for SQL unit test files..."
  source "${CURR_ENV_FILE}"
  local SQL_VARIANT=$(dataSqlGetSqlVariant)
  local TEST_FILES TEST_FILE_COUNT
  findDataFiles TEST_FILES TEST_FILE_COUNT "$SQL_VARIANT" "test"
  if (( $TEST_FILE_COUNT > 0 )); then
    echo "Found $TEST_FILE_COUNT unit test files."
    if [[ -z "$SKIP_REBUILD" ]]; then
      data-rebuild-sql
    else
      echo "Skipping RDB rebuild."
    fi
    dataSQLCheckRunning "$@" > /dev/null
    echo "Starting tests..."
    cat $TEST_FILES | services-connect sql
    echo "Testing complete!"
  else
    echo "No SQL unit tests found."
  fi
}
