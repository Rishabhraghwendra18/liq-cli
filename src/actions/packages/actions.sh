requirements-packages() {
  requireCatalystfile
  # Requiring 'the' NPM package here (rather than based on command parameters)
  # is an artifact of the alpha-version limitation to a single package.
  requirePackage
}

packages-audit() {
  cd "${BASE_DIR}"
  npm audit
}

packages-build() {
  runPackageScript build
}

packages-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'catalyst go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

packages-link() {
  local LINK_SPEC
  for LINK_SPEC in "$@"; do
    local LINK_PROJECT=$(echo "$LINK_SPEC" | awk -F: '{print $1}')
    local LINK_PACKAGE=$(echo "$LINK_SPEC" | awk -F: '{print $2}')

    if [[ ! -d "${CATALYST_PLAYGROUND}/${LINK_PROJECT}" ]]; then
      echoerrandexit "Could not find project directory '${LINK_PROJECT}' in Catalyst playground."
    fi

    local CANDIDATE_PACKAGE_FILE=''
    local CANDIDATE_PACKAGE_NAME=''
    local CANDIDATE_PACKAGE_FILE=''
    local CANDIDATE_PACKAGE_FILE_IT=''
    local CANDIDATE_COUNT=0
    # Huh... piping the find causes everything to be run in a forked process (I
    # guess) because the vars set in the loop are not set after exiting
    # read a b dump < <(echo 1 2 3 4 5)
    while read CANDIDATE_PACKAGE_FILE_IT; do
      # Not sure why, but the _IT is necessary because setting
      # CANDIDATE_PACKAGE_FILE directly in the read causes the value to reset
      # after the loop.
      CANDIDATE_PACKAGE_FILE="${CANDIDATE_PACKAGE_FILE_IT}"
    # find -H "${CATALYST_PLAYGROUND}/${LINK_PROJECT}" -name "package.json" -not -path "*/node_modules/*" | while read CANDIDATE_PACKAGE_FILE; do
    # local CANDIDATE_PACKAGE_FILES="$(find -H "${CATALYST_PLAYGROUND}/${LINK_PROJECT}" -name "package.json" -not -path "*/node_modules/*")"
    # for CANDIDATE_PACKAGE_FILE in '/Users/zane/playground/catalyst-core-api/package.json'; do
      CANDIDATE_PACKAGE_NAME=$(cat "$CANDIDATE_PACKAGE_FILE" | jq --raw-output '.name | @sh' | tr -d "'")
      if [[ -n "$LINK_PACKAGE" ]]; then
        if [[ "$LINK_PACKAGE" == "$CANDIDATE_PACKAGE_NAME" ]]; then
          break;
        fi
      elif (( $CANDIDATE_COUNT > 0 )); then
        echoerrandexit "Project '$LINK_PROJECT' contains multiple packages. You must specify the package to link. Try\ncatalyst packages link ${LINK_PROJECT}:<package name>"
      fi
      CANDIDATE_COUNT=$(( $CANDIDATE_COUNT + 1 ))
    done < <(find -H "${CATALYST_PLAYGROUND}/${LINK_PROJECT}" -name "package.json" -not -path "*/node_modules*/*")

    # If we get here without exiting, then 'CANDIDATE_PACKAGE_FILE' has the
    # location of the package.json we want to link.
    local CANDIDATE_PACKAGE_DIR=$(dirname "$CANDIDATE_PACKAGE_FILE")
    # 1) Setup the to-be-linked-packages dependencies.
    packagesLinkNodeModules "${CANDIDATE_PACKAGE_DIR}"
    packagesLinkPeerDep
    # 2) Link the package to the base project.
    packagesLinkNodeModules "${BASE_DIR}"
    # Delete the link to the current install, if any.
    rm "${BASE_DIR}/node_modules/${CANDIDATE_PACKAGE_NAME}" 2>/dev/null || true
    if [[ "${CANDIDATE_PACKAGE_NAME}" == '@'*'/'* ]]; then
      ln -s "${CANDIDATE_PACKAGE_DIR}" "${BASE_DIR}/node_modules/$(dirname "$CANDIDATE_PACKAGE_NAME")"
    else
      ln -s "${CANDIDATE_PACKAGE_DIR}" "${BASE_DIR}/node_modules"
    fi
  done
}

packages-lint() {
  local TMP
  TMP=$(setSimpleOptions FIX -- "$@") \
    || ( usage-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -z "$FIX" ]]; then
    runPackageScript lint
  else
    runPackageScript lint-fix
  fi
}

packages-test() {
  runPackageScript pretest
  runPackageScript test
}

packages-version-check() {
  requireNpmCheck

  local TMP
  TMP=$(setSimpleOptions IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS= -- "$@") \
    || ( usage-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  local IGNORED_PACKAGES IPACKAGE
  # the '@sh' breaks '-e'; https://github.com/stedolan/jq/issues/1792
  if echo "$PACKAGE" | jq -e --raw-output '.catalyst."version-check".ignore' > /dev/null; then
    IGNORED_PACKAGES=`echo "$PACKAGE" | jq --raw-output '.catalyst."version-check".ignore | @sh' | tr -d "'" | sort`
  fi
  local CMD_OPTS="$OPTIONS"
  if [[ -z "$CMD_OPTS" ]] && echo "$PACKAGE" | jq -e --raw-output '.catalyst."version-check".options' > /dev/null; then
    CMD_OPTS=`echo "$PACKAGE" | jq --raw-output '.catalyst."version-check".options'`
  fi

  if [[ -n "$UPDATE" ]] \
      && ( (( ${_OPTS_COUNT} > 2 )) || ( (( ${_OPTS_COUNT} == 2 )) && [[ -z $OPTIONS_SET ]]) ); then
    echoerrandexit "'--update' option may only be combined with '--options'."
  elif [[ -n "$IGNORE" ]] || [[ -n "$UNIGNORE" ]]; then
    if [[ -n "$IGNORE" ]] && [[ -n "$UNIGNORE" ]]; then
      echoerrandexit "Cannot 'ignore' and 'unignore' packages in same command."
    fi

    packagesVersionCheckManageIgnored
  elif [[ -n "$SHOW_CONFIG" ]]; then
    packagesVersionCheckShowConfig
  elif [[ -n "$OPTIONS_SET" ]] && (( $_OPTS_COUNT == 1 )); then
    packagesVersionCheckSetOptions
  else # actually do the check
    packagesVersionCheck
  fi
}
