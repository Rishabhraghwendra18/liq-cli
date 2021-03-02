# Echoes common options for all liq commands.
pre-options-liq() {
  # TODO: VERBOSE and DEBUG are not currently supported; need to add to echofmt (and then derive echodebug and also
  # change the implicatino of information from 'something highlighted' to 'secondary info')
  echo -n "QUIET SILENT: VERBOSE: DEBUG:"
}

# Processes common options for liq commands. Currently, all options are "just" flags that other functions will check, so
# there's nothing for us to do here.
post-options-liq() {
  ECHO_QUIET="${QUIET}"
  ECHO_SILENT="${SILENT}"
  ECHO_VERBOSE="${VERBOSE}"
  ECHO_DEBUG="${DEBUG}"
}
