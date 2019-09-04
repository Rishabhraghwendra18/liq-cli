requirements-project() {
  if [[ "${ACTION}" != "init" ]]; then
    sourceCatalystfile
  fi
}

project-close() {
  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi

  cd "$LIQ_PLAYGROUND"
  if [[ -d "$PROJECT_NAME" ]]; then
    cd "$PROJECT_NAME"
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $(git status --porcelain 2>/dev/null| grep "^??" || true | wc -l) == 0 )); then
        if [[ `git rev-parse --verify master` == `git rev-parse --verify origin/master` ]]; then
          cd "$LIQ_PLAYGROUND"
          rm -rf "$PROJECT_NAME" && echo "Removed project '$PROJECT_NAME'."
          # now check to see if we have an empty "org" dir
          local ORG_NAME
          ORG_NAME=$(dirname "${PROJECT_NAME}")
          if [[ "$ORG_NAME" != "." ]] && (( 0 == $(ls "$ORG_NAME" | wc -l) )); then
            rmdir "$ORG_NAME"
          fi
        else
          echoerrandexit "Not all changes have been pushed to master." 1
        fi
      else
        echoerrandexit "Found untracked files." 1
      fi
    else
      echoerrandexit "Found uncommitted changes." 1
    fi
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
  # TODO: need to check whether the project is linked to other projects
}

project-create() {
  echoerrandexit "'project create not yet implemented'"
  # re-orient the origin from the template to the ORIGIN URL
  local TMP
  TMP=$(setSimpleOptions TYPE= TEMPLATE:T= ORIGIN= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  local PROJECT_NAME="${1}"
  local TEMPLATE_URL
  if [[ -n "$TYPE" ]] && [[ -n "$TEMPLATE" ]]; then
    echoerrandexit "You specify either project 'type' or 'template, but not both.'"
  elif [[ -z "$TYPE" ]] && [[ -z "$TEMPLATE" ]]; then
    echoerrandexit "You must specify one of 'type' or 'template'."
  elif [[ -n "$TEMPLATE" ]]; then
    # determine if package or URL
    : # TODO: we do this in import too; abstract?
  else # it's a type
    : # TODO: use the default type URLs
  fi
  cd "$LIQ_STAGING"
  git clone "$TEMPLATE_URL"
  # TODO: determine dir by same method used in import
  # cd IMPORT_DIR
  git remote set-url origin "${ORIGIN}"
  git remote set-url origin --push "${ORIGIN}"
  # cd "$LIQ_STAGING"
  local ORG_NAME=$(dirname "$PROJECT_NAME")
  # stuff
  # update package.json
}

project-import() {
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
      echoerrandexit "Did not find expected project direcotry '$PROJ_STAGE' in staging."
    fi
  }

  local PROJ_SPEC PROJ_NAME PROJ_URL PROJ_STAGE
  if [[ "$1" == *://* ]]; then # it's a URL
    PROJ_URL="${1}"
    checkGitAndClone "$PROJ_URL"
    PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'")
    checkInPlayground
  else # it's an NPM package
    PROJ_NAME="${1}"
    checkInPlayground
    # Note: NPM will accept git URLs, but this saves us a step, let's us check if in playground earlier, and simplifes branching
    PROJ_URL=$(npm view "$PROJ_NAME" repository.url) \
      || echoerrandexit "Did not find expected NPM package '${PROJ_NAME}'. Did you forget the '--url' option?"
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

project-save() {
  echoerrandexit "The 'save' action is not yet implemented."
}
