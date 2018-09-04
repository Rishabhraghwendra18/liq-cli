webapp-configure() {
  if [[ -z "${SQL_DIR:-}" ]]; then
    echo -p "Please provide the path to the webapp:"
    read -p "(${BASE_DIR}/webapp): " WEB_APP_DIR
    WEB_APP_DIR=${SQL_DIR:-"${BASE_DIR}/webapp"}
    echo
  fi

  updateCatalystFile
}

webapp-audit() {
  colorerr "bash -c 'cd ${WEB_APP_DIR}; npm audit'"
}

webapp-build() {
  colorerr "bash -c 'cd ${WEB_APP_DIR}; npm run-script build'"
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
