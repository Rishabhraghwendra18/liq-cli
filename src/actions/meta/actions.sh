# TODO: share this with '/install.sh'
COMPLETION_PATH="/usr/local/etc/bash_completion.d"

requirements-meta() {
  :
}

meta-init() {
  eval "$(setSimpleOptions PLAYGROUND= SILENT -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -z "$PLAYGROUND" ]]; then
    # TODO: require-answer-matching (or something) to force absolute path here
    require-answer "Liquid playground location: " LIQ_PLAYGROUND "${HOME}/playground"
  else
    LIQ_PLAYGROUND="$PLAYGROUND"
  fi
  if [[ "$LIQ_PLAYGROUND" != /* ]]; then
    echoerrandexit "Playground path must be absolute."
  fi

  if [[ -n "$SILENT" ]]; then
    meta-lib-setup-liq-db > /dev/null
  else
    meta-lib-setup-liq-db
  fi
}

meta-bash-config() {
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
}

meta-next() {
  eval "$(setSimpleOptions TECH_DETAIL ERROR -- "$@")"

  local COLOR="green"
  [[ -z "$ERROR" ]] || COLOR="red"

  if [ ! -d "${LIQ_DB}" ]; then
    [[ -z "$TECH_DETAIL" ]] || TECH_DETAIL=" (expected ~/${LIQ_DB_BASENAME})"
    echofmt $COLOR "It looks like liq CLI hasn't been setup yet$TECH_DETAIL. Try:\nliq meta init"
  elif [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    source "${LIQ_WORK_DB}/curr_work"
    local PROJ DONE
    export DONE
    for PROJ in $INVOLVED_PROJECTS; do
      PROJ=${PROJ/@/}
      cd "$LIQ_PLAYGROUND/${PROJ}"
      if [[ -n "$(git status --porcelain)" ]]; then
        echofmt $COLOR "It looks like you were worknig on '${WORK_DESC}' and have uncommitted changes in '${PROJ}'. Try:\n\nliq work save -m 'commit message' --project $PROJ\n\nOr, to use 'liq work stage' with 'liq work save' to save sets of files with different messages.\n\nOr, to get an overview of all work status, try:\n\nliq work status."
        DONE=true
        break
      fi
    done
    if [[ "$DONE" != "true" ]]; then
      echofmt $COLOR "It looks like you were worknig on '${WORK_DESC}' and everything is committed. If ready to submit changes, try:\nliq work submit"
    fi
  elif requirePackage; then
    echofmt $COLOR "Looks like you're currently in project '$PACKAGE_NAME'. You could start working on an issue. Try:\nliq work start ..."
  else
    echofmt $COLOR "Choose a project and 'cd' there."
  fi

  [[ -z "$ERROR" ]] || exit 1
}
