print_usage() {
  echo "Usage:"
  echo
  echo "  catalyst help : Prints help info."
  for d in `find "${SOURCE_DIR}/actions" -type d -maxdepth 1 -not -path "${SOURCE_DIR}/actions"`; do
    echo
    print_$(basename ${d})_usage "  " "catalyst "
  done
}
