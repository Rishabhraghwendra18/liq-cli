# Expects:
# * NO_DELETE, PROJECT, NO_UPDATE_LABELS from options, and
# * GIT_BASE and PACKAGE to be set.
projects-lib-setup-labels-sync() {
  local ORG_BASE ORG_PROJECT
  ORG_BASE="$(echo "${PACKAGE}" | jq -r '.liquidDev.orgBase' )"
  if [[ "${ORG_BASE}" == *'github.com'*'git' ]]; then # it's a git URL; convert to project name
    # separate the path element from the URL
    ORG_PROJECT="$(echo "${ORG_BASE}" | cut -d: -f2 )"
    ORG_PROJECT="${ORG_PROJECT:0:$(( ${#ORG_PROJECT} - 4 ))}" # remove '.git'
    local ORG_BIT PROJ_BIT
    # TODO: our defacto conventions are all over the place
    ORG_BIT="$(echo "${ORG_PROJECT}" | cut -d/ -f1 | tr '[:upper:]' '[:lower:]')"
    PROJ_BIT="$(echo "${ORG_PROJECT}" | cut -d/ -f2)"
    ORG_PROJECT="${ORG_BIT}/${PROJ_BIT}"
  else
    echoerrandexit "'liquidDev.orgBase' from 'package.json' in unknown format."
  fi

  if ! [[ -d "${LIQ_PLAYGROUND}/${ORG_PROJECT}" ]]; then
    # TODO: support '--import-org'
    echoerrandexit "Org def project '${ORG_PROJECT}' not found locally. Try:\nliq projects import ${ORG_BASE}"
  fi
  source "${LIQ_PLAYGROUND}/${ORG_PROJECT}/settings.sh"
  if [[ -z "${PROJECT_LABELS:-}" ]]; then
    echo "No project labels defined; using default label set..."
    PROJECT_LABELS=$(cat <<EOF
bounty:This task offers a bounty:209020
bug:Something is broken:d73a4a
enhancement:New feature or request:a2eeef
good first issue:Good for newcomers:7050ff
needs spec:The task as-is is not fully specified:ff4040
optimization:Make better without changing behavior:00dd70
EOF
    )
  fi

  local CURR_LABEL_DATA CURR_LABELS TEST_LABEL INDEX PROJECT_LABEL_NAMES
  PROJECT_LABEL_NAMES="$(echo "${PROJECT_LABELS}" | awk -F: '{print $1}')"
  CURR_LABEL_DATA="$(hub api "/repos/${GIT_BASE}/labels")"
  CURR_LABELS="$(echo "$CURR_LABEL_DATA" | jq -r '.[].name' )"

  local NON_STD_LABELS="${CURR_LABELS}"
  while read -r TEST_LABEL; do
    INDEX=$(list-get-index NON_STD_LABELS "${TEST_LABEL}")
    if [[ -n "${INDEX}" ]]; then
      list-rm-item NON_STD_LABELS "${TEST_LABEL}"
    fi
  done <<< "${PROJECT_LABEL_NAMES}"

  MISSING_LABELS="${PROJECT_LABEL_NAMES}"
  while read -r TEST_LABEL; do
    INDEX=$(list-get-index MISSING_LABELS "${TEST_LABEL}")
    if [[ -n "${INDEX}" ]]; then
      list-rm-item MISSING_LABELS "${TEST_LABEL}"
    fi
  done <<< "${CURR_LABELS}"

  local LABELS_SYNCED=true
  if [[ -n "${NON_STD_LABELS}" ]]; then
    if [[ -z "${NO_DELETE}" ]]; then
      while read -r TEST_LABEL; do
        echo "Removing non-standard label '${TEST_LABEL}'..."
        hub api -X DELETE "/repos/${GIT_BASE}/labels/${TEST_LABEL}"
      done <<< "${NON_STD_LABELS}"
    else
      echowarn "The following non-standard labels where found in ${PROJECT}:\n$(echo "${NON_STD_LABELS}" | awk '{ print "* "$0 }')\n\nInclude the '--delete' option to attempt removal."
      LABELS_SYNCED=false
    fi
  fi # non-standard label check; potential deletion

  local LABEL_SPEC NAME COLOR DESC
  set-spec() {
    NAME="$(echo "${LABEL_SPEC}" | awk -F: '{print $1}')"
    DESC="$(echo "${LABEL_SPEC}" | awk -F: '{print $2}')"
    COLOR="$(echo "${LABEL_SPEC}" | awk -F: '{print $3}')"
  }

  if [[ -n "${MISSING_LABELS}" ]]; then
    while read -r TEST_LABEL; do
      LABEL_SPEC="$(list-get-item-by-prefix PROJECT_LABELS "${TEST_LABEL}:")"
      set-spec
      echo "Adding label '${TEST_LABEL}'..."
      hub api -X POST "/repos/${GIT_BASE}/labels" -f name="${NAME}" -f description="${DESC}" -f color="${COLOR}" > /dev/null
    done <<< "$MISSING_LABELS"
  fi # missing labels creation

  if [[ -z "$NO_UPDATE_LABELS" ]] && [[ "${LABELS_SYNCED}" == true ]]; then
    [[ "${LABELS_SYNCED}" != true ]] || echo "Label names synchronized."
    echo "Checking label definitions..."
    LABELS_SYNCED=false
    while read -r LABEL_SPEC; do
      set-spec
      local CURR_DESC CURR_COLOR
      CURR_DESC="$(echo "$CURR_LABEL_DATA" | jq -r "map(select(.name == \"${NAME}\"))[0].description")"
      CURR_COLOR="$(echo "$CURR_LABEL_DATA" | jq -r "map(select(.name == \"${NAME}\"))[0].color")"
      if [[ "${CURR_COLOR}" != "${COLOR}" ]] || [[ "$CURR_DESC" != "${DESC}" ]]; then
        echo "Updating label definition for '${NAME}'..."
        hub api -X PATCH "/repos/${GIT_BASE}/labels/${NAME}" -f description="${DESC}" -f color="${COLOR}" > /dev/null
        LABELS_SYNCED=true
      fi
    done <<< "${PROJECT_LABELS}"

    [[ "$LABELS_SYNCED" == true ]] && echo "Label definitions updated." || echo "Labels already up-to-date."
  else
    [[ "${LABELS_SYNCED}" != true ]] || [[ -n "$NO_UPDATE_LABELS" ]] || echo "Labels not synchronized; skipping update."
    [[ -z "${NO_UPDATE_LABELS}" ]] || echo "Skipping update."
  fi # labels definition check and update
}
