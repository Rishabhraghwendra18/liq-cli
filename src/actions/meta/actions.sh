# TODO: share this with '/install.sh'
COMPLETION_PATH="/usr/local/etc/bash_completion.d"

requirements-meta() {
  :
}

meta-init() {
  require-answer "Liquid playground location: " LIQ_PLAYGROUND "${HOME}/playground"
  metaSetupLiqDb
}

meta-bash-config() {
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/catalyst'"
}
