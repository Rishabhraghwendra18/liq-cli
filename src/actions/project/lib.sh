projectCheckIfInPlayground() {
  local PROJ_NAME="${1}"
  if [[ -d "${LIQ_PLAYGROUND}/$(orgsCurrentOrg --require)/${PROJ_NAME}" ]]; then
    echo "'$PROJ_NAME' is already in the playground."
    return 0
  fi
}

projectCheckGitAuth() {
  # if we don't supress the output, then we get noise even when successful
  ssh -qT git@github.com 2> /dev/null || if [ $? -ne 1 ]; then
    echoerrandexit "Could not connect to github; add your github key with 'ssh-add'."
  fi
}

projectsGetUpstreamUrl() {
  local PROJ_NAME="${1}"

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg --require)"
  cd "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJ_NAME}"
  git config --get remote.upstream.url \
		|| echoerrandexit "Failed to get upstream remote URL for ${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJ_NAME}"
}

# expects STAGING and PROJ_STAGE to be set declared by caller(s)
projectResetStaging() {
  local PROJ_NAME="${1}"
  STAGING="${LIQ_PLAYGROUND}/$(orgsCurrentOrg --require)/.staging"
  rm -rf "${STAGING}"
  mkdir -p "${STAGING}"

  PROJ_STAGE="$PROJ_NAME"
  PROJ_STAGE="${PROJ_STAGE%.*}" # remove '.git' if present
  PROJ_STAGE="${STAGING}/${PROJ_STAGE}"
}

# Expects 'PROJ_STAGE' to be declared local by the caller.
projectClone() {
  local URL="${1}"

  projectCheckGitAuth

  local STAGING
  projectResetStaging $(basename "$URL")
  cd "$STAGING"

  git clone --quiet --origin upstream "${URL}" || echoerrandexit "Failed to clone."

  if [[ ! -d "$PROJ_STAGE" ]]; then
    echoerrandexit "Did not find expected project direcotry '$PROJ_STAGE' in staging."
  fi
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

  projectCheckGitAuth

  local PROJ_NAME ORG_URL GITHUB_NAME
  PROJ_NAME=$(basename "$URL")
  ORG_URL=$(dirname "$URL")
  projectHubWhoami GITHUB_NAME
  FORK_URL="$(echo "$ORG_URL" | sed 's|[a-zA-Z0-9-]*$||')/${GITHUB_NAME}/${PROJ_NAME}"

  local STAGING
  projectResetStaging $PROJ_NAME
  cd "$STAGING"

  echo -n "Checking for existing fork at '${FORK_URL}'... "
  git clone --dry-run --quiet --origin workspace "${FORK_URL}" \
  && { \
    # Be sure and exit on errors to avoid a failure here and then executing the || branch
    echo "found existing fork."
    cd $PROJ_STAGE || echoerrandexit "Did not find expected staging dir: $PROJ_STAGE"
    echo "Updating remotes..."
    git remote add upstream "$URL" || echoerrandexit "Problem setting upstream URL."
    git branch -u upstream/master master
  } \
  || { \
    echo "none found; cloning source."
    local GITHUB_NAME
    git clone --quiet --origin upstream "${URL}" || echoerrandexit "Could not clone source."
    cd $PROJ_STAGE
    echo "Creating fork..."
    hub fork --remote-name workspace
    git branch -u upstream/master master
  }
}

# Expects caller to have defined PROJ_NAME and PROJ_STAGE
projectMoveStaged() {
  local TRUNC_NAME CURR_ORG
  TRUNC_NAME="$(dirname "$PROJ_NAME")"
  CURR_ORG=$(orgsCurrentOrg --require)
  mkdir -p "${LIQ_PLAYGROUND}/${CURR_ORG}/${TRUNC_NAME}"
  mv "$PROJ_STAGE" "$LIQ_PLAYGROUND/${CURR_ORG}/${TRUNC_NAME}" \
    || echoerrandexit "Could not moved staged '$PROJ_NAME' to playground. See above for details."
}
