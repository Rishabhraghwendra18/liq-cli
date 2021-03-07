requirements-orgs() {
  :
}

# see `liq help orgs close`
orgs-close() {
  eval "$(setSimpleOptions FORCE -- "$@")"

  if (( $# < 1 )); then
    echoerrandexit "Must specify 'org package' explicitly to close."
  fi

  local ORG_PROJ TO_DELETE OPTS
  if [[ -n "$FORCE" ]]; then OPTS='--force'; fi
  for ORG_PROJ in "$@"; do
    projectsSetPkgNameComponents "$ORG_PROJ"
    local IS_BASE_ORG=false
    if [[ "${LIQ_ORG_DB}/${PKG_ORG_NAME}" -ef "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}/${PKG_BASENAME}" ]]; then
      IS_BASE_ORG=true
    fi
    projects-close $OPTS "${PKG_ORG_NAME}/${PKG_BASENAME}"
    if [[ "$IS_BASE_ORG" == true ]]; then
      rm "${LIQ_ORG_DB}/${PKG_ORG_NAME}"
    fi
  done
}

# see `liq help orgs create`
orgs-create() {
  local FIELDS="COMMON_NAME GITHUB_NAME LEGAL_NAME ADDRESS:"
  local OPT_FIELDS="NAICS NPM_REGISTRY DEFAULT_LICENSE"
  local FIELDS_SENSITIVE="EIN"
  eval "$(setSimpleOptions COMMON_NAME= GITHUB_NAME= LEGAL_NAME= ADDRESS= NAICS= NPM_REGISTRY:r= DEFAULT_LICENSE= EIN= NO_SENSITIVE:X NO_STAFF:S PRIVATE_POLICY -- "$@")"

  local ORG_PKG="${1}"; shift

  # because some fields are optional, but may be set, we can't just rely on 'gather-answers' to skip interactive bit
  local FULLY_DEFINED=true
  for FIELD in $FIELDS; do
    FIELD=${FIELD/:/}
    [[ -n "${!FIELD}" ]] || FULLY_DEFINED=false
  done

  defaulter() {
    local FIELD="${1}"

    case "$FIELD" in
      "NPM_REGISTRY")
        echo "https://registry.npmjs.org/";;
    esac
  }

  if [[ "$FULLY_DEFINED" == true ]]; then
    NPM_REGISTRY=$(defaulter NPM_REGISTRY)
  else
    # TODO: we need to mark fields as optional for gather-answers or provide func equivalent
    local GATHER_FIELDS
    if [[ -n "$NO_SENSITIVE" ]]; then
      GATHER_FIELDS="$FIELDS $OPT_FIELDS"
    else
      GATHER_FIELDS="$FIELDS $OPT_FIELDS $FIELDS_SENSITIVE"
    fi
    gather-answers --defaulter=defaulter --verify "$GATHER_FIELDS"
  fi

  projectsSetPkgNameComponents "${ORG_PKG}"

  cd "${LIQ_PLAYGROUND}"
  mkdir -p "${PKG_ORG_NAME}"
  cd "${PKG_ORG_NAME}"

  if [[ -L "${PKG_BASENAME}" ]]; then
    echoerrandexit "Duplicate or name conflict; found existing locol org package ($ORG_PKG)."
  fi
  mkdir "${PKG_BASENAME}"
  cd "${PKG_BASENAME}"

  commit-settings() {
    local REPO_TYPE="${1}"; shift
    local FIELD
    local SETTINGS='data/orgs/settings.sh'

    echofmt "Initializing ${REPO_TYPE} repository..."
    git init --quiet .

    mkdir $(dirname "${SETTINGS}")
    for FIELD in "$@"; do
      FIELD=${FIELD/:/}
      echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> "${SETTINGS}"
    done

    git add "${SETTINGS}"
    git commit -m "initial org settings"
    git push --set-upstream upstream master
  }

  local SENSITIVE_REPO POLICY_REPO STAFF_REPO
  # TODO: give option to use package or repo; these have different implications
  if [[ -z "$NO_SENSITIVE" ]]; then
    SENSITIVE_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}-sensitive"
  fi
  if [[ -z "$NO_STAFF" ]]; then
    STAFF_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}-staff"
  fi
  if [[ -n "$PRIVATE_POLICY" ]]; then
    POLICY_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}-policy"
  else
    POLICY_REPO="${PKG_ORG_NAME}/${PKG_BASENAME}"
  fi
  hub create --remote-name upstream -d "Public settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}"
  commit-settings "base" $FIELDS $OPT_FIELDS SENSITIVE_REPO POLICY_REPO STAFF_REPO

  if [[ -z "$NO_SENSITIVE" ]]; then
    cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}"
    mkdir "${PKG_BASENAME}-sensitive"
    cd "${PKG_BASENAME}-sensitive"

    hub create --remote-name upstream --private -d "Sensitive settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}-sensitive"
    commit-settings "sensitive" "$FIELDS_SENSITIVE"
  fi

  if [[ -z "$NO_STAFF" ]]; then
    cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}"
    mkdir "${PKG_BASENAME}-staff"
    cd "${PKG_BASENAME}-staff"

    hub create --remote-name upstream --private -d "Staff settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}-staff"
    commit-settings "staff" ""
  fi

  if [[ -n "$PRIVATE_POLICY" ]]; then
    cd "${LIQ_PLAYGROUND}/${PKG_ORG_NAME}"
    mkdir "${PKG_BASENAME}-policy"
    cd "${PKG_BASENAME}-policy"

    hub create --remote-name upstream --private -d "Policy settings for ${LEGAL_NAME}." "${GITHUB_NAME}/${PKG_BASENAME}-policy"
    commit-settings "policy" ""
  fi
}

# see `liq help orgs import`
orgs-import() {
  eval "$(setSimpleOptions IMPORT_REFS:r -- "$@")"
  local PKG_NAME BASENAME ORG_NPM_NAME
  projects-import --set-name PKG_NAME "$@"
  # TODO: we can refine our logic here by indicating whether project is already imported or not.

  # TODO: check that the package is a 'base' org, and if not, skip and echowarn "This is not necessarily a problem."
  mkdir -p "${LIQ_ORG_DB}"
  projectsSetPkgNameComponents "$PKG_NAME"
  # If '--import-refs', then not surprising to find extant company.
  if [[ -L "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]] && [[ -z $IMPORT_REFS ]]; then
    echowarn "Found possible remnant file:\n${LIQ_ORG_DB}/${PKG_ORG_NAME}\n\nWill attempt to delete and continue. Refer to 'ls' output results below for more info."
    ls -l "${LIQ_ORG_DB}"
    rm "${LIQ_ORG_DB}/${PKG_ORG_NAME}"
    echo
  fi
  [[ -L "${LIQ_ORG_DB}/${PKG_ORG_NAME}" ]] \
    || (
      cd "${LIQ_ORG_DB}"
      ln -s "../playground/${PKG_ORG_NAME}/${PKG_BASENAME}" "${LIQ_ORG_DB}/${PKG_ORG_NAME}"
    )

  if [[ -n "${IMPORT_REFS}" ]]; then
    local REF_REPO
    orgs-lib-source-settings "$(dirname "$PKG_NAME")"
    for REF_REPO in ORG_POLICY_REPO ORG_SENSITIVE_REPO ORG_STAFF_REPO; do
      if [[ -n ${!REF_REPO:-} ]]; then
        projects-import ${!REF_REPO}
      fi
    done
  fi
}

# see `liq help orgs list`
orgs-list() {
  find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type l -exec basename '{}' \; | sort
}

orgs-refresh() {
  local OPTIONS
  OPTIONS="$(pre-options-liq-orgs) PROJECTS"
  eval "$(setSimpleOptions ${OPTIONS} -- "$@")"
  post-options-liq-orgs

  # This is silly at the moment, but in future when there are other things to refresh, this set's up a 'refresh all' as
  # the default if specific targets are not specified
  [[ -n "${PROJECTS}" ]] || PROJECTS=true

  [[ -z "${PROJECTS}" ]] || org-lib-refresh-projects
}

# see `liq help orgs show`
orgs-show() {
  eval "$(setSimpleOptions DIR PROJECT SETTINGS -- "$@")"
  findBase
  cd "${BASE_DIR}/.."
  local NPM_ORG
  NPM_ORG="$(basename "$PWD")"

  if ! [[ -e "${LIQ_ORG_DB}/${NPM_ORG}" ]]; then
    echoerrandexit "No base package found for '${NPM_ORG}'. Try:\nliq orgs import <base pkg|URL>"
  fi

  # Recall the org DB links the npm org name to the repo.
  { { [[ -n "$DIR" ]] && readlink "${LIQ_ORG_DB}/${NPM_ORG}"; } \
  || { [[ -n "$PROJECT" ]] && cat "${LIQ_ORG_DB}/${NPM_ORG}/package.json" | jq -r '.name'; } \
  || { [[ -n "$SETTINGS" ]] && cat "${LIQ_ORG_DB}/${NPM_ORG}/data/orgs/settings.sh"; } } || \
  { # the no specific format option
    cat <<EOF
Project: $(cat "${LIQ_ORG_DB}/${NPM_ORG}/package.json" | jq -r '.name')
Local dir:  $(readlink "${LIQ_ORG_DB}/${NPM_ORG}")
EOF
  }
}
