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

data-dump-sql() {
  local DATE_FMT='%Y-%m-%d %H:%M:%S %z'
  local MAIN=$(cat <<'EOF'
    if runScript $SERV_SCRIPT dump-check 2> /dev/null; then
      if [[ -n "$SERV_SCRIPTS_COOKIE" ]]; then
        echoerrandexit "Multilpe dump providers found; try specifying service process."
      fi
      SERV_SCRIPTS_COOKIE='found'
      if [[ -n "$OUT_FILE" ]]; then
        mkdir -p "$(dirname "${OUT_FILE}")"
        echo "-- start $(date +'%Y-%m-%d %H:%M:%S %z')" > "${OUT_FILE}"
        eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT dump" >> "${OUT_FILE}"
        echo "-- end $(date +'%Y-%m-%d %H:%M:%S %z')" >> "${OUT_FILE}"
      else
        echo "-- start $(date +"${DATE_FMT}")"
        eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT dump"
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

data-rebuild-sql() {
  # TODO: break out the file search and do it first to avoid dropping when the build is sure to fail.
  data-reset-sql
  data-build-sql
}

data-reset-sql() {
  echo "Dropping..."
  colorerr "cat '$(dirname ${BASH_SOURCE[0]})/../../../../tools/data/drop_all.sql' | services-connect sql"
}
