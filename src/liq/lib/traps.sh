LOG_MODE_USER='user'
LOG_MODE_USER_DEBUG='user-debug'
LOG_MODE_PARSEABLE='parseable'
LOG_MODE_PARSEABLE_DEBUG='parseable-debug'
LOG_MODE_NONE='none'
LOG_HANDLED_USER=125 # special exit code which suppresses error output in user mode

log-start() {
  set -o errtrace # inherits trap on ERR in function and subshell

  trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
  # TODO: why is this disabled?
  # trap 'trapexit $? $LINENO' EXIT
}

log-pause() {
  LOG_STYLE='none'
}

function trapexit() {
  echo "$(date) $(hostname) $0: EXIT on line $2 (exit status $1)"
}

function traperror () {
    local err=$1 # error status
    local line=$2 # LINENO
    local linecallfunc=$3
    local command="$4"
    local funcstack="$5"

    if [[ -z "${LOG_MULTILINE_COMMAND:-}" ]] && (( $(echo "${command:-}" | wc -l ) > 1 )); then
      # we extract just the first line of any multi-line commands
      command="$(echo "${command}" | head -n 1)..."
    fi

    if [[ "${LOG_STYLE:-}" == "${LOG_MODE_USER}"* ]]; then
      # check for special case exit code
      (( ${err} == ${LOG_HANDLED_USER} )) && return

      echo "${red:-}ERROR '$command' failed at line $line - exited with status: $err${reset:-}" >&2

      if [[ "${LOG_STYLE:-}" == *-debug ]] && [[ "${funcstack}" != "::" ]]; then
        # TODO: decompose the funcstack and generate useful line numbers. See 'TODO' note above 'log()'
        echo "$0: DEBUG Error in ${funcstack} " >&2
        if [[ "$linecallfunc" != "" ]]; then
          echo "called at line $linecallfunc" >&2
        else
          echo
        fi
      fi
    elif [[ "${LOG_STYLE:-}" != 'none' ]]; then # use default 'parseable' style
      echo "$(date) $(hostname) $0: ERROR '$command' failed at line $line - exited with status: $err"
      # TODO: test and enable... parseable-debug?
      # if [[ "${LOG_STYLE:-}" == *-debug ]] && [[ "${funcstack:-}" != "::" ]]; then
      #  echo -n "$(date) $(hostname) $0: DEBUG Error in ${funcstack}"
      # fi
    fi
    # echo "'$command' failed at line $line - exited with status: $err" | mail -s "ERROR: $0 on $(hostname) at $(date)" xxx@xxx.com
}

# TODO: this logic is preserved because the 'lineno=' seems to indicate we need to get fancy with our line reference...?
# Parsable log entries.
# function log() {
#    local msg=$1
#    now=$(date)
#    i=${#FUNCNAME[@]}
#    lineno=${BASH_LINENO[$i-2]}
#    file=${BASH_SOURCE[$i-1]}
#    echo "${now} $(hostname) $0:${lineno} ${msg}"
# }
