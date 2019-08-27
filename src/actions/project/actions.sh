requirements-project() {
  if [[ "${ACTION}" != "init" ]]; then
    sourceCatalystfile
  fi
}

project-import() {
  local TMP
  TMP=$(setSimpleOptions URL -- "$@") \
    || ( help project import; echoerrandexit "Bad options." )
  eval "$TMP"

  local PROJ_SPEC PROJ_NAME PROJ_URL PROJ_STAGE

  checkInPlayground() {
    if [[ -d "${LIQ_PLAYGROUND}/${PROJ_NAME}" ]]; then
      echo "'$PROJ_NAME' is already in the playground."
      exit 0
    fi
  }

  checkGitAndClone() {
    local URL="${1}"
    ssh -qT git@github.com 2> /dev/null || if [ $? -ne 1 ]; then echoerrandexit "Could not connect to github; add your github key with 'ssh-add'."; fi
    local STAGING="${LIQ_PLAYGROUND}/.staging"
    mkdir -p "$STAGING"
    cd "$STAGING"
    git clone --quiet "${URL}" || echoerrandexit "Failed to clone "
    PROJ_STAGE=$(basename "$PROJ_URL")
    PROJ_STAGE="${PROJ_STAGE%.*}"
    PROJ_STAGE="${STAGING}/${PROJ_STAGE}"
    if [[ ! -d "$PROJ_STAGE" ]]; then
      echoerrandexit "Did not find expected project direcotry '$PROJ_DIR' in staging."
    fi
  }

  local PROJ_SPEC PROJ_NAME PROJ_URL PROJ_STAGE
  if [[ -n "$URL" ]]; then
    PROJ_URL="${1}"
    checkGitAndClone "$PROJ_URL"
    PROJ_NAME=$(cat "$PROJ_DIR/package.json" | jq --raw-output '.name' | tr -d "'")
    checkInPlayground
  else # it's an NMP project name
    PROJ_NAME="${1}"
    checkInPlayground
    PROJ_URL=$(npm view "$PROJ_NAME" repository.url)
    PROJ_URL=${PROJ_URL##git+}
    checkGitAndClone "$PROJ_URL"
  fi
  local TRUNC_NAME
  TRUNC_NAME="$(dirname "$PROJ_NAME")"
  mkdir -p "${LIQ_PLAYGROUND}/${TRUNC_NAME}"
  mv "$PROJ_STAGE" "$LIQ_PLAYGROUND/${TRUNC_NAME}" \
    || echoerrandexit "Could not moved staged '$PROJ_NAME' to playground. See above for details."

  echo "'$PROJ_NAME' imported into playground."
}

project-init() {
  echoerrandexit "The 'init' action is disabled in this version pending further testing."
  local FOUND_PROJECT=Y
  sourceCatalystfile 2> /dev/null || FOUND_PROJECT=N
  if [[ $FOUND_PROJECT == Y ]]; then
    echoerr "It looks like there's already a '.catalyst' file in place. Bailing out..."
    exit 1
  else
    BASE_DIR="$PWD"
  fi
  # TODO: verify that the parent directory is a playground?

  projectGitSetup
}

project-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}
