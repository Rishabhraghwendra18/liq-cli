requirements-orgs() {
  findBase
}

# see `liq help orgs affiliate`
orgs-affiliate() {
  eval "$(setSimpleOptions LEAVE: SELECT SENSITIVE: -- "$@")"

  local ORG_URL="${1:-}"

  if [[ -n "$LEAVE" ]]; then
    if [[ -z "$ORG_URL" ]]; then # which is really the nick name
      echoerrandexit "You must explicitly name the org when leaving. Try:\nliq orgs leave <org nick>"
    elif [[ ! -d "${LIQ_ORG_DB}/${ORG_URL}" ]]; then
      echoerrandexit "Did not find org with nick name '${ORG_URL}'. Try:\nliq orgs list"
    fi
    cd "${LIQ_ORG_DB}"
    if [[ "$(orgsCurrentOrg)" == "$ORG_URL" ]]; then
      rm -rf curr_org
    fi
    rm -rf "$ORG_URL"
    echo "Local org info removed."
    return
  fi

  local CURR_ORG
  CURR_ORG="$(orgsCurrentOrg)"
  mkdir -p "${LIQ_ORG_DB}"
  cd "${LIQ_ORG_DB}"
  if [[ -n "$ORG_URL" ]]; then
    rm -rf .staging
    git clone --origin upstream --quiet "${ORG_URL}/org_settings.git" .staging \
      || { rm -rf .staging; echoerrandexit "Could not retrieve the public org repo."; }
    source .staging/settings.sh
    if [[ -d "${LIQ_ORG_DB}/${ORG_NICK_NAME}" ]]; then
      echo "Public repo for '${ORG_NICK_NAME}' already present."
      rm -rf .staging
    else
      mkdir -p "${LIQ_ORG_DB}/${ORG_NICK_NAME}"
      mv .staging "${LIQ_ORG_DB}/${ORG_NICK_NAME}/public"
    fi
  elif [[ -z "$ORG_URL" ]] && [[ -n "$REQUIRE_SENSITIVE" ]] && [[ -n "$CURR_ORG" ]]; then
    # setup ORG_URL from CURR_ORG for the 'add sensitive to current' use case
    source "${CURR_ORG}/public/settings.sh"
    ORG_URL="git@github.com:${ORG_GITHUB_NAME}"
  else
    echoerrandexit "Incompatable command options."
  fi

  if [[ -n "${SENSITIVE}" ]]; then
    git clone --origin upstream --quiet "${ORG_URL}/org_settings_sensitive.git" .staging \
      || { rm -rf .staging; echoerrandexit "Could not retrieve the sensitive org repo."; }
    mv .staging "${LIQ_ORG_DB}/${ORG_NICK_NAME}/sensitive"
  fi

  if [[ -n "${SELECT}" ]]; then orgs-select "$ORG_NICK_NAME"; fi
}

# see `liq help orgs create`
orgs-create() {
  local FIELDS="COMMON_NAME GITHUB_NAME LEGAL_NAME ADDRESS: NAICS"
  local OPT_FIELDS="NPM_REGISTRY NPM_SCOPE DEFAULT_LICENSE"
  local FIELDS_SENSITIVE="EIN"
  eval "$(setSimpleOptions NO_AFFILIATE:S SELECT COMMON_NAME= GITHUB_NAME= LEGAL_NAME= ADDRESS= EIN= NAICS= NPM_REGISTRY:= NPM_SCOPE:= -- "$@")"

  if [[ -n "$NO_AFFILIATE" ]] && [[ -n "$SELECT" ]]; then
    echoerrandexit "The '--no-affiliate' and '--select' options are incompatible."
  fi

  # because some fields are optional, but may be set, we can't just rely on 'gather-answers' to skip interactive bit
  local FULLY_DEFINED=true
  for FIELD in $FIELDS $FIELDS_SENSITIVE; do
    FIELD=${FIELD/:/}
    [[ -n "${!FIELD}" ]] || FULLY_DEFINED=false
  done

  defaulter() {
    local FIELD="${1}"

    case "$FIELD" in
      "NPM_REGISTRY")
        echo "https://registry.npmjs.org/";;
      "NPM_SCOPE")
        echo "$GITHUB_NAME" | tr '[:upper:]' '[:lower:]';;
    esac
  }

  if [[ "$FULLY_DEFINED" == true ]]; then
    NPM_REGISTRY=$(defaulter NPM_REGISTRY)
    NPM_SCOPE=$(defaulter NPM_SCOPE)
  else
    gather-answers --defaulter=defaulter --verify "$FIELDS $OPT_FIELDS $FIELDS_SENSITIVE"
  fi

  cd ${LIQ_DB}
  mkdir -p orgs
  cd orgs
  local DIR_NAME
  DIR_NAME="$(echo "$COMMON_NAME" | tr ' -' '_' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_')"

  if [[ -d "$DIR_NAME" ]]; then
    echoerrandexit "Duplicate or name conflict; found existing org entry ($DIR_NAME)."
  fi

  mkdir "${DIR_NAME}"
  local REPO
  for REPO in public sensitive; do
    cd "${LIQ_DB}/orgs/${DIR_NAME}"
    mkdir "${REPO}"
    cd "${REPO}"
    git init .
  done

  prep-repo() {
    cd "${LIQ_DB}/orgs/${DIR_NAME}/${1}"
    git add settings.sh
    git commit -m "initial org settings"
  }

  cd "${LIQ_DB}/orgs/${DIR_NAME}/public"
  for FIELD in $FIELDS $OPT_FIELDS; do
    FIELD=${FIELD/:/}
    echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> settings.sh
  done
  echo "ORG_NICK_NAME='${DIR_NAME}'" >> settings.sh
  prep-repo public
  hub create -d "Public liq settings for ${LEGAL_NAME}." "${GITHUB_NAME}/org_settings"
  git push --set-upstream origin master

  cd "${LIQ_DB}/orgs/${DIR_NAME}/sensitive"
  for FIELD in $FIELDS_SENSITIVE; do
    FIELD=${FIELD/:/}
    echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> settings.sh
  done
  prep-repo sensitive
  hub create -p -d "Sensitive liq settings for ${LEGAL_NAME}." "${GITHUB_NAME}/org_settings_sensitive"
  git push --set-upstream origin master

  if [[ "$SELECT" == true ]]; then
    orgs-select "$DIR_NAME"
  fi
  if [[ "$NO_AFFILIATE" == true ]]; then
    cd "${LIQ_DB}/orgs"
    rm -rf "$DIR_NAME"
  fi
}

# see `liq help orgs list`
orgs-list() {
  orgsOrgList "$@"
}

# see `liq help orgs select`
orgs-select() {
  eval "$(setSimpleOptions NONE -- "$@")"

  if [[ -n "$NONE" ]]; then
    rm "${CURR_ORG_DIR}"
    return
  fi

  local ORG_NAME="${1:-}"
  if [[ -z "$ORG_NAME" ]]; then
    local ORGS
    ORGS="$(orgsOrgList)"

    if test -z "${ORGS}"; then
      echoerrandexit "No org affiliations found. Try:\nliq orgs create\nor\nliq orgs affiliate <git url>"
    fi

    echo "Select org:"
    selectOneCancel ORG_NAME ORGS
    ORG_NAME="${ORG_NAME//[ *]/}"
  fi

  if [[ -d "${LIQ_ORG_DB}/${ORG_NAME}" ]]; then
    if [[ -L $CURR_ORG_DIR ]]; then rm $CURR_ORG_DIR; fi
    cd "${LIQ_ORG_DB}" && ln -s "./${ORG_NAME}" $(basename "${CURR_ORG_DIR}")
    source "${CURR_ORG_DIR}/public/settings.sh"
    if [[ -n "${ORG_NPM_SCOPE}" ]] && [[ -n "${ORG_NPM_REGISTRY}" ]]; then
      addLineIfNotPresentInFile ~/.npmrc "@${ORG_NPM_SCOPE}:registry=${ORG_NPM_REGISTRY}"
    fi
  else
    echoerrandexit "No such org '$ORG_NAME' defined."
  fi
}

# see `liq help orgs show`
orgs-show() {
  eval "$(setSimpleOptions SENSITIVE -- "$@")"

  local ORG_NAME="${1:-}"
  if [[ -z "$ORG_NAME" ]]; then
    ORG_NAME=$(orgsCurrentOrg)
    if [[ -z "$ORG_NAME" ]]; then
      echoerrandexit "No org name given and no org currently selected. Try one of:\nliq orgs show <org name>\nliq orgs select"
    fi
  fi

  if [[ ! -d "${LIQ_ORG_DB}/${ORG_NAME}" ]]; then
    echoerrandexit "No such org with local nick name '${ORG_NAME}'. Try:\nliq orgs list"
  fi

  cat "${LIQ_ORG_DB}/${ORG_NAME}/public/settings.sh"
  if [[ -n "$SENSITIVE" ]]; then
    cat "${LIQ_ORG_DB}/${ORG_NAME}/sensitive/settings.sh"
  fi
}
