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
  local PROJECT_URL="${1:-}"
  requireArgs "$PROJECT_URL" || exit 1
  requireWorkspaceConfig
  if [[ -f "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}" ]]; then
    source "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}"
    cd "$BASE_DIR"
    git clone "${PROJECT_HOME}"
    PROJECT_MIRRORS=${PROJECT_MIRRORS:-}
    if [[ -n "$PROJECT_MIRRORS" ]]; then
      cd "$PROJECT_URL"
      git remote set-url --add --push origin "${PROJECT_HOME}"
      for MIRROR in $PROJECT_MIRRORS; do
        git remote set-url --add --push origin "$MIRROR"
      done
    fi
  else
    (cd "${BASE_DIR}"
     git clone "$PROJECT_URL")
    # TODO: suport a 'project fork' that resets the _PROJECT_PUB_CONFIG file?
    local PROJECT_NAME=`basename "${PROJECT_URL}"`
    if [[ -n `expr "$PROJECT_NAME" : '.*\(\.git\)'` ]]; then
      PROJECT_NAME=${PROJECT_NAME::${#PROJECT_NAME}-4}
    fi
    cd "$BASE_DIR/$PROJECT_NAME"
    git remote set-url --add --push origin "${PROJECT_URL}"
    touch .catalyst # TODO: switch to _PROJECT_CONFIG
    if [[ -f "$_PROJECT_PUB_CONFIG" ]]; then
      cp "$_PROJECT_PUB_CONFIG" "$BASE_DIR/$_WORKSPACE_DB/projects/"
    else
      requireCatalystfile
      PROJECT_HOME="$PROJECT_URL"
      updateProjectPubConfig
      echoerr "Please add the '${_PROJECT_PUB_CONFIG}' file to the git repo."
    fi
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
