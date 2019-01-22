findDataFiles() {
  local DATA_IFACE="$1"
  local FILE_TYPE="$2"
  local _VAR_NAME="$3"
  local _FILES

  local CAT_PACKAGE
  for CAT_PACKAGE in `getCatPackagePaths`; do
    if [[ -d "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
      local FIND_RESULTS="`find "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" -type f`"
      if [[ -z "$_FILES" ]]; then
        _FILES="${FIND_RESULTS}"
      else
        _FILES="${_FILES}"$'\n'"${FIND_RESULTS}"
      fi
    fi
  done
  if [[ -d "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
    _FILES="${_FILES}"$'\n'"`find "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" -type f`"
  fi

  if [[ -z "$_FILES" ]]; then
    echoerrandexit "\nDid not find any ${FILE_TYPE} files for '${DATA_IFACE}'."
  else
    # TODO: should verify all the files have the required naming convention.
    # now we sort the schema files according the file numbers
    _FILES=`echo "${_FILES}" | awk -F/ '{ print $NF, $0 }' | sort -n -k1 | sed -Ee 's/[0-9]+[^ ]+ //'`
    eval "$_VAR_NAME=\"${_FILES}\""
  fi
}
