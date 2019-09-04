# TODO: share this with '/install.sh'
COMPLETION_PATH="/usr/local/etc/bash_completion.d"

requirements-meta() {
  :
}

meta-init() {
  local TMP # see https://unix.stackexchange.com/a/88338/84520
  TMP=$(setSimpleOptions PLAYGROUND= SILENT -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

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
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/catalyst'"
}
