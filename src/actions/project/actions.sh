requirements-project() {
  :
}

project-close() {
  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    findBase
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi

  cd "$LIQ_PLAYGROUND"
  if [[ -d "$PROJECT_NAME" ]]; then
    cd "$PROJECT_NAME"
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $(git status --porcelain 2>/dev/null| grep '^??' || true | wc -l) == 0 )); then
        if [[ $(git rev-parse --verify master) == $(git rev-parse --verify origin/master) ]]; then
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
      echoerrandexit "Found uncommitted changes.\n$(git status --porcelain)" 1
    fi
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
  # TODO: need to check whether the project is linked to other projects
}

project-create() {
  echoerrandexit "'create' needs to be reworked for forks."
  local TMP PROJ_STAGE PROJ_NAME TEMPLATE_URL
  TMP=$(setSimpleOptions TYPE= TEMPLATE:T= ORIGIN= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options."; )
  eval "$TMP"

  PROJ_NAME="${1}"
  if [[ -z "$PROJ_NAME" ]]; then
    echoerrandexit "Must specify project name (1st argument)."
  fi

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
  projectClone "$TEMPLATE_URL"
  cd "$PROJ_STAGE"
  # re-orient the origin from the template to the ORIGIN URL
  git remote set-url origin "${ORIGIN}"
  git remote set-url origin --push "${ORIGIN}"
  if [[ -f "package.json" ]]; then
    echowarn --no-fold "This project already has a 'project.json' file. Will continue as import.\nIn future, try:\nliq import $PROJ_NAME"
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
  local TMP
  TMP=$(setSimpleOptions NO_FORK:F -- "$@")
  eval "$TMP"

  if [[ "$1" == *:* ]]; then # it's a URL
    PROJ_URL="${1}"
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$PROJ_URL"
    else
      projectForkClone "$PROJ_URL"
    fi
    if PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'"); then
      projectCheckIfInPlayground "$PROJ_NAME"
    else
      rm -rf "$PROJ_STAGE"
      echoerrandexit -F "The specified source is not a valid Liquid Dev package (no 'package.json'). Try:\nliq project create --type=bare --origin='$PROJ_URL' <project name>"
    fi
  else # it's an NPM package
    PROJ_NAME="${1}"
    projectCheckIfInPlayground "$PROJ_NAME"
    # Note: NPM will accept git URLs, but this saves us a step, let's us check if in playground earlier, and simplifes branching
    PROJ_URL=$(npm view "$PROJ_NAME" repository.url) \
      || echoerrandexit "Did not find expected NPM package '${PROJ_NAME}'. Did you forget the '--url' option?"
    PROJ_URL=${PROJ_URL##git+}
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$PROJ_URL"
    else
      projectForkClone "$PROJ_URL"
    fi
  fi

  projectMoveStaged

  echo "'$PROJ_NAME' imported into playground."
}

project-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}

project-test() {
  local TMP
  # TODO https://github.com/Liquid-Labs/liq-cli/issues/27
  TMP=$(setSimpleOptions TYPES= NO_DATA_RESET:D GO_RUN= NO_START:S NO_SERVICE_CHECK:C -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -z "${NO_SERVICE_CHECK}" ]] \
     && ( [[ -z "${TEST_TYPES:-}" ]] \
       || echo "$TEST_TYPES" | grep -qE '(^|, *| +)int(egration)?(, *| +|$)' ); then
    requireEnvironment
    echo -n "Checking services... "
    if ! services-list --show-status --exit-on-stopped --quiet > /dev/null; then
      if [[ -z "${NO_START:-}" ]]; then
        services-start || echoerrandexit "Could not start services for testing."
      else
        echo "${red}necessary services not running.${reset}"
        echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\nliq packages test --types=unit\nliq services start"
      fi
    else
      echo "${green}looks good.${reset}"
    fi
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" runPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\nliq packages test --type=unit" $?
}
