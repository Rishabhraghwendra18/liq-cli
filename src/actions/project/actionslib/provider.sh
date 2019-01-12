CAT_PROVIDERS_KEY='_catalystProviders'

project-provider() {
  verifyService() {
    if ! echo "$PACKAGE" | jq -e ".$CAT_PROVIDERS_KEY | has(\"$SERVICE_TYPE\")" > /dev/null; then
      echoerr "No such service type '$SERVICE_TYPE' in providers definition."
      return 1
    else return 0; fi
  }

  listType() {
    # TYPE comes in like 'webapp'; handles the single quote
    SERVICE_TYPE=`echo $SERVICE_TYPE | tr -d "'"`
    echo "$SERVICE_TYPE : "`echo $PACKAGE | jq --raw-output ".${CAT_PROVIDERS_KEY}.${SERVICE_TYPE} | @csv" | tr -d \" | sed 's/,/, /g'`
  }

  local PACKAGE=`cat "$PACKAGE_FILE"`

  # If we're not adding, then there we expect $CAT_PROVIDERS_KEY to be present.
  if [[ "${1:-}" != "-a" ]] && \
     ! echo "$PACKAGE" | jq -e "(.$CAT_PROVIDERS_KEY | length) > 0" > /dev/null; then
    echoerrandexit "No '$CAT_PROVIDERS_KEY' provider definition found."
  fi

  if [[ $# -eq 0 ]]; then # list
    local SERVICE_TYPES=`cat $PACKAGE_FILE | jq --raw-output ".$CAT_PROVIDERS_KEY | keys | @sh"`
    local SERVICE_TYPE
    for SERVICE_TYPE in $SERVICE_TYPES; do
      listType
    done
  elif [[ "$1" == '-a' ]]; then
    local SERVICE_TYPE="$2"
    [[ $SERVICE_TYPE == *'.'* ]] && \
      echoerrandexit "Service type '$SERVICE_TYPE' contains illegal '.'."
    local INDEX=3
    while (($INDEX <= $#)); do
      local DEP="${!INDEX}"
      PACKAGE=`echo "$PACKAGE" | jq ". * { $CAT_PROVIDERS_KEY : { $SERVICE_TYPE : (.$CAT_PROVIDERS_KEY.$SERVICE_TYPE + [ \"$DEP\" ]  ) } } "`
      INDEX=$((INDEX + 1))
    done
    echo "$PACKAGE" | jq > "$PACKAGE_FILE"
  elif [[ "$1" == '-d' ]]; then
    if [[ $# == 1 ]]; then
      local DONE=false
      while [[ $DONE != true ]]; do
        select SPEC in `echo "$PACKAGE" | jq "(.$CAT_PROVIDERS_KEY | keys) + ( [ (.$CAT_PROVIDERS_KEY | to_entries | .[] | .key + \".\" + (.value | .[])  ) ] ) | sort | @sh" | tr -d "\"'"` '<done>'; do
          case $SPEC in
            '<done>')
              DONE=true
              break;;
            *)
              project-provider -d "$SPEC"
              PACKAGE=`cat "$PACKAGE_FILE"`
              break;;
          esac
        done # select
      done # while
    else
      local INDEX=2
      while (($INDEX <= $#)); do
        local SERVICE_TYPE=`echo ${!INDEX} | cut -d. -f1`
        local DEP=''
        if [[ ${!INDEX} == *'.'* ]]; then
          # TODO: can package names contain '.'? If so, we need to add all fields after the first to dep
          DEP=`echo ${!INDEX} | cut -d. -f2`
        fi

        if verifyService; then
          # Are we deletin the whole type def or just a single provider?
          if [[ -z "$DEP" ]]; then # delete whole service type entry
            PACKAGE=`echo "$PACKAGE" | jq ". + del(.$CAT_PROVIDERS_KEY.$SERVICE_TYPE)"`
          else
            if ! echo "$PACKAGE" | jq -e "(.$CAT_PROVIDERS_KEY.$SERVICE_TYPE | map(select(. == \"$DEP\")) | length) > 0" > /dev/null; then
              echoerr "No such provider '$DEP' in '$SERVICE_TYPE' providers."
            else
              PACKAGE=`echo "$PACKAGE" | jq "delpaths([[\"$CAT_PROVIDERS_KEY\", \"$SERVICE_TYPE\"]]) * { $CAT_PROVIDERS_KEY: { $SERVICE_TYPE: (.$CAT_PROVIDERS_KEY.$SERVICE_TYPE - [\"$DEP\"]) } }"`
              # now, cleanup if necessary
              if echo "$PACKAGE" | jq -e "(.$CAT_PROVIDERS_KEY.$SERVICE_TYPE | length) == 0" > /dev/null; then
                # TODO: this is a copy and past line
                PACKAGE=`echo "$PACKAGE" | jq ". + del(.$CAT_PROVIDERS_KEY.$SERVICE_TYPE)"`
              fi
            fi
          fi
        fi
        INDEX=$((INDEX + 1))
      done
    fi
    echo "$PACKAGE" | jq > "$PACKAGE_FILE"
  else # list named services
    local INDEX=1
    while (($INDEX <= $#)); do
      local SERVICE_TYPE=${!INDEX}
      if verifyService; then
        listType
      fi
      INDEX=$((INDEX + 1))
    done
  fi
}
