org-lib-refresh-projects() {
  local PROJECTS_NAMES PROJECT_NAME

  local PAGE_COUNT=39 # starts at 1
  local STAGING_DIR="/tmp/liq.tmp.projects-refresh"
  local STAGED_JSON="${STAGING_DIR}/projects.json"
  local PER_PAGE=3 # 50

  rm -rf "${STAGING_DIR}"
  mkdir -p "${STAGING_DIR}"

  echo '{' > "${STAGED_JSON}"
  while true; do # we break to end
    echofmt "\n---------\nPage ${PAGE_COUNT}...\n---------"
    REPOS_DATA="$(hub api -X GET orgs/${ORG}/repos \
      -f sort=full_name -f direction=asc -f per_page=${PER_PAGE} -f page=${PAGE_COUNT} \
      | jq -r '[ .[] | with_entries(select([.key] | inside(["name", "full_name", "private"]))) ]')"
    # Repos data now has trimmed down entries with only what we care about

    [[ "${REPOS_DATA}" != '[]' ]] || { echofmt "No more results."; break; }

    local RESULT_COUNT=0
    for PROJECT_NAME in $(echo "${REPOS_DATA}" | jq -r '.[] | .name'); do
      # TODO: add '-n' support to echofmt and use it here.
      echo -n "Processing ${ORG}/${PROJECT_NAME}... "
      local STAGED_PACKAGE_JSON="${STAGING_DIR}/${PROJECT_NAME}.package.json"
      # the 'jq' step is to catch invalid package.json files...
      hub api -X GET /repos/${ORG}/${PROJECT_NAME}/contents/package.json \
          | jq -r '.content' \
          | base64 --decode > "${STAGED_PACKAGE_JSON}" \
          | jq \
        && echofmt "staged!" \
        || { echofmt "skipping; package.json missing or invalid."; rm "${STAGED_PACKAGE_JSON}"; }
    done


    local PACKAGE_FILE
    for PACKAGE_FILE in $(ls "${STAGING_DIR}"/*.package.json); do
      PROJECT_NAME=$(basename "${PACKAGE_FILE}")
      PROJECT_NAME="${PROJECT_NAME/.package.json/}"
      echo -n "\"${PROJECT_NAME}\": " >> "${STAGED_JSON}"
      cat "${PACKAGE_FILE}" >> "${STAGED_JSON}"
      echo -n "," >> ${STAGED_JSON} # -n so easier to remove in a bit; eventually all reformatted anyway
    done

    PAGE_COUNT=$(( ${PAGE_COUNT} + 1 ))
  done # the paging loop
  # remove last comma
  sed -i tmp '$ s/,$//' "${STAGED_JSON}"
  echo '}' >> "${STAGED_JSON}"

  local PROJECTS_JSON="${CURR_ORG_PATH}/data/orgs/projects.json"
  # pipe through jq to format
  cat "${STAGED_JSON}" | jq > "${PROJECTS_JSON}"
}
