requirements-provided-services() {
  requireCatalystfile
  requirePackage
}

provided-services-add() {
  # TODO: check for global to allow programatic use
  local SERVICE_NAME="${1:-}"
  if [[ -z "$SERVICE_NAME" ]]; then
    require-answer "Service name: " SERVICE_NAME
  fi

  local SERVICE_DEF=$(cat <<EOF
{
  "name": "${SERVICE_NAME}",
  "interface-classes": [],
  "platform-types": [],
  "purposes": [],
  "ctrl-scripts": [],
  "params-req": [],
  "params-opt": [],
  "config-const": {}
}
EOF
)

  function selectOptions() {
    local OPTIONS
    local OPTION
    local OPTIONS_NAME="$1"; shift
    PS3="$1"; shift
    local OPTS_ONLY="$1"; shift

    if [[ -n "$OPTS_ONLY" ]]; then
      selectDoneCancel OPTIONS "$@"
    else
      selectDoneCancelAnyOther OPTIONS "$@"
    fi
    for OPTION in $OPTIONS; do
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"$OPTIONS_NAME\": (.\"$OPTIONS_NAME\" + [\"$OPTION\"]) }"`
    done
  }

  selectOptions 'interface-classes' 'Interface class: ' '' $STD_IFACE_CLASSES
  selectOptions 'platform-types' 'Platform type: ' '' $STD_PLATFORM_TYPES
  selectOptions 'purposes' 'Purpose: ' '' $STD_PURPOSES
  selectOptions 'ctrl-scripts' "Control script: " true `find "${BASE_DIR}/bin/" -type f -not -name '*~' -prune -execdir echo '{}' \;`

  defineParameters SERVICE_DEF

  PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_PROVIDES_SERVICE\": (.\"$CAT_PROVIDES_SERVICE\" + [$SERVICE_DEF]) }"`
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

provided-services-delete() {
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

provided-services-list() {
  echo $PACKAGE | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | .\"name\""
}

provided-services-show() {
  while [[ $# -gt 0 ]]; do
    if ! echo $PACKAGE | jq -e "(.\"$CAT_PROVIDES_SERVICE\") and (.\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$1\"))" > /dev/null; then
      echoerr "No such service '$1'."
    else
      echo "$1:"
      echo
      echo $PACKAGE | jq ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$1\")"
      if [[ $# -gt 1 ]]; then
        echo
        read -p "Hit enter to continue to '$2'..."
      fi
    fi
    shift
  done
}
