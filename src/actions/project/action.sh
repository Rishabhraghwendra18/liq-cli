project-init_git_setup() {
  local CURR_ORIGIN=`git config --get remote.origin.url || true`
  if [[ -z "$CURR_ORIGIN" ]]; then
    if [[ -z "${ORIGIN_URL:-}" ]]; then
      echo
      echo "You can set up the remote origin now, if not already done, which will be cloned into"
      echo "the current directory if it is empty. Otherwise, the current directory will be"
      echo "initialized as a git repo if not already done, and the remote origin added if an "
      echo "origin URL provided."
      read -p 'git origin URL: ' ORIGIN_URL
    fi

    local HAS_FILES=`ls "${BASE_DIR}" | wc -w`
    if [[ -n "$ORIGIN_URL" ]] && (( $HAS_FILES == 0 )); then
      git clone -q "$ORIGIN_URL" "${BASE_DIR}" && echo "Cloned '$ORIGIN_URL' into '${BASE_DIR}'."
    else
      if [[ ! -d "${BASE_DIR}/.git" ]]; then
        git init "${BASE_DIR}"
      fi
      if [[ -n "$ORIGIN_URL" ]]; then
        get remote add origin "$ORIGIN_URL"
      fi
    fi
  fi

  addLineIfNotPresentInFile "${BASE_DIR}/.gitignore" '.catalyst' # TODO: change to _PROJECT_CONFIG
}

project-init() {
  local FOUND_PROJECT=Y
  sourceCatalystfile 2> /dev/null || FOUND_PROJECT=N
  if [[ $FOUND_PROJECT == Y ]]; then
    echoerr "It looks like there's already a '.catalyst' file in place. Bailing out..."
    exit 1
  else
    BASE_DIR="$PWD"
  fi
  # TODO: verify that the parent directory is a workspace?

  project-init_git_setup

  if [[ -z "$ORGANIZATION_ID" ]]; then
    echo "First we need to determine your 'organization ID' where your project lives."
    echo "If the local project is not currentyl associated with a GCP Project, it's fine to leave this value blank."
    local FALLBACK=N
    handleOpenOrgSettings() {
      open ${_ORG_ID_URL} || FALLBACK=Y
      echo
    }
    handleManual() {
      echo 'If you have access to the GCP console, you can find it here:'
      echo $_ORG_ID_URL
      echo 'or find further instructions here:'
      echo 'https://cloud.google.com/resource-manager/docs/creating-managing-organization#retrieving_your_organization_id'
      echo
    }
    yesno 'Would you like me to try and open the Google Console for you? (Y/n) ' Y handleOpenOrgSettings handleManual
    if [[ $FALLBACK == 'Y' ]]; then handleManual; fi
    read -p 'Organization ID: ' ORGANIZATION_ID
  fi
  updateCatalystFile 'suppress-msg'

  if [[ -z "$BILLING_ACCOUNT_ID" ]]; then
    handleBilling() {
      echo "Then let's get your billing id."
      project-set-billing
    }
    handleNoBilling() {
      echo "After setting up billing, you can set the billing account with 'catalyst project set-billing'."
      echo
      updateCatalystFile # so the user gets the update message
    }
    yesno "Have you set up billing for this account yet? (Y\n) " Y handleBilling handleNoBilling
  fi
  updateCatalystFile
}

project-import() {
  setupMirrors() {
    local PROJECT_DIR="$1"
    local PROJECT_HOME="$2"
    local PROJECT_MIRRORS="$3"

    if [[ -n "$PROJECT_MIRRORS" ]]; then
      cd "$PROJECT_DIR"
      git remote set-url --add --push origin "${PROJECT_HOME}"
      for MIRROR in $PROJECT_MIRRORS; do
        git remote set-url --add --push origin "$MIRROR"
      done
    fi
  }

  local PROJECT_URL="${1:-}"
  requireArgs "$PROJECT_URL" || exit 1
  requireWorkspaceConfig
  if [[ -f "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}" ]]; then
    source "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}"
    cd "$BASE_DIR"
    git clone --quiet "${PROJECT_HOME}" && echo "'$ROJECT_URL' imported into workspace."
    setupMirrors "$PROJECT_URL" "$PROJECT_HOME" "${PROJECT_MIRRORS:-}"
  else
    local PROJECT_NAME=`basename "${PROJECT_URL}"`
    if [[ -n `expr "$PROJECT_NAME" : '.*\(\.git\)'` ]]; then
      PROJECT_NAME=${PROJECT_NAME::${#PROJECT_NAME}-4}
    fi

    (cd "${BASE_DIR}"
     git clone --quiet "$PROJECT_URL" && echo "'${PROJECT_NAME}' imported into workspace.")
    # TODO: suport a 'project fork' that resets the _PROJECT_PUB_CONFIG file?

    local PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"
    cd "$PROJECT_DIR"
    git remote set-url --add --push origin "${PROJECT_URL}"
    touch .catalyst # TODO: switch to _PROJECT_CONFIG
    if [[ -f "$_PROJECT_PUB_CONFIG" ]]; then
      cp "$_PROJECT_PUB_CONFIG" "$BASE_DIR/$_WORKSPACE_DB/projects/"
      source "$_PROJECT_PUB_CONFIG"
      setupMirrors "$PROJECT_DIR" "$PROJECT_URL" "${PROJECT_MIRRORS:-}"
    else
      requireCatalystfile
      PROJECT_HOME="$PROJECT_URL"
      updateProjectPubConfig
      echoerr "Please add the '${_PROJECT_PUB_CONFIG}' file to the git repo."
    fi
  fi
}

project-close() {
  local PROJECT_NAME="${1:-}"

    # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    cd "$BASE_DIR"
    PROJECT_NAME=`basename $PWD`
  fi
  # TODO: confirm this
  requireWorkspaceConfig
  cd "$BASE_DIR"
  if [[ -d "$PROJECT_NAME" ]]; then
    cd "$PROJECT_NAME"
    # Is everything comitted?
    # credit: https://stackoverflow.com/a/8830922/929494
    if git diff --quiet && git diff --cached --quiet; then
      if (( $(git status --porcelain 2>/dev/null| grep "^??" || true | wc -l) == 0 )); then
        if [[ `git rev-parse --verify master` == `git rev-parse --verify origin/master` ]]; then
          cd "$BASE_DIR"
          rm -rf "$PROJECT_NAME" && echo "Removed project '$PROJECT_NAME'."
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
}

project-add-mirror() {
  local GIT_URL="${1:-}"
  requireArgs "$GIT_URL" || exit 1
  source "$BASE_DIR/${_PROJECT_PUB_CONFIG}"
  PROJECT_MIRRORS=${PROJECT_MIRRORS:-}
  if [[ $PROJECT_MIRRORS = *$GIT_URL* ]]; then
    echoerr "Remote URL '$GIT_URL' already in mirror list."
  else
    git remote set-url --add --push origin "$GIT_URL"
    if [[ -z "$PROJECT_MIRRORS" ]]; then
      PROJECT_MIRRORS=$GIT_URL
    else
      PROJECT_MIRRORS="$PROJECT_MIRRORS $GIT_URL"
    fi
    updateProjectPubConfig
  fi
}

project-set-billing() {
  handleOpenBilling() {
    open "${_BILLING_ACCT_URL}${ORGANIZATION_ID}" || FALLBACK=Y
    echo
  }
  handleManual() {
    echo "Check this page for existing billing account or to set one up:"
    echo "${_BILLING_ACCT_URL}${ORGANIZATION_ID}"
    echo
  }
  yesno "Would you like me to open the billing page for you? (Y/n) " Y handleOpenBilling handleManual
  if [[ $FALLBACK == 'Y' ]]; then handleManual; fi
  read -p 'Billing account ID: ' BILLING_ACCOUNT_ID
  updateCatalystFile
}

project-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'catalyst go configure'."
    exit 1
  fi
  colorerr "bash -c 'cd $GOPATH/src/unodelivers.com/app; gcloud app deploy'"
}
