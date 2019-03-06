requirements-services() {
  requireEnvironment
}

services-list() {
  local TMP
  # If you try to set TMP with 'local' and use the '||', it silently ignores the
  # '||'. I guess it gets parse as part of the varible set, and then ignored due
  # to word splitting.
  TMP=$(setSimpleOptions SHOW_STATUS PORCELAIN EXIT_ON_STOPPED QUIET -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  local GET_STATUS=''
  if [[ -n "$SHOW_STATUS" ]] || [[ -n "$EXIT_ON_STOPPED" ]]; then
    GET_STATUS='local _SERV_STATUS=$(eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT status");'
  fi

  local OUTPUT='echo "$PROCESS_NAME";'
  if [[ -n "$QUIET" ]]; then
    OUTPUT=''
  else
    if [[ -n "$SHOW_STATUS" ]]; then
      if [[ -n "$PORCELAIN" ]]; then
        OUTPUT='echo "${PROCESS_NAME}:${_SERV_STATUS}";'
      else
        OUTPUT='( test "$_SERV_STATUS" == "running" && echo "${PROCESS_NAME} (${green}${_SERV_STATUS}${reset})" ) || echo "$PROCESS_NAME (${yellow}${_SERV_STATUS}${reset})";'
      fi
    fi
  fi

  local CHECK_EXIT=''
  if [[ -n "$EXIT_ON_STOPPED" ]]; then
    CHECK_EXIT='test "$_SERV_STATUS" == "running" || return 27;'
  fi

  local MAIN="${GET_STATUS}${OUTPUT}${CHECK_EXIT}"

  runtimeServiceRunner "$MAIN" '' "$@"
}

services-start() {
  local TMP
  TMP=$(setSimpleOptions PASSTHRU= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  # TODO: check status before starting
  local MAIN=$(cat <<'EOF'
    # rm -f "${SERV_LOG}" "${SERV_ERR}"

    if services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}"; then
      echo "${PROCESS_NAME} already running." >&2
    else
      echo "Starting ${PROCESS_NAME}..."
      eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT start ${PASSTHRU}" \
        || echoerrandexit "Attempt to start service '${PROCESS_NAME}' failed."
      sleep 1
      if [[ -f "${SERV_ERR}" ]] && [[ `wc -l "${SERV_ERR}" | awk '{print $1}'` -gt 0 ]]; then
        cat "${SERV_ERR}"
        echoerr "Possible errors while starting ${PROCESS_NAME}. See error log above."
      fi
      services-list -s "${PROCESS_NAME}"
    fi
EOF
)
  runtimeServiceRunner "$MAIN" '' "$@"
}

services-stop() {
  # TODO: check status before stopping
  local MAIN=$(cat <<'EOF'
    if ! services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}"; then
      echo "${PROCESS_NAME} already stopped." >&2
    else
      echo "Stopping ${PROCESS_NAME}..."
      eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT stop"
      sleep 1
      services-list -s "${PROCESS_NAME}"
    fi
EOF
)
  local REVERSE_ORDER=true
  runtimeServiceRunner "$MAIN" '' "$@"
}

services-restart() {
  local MAIN=$(cat <<'EOF'
    echo "Restarting ${PROCESS_NAME}..."
    if services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}"; then
      eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT restart"
    else
      echowarn "'${PROCESS_NAME}' currently stopped; starting..."
      eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT start"
    fi
    sleep 1
    services-list -s "${PROCESS_NAME}"
EOF
)
  runtimeServiceRunner "$MAIN" '' "$@"
}

# TODO: support remote logs!
logMain() {
  local DESC="$1"
  local SUFFIX="$2"
  local FILE_NAME='${_CATALYST_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}.'${SUFFIX}

  cat <<EOF
    echo "${FILE_NAME}"
    if [[ -f "${FILE_NAME}" ]]; then
      if stat -f'%z' ${FILE_NAME} | grep -qE '^\s*0\s*\$'; then
        echo "Error log for '${green}\${PROCESS_NAME}${reset}' is empty."
        pressAnyKeyToContinue
        echo
      else
        ( echo -e "Local ${DESC} for '${green}\${PROCESS_NAME}${reset}:\n<hit 'q' to adavance to next logs, if any.>\n" && \
          # tail -f "${FILE_NAME}" )
          cat "${FILE_NAME}" ) | less -R
      fi
    else
      echo "No local logs for '${red}\${PROCESS_NAME}${reset}'."
      echo "If this is a remote service, logs may be available through the service platform."
      pressAnyKeyToContinue
      echo
    fi
EOF
}

services-log() {
  local TMP
  TMP=$(setSimpleOptions CLEAR -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -n "$CLEAR" ]]; then
    runtimeServiceRunner 'rm -f "${_CATALYST_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}.log"' '' "$@"
  else
    runtimeServiceRunner "$(logMain log log)" '' "$@"
  fi
}

services-err-log() {
  runtimeServiceRunner "$(logMain 'error log' 'err')" '' "$@"
}

services-connect() {
  if (( $# != 1 )); then
    contextHelp
    echoerrandexit "Connect requires specification of a single service."
  fi

  local MAIN=$(cat <<'EOF'
    if runScript $SERV_SCRIPT connect-check 2> /dev/null; then
      if [[ -n "$SERV_SCRIPTS_COOKIE" ]]; then
        echoerrandexit "Multilpe connection points found; try specifying service process."
      fi
      SERV_SCRIPTS_COOKIE='found'
      services-list -qe "${SERV_IFACE}.${SCRIPT_NAME}" \
        || echoerrandexit "Can't connect to stopped '${SERV_IFACE}.${SCRIPT_NAME}'."
      eval "$(ctrlScriptEnv) runScript $SERV_SCRIPT connect"
    fi
EOF
)
  # After we've tried to connect with each process, check if anything worked
  local ALWAYS_RUN=$(cat <<'EOF'
    if (( $SERV_SCRIPT_COUNT == ( $SERV_SCRIPT_INDEX + 1 ) )) && [[ -z "$SERV_SCRIPTS_COOKIE" ]]; then
      echoerrandexit "${PROCESS_NAME}' does not support connections."
    fi
EOF
)

  runtimeServiceRunner "$MAIN" "$ALWAYS_RUN" "$@"
}
