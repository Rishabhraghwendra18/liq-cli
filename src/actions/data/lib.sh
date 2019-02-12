findDataFiles() {
  local _FILES_VAR="$1"
  local _COUNT_VAR="$2"
  local DATA_IFACE="$3"
  local FILE_TYPE="$4"
  local _FILES

  local CAT_PACKAGE FIND_RESULTS
  # search Catalyst packages in dependencies (i.e., ./node_modules)
  for CAT_PACKAGE in `getCatPackagePaths`; do
    if [[ -d "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
      FIND_RESULTS="$(find "${CAT_PACKAGE}/data/${DATA_IFACE}/${FILE_TYPE}" -type f)"
      list-add-item _FILES "$FIND_RESULTS" "\n"
    fi
  done
  # search our own package
  if [[ -d "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" ]]; then
    FIND_RESULTS="$(find "${BASE_DIR}/data/${DATA_IFACE}/${FILE_TYPE}" -type f)"
    list-add-item _FILES "$FIND_RESULTS" "\n"
  fi

  if [[ -z "$_FILES" ]]; then
    echoerrandexit "\nDid not find any ${FILE_TYPE} files for '${DATA_IFACE}'."
  else
    # TODO: should verify all the files have the required naming convention.
    # sort the files so dependency orders are respected
    # 1) awk will pull off the last 'field'=='the file name', so
    # 2) sort will then sort against the filename, and
    # 3) sed removes the leading filename getting us back to a list of sorted files.
    _FILES=`echo "${_FILES}" | awk -F/ '{ print $NF, $0 }' | sort -n -k1 | sed -Ee 's/[^ ]+ //'`
    eval "$_FILES_VAR=\"${_FILES}\""
  fi

  eval "$_COUNT_VAR"=$(echo "$_FILES" | wc -l | tr -d ' ')
}
