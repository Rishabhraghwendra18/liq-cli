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
    metaSetupLiqDb > /dev/null
  else
    metaSetupLiqDb
  fi
}

meta-bash-config() {
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
}

meta-next() {
  eval "$(setSimpleOptions TECH_DETAIL ERROR -- "$@")"

  local COLOR="green"
  [[ -z "$ERROR" ]] || COLOR="red"

  if [ ! -d "$HOME/.liquid-development" ]; then
    [[ -z "$TECH_DETAIL" ]] || TECH_DETAIL=" (expected ~/.liquid-development)"
    echofmt $COLOR "It looks like liq CLI hasn't been setup yet$TECH_DETAIL. Try:\nliq meta init"
  elif [[ -L "${LIQ_WORK_DB}/curr_work" ]]; then
    source "${LIQ_WORK_DB}/curr_work"
    echofmt $COLOR "It looks like you were worknig on something: '${WORK_DESC}'. Try:\nliq work status"
  elif requirePackage; then
    echofmt $COLOR "Looks like you're currently in project '$PACKAGE_NAME'. You could start working on an issue. Try:\nliq work start ..."
  else
    echofmt $COLOR "Choose a project and 'cd' there."
  fi

  [[ -z "$ERROR" ]] || exit 1
}
