

webapp-audit() {
  colorerr "bash -c 'cd ${WEB_APP_DIR}; npm audit'"
}

webapp-build() {
  colorerr "bash -c 'cd ${WEB_APP_DIR}; npm run-script build'"
}
