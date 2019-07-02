# TODO: share this with '/install.sh'
COMPLETION_PATH="/usr/local/etc/bash_completion.d"

requirements-meta() {
  # TODO: really noop at this point, but need to do something or it's a syntax error
  sourceCatalystfile
}

meta-bash-config() {
  echo "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/catalyst'"
}
