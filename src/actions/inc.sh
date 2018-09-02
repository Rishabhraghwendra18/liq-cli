getActions() {
  local MY_DIR=`dirname "${BASH_SOURCE[0]}"`
  for d in `find "${MY_DIR}" -type d -maxdepth 1 -not -path "${MY_DIR}"`; do
    for f in "${d}/"*.sh; do echo "f: ${f}"; source "$f"; done
  done
}
getActions
