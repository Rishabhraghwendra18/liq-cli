local-start() {
  sql-start-proxy
  sleep 2 # give the proxy a moment to connect; it's generally pretty quick
  go-start
  webapp-start
}

local-stop() {
  webapp-stop
  go-stop
  sql-stop-proxy
}

local-restart() {
  local-stop
  sleep 2
  local-start
}

local-clear-logs() {
  rm "${BASE_DIR}/go-server.log" "${BASE_DIR}/sql-proxy.log" "${BASE_DIR}/webapp-dev-server.log" 2> /dev/null
}
