project-setup_git_setup() {
  local HAS_FILES=`ls -a "${BASE_DIR}" | (grep -ve '^\.$' || true) | (grep -ve '^\.\.$' || true) | wc -w`
  local IS_GIT_REPO
  if [[ -d "${BASE_DIR}"/.git ]]; then
    IS_GIT_REPO='true'
  else
    IS_GIT_REPO='false'
  fi
  # first we test if set externally as environment variable (used in testing).
  if [[ -z "${ORIGIN_URL}" ]]; then
    ORIGIN_URL=`git config --get remote.origin.url || true`
    if [[ -z "${ORIGIN_URL:-}" ]]; then
      if [[ -z "${ORIGIN_URL:-}" ]]; then
        if (( $HAS_FILES == 0 )) && [[ $IS_GIT_REPO == 'false' ]]; then
          echo "The origin will be cloned, if provided."
        elif [[ -n "$ORIGIN_URL" ]] && [[ $IS_GIT_REPO == 'false' ]]; then
          echo "The current directory will be initialized as a git repo with the provided origin."
        else
          echo "The origin of this existing git repo will be set, if provided."
        fi
        read -p 'git origin URL: ' ORIGIN_URL
      fi
    fi # -z "$ORIGIN_URL" - git test
  fi # -z "$ORIGIN_URL" - external / global

  if [[ -n "$ORIGIN_URL" ]] && (( $HAS_FILES == 0 )) && [[ $IS_GIT_REPO == 'false' ]]; then
    git clone -q "$ORIGIN_URL" "${BASE_DIR}" && echo "Cloned '$ORIGIN_URL' into '${BASE_DIR}'."
  elif [[ -n "$ORIGIN_URL" ]] && [[ $IS_GIT_REPO == 'false' ]]; then
    git init "${BASE_DIR}"
    git remote add origin "$ORIGIN_URL"
  fi

  if [[ -d "${BASE_DIR}/.git" ]]; then
    git remote set-url --add --push origin "${ORIGIN_URL}"
  fi
  addLineIfNotPresentInFile "${BASE_DIR}/.gitignore" '.catalyst' # TODO: change to _PROJECT_CONFIG
  if [[ -n "$ORIGIN_URL" ]]; then
    PROJECT_HOME="$ORIGIN_URL"
    PROJECT_DIR="${BASE_DIR}"
    updateProjectPubConfig
    # TODO: the above overwrites the project BASE_DIR, which we rely on later. See https://github.com/Liquid-Labs/catalyst-cli/issues/2
    BASE_DIR="$PROJECT_DIR"
  fi
}

project-setup() {
  local FOUND_PROJECT=Y
  sourceCatalystfile 2> /dev/null || FOUND_PROJECT=N
  if [[ $FOUND_PROJECT == Y ]]; then
    echoerr "It looks like there's already a '.catalyst' file in place. Bailing out..."
    exit 1
  else
    BASE_DIR="$PWD"
  fi
  # TODO: verify that the parent directory is a workspace?

  project-setup_git_setup

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
  cd "$BASE_DIR"
  if [ -d "$PROJECT_URL" ]; then
    echo "It looks like '${PROJECT_URL}' has already been imported."
    exit 0
  fi
  if [[ -f "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}" ]]; then
    source "${BASE_DIR}/${_WORKSPACE_DB}/projects/${PROJECT_URL}"
    # TODO: this assumes SSH style access, which we should, but need to enforce
    # the 'ssh' will be denied with 1 if successful and 255 if no key found.
    ssh -qT git@github.com 2> /dev/null || if [ $? -ne 1 ]; then echoerrandexit "Could not connect to github; add your github key with 'ssh-add'."; fi
    git clone --quiet "${PROJECT_HOME}" && echo "'$PROJECT_URL' imported into workspace."
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

project-setup-scripts() {
  source `dirname $BASH_SOURCE`/../../../lib/files/find-exec.func.sh
  local CATALYST_SCRIPTS=`find-exec 'catalyst-scripts' "$BASE_DIR"`
  if [[ ! -x $CATALYST_SCRIPTS ]] && which -s npm; then
    cd $BASE_DIR && npm install @liquid-labs/catalyst-scripts
    CATALYST_SCRIPTS=$(npm bin)/catalyst-scripts
  fi
  if [[ -x $CATALYST_SCRIPTS ]]; then
    "$CATALYST_SCRIPTS" "$BASE_DIR" setup-scripts
  fi
}

_project_script() {
  local ACTION="$1"
  cd "${BASE_DIR}"
  if [[ "$ACTION" == 'build' ]] || [[ "$ACTION" == 'start' ]]; then
    source "$BASE_DIR/${_PROJECT_PUB_CONFIG}"
    if [[ "${IS_APP:-}" -eq 1 ]] || [[ "${BUILD_WITH_NPM:-}" -eq 1 ]]; then
      npm run $ACTION
      return
    fi
  fi
  # If we get here, then it's either an action we always handle with
  # catalyst-scripts or CRA is not used in the target project.

  local CATALYST_SCRIPTS=$(npm bin)/catalyst-scripts
  if [[ ! -x "$CATALYST_SCRIPTS" ]]; then
    echoerr "This project does not appear to be using 'catalyst-scripts'. Try:"
    echoerr ""
    echoerrandexit "npm install --save-dev @liquid-labs/catalyst-scripts"
  fi
  "${CATALYST_SCRIPTS}" "${BASE_DIR}" $ACTION
}

project-build() {
  _project_script build
}

project-start() {
  _project_script start
}

project-lint() {
  _project_script lint
}

project-lint-fix() {
  _project_script lint-fix
}

project-test() {
  _project_script pretest
  _project_script test
}

_require-npm-check() {
  if ! which -s npm-check; then
    echoerr "'npm-check' not found; could not check package status. Install with:"
    echoerr ''
    echoerr '    npm install -g npm-check'
    echoerr ''
    exit 10
  fi
}

project-npm-check() {
  _require-npm-check
  source "$BASE_DIR/${_PROJECT_PUB_CONFIG}"
  if npm-check ${NPM_CHECK_OPTS:-}; then
    return 0
  else
    return 1
  fi

}

project-npm-update() {
  _require-npm-check
  source "$BASE_DIR/${_PROJECT_PUB_CONFIG}"
  npm-check -u ${NPM_CHECK_OPTS:-}
  # TODO: by default, it should also swap out any 'file:' based installation of
  # internal projects with the latest published internal
}

project-qa() {
  echo "Checking local repo status..."
  work-report
  echo "Checking package dependencies..."
  project-npm-check
  echo "Linting code..."
  project-lint
}

_project-link() {
  local LINK_PROJECT="${1:-}"
  requireArgs "$LINK_PROJECT" || exit 1
  local PACKAGE_REL_PATH="${2:-}" # this one's optional

  local CURR_PROJECT_DIR="${BASE_DIR}"
  cd "${CURR_PROJECT_DIR}"
  local OUR_PACKAGE_DIR=`find . -name "package.json" -not -path "*/node_modules/*"`
  local PACKAGE_COUNT=`echo "$OUR_PACKAGE_DIR" | wc -l`
  if (( $PACKAGE_COUNT == 0 )); then
    echoerrandexit "Did not find local 'package.json'."
  elif (( $PACKAGE_COUNT > 1 )); then
    # TODO: requrie the user to be in the dir with the package.json
    echoerrandexit "Found multiple 'package.json' files; this is currently a limitation, perform linking manually."
  fi

  if [[ -z "$OUR_PACKAGE_DIR" ]]; then
    echoerrandexit "Did not find 'package.json' in current project"
  else
    OUR_PACKAGE_DIR=`dirname "$OUR_PACKAGE_DIR"`
  fi

  requireWorkspaceConfig
  cd "${BASE_DIR}" # now workspace base
  if [[ ! -d "$LINK_PROJECT" ]]; then
    echoerrandexit "Did not find project '${LINK_PROJECT}' to link."
  fi

  cd "$LINK_PROJECT"
  # determine the package-to-link's package.json
  local LINK_PACKAGE
  if [[ -n "$PACKAGE_REL_PATH" ]]; then
    if [[ -f "$PACKAGE_REL_PATH/package.json" ]]; then
      LINK_PACKAGE="$PACKAGE_REL_PATH/package.json"
    else
      echoerrandexit "Did not find 'package.json' under specified path '$PACKAGE_REL_PATH'."
    fi
  else
    LINK_PACKAGE=`find . -name "package.json" -not -path "*/node_modules/*"`
    local LINK_PACKAGE_COUNT=`echo "$LINK_PACKAGE" | wc -l`
    if (( $LINK_PACKAGE_COUNT == 0 )); then
      echoerrandexit "Did not find 'package.json' in '$LINK_PROJECT'."
    elif (( $LINK_PACKAGE_COUNT > 1 )); then
      echoerrandexit "Found multiple packages to link in '$LINK_PROJECT'; specify relative package path."
    fi
  fi

  local LINK_PACKAGE_NAME=`node -e "const fs = require('fs'); const package = JSON.parse(fs.readFileSync('${LINK_PACKAGE}')); console.log(package.name);"`
  npm -q link

  cd "$CURR_PROJECT_DIR"
  cd "$OUR_PACKAGE_DIR"
  npm -q link "$LINK_PACKAGE_NAME"

  echo "$LINK_PACKAGE_NAME"
}

project-link() {
  local LINK_PROJECT="${1:-}"
  local LINK_PACKAGE_NAME=`_project-link "$@" | tail -n 1`
  if [[ -n "$LINK_PACKAGE_NAME" ]]; then
    npm install --save "file:/usr/local/lib/node_modules/${LINK_PACKAGE_NAME}"
    echo "Linked Catalyst project '$LINK_PROJECT' as dependency."
  fi
}

project-link-dev() {
  local LINK_PROJECT="${1:-}"
  local LINK_PACKAGE_NAME=`_project-link "$@" | tail -n 1`
  if [[ -n "$LINK_PACKAGE_NAME" ]]; then
    npm install --save-dev "file:/usr/local/lib/node_modules/${LINK_PACKAGE_NAME}"
    echo "Linked Catalyst project '$LINK_PROJECT' as dev dependency."
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

project-diff-master() {
  git diff HEAD..$(git merge-base master HEAD)
}

project-ignore-rest() {
  sourceCatalystfile

  pushd "${BASE_DIR}" > /dev/null
  touch .gitignore
  # first ignore whole directories
  for i in `git ls-files . --exclude-standard --others --directory`; do
    echo "${i}" >> .gitignore
  done
  popd > /dev/null
}
