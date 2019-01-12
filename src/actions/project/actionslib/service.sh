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
  # TODO: check for global to allow programatic use
  local SERVICE_TYPE="${1:-}"
  if [[ -z "$SERVICE_TYPE" ]]; then
    PS3="Service type: "
    select SERVICE_TYPE in 'webapp' 'db-mysql' 'api-go' '<other>' '<cancel>'; do
      break
    done
    case "$SERVICE_TYPE" in
      '<cancel>')
        exit;;
      '<other>')
        requireAnswer 'Service type: ' SERVICE_TYPE;;
      *)
        ;;
    esac
  fi # -z "$SERVICE_TYPE"

  local SERVICE_DEF=$(cat <<EOF
{
  "serviceType": "${SERVICE_TYPE}",
  "envTypes": [],
  "purposes": [],
  "deployScript": null,
  "ctrlScript": null,
  "reqParams": [],
  "optParams": []
}
EOF
)
  local ENVIRONMENT_TYPES
  local ENVIRONMENT_TYPE
  PS3="Environment type: " # TODO: environment 'platform' better? type is so generic
  selectOtherDoneCancel ENVIRONMENT_TYPES 'local' 'gcp'
  for ENVIRONMENT_TYPE in $ENVIRONMENT_TYPES; do
    echo "$ENVIRONMENT_TYPE"
    SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"envTypes\": (.envTypes + [\"$ENVIRONMENT_TYPE\"]) }"`
  done

  local PURPOSES
  local PURPOSE
  PS3="Purpose: "
  selectOtherDoneCancel PURPOSES 'dev' 'test' 'pre-production', 'produciton'
  for PURPOSE in $PURPOSES; do
    SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"purposes\": (.purposes + [\"$PURPOSE\"]) }"`
  done

  local SCRIPT_FILE
  requireAnswer 'Delpoy script: '
  SERVICE_DEF=`echo "$SERVICE_DEF" | jq "setpath([\"deployScript\"]; \"$SCRIPT_FILE\")"`

  requireAnswer 'Control script: '
  SERVICE_DEF=`echo "$SERVICE_DEF" | jq "setpath([\"ctrlScript\"]; \"$SCRIPT_FILE\")"`

  echo "Enter required parameters. Enter blank line when done."
  local PARAM_NAME
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Required parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then PARAM_NAME='...quit...'; fi
  done

  echo "Enter optional parameters. Enter blank line when done."
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Optional parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then PARAM_NAME='...quit...'; fi
  done

  echo "$SERVICE_DEF" | jq
}
