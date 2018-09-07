go-configure() {
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

go-get-deps() {
  colorerr "GOPATH=${GOPATH} bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; go get ./...'"
}

go-build() {
  colorerr "GOPATH=${GOPATH} bash -c 'go build $REL_GOAPP_PATH'"
}

go-start() {
  colorerr "GOPATH=${GOPATH} bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; ( dev_appserver.py --enable_watching_go_path=true app.yaml & echo \$! >&3 ) 3> ${BASE_DIR}/go-server.pid 2>&1 | tee ${BASE_DIR}/go-server.log &'"
}

go-stop() {
  # TODO: fallback to 'ps aux'
  colorerr "bash -c '( kill `cat ${BASE_DIR}/go-server.pid` && rm ${BASE_DIR}/go-server.pid ) \
    || echo \"There may have been a problem shutting down the go dev server. Check manually.\"'"
}

go-view-log() {
  less "${BASE_DIR}/go-server.log"
}
