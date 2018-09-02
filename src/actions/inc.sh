getActions() {
  for d in `find "${SOURCE_DIR}/actions" -type d -maxdepth 1 -not -path "${SOURCE_DIR}/actions"`; do
    for f in "${d}/"*.sh; do source "$f"; done
  done
}
getActions
