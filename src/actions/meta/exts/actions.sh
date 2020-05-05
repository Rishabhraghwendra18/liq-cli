meta-exts() {
  local ACTION="${1}"; shift

  if [[ $(type -t "meta-exts-${ACTION}" || echo '') == 'function' ]]; then
    meta-exts-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" meta exts
  fi
}

meta-exts-install() {
  eval "$(setSimpleOptions LOCAL -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  local PKG="${1}"
  PKG="${PKG/@/}"
  cd "${LIQ_EXTS_DB}"

  [[ -f 'exts.sh' ]] || touch './exts.sh'

  if [[ -n "${LOCAL}" ]]; then
    npm i "${LIQ_PLAYGROUND}/${PKG}"
  else
    npm i "@${PKG}"
  fi
  local PKG_DIR
  PKG_DIR="$(npm explore @${PKG} -- pwd)"
  echo "source '${PKG_DIR}/dist/ext.sh'" >> './exts.sh'
  echo "source '${PKG_DIR}/dist/comp.sh'" >> './comps.sh'
}

meta-exts-list() {
  :
}
