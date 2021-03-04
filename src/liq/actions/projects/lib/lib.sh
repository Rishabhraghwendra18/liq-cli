projectCheckIfInPlayground() {
  local PROJ_NAME="${1/@/}"
  if [[ -d "${LIQ_PLAYGROUND}/${PROJ_NAME}" ]]; then
    echo "'$PROJ_NAME' is already in the playground."
    return 0
  else
    return 1
  fi
}

projectsGetUpstreamUrl() {
  local PROJ_NAME="${1/@/}"

  cd "${LIQ_PLAYGROUND}/${PROJ_NAME}"
  git config --get remote.upstream.url \
		|| echoerrandexit "Failed to get upstream remote URL for ${LIQ_PLAYGROUND}/${PROJ_NAME}"
}

# expects STAGING and PROJ_STAGE to be set declared by caller(s)
projectResetStaging() {
  local PROJ_NAME="${1}"
  STAGING="${LIQ_PLAYGROUND}/.staging"
  rm -rf "${STAGING}"
  mkdir -p "${STAGING}"

  PROJ_STAGE="$PROJ_NAME"
  PROJ_STAGE="${PROJ_STAGE%.*}" # remove '.git' if present
  PROJ_STAGE="${STAGING}/${PROJ_STAGE}"
}

# Expects 'PROJ_STAGE' to be declared local by the caller.
projectClone() {
  local URL="${1}"
  local ORIGIN_NAME="${2:-upstream}"

  check-git-access

  local STAGING
  projectResetStaging $(basename "$URL")
  cd "$STAGING"

  echo "Cloning '${ORIGIN_NAME}'..."
  git clone --quiet --origin "$ORIGIN_NAME" "${URL}" || echoerrandexit "Failed to clone."

  if [[ ! -d "$PROJ_STAGE" ]]; then
    echoerrandexit "Did not find expected project direcotry '$PROJ_STAGE' in staging after cloning repo."
  fi
}

# Returns true if the current working project has the dependency as either dep, dev, or peer.
projects-lib-has-any-dep() {
  local PROJ="${1}"
  local DEP="${2}"

  cat "${LIQ_PLAYGROUND}/${PROJ/@/}/package.json" | jq -r '.dependencies + .devDependencies + .peerDependencies + {} | keys' | grep -qE '"@?'${DEP}'"'
}

projectHubWhoami() {
  local VAR_NAME="${1}"

  if [[ ! -f ~/.config/hub ]]; then
    echo "Need to establish GitHub connection..."
    hub api https://api.github.com/user > /dev/null
  fi
  local WHOAMI
  WHOAMI=$(cat ~/.config/hub | grep 'user:' | sed 's/^[[:space:]]*-[[:space:]]*user:[[:space:]]*//')
  eval $VAR_NAME=$WHOAMI
}

projectForkClone() {
  local URL="${1}"

  check-git-access

  local PROJ_NAME ORG_URL GITHUB_NAME
  PROJ_NAME=$(basename "$URL")
  ORG_URL=$(dirname "$URL")
  projectHubWhoami GITHUB_NAME
  FORK_URL="$(echo "$ORG_URL" | sed 's|[a-zA-Z0-9-]*$||')/${GITHUB_NAME}/${PROJ_NAME}"

  local STAGING
  projectResetStaging $PROJ_NAME
  cd "$STAGING"

  echo -n "Checking for existing fork at '${FORK_URL}'... "
  git clone --quiet --origin workspace "${FORK_URL}" 2> /dev/null \
  && { \
    # Be sure and exit on errors to avoid a failure here and then executing the || branch
    echo "found existing fork."
    cd $PROJ_STAGE || echoerrandexit "Did not find expected staging dir: $PROJ_STAGE"
    echo "Updating remotes..."
    git remote add upstream "$URL" || echoerrandexit "Problem setting upstream URL."
    git fetch upstream || echoerrandexit "Could not fetch upstream data."
    git branch -u upstream/master master || echoerrandexit "Failed to configure upstream master."
    git pull || echoerrandexit "Failed to pull from upstream master."
  } \
  || { \
    echo "none found; cloning source."
    local GITHUB_NAME
    git clone --quiet --origin upstream "${URL}" || echoerrandexit "Could not clone source."
    cd $PROJ_STAGE
    echo "Creating fork..."
    hub fork --remote-name workspace > /dev/null
    git branch --quiet -u upstream/master master
  }
}

# Expects caller to have defined PROJ_NAME and PROJ_STAGE
projectMoveStaged() {
  local NPM_ORG
  local PROJ_NAME="${1}"
  local PROJ_STAGE="${2}"
  NPM_ORG="$(dirname "$PROJ_NAME")"
  NPM_ORG="${NPM_ORG/@/}"
  mkdir -p "${LIQ_PLAYGROUND}/${NPM_ORG}"
  echo "Moving staging dir to playground..."
  mv "$PROJ_STAGE" "$LIQ_PLAYGROUND/${NPM_ORG}" \
    || echoerrandexit "Could not moved staged '$PROJ_NAME' to playground. See above for details."
}

projectsRunPackageScript() {
  eval "$(setSimpleOptions IGNORE_MISSING SCRIPT_ONLY -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  local ACTION="$1"; shift

  cd "${BASE_DIR}"
  if cat package.json | jq -e "(.scripts | keys | map(select(. == \"$ACTION\")) | length) == 1" > /dev/null; then
    npm run-script "${ACTION}"
  elif [[ -n "$SCRIPT_ONLY" ]] && [[ -z "$IGNORE_MISSING" ]]; then # SCRIPT_ONLY is a temp. workaround to implement future behaior. See note below.
    echoerrandexit "Did not find expected NPM script for '$ACTION'."
  elif [[ -z "$SCRIPT_ONLY" ]]; then
    # TODO: drop this; require that the package interface with catalyst-scripts
    # through the the 'package-scripts'. This will avoid confusion and also
    # allow "plain npm" to run more of what can be run. It will also allow users
    # to override the scripts if they really want to. (But we should catch) that
    # on an audit.
    local CATALYST_SCRIPTS=$(npm bin)/catalyst-scripts
    if [[ ! -x "$CATALYST_SCRIPTS" ]]; then
      # TODO: offer to install and re-run
      echoerr "This project does not appear to be using 'catalyst-scripts'. Try:"
      echoerr ""
      echoerrandexit "npm install --save-dev @liquid-labs/catalyst-scripts"
    fi
    # kill the debug trap because if the script exits with an error (as in a
    # failed lint), that's OK and the debug doesn't provide any useful info.
    "${CATALYST_SCRIPTS}" "${BASE_DIR}" $ACTION || true
  fi
}

# Accepts single NPM package name and exports 'PKG_ORG_NAME' and 'PKG_BASENAME'.
projectsSetPkgNameComponents() {
  PKG_ORG_NAME="$(dirname ${1/@/})"
  PKG_BASENAME="$(basename "$1")"
}

projects-lib-is-at-production() {
  local REPO_PATH="${1}"

  (
    cd "${REPO_PATH}"
    # Redirect stderr since production tag may not exist. That's OK for the test logic, but generates unwanted output.
    [[ $(git rev-parse HEAD) == $(git rev-parse ${PRODUCTION_TAG} 2> /dev/null || true) ]]
  )
}
