CAT_REQ_SERVICES_KEY='_catalystRequiresService'

project-requires-service() {
  local PACKAGE=`cat "$PACKAGE_FILE"`

  if [[ $# -eq 0 ]]; then # list
    project-requires-service-list
  elif [[ "$1" == '-a' ]]; then
    shift
    local IFACE_CLASS
    if [[ $# -eq 0 ]]; then # interactive add
      local REQ_SERVICES
      PS3="Required service interface: "
      selectDoneCancelOther REQ_SERVICES $STD_IFACE_CLASSES
      for IFACE_CLASS in $REQ_SERVICES; do
        PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_REQ_SERVICES_KEY\" : ( .\"$CAT_REQ_SERVICES_KEY\" + [ \"$IFACE_CLASS\" ] ) }"`
      done
    else
      while (($# > 0)); do
        IFACE_CLASS="$1"; shift
        PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_REQ_SERVICES_KEY\" : ( .\"$CAT_REQ_SERVICES_KEY\" + [ \"$IFACE_CLASS\" ] ) }"`
      done
    fi
    echo "$PACKAGE" | jq > "$PACKAGE_FILE"
  elif [[ "$1" == '-d' ]]; then
    shift
    if [[ $# -eq 0 ]]; then # interactive delete
      local DEL
      while [[ $DEL != '...quit...' ]]; do
        local OPTIONS=`project-requires-service-list`
        # TODO: rework to support canctel; add and use 'selectDone'?
        if [[ -z "$OPTIONS" ]]; then
          echo "Nothing left to delete."
          DEL='...quit...'
        else
          select DEL in '<done>' $OPTIONS; do
            case $DEL in
              '<done>')
                DEL='...quit...'
                break;;
              *)
                project-requires-service -d "$DEL"
                PACKAGE=`cat "$PACKAGE_FILE"`
                break;;
            esac
          done # select
        fi
      done # while
    else
      while (($# > 0)); do
        local IFACE_CLASS="$1"; shift
        if ! echo "$PACKAGE" | jq -e "(.$CAT_REQ_SERVICES_KEY | map(select(. == \"$IFACE_CLASS\")) | length) > 0" > /dev/null; then
          echoerr "No such requirement '$IFACE_CLASS' found."
        else
          PACKAGE=`echo "$PACKAGE" | jq ". + {\"$CAT_REQ_SERVICES_KEY\": [ .\"$CAT_REQ_SERVICES_KEY\" | .[] | select(. != \"$IFACE_CLASS\") ] }"`
        fi
      done
    fi
    # cleanup $CAT_REQ_SERVICES_KEY if empty
    if echo "$PACKAGE" | jq -e "(.$CAT_REQ_SERVICES_KEY | length) == 0" > /dev/null; then
      PACKAGE=`echo "$PACKAGE" | jq "del(.$CAT_REQ_SERVICES_KEY)"`
    fi
    echo "$PACKAGE" | jq > "$PACKAGE_FILE"
  else
    echoerrandexit "Unknown command options: '$@'"
    usage-project-requires-service
  fi
}

project-requires-service-list() {
  if echo "$PACKAGE" | jq -e "(.$CAT_REQ_SERVICES_KEY | length) > 0" > /dev/null; then
    echo "$PACKAGE" | jq --raw-output ".$CAT_REQ_SERVICES_KEY | @sh" | tr -d "'"
  fi
}
