_select_db() {
  if [[ x"$1" == "xtest" ]]; then echo ${CLOUDSQL_DB_TEST}; else echo ${CLOUDSQL_DB_DEV}; fi;
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
