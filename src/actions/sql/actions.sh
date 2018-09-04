_select_db() {
  if [[ x"$1" == "xtest" ]]; then echo ${CLOUDSQL_DB_TEST}; else echo ${CLOUDSQL_DB_DEV}; fi;
}

sql-configure() {
  if [[ -z "${SQL_DIR:-}" ]]; then
    echo "Please provide the path to the SQL schema files:"
    read -p "(${BASE_DIR}/sql): " SQL_DIR
    SQL_DIR=${SQL_DIR:-"${BASE_DIR}/sql"}
    echo
  fi
  if [[ -z "${TEST_DATA_DIR:-}" ]]; then
    echo "Please provide the path to the SQL test data files:"
    read -p "(${BASE_DIR}/test): " TEST_DATA_DIR
    TEST_DATA_DIR=${TEST_DATA_DIR:-"${BASE_DIR}/test"}
    echo
  fi
  if [[ -z "${CLOUDSQL_CONNECTION_NAME:-}" ]]; then
    read -p "Please provide the Cloud SQL connection name: " CLOUDSQL_CONNECTION_NAME
    echo
  fi
  if [[ -z "${CLOUDSQL_CREDS:-}" ]]; then
    read -p "Please provide the location of the Cloud SQL credentials file: " CLOUDSQL_CREDS
    echo
  fi
  if [[ -z "${CLOUDSQL_DB_DEV:-}" ]]; then
    read -p "Please provide the developer DB name: " CLOUDSQL_DB_DEV
    echo
  fi
  if [[ -z "${CLOUDSQL_DB_TEST:-}" ]]; then
    read -p "Please provide the test DB name: " CLOUDSQL_DB_TEST
    echo
  fi

  updateCatalystFile
}

sql-start-proxy() {
  colorerr "bash -c 'cd ${BASE_DIR}/tools/; ( ./cloud_sql_proxy -instances=${CLOUDSQL_CONNECTION_NAME}=tcp:3306 -credential_file=${CLOUDSQL_CREDS} & echo \$! >&3 ) 3> ${BASE_DIR}/sql-proxy.pid 2>&1 | tee ${BASE_DIR}/sql-proxy.log &'"
}

sql-stop-proxy() {
  colorerr "bash -c 'kill `cat ${BASE_DIR}/sql-proxy.pid` && rm ${BASE_DIR}/sql-proxy.pid'"
}

sql-view-proxy-log() {
  less "${BASE_DIR}/sql-proxy.log"
}

sql-connect() {
  local CLOUDSQL_DB=`_select_db "$1"`
  local TZ=`date +%z`
  TZ=`echo ${TZ: 0: 3}:${TZ: -2}`
  echo "Setting time zone: $TZ"
  mysql -h127.0.0.1 "${CLOUDSQL_DB}" --init-command 'SET time_zone="'$TZ'"'
}

sql-rebuild() {
  local CLOUDSQL_DB=`_select_db "$1"`
  echo "Using DB '$CLOUDSQL_DB':"
  echo "Dropping..."
  colorerr "cat '${SQL_DIR}/drop_all.sql' | mysql -h127.0.0.1 ${CLOUDSQL_DB}"
  echo "Setting schema..."
  for i in `ls ${SQL_DIR}/schema-* | sort -n -t '-' -k 2`; do
    local FILE=`basename "$i"`
    echo "loading '$FILE'..."
    colorerr "cat '$i' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
  done
  echo "Loading test data..."
  colorerr "cat '${TEST_DATA_DIR}/test-data.sql' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
}
