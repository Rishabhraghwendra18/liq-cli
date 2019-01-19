source "`dirname ${BASH_SOURCE[0]}`/serviceslib.sh"

runtime-services() {
  requireEnvironment

  if [[ $# -eq 0 ]]; then
    usage-runtime-services
    echoerrandexit "Missing action argument. See usage above."
  else
    local ACTION="$1"; shift
    if type -t ${GROUP}-${SUBGROUP}-${ACTION} | grep -q 'function'; then
      ${GROUP}-${SUBGROUP}-${ACTION} "$@"
    else
      exitUnknownAction
    fi
  fi
}

runtime-services-list() {
  local TMP
  # If you try to set TMP with 'local' and use the '||', it silently ignores the
  # '||'. I guess it gets parse as part of the varible set, and then ignored due
  # to word splitting.
  TMP=$(setSimpleOptions SHOW_STATUS -- "$@") \
    || ( usage-runtime-services; echoerrandexit "Bad options." )
  eval "$TMP"

  local MAIN='echo "$PROCESS_NAME"'
  if [[ -n "$SHOW_STATUS" ]]; then
    MAIN='echo "$PROCESS_NAME ($(eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT status"))"'
  fi

  runtimeServiceRunner "$@"
}

runtime-services-start() {
  # TODO: check status before starting
  local MAIN=$(cat <<'EOF'
    # rm -f "${SERV_LOG}" "${SERV_ERR}"

    echo "Starting ${PROCESS_NAME}..."
    eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT start"
    sleep 1
    if [[ -f "${SERV_ERR}" ]] && [[ `wc -l "${SERV_ERR}" | awk '{print $1}'` -gt 0 ]]; then
      cat "${SERV_ERR}"
      echoerr "Possible errors while starting ${PROCESS_NAME}. See error log above."
    fi
    runtime-services-list -s "${PROCESS_NAME}"
EOF
)
  runtimeServiceRunner "$@"
}

runtime-services-stop() {
  # TODO: check status before stopping
  local MAIN=$(cat <<'EOF'
    echo "Stopping ${PROCESS_NAME}..."
    eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT stop"
    sleep 1
    runtime-services-list -s "${PROCESS_NAME}"
EOF
)
  local REVERSE_ORDER=true
  runtimeServiceRunner "$@"
}

runtime-services-restart() {
  local MAIN=$(cat <<'EOF'
    echo "Restarting ${PROCESS_NAME}..."
    eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT restart"
    sleep 1
    runtime-services-list "${PROCESS_NAME}"
EOF
)
  runtimeServiceRunner "$@"
}

# TODO: support remote logs!
logMain() {
  local DESC="$1"
  local SUFFIX="$2"
  local FILE_NAME='${_CATALYST_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}.'${SUFFIX}

  MAIN=$(cat <<EOF
    echo "${FILE_NAME}"
    if [[ -f "${FILE_NAME}" ]]; then
      if stat -f'%z' ${FILE_NAME} | grep -qE '^\s*0\s*\$'; then
        echo "Error log for '${green}\${PROCESS_NAME}${reset}' is empty."
        pressAnyKeyToContinue
        echo
      else
        ( echo -e "Local ${DESC} for '${green}\${PROCESS_NAME}${reset}:\n<hit 'q' to adavance to next logs, if any.>\n" && \
          cat "\${_CATALYST_ENV_LOGS}/\${PROCESS_NAME}.${SUFFIX}" ) | less -R
      fi
    else
      echo "No local logs for '${red}\${PROCESS_NAME}${reset}'."
      echo "If this is a remote service, logs may be available through the service platform."
      pressAnyKeyToContinue
      echo
    fi
EOF
)
}

runtime-services-log() {
  local MAIN; logMain "log" "log"

  runtimeServiceRunner "$@"
}

runtime-services-err-log() {
  local MAIN; logMain "error log" "err"

  runtimeServiceRunner "$@"
}

runtime-services-connect() {
  if (( $# != 1 )); then
    usage-runtime-services
    echoerrandexit "Connect requires specification of a single service."
  fi

  local MAIN=$(cat <<'EOF'
    if npx --no-install $SERV_SCRIPT connect-check 2> /dev/null; then
      if [[ -n "$SERV_SCRIPTS_COOKIE" ]]; then
        echoerrandexit "Multilpe connection points found; try specifying service process."
      fi
      SERV_SCRIPTS_COOKIE='found'
      eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT connect"
    fi
EOF
)
  local ALWAYS_RUN=$(cat <<'EOF'
    if (( $SERV_SCRIPT_COUNT == ( $SERV_SCRIPT_INDEX + 1 ) )) && [[ -z "$SERV_SCRIPTS_COOKIE" ]]; then
      echoerrandexit "${PROCESS_NAME}' does not support connections."
    fi
EOF
)

  runtimeServiceRunner "$@"
}
