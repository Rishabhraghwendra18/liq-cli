findDataFiles() {
  local DATA_IFACE="$1"
  local FILE_TYPE="$2"

  local SCHEMA_FILES

  local CAT_PACKAGE
  for CAT_PACKAGE in `getCatPackagePaths`; do
    if [[ -d "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
      local FIND_RESULTS="`find "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" -type f`"
      if [[ -z "$SCHEMA_FILES" ]]; then
        SCHEMA_FILES="${FIND_RESULTS}"
      else
        SCHEMA_FILES="${SCHEMA_FILES}"$'\n'"${FIND_RESULTS}"
      fi
    fi
  done
  if [[ -d "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
    SCHEMA_FILES="${SCHEMA_FILES}"$'\n'"`find "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" -type f`"
  fi

  # now we sort the schema files according the file numbers
  SCHEMA_FILES=`echo "${SCHEMA_FILES}" | awk -F/ '{ print $NF, $0 }' | sort -n -k1 | sed -Ee 's/[0-9]+[^ ]+ //'`

  echo "$SCHEMA_FILES"
}
