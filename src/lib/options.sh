# Echoes common options for all liq commands.
pre-options-liq() {
  echo -n "QUIET VERBOSE: DEBUG:"
}

# Processes common options for liq commands. Currently, all options are "just" flags that other functions will check, so
# there's nothing for us to do here.
post-options-liq() {
  :
}
