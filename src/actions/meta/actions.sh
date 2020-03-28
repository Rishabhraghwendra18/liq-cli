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
  else
    [[ -n "$ERROR" ]] || COLOR="yellow"
    echofmt $COLOR "I have no advice to give you at this time."
  fi

  [[ -z "$ERROR" ]] || exit 1
}
