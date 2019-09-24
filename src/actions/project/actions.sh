requirements-project() {
  if [[ "${ACTION}" != "create" ]] && [[ "${ACTION}" != "import" ]]; then
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
  local TMP PROJ_STAGE PROJ_NAME TEMPLATE_URL

  TMP=$(setSimpleOptions TYPE= TEMPLATE:T= ORIGIN= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  PROJ_NAME="${1}"

  if [[ -n "$TYPE" ]] && [[ -n "$TEMPLATE" ]]; then
    echoerrandexit "You specify either project 'type' or 'template, but not both.'"
  elif [[ -z "$TYPE" ]] && [[ -z "$TEMPLATE" ]]; then
    echoerrandexit "You must specify one of 'type' or 'template'."
  elif [[ -n "$TEMPLATE" ]]; then
    # determine if package or URL
    : # TODO: we do this in import too; abstract?
  else # it's a type
    case "$TYPE" in
      bare)
        if [[ -z "$ORIGIN" ]]; then
          echoerrandexit "Creating a 'raw' project, '--origin' must be specified."
        fi
        TEMPLATE_URL="$ORIGIN";;
      *)
        echoerrandexit "Unknown 'type'. Try one of: bare"
    esac
  fi
  projectCheckGitAndClone "$TEMPLATE_URL"
  cd "$PROJ_STAGE"
  # re-orient the origin from the template to the ORIGIN URL
  git remote set-url origin "${ORIGIN}"
  git remote set-url origin --push "${ORIGIN}"
  if [[ -f "package.json" ]]; then
    echoerr "This project already has a 'project.json' file. Will continue as import.\nIn future, try:\nliq import $PROJ_NAME"
  else
    local SCOPE
    SCOPE=$(dirname "$PROJ_NAME")
    if [[ -n "$SCOPE" ]]; then
      npm init --scope "${SCOPE}"
    else
      npm init
    fi
    git add package.json
  fi
  cd
  projectMoveStaged
}

project-import() {
  local PROJ_SPEC PROJ_NAME PROJ_URL PROJ_STAGE

  if [[ "$1" == *:* ]]; then # it's a URL
    PROJ_URL="${1}"
    projectCheckGitAndClone "$PROJ_URL"
    PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'")
    projectCheckInPlayground "$PROJ_NAME"
  else # it's an NPM package
    PROJ_NAME="${1}"
    projectCheckInPlayground "$PROJ_NAME"
    # Note: NPM will accept git URLs, but this saves us a step, let's us check if in playground earlier, and simplifes branching
    PROJ_URL=$(npm view "$PROJ_NAME" repository.url) \
      || echoerrandexit "Did not find expected NPM package '${PROJ_NAME}'. Did you forget the '--url' option?"
    PROJ_URL=${PROJ_URL##git+}
    projectCheckGitAndClone "$PROJ_URL"
  fi
  projectMoveStaged

  echo "'$PROJ_NAME' imported into playground."
}

project-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}

project-save() {
  echoerrandexit "The 'save' action is not yet implemented."
}
