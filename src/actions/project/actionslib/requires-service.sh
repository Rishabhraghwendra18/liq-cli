CAT_REQ_SERVICES_KEY='_catalystRequiresService'

project-requires-service() {
  local PACKAGE=`cat "$PACKAGE_FILE"`

  if [[ $# -eq 0 ]]; then # list
    project-requires-service-list
  elif [[ "$1" == '-a' ]]; then
    shift
    if [[ $# -eq 0 ]]; then # interactive add
      echo "TODO: implement interactive add"
    else
      while (($# > 0)); do
        local IFACE_CLASS="$1"; shift
        PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_REQ_SERVICES_KEY\" : ( .\"$CAT_REQ_SERVICES_KEY\" + [ \"$IFACE_CLASS\" ] ) }"`
      done
    fi
    echo "$PACKAGE" | jq > "$PACKAGE_FILE"
  elif [[ "$1" == '-d' ]]; then
    shift
    if [[ $# -eq 0 ]]; then # interactive delete
      local DEL
      while [[ $DEL != '...quit...' ]]; do
        select DEL in `project-requires-service-list` '<done>'; do
          case $SPEC in
            '<done>')
              DEL='...quit...'
              break;;
            *)
              project-requires-service -d "$SPEC"
              PACKAGE=`cat "$PACKAGE_FILE"`
              break;;
          esac
        done # select
      done # while
    else
      while (($# > 0)); do
        local IFACE_CLASS="$1"; shift
        if ! echo "$PACKAGE" | jq -e "(.$CAT_REQ_SERVICES_KEY.$SERVICE_TYPE | map(select(. == \"$DEP\")) | length) > 0" > /dev/null; then
          echoerr "No such requirement '$DEP' found."
        else
          PACKAGE=`echo "$PACKAGE" | jq ". + {\"$CAT_REQ_SERVICES_KEY\": ( .\"$CAT_REQ_SERVICES_KEY | .[] | select(. != \"$IFACE_CLASS\") ) }"`
          # cleanup $CAT_REQ_SERVICES_KEY if empty
          if echo "$PACKAGE" | jq -e "(.$CAT_REQ_SERVICES_KEY | length) == 0" > /dev/null; then
            PACKAGE=`echo "$PACKAGE" | jq ". + del(.$CAT_REQ_SERVICES_KEY)"`
          fi
        fi
      done
    fi
    echo "$PACKAGE" | jq > "$PACKAGE_FILE"
  else
    echoerrandexit "Unknown command options: '$@'"
    usage-project-requires-service
  fi
}

project-requires-service-list() {
  echo "$PACKAGE" | jq ".$CAT_REQ_SERVICES_KEY | @sh"
}
