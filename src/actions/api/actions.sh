api-configure() {
  if [[ -z "${GOPATH:-}" ]]; then
    echo "Please provide the 'GOPATH' to the root of go application code, right below 'src'."
    read -p 'GOPATH: ' GOPATH
  fi
  if [[ -z "${REL_GOAPP_PATH:-}" ]]; then
    echo "Please provide the path to your go application relative to '\$GOPATH/src'."
    read -p 'Relative app path: ' REL_GOAPP_PATH
  fi
  updateCatalystFile
}

api-get-deps() {
  colorerr "bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; go get ./...'"
}

api-build() {
  colorerr "bash -c 'go build $REL_GOAPP_PATH'"
}

api-start() {
  colorerr "bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; ( dev_appserver.py --enable_watching_go_path=true app.yaml & echo \$! >&3 ) 3> ${BASE_DIR}/api-server.pid 2>&1 | tee ${BASE_DIR}/api-server.log &'"
}

api-stop() {
  # TODO: fallback to 'ps aux'
  colorerr "bash -c '( kill `cat ${BASE_DIR}/api-server.pid` && rm ${BASE_DIR}/api-server.pid ) \
    || echo \"There may have been a problem shutting down the api dev server. Check manually.\"'"
}

api-view-log() {
  less "${BASE_DIR}/api-server.log"
}
