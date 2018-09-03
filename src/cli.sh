#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

function importlibs() {
  local REAL_CLI_REL=`readlink "${BASH_SOURCE[0]}"`
  local REAL_CLI_REL_PATH=`dirname $REAL_CLI_REL`
  # Now we have the installed package location and can start sourcing our files.
  SOURCE_DIR="$( cd "`dirname ${BASH_SOURCE[0]}`/$REAL_CLI_REL_PATH" && pwd )"

  for f in "${SOURCE_DIR}/lib/"*.sh; do source "$f"; done
  for f in "${SOURCE_DIR}/actions/"*.sh; do source "$f"; done
}
importlibs
# process global overrides of the form 'key="value"'
while (( $# > 0 )) && [[ $1 == *"="* ]]; do
  eval ${1%=*}="'${1#*=}'"
  shift
done

# see note at bottom of proj function
# local SAW_ERROR=''
if [[ $# -lt 1 ]]; then
  print_usage
  echoerr "Invalid invocation. See usage above."
  exit 1
fi

source "$SOURCE_DIR"/dispatch.sh

exit 0

SQL_DIR="${BASE_DIR}/sql"
TEST_DIR="${BASE_DIR}/test"
WEB_APP_DIR="${BASE_DIR}/apps/store"
CLOUDSQL_CONNECTION_NAME="uno-delivery-test:us-central1:uno-test"
CLOUDSQL_CREDS="${BASE_DIR}/gcp/test/uno-8f896347.creds"
CLOUDSQL_DB_DEV="uno_dev_"`whoami`
CLOUDSQL_DB_TEST="uno_test"



proj() {

  global-clear-all-logs() {
    rm "${BASE_DIR}/api-server.log" "${BASE_DIR}/db-proxy.log" "${BASE_DIR}/webapp-dev-server.log" 2> /dev/null
  }

  api-get-deps() {
    bash -c "cd $GOPATH/src/unodelivers.com/app; go get ./..."
  }

  api-build() {
    colorerr "bash -c 'go build unodelivers.com/app'"
  }

  api-start() {
    bash -c "cd $GOPATH/src/unodelivers.com/app; ( dev_appserver.py --enable_watching_go_path=true app.yaml & echo \$! >&3 ) 3> ${BASE_DIR}/api-server.pid 2>&1 | tee ${BASE_DIR}/api-server.log &"
  }

  api-stop() {
    bash -c "kill `cat ${BASE_DIR}/api-server.pid` && rm ${BASE_DIR}/api-server.pid"
  }

  api-view-log() {
    less "${BASE_DIR}/api-server.log"
  }

  _select_db() {
    if [[ x"$1" == "xtest" ]]; then echo ${CLOUDSQL_DB_TEST}; else echo ${CLOUDSQL_DB_DEV}; fi;
  }

  db-start-proxy() {
    bash -c "cd ${BASE_DIR}/tools/; ( ./cloud_sql_proxy -instances=${CLOUDSQL_CONNECTION_NAME}=tcp:3306 -credential_file=${CLOUDSQL_CREDS} & echo \$! >&3 ) 3> ${BASE_DIR}/db-proxy.pid 2>&1 | tee ${BASE_DIR}/db-proxy.log &"
  }

  db-stop-proxy() {
    bash -c "kill `cat ${BASE_DIR}/db-proxy.pid` && rm ${BASE_DIR}/db-proxy.pid"
  }

  db-view-proxy-log() {
    less "${BASE_DIR}/db-proxy.log"
  }

  db-connect() {
    local CLOUDSQL_DB=`_select_db "$1"`
    local TZ=`date +%z`
    TZ=`echo ${TZ: 0: 3}:${TZ: -2}`
    echo "Setting time zone: $TZ"
    mysql -h127.0.0.1 "${CLOUDSQL_DB}" --init-command 'SET time_zone="'$TZ'"'
  }

  db-rebuild() {
    local CLOUDSQL_DB=`_select_db "$1"`
    echo "Using DB '$CLOUDSQL_DB':"
    echo "Dropping..."
    cat "${SQL_DIR}/drop_all.sql" | mysql -h127.0.0.1 ${CLOUDSQL_DB}
    echo "Setting schema..."
    for i in `ls ${SQL_DIR}/schema-* | sort -n -t '-' -k 2`; do
      local FILE=`basename "$i"`
      echo "loading '$FILE'..."
      colorerr "cat '$i' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
    done
    echo "Loading test data..."
    colorerr "cat '${TEST_DIR}/test-data.sql' | mysql -h127.0.0.1 '${CLOUDSQL_DB}'"
  }

  webapp-audit() {
    bash -c "cd ${WEB_APP_DIR}; npm audit"
  }
  webapp-build() {
    bash -c "cd ${WEB_APP_DIR}; npm run-script build"
  }
  webapp-start() {
    bash -c "cd ${WEB_APP_DIR}; npm start 2>&1 | tee ${BASE_DIR}/webapp-dev-server.log &"
    sleep 1
    ps aux | (grep "${WEB_APP_DIR}/node_modules/react-scripts/scripts/start.js" || true) | (grep -v 'grep' || true) | awk '{print $2}' > webapp-dev-server.pid
  }

  webapp-stop() {
    cat "${BASE_DIR}/webapp-dev-server.pid" | xargs kill && rm "${BASE_DIR}/webapp-dev-server.pid"
  }

  webapp-view-log() {
    less "${BASE_DIR}/webapp-dev-server.log"
  }

  # TODO: in case the output is long, want to note whether we noted any problems
  # at the end; however, we're having troubling capturing 'SAW_ERROR'.
  # echo
  # if [ -n "$SAW_ERROR" ]; then
  #   echo "${red}Errors were observed. Check the logs above.${reset}"
  # else
  #   echo "${green}Everything looks good.${reset}"
  # fi
}

if [ ! -f ~/.my.cnf ]; then
  cat <<EOF
No '~/.my.cnf' file found; some 'db' actions won't work. File should contain:

[client]
user=the_user_name
password=the_password
EOF
fi

export GOPATH="${BASE_DIR}/api"
