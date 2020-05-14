meta-exts() {
  local ACTION="${1}"; shift

  if [[ $(type -t "meta-exts-${ACTION}" || echo '') == 'function' ]]; then
    meta-exts-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" meta exts
  fi
}

meta-exts-install() {
  eval "$(setSimpleOptions LOCAL REGISTRY -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -n "$LOCAL" ]] && [[ -n "$REGISTRY" ]]; then
    echoerrandexit "The '--local' and '--registry' options are mutually exclusive."
  fi

  local PKGS="$@"
  PKGS="${PKGS//@/}"
  cd "${LIQ_EXTS_DB}"

  [[ -f 'exts.sh' ]] || touch './exts.sh'

  if [[ -n "${LOCAL}" ]]; then
    npm i "${LIQ_PLAYGROUND}/${PKGS}"
  else
    npm i "@${PKGS}"
  fi
  local PKG
  for PKG in ${PKGS//@/}; do
    local PKG_DIR
    PKG_DIR="$(npm explore @${PKG} -- pwd)"
    echo "source '${PKG_DIR}/dist/ext.sh'" >> './exts.sh'
    echo "source '${PKG_DIR}/dist/comp.sh'" >> './comps.sh'
  done
}

meta-exts-list() {
  ! [[ -f "${LIQ_EXTS_DB}/exts.sh" ]] \
    || cat "${LIQ_EXTS_DB}/exts.sh" | awk -F/ 'NF { print $(NF-3)"/"$(NF-2) }'
}

meta-exts-uninstall() {
  local PKGS="$@"
  PKGS="${PKGS//@/}"
  cd "${LIQ_EXTS_DB}"

  [[ -f 'exts.sh' ]] || touch './exts.sh'

  # npm uninstall "@${PKGS}"

  local NEW_EXTS NEW_COMPS PKG
  NEW_EXTS="$(cat './exts.sh')"
  NEW_COMPS="$(cat './comps.sh')"
  for PKG in ${PKGS//@/}; do
    NEW_EXTS="$(echo -n "$NEW_EXTS" \
      | { grep -Ev "${PKG}/dist/ext.sh'\$" || echowarn "No such extension found: '${PKG}'"; })"
    NEW_COMPS="$(echo -n "$NEW_COMPS" | { grep -Ev "${PKG}/dist/comp.sh'\$" || true; })"
  done

  echo "$NEW_EXTS" > './exts.sh'
  echo "$NEW_COMPS" > './comps.sh'
}
