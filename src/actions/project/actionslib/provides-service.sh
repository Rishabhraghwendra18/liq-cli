project-provides-service() {
  local PACKAGE=`cat "$PACKAGE_FILE"`

  if [[ $# -eq 0 ]]; then #list
    echo $PACKAGE | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | .\"name\""
  elif [[ "$1" == '-a' ]]; then # add
    shift
    project-provides-service-add "$@"
  elif [[ "$1" == '-d' ]]; then # delete
    shift
    project-provides-service-delete "$@"
  else # show detail on each named service
    while [[ $# -gt 0 ]]; do
      echo "$1:"
      echo
      echo $PACKAGE | jq ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$1\")"
      if [[ $# -gt 1 ]]; then
        echo
        read -p "Hit enter to continue to '$2'..."
      fi
      shift
    done
  fi
}

project-provides-service-add() {
  # TODO: check for global to allow programatic use
  local SERVICE_NAME="${1:-}"
  if [[ -z "$SERVICE_NAME" ]]; then
    requireAnswer "Service name: " SERVICE_NAME
  fi

  local SERVICE_DEF=$(cat <<EOF
{
  "name": "${SERVICE_NAME}",
  "interface-classes": [],
  "platform-types": [],
  "purposes": [],
  "ctrl-script": null,
  "params-req": [],
  "params-opt": []
}
EOF
)

  function selectOptions() {
    local OPTIONS
    local OPTION
    local OPTIONS_NAME="$1"; shift
    PS3="$1"; shift
    selectOtherDoneCancelAny OPTIONS "$@"
    for OPTION in $OPTIONS; do
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"$OPTIONS_NAME\": (.\"$OPTIONS_NAME\" + [\"$OPTION\"]) }"`
    done
  }

  selectOptions 'interface-classes' 'Interface class: ' $STD_IFACE_CLASSES
  selectOptions 'platform-types' 'Platform type: ' $STD_PLATFORM_TYPES
  selectOptions 'purposes' 'Purpose: ' $STD_PURPOSES

  local SCRIPT_FILE
  PS3='Control script: '
  select SCRIPT_FILE in `ls ${BASE_DIR}/bin`; do
    SERVICE_DEF=`basename "$SERVICE_DEF" | jq "setpath([\"ctrl-script\"]; \"$SCRIPT_FILE\")"`
    break
  done

  echo "Enter required parameters. Enter blank line when done."
  local PARAM_NAME
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Required parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then
      PARAM_NAME='...quit...'
    else
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"params-req\": (.\"params-req\" + [\"$PARAM_NAME\"]) }"`
    fi
  done

  PARAM_NAME=''
  echo "Enter optional parameters. Enter blank line when done."
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Optional parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then
      PARAM_NAME='...quit...'
    else
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"params-opt\": (.\"params-opt\" + [\"$PARAM_NAME\"]) }"`
    fi
  done

  PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_PROVIDES_SERVICE\": (.\"$CAT_PROVIDES_SERVICE\" + [$SERVICE_DEF]) }"`
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

project-provides-service-delete() {
  if (( $# == 0 )); then
    echoerrandexit "Must specify service names to delete."
  fi

  local SERV_NAME
  for SERV_NAME in "$@"; do
    if echo "$PACKAGE" | jq -e "(.\"$CAT_PROVIDES_SERVICE\" | map(select(.name == \"$SERV_NAME\")) | length) == 0" > /dev/null; then
      echoerr "Did not find service '$SERV_NAME' to delete."
    fi
    PACKAGE=`echo "$PACKAGE" | jq "setpath([\"$CAT_PROVIDES_SERVICE\"]; .\"$CAT_PROVIDES_SERVICE\" | map(select(.name != \"$SERV_NAME\")))"`
  done
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}
