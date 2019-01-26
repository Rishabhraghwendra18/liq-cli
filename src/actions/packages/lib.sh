runPackageScript() {
  local ACTION="$1"

  cd "${BASE_DIR}"
  if cat package.json | jq -e "(.scripts | keys | map(select(. == \"$ACTION\")) | length) == 1" > /dev/null; then
    npm run-script "${ACTION}"
  else
    local CATALYST_SCRIPTS=$(npm bin)/catalyst-scripts
    if [[ ! -x "$CATALYST_SCRIPTS" ]]; then
      # TODO: offer to install and re-run
      echoerr "This project does not appear to be using 'catalyst-scripts'. Try:"
      echoerr ""
      echoerrandexit "npm install --save-dev @liquid-labs/catalyst-scripts"
    fi
    # kill the debug trap because if the script exits with an error (as in a
    # failed lint), that's OK and the debug doesn't provide any useful info.
    "${CATALYST_SCRIPTS}" "${BASE_DIR}" $ACTION || true
  fi
}

requireNpmCheck() {
  # TODO: offer to install
  if ! which -s npm-check; then
    echoerr "'npm-check' not found; could not check package status. Install with:"
    echoerr ''
    echoerr '    npm install -g npm-check'
    echoerr ''
    exit 10
  fi
}

packagesVersionCheckManageIgnored() {
  local IPACKAGES
  if [[ -n "$IGNORE" ]]; then
    local LIVE_PACKAGES=`echo "$PACKAGE" | jq --raw-output '.dependencies | keys | @sh' | tr -d "'"`
    for IPACKAGE in $IGNORED_PACKAGES; do
      LIVE_PACKAGES=$(echo "$LIVE_PACKAGES" | sed -Ee 's~(^| +)'$IPACKAGE'( +|$)~~')
    done
    if (( $# == 0 )); then # interactive add
      PS3="Exclude package: "
      selectDoneCancel IPACKAGES $LIVE_PACKAGES
    else
      IPACKAGES="$@"
    fi

    for IPACKAGE in $IPACKAGES; do
      if echo "$IGNORED_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
        echoerr "Package '$IPACKAGE' already ignored."
      elif ! echo "$LIVE_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
        echoerr "No such package '$IPACKAGE' in dependencies."
      else
        if [[ -z "$IGNORED_PACKAGES" ]]; then
          PACKAGE=`echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","ignore"]; ["'$IPACKAGE'"])'`
        else
          PACKAGE=`echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","ignore"]; getpath(["catalyst","version-check","ignore"]) + ["'$IPACKAGE'"])'`
        fi
        IGNORED_PACKAGES="${IGNORED_PACKAGES} ${IPACKAGE}"
      fi
    done
  elif [[ -n "$UNIGNORE" ]]; then
    if [[ -z "$IGNORED_PACKAGES" ]]; then
      if (( $# > 0 )); then
        echoerr "No packages currently ignored."
      else
        echo "No packages currently ignored."
      fi
      exit
    fi
    if (( $# == 0 )); then # interactive add
      PS3="Include package: "
      selectDoneCancelAll IPACKAGES $IGNORED_PACKAGES
    else
      IPACKAGES="$@"
    fi

    for IPACKAGE in $IPACKAGES; do
      if ! echo "$IGNORED_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
        echoerr "Package '$IPACKAGE' is not currently ignored."
      else
        PACKAGE=`echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","ignore"]; getpath(["catalyst","version-check","ignore"]) | map(select(. != "'$IPACKAGE'")))'`
      fi
    done
  fi

  # TODO: cleanup empty bits
  echo "$PACKAGE" > "$PACKAGE_FILE"

  if [[ -n "$SHOW_CONFIG" ]]; then
    project-packages-version-check -c
  fi
}

packagesVersionCheckShowConfig() {
  if [[ -z "$IGNORED_PACKAGES" ]]; then
    echo "Ignored packages: none"
  else
    echo "Ignored packages:"
    echo "$IGNORED_PACKAGES" | tr " " "\n" | sed -E 's/^/  /'
  fi
  if [[ -z "$CMD_OPTS" ]]; then
    echo "Additional options: none"
  else
    echo "Additional options: $CMD_OPTS"
  fi
}

packagesVersionCheckSetOptions() {
  if [[ -n "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'setpath(["catalyst","version-check","options"]; "'$OPTIONS'")')
  elif [[ -z "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'del(.catalyst."version-check".options)')
  fi
  echo "$PACKAGE" > "$PACKAGE_FILE"
}

packagesVersionCheck() {
  for IPACKAGE in $IGNORED_PACKAGES; do
    CMD_OPTS="${CMD_OPTS} -i ${IPACKAGE}"
  done
  if [[ -n "$UPDATE" ]]; then
    CMD_OPTS="${CMD_OPTS} -u"
  fi
  npm-check ${CMD_OPTS} || true
}

packagesLinkNodeModules() {
  local TARGET_DIR="$1"
  echo "TARGET_DIR: ${TARGET_DIR}"
  if [[ ! -d "${TARGET_DIR}/node_modules.orig" ]]; then
    if [[ -d "${TARGET_DIR}/node_modules" ]]; then
      mv "${TARGET_DIR}/node_modules" "${TARGET_DIR}/node_modules.orig"
    else
      mkdir "${TARGET_DIR}/node_modules.orig"
    fi
    mkdir "${TARGET_DIR}/node_modules"
    local NPM_PACK
    local ORG_PACK
    for NPM_PACK in $(ls "${TARGET_DIR}/node_modules.orig/"); do
      if [[ "$NPM_PACK" == '@'* ]]; then # the pack is an org
        mkdir "${TARGET_DIR}/node_modules/${NPM_PACK}"
        ln -s "${TARGET_DIR}/node_modules.orig/${NPM_PACK}/"* "${TARGET_DIR}/node_modules/${NPM_PACK}"
      else
        ln -s "${TARGET_DIR}/node_modules.orig/${NPM_PACK}" "${TARGET_DIR}/node_modules"
      fi
    done
    ls -s "${TARGET_DIR}/node_modules.orig/.bin" "${TARGET_DIR}/node_modules"
  fi
}

# Could not find peer dependency '@material-ui/core' for 'catalyst-core-ui'.
# Could not find peer dependency 'classnames' for 'catalyst-core-ui'.

packagesLinkPeerDep() {
  # Yes, fragile, but for now just takes locals from parent func.
  echo "PLPD: $CANDIDATE_PACKAGE_FILE"
  echo "CPD: $CANDIDATE_PACKAGE_DIR"
  local PEER_DEP
  cat "$CANDIDATE_PACKAGE_FILE" | jq -e --raw-output '.peerDependencies' \
    || return
  cat "$CANDIDATE_PACKAGE_FILE" | jq --raw-output '.peerDependencies | keys | @sh'
  cat "$CANDIDATE_PACKAGE_FILE" | jq --raw-output '.peerDependencies | keys | @sh' | tr -d "'"
  for PEER_DEP in $(cat "$CANDIDATE_PACKAGE_FILE" | jq --raw-output '.peerDependencies | keys | @sh' | tr -d "'"); do
    echo "checking: ${BASE_DIR}/node_modules/${PEER_DEP}"
    if [[ ! -e "${BASE_DIR}/node_modules/${PEER_DEP}" ]]; then
      echoerr "Could not find peer dependency '${PEER_DEP}' for '${LINK_SPEC}'." # TODO: in current project
    elif [[ ! -e "${CANDIDATE_PACKAGE_DIR}/node_modules/${PEER_DEP}" ]]; then
      if [[ "${PEER_DEP}" == '@'*'/'* ]]; then
        ln -s "${BASE_DIR}/node_modules/${PEER_DEP}" "${CANDIDATE_PACKAGE_DIR}/node_modules/$(dirname "$PEER_DEP")"
      else
        ln -s "${BASE_DIR}/node_modules/${PEER_DEP}" "${CANDIDATE_PACKAGE_DIR}/node_modules"
      fi
    fi
  done
}
