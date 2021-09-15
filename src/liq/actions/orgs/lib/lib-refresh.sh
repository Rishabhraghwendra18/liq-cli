org-lib-refresh-projects() {
  local PROJECTS_NAMES PROJECT_NAME

  local PAGE_COUNT=1 # starts at 1
  local STAGING_DIR="/tmp/liq.tmp.projects-refresh"
  local STAGED_JSON="${STAGING_DIR}/projects.json"
  local PER_PAGE=25
  local END_CURSOR='null'
  local HAS_MORE='true'
  local UNWRAP_ORG='.data.viewer.organization'
  local UNWRAP_REPOS="${UNWRAP_ORG}.repositories"
  local UNWRAP_EDGES="${UNWRAP_REPOS}.edges"
  local GH_GRAPHQL_VER='application/vnd.github.v4.idl'
  orgs-lib-source-settings # to set ORG_GITHUB_NAME
  
  rm -rf "${STAGING_DIR}"
  mkdir -p "${STAGING_DIR}"
  
  echo "{" > "${STAGED_JSON}"

  echofmt "\nRetrieving repository data for github org: ${ORG_GITHUB_NAME}"
  while [[ "${HAS_MORE}" == 'true' ]]; do
    local RAW_DATA REPOS_DATA
    # TODO: echofmt gets confused and treats the line as an option if it's starts with '-'
    echofmt "|---------\nPage ${PAGE_COUNT}...\n---------"

    fail-msg() {
      local ERROR_MSG="${1:-}"
      
      [[ -z "${ERROR_MSG}" ]] \
        || ERROR_MSG=" (err msg: ${ERROR_MSG})"
      
      echo "No data found for org '${ORG_GITHUB_NAME}'${ERROR_MSG}. If there are truly no repositories, then this is not an error. Otherwise, ensure that you have the necessary scopes configured with the hub authentication token.\n\nYou can check current scopes at:\nhttps://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps\n\nScopes needed for GraphQL:\nhttps://docs.github.com/en/graphql/guides/forming-calls-with-graphql#authenticating-with-graphql"
    }
    
    RAW_DATA="$(hub api graphql \
        -H "Accept: ${GH_GRAPHQL_VER}" \
        -F query="$(org-lib-repos-query "${ORG_GITHUB_NAME}" ${PER_PAGE} ${END_CURSOR})")" \
      || echoerrandexit "$(fail-msg "${RAW_DATA}")"
    [[ -n "${RAW_DATA}" ]] \
      && [[ "$(echo "${RAW_DATA}" | jq "${UNWRAP_ORG}")" != 'null' ]] \
      || echoerrandexit "$(fail-msg)"
    local STAGED_RAW_DATA="${STAGING_DIR}/repos-page-${PAGE_COUNT}.json"
    
    echo "${RAW_DATA}" > "${STAGED_RAW_DATA}"
    
    HAS_MORE="$(echo "${RAW_DATA}" | jq "${UNWRAP_REPOS}.pageInfo.hasNextPage")"
    END_CURSOR="$(echo "${RAW_DATA}" | jq "${UNWRAP_REPOS}.pageInfo.endCursor")" # quotes come along with value

    # let's go ahead and trim things down for
    REPOS_DATA="$( echo "${RAW_DATA}" \
      | jq "[ ${UNWRAP_EDGES}[] | { (.node.name): ( .node | del(.name)) } ] | add")" \
      || echoerrandexit "Failed to retrive repository data: '${REPOS_DATA}'"
    # looks something like:
    # {
    #   "repository-name": {
    #     "isPrivate": true,
    #     "squashMergeAllowed": true,
    #     "rebaseMergeAllowed": true
    #   }, ...
    # }

    # echo "${REPOS_DATA}" > "${STAGING_DIR}/repos-data.json" # useful for debugging
    # TODO: I don't this can happen with the current implementation
    # [[ "${REPOS_DATA}" != '{}' ]] || { echofmt "No more results."; break; }

    local PROJECT_NAMES
    PROJECT_NAMES="$(echo "${REPOS_DATA}" | jq -r 'keys | .[]')"
    for PROJECT_NAME in $PROJECT_NAMES; do
      # TODO: add '-n' support to echofmt and use it here.
      echo -n "Processing ${ORG_GITHUB_NAME}/${PROJECT_NAME}... "
      # Each entry we add will look something like:
      # "project-name": { "package": {...}, "repository": { "isPrivate": true, ...}}

      echo -n "\"${PROJECT_NAME}\": { \"package\": " >> "${STAGED_JSON}"
      
      # save the project package file locally; it's useful
      local PKG_CONTENTS
      PKG_CONTENTS="$(hub api graphql \
        -H "Accept: ${GH_GRAPHQL_VER}" \
        -F query="$(org-lib-package-json-content-query)" \
        -F owner="${ORG_GITHUB_NAME}" -F name="${PROJECT_NAME}" -F path="HEAD:package.json")"
      # when testing jq directly, running the above leaves PKG_CONTENTS empty. However, when executed in the subshell,
      # it's consistently 'null'. This was reproducd in a minimal command line test as well. Wha??
      PKG_CONTENTS="$(echo "${PKG_CONTENTS}" | jq -r '.data.repository.object.text')"
      
      if [[ -n "${PKG_CONTENTS}" ]] && [[ "${PKG_CONTENTS}" != 'null' ]]; then
        echo "${PKG_CONTENTS}" >> "${STAGED_JSON}"
        echofmt "staged!"
      else
        echofmt "no package.json (or cannot be parsed)."
        echo "null" >> "${STAGED_JSON}"
      fi
      echo -n ', "repository": ' >> "${STAGED_JSON}"
      echo "$(echo "${REPOS_DATA}" | jq -r ".[\"${PROJECT_NAME}\"]")" >> "${STAGED_JSON}"
      # Close the project entry
      echo -n "}," >> ${STAGED_JSON} # -n so easier to remove in a bit; eventually all reformatted anyway
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

# Returns a query to get the needed repository info
org-lib-repos-query() {
  local ORG_GITHUB_NAME="${1}"
  local PER_PAGE="${2}"
  local END_CURSOR="${3:-null}"
  # TODO: it may be possible to combine the content query with the list query, but I'm not sure. And no time for it now.
  echo "query {
    viewer {
      organization(login:\"${ORG_GITHUB_NAME}\") {
        repositories(first:${PER_PAGE}, after:${END_CURSOR}, orderBy:{ field:NAME, direction:ASC}) {
          edges {
            node {
              name
              isPrivate
              squashMergeAllowed
              rebaseMergeAllowed
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }"
}

org-lib-package-json-content-query() {
  echo "query RepoFiles(\$owner: String!, \$name: String!, \$path: String!) {
    repository(owner: \$owner, name: \$name) {
      object(expression: \$path) {
        ... on Blob {
          byteSize
          text
        }
      }
    }
  }"
}
