requirements-orgs() {
  findBase
}

orgs-create() {
  local FIELDS="COMMON_NAME GITHUB_NAME LEGAL_NAME ADDRESS NAICS"
  local FIELDS_SENSITIVE="EIN"
  eval "$(setSimpleOptions NO_SUBSCRIBE:S ACTIVATE COMMON_NAME= GITHUB_NAME= LEGAL_NAME= ADDRESS= EIN= NAICS= -- "$@")"

  if [[ -n "$NO_SUBSCRIBE" ]] && [[ -n "$ACTIVATE" ]]; then
    echoerrandexit "The '--no-subscribe' and '--activate' options are incompatible."
  fi

  local FIELD FIELD_SET VERIFIED
  while [[ "${VERIFIED}" != true ]]; do
    for FIELD in $FIELDS $FIELDS_SENSITIVE; do
      local OPTS=''
      # if VERIFIED is set, but false, then we need to force require-answer to set the var
      [[ "$VERIFIED" == false ]] && OPTS='--force '
      [[ "$FIELD" == "ADDRESS" ]] && OPTS="${OPTS}--multi-line "
      require-answer ${OPTS} "${FIELD//_/ }: " $FIELD
    done
    verify() { VERIFIED=true; }
    no-verify() { VERIFIED=false; }
    echo
    echo "Verify the following:"
    for FIELD in $FIELDS $FIELDS_SENSITIVE; do
      echo "$FIELD: ${!FIELD}"
    done
    echo
    yesno "Are these values correct? (y/N) " N verify no-verify
  done

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
  for FIELD in $FIELDS; do
    echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> settings.sh
  done
  prep-repo public
  hub create -d "Public liq settings for ${LEGAL_NAME}." "${GITHUB_NAME}/org_settings"
  git push --set-upstream origin master

  cd "${LIQ_DB}/orgs/${DIR_NAME}/sensitive"
  for FIELD in $FIELDS_SENSITIVE; do
    echo "ORG_${FIELD}='$(echo "${!FIELD}" | sed "s/'/'\"'\"'/g")'" >> settings.sh
  done
  prep-repo sensitive
  hub create -p -d "Sensitive liq settings for ${LEGAL_NAME}." "${GITHUB_NAME}/org_settings_sensitive"
  git push --set-upstream origin master

  if [[ "$ACTIVATE" == true ]]; then
    cd "${LIQ_DB}/orgs"
    ln -s "$DIR_NAME" curr_org
  fi
  if [[ "$NO_SUBSCRIBE" == true ]]; then
    cd "${LIQ_DB}/orgs"
    rm -rf "$DIR_NAME"
  fi
}
