CAT_SERVICES_KEY="_catServices"

project-service() {
  if [[ $# -eq 0 ]]; then #list
    echo 'TODO list'
  elif [[ "$1" == '-a' ]]; then # add
    shift
    project-service-add "$@"
  fi # -a
}

project-service-add() {
  local PACKAGE=`cat "$PACKAGE_FILE"`
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
  "script-deploy": null,
  "script-ctrl": null,
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
    selectOtherDoneCancel OPTIONS "$@"
    for OPTION in $OPTIONS; do
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"$OPTIONS_NAME\": (.\"$OPTIONS_NAME\" + [\"$OPTION\"]) }"`
    done
  }

  selectOptions 'interface-classes' 'Interface class: ' 'http' 'sql' 'mysql'
  selectOptions 'platform-types' 'Platform type: ' 'local' 'gcp' 'aws'
  selectOptions 'purposes' 'Purpose: ' 'dev' 'test' 'pre-production', 'produciton'

  local SCRIPT_FILE
  requireAnswer 'Delpoy script: ' SCRIPT_FILE
  SERVICE_DEF=`echo "$SERVICE_DEF" | jq "setpath([\"script-deploy\"]; \"$SCRIPT_FILE\")"`

  SCRIPT_FILE=''
  requireAnswer 'Control script: ' SCRIPT_FILE
  SERVICE_DEF=`echo "$SERVICE_DEF" | jq "setpath([\"script-ctrl\"]; \"$SCRIPT_FILE\")"`

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

  PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_SERVICES_KEY\": (.\"$CAT_SERVICES_KEY\" + [$SERVICE_DEF]) }"`
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}
