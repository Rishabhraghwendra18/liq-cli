projectGitSetup() {
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
  if [[ -n "$ORIGIN_URL" ]]; then
    PROJECT_HOME="$ORIGIN_URL"
    PROJECT_DIR="${BASE_DIR}"
    updateProjectPubConfig
    # TODO: the above overwrites the project BASE_DIR, which we rely on later. See https://github.com/Liquid-Labs/catalyst-cli/issues/2
    BASE_DIR="$PROJECT_DIR"
  fi
}
