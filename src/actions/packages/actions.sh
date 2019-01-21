requirements-packages() {
  requireCatalystfile
  # Requiring 'the' NPM package here is an artifact of the alpha-version
  # limitation to a single package
  requireNpmPackage
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
  echoerrandexit "The 'link' action is disabled in this version pending testing."

  local TMP
  TMP=$(setSimpleOptions DEV -- "$@") \
    || ( usage-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  local LINK_PROJECT="${1:-}"
  local LINK_PACKAGE_NAME=`packagesProjectLink "$@" | tail -n 1`
  if [[ -n "$LINK_PACKAGE_NAME" ]]; then
    local SAVE_OPT='--save'
    if [[ -n "$DEV" ]]; then SAVE_OPT='--save-dev'; fi
    npm install --save "file:/usr/local/lib/node_modules/${LINK_PACKAGE_NAME}"
    echo "Linked Catalyst project '$LINK_PROJECT' as dependency."
  fi
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

packages-qa() {
  echo "Checking local repo status..."
  work-report
  echo "Checking package dependencies..."
  packages-version-check
  echo "Linting code..."
  packages-lint
  echo "Running tests..."
  packages-test
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
      && ( (( ${_OPTS_COUNT} > 2 )) || ( (( ${_OPTS_COUNT} == 1 )) && [[ -z $OPTIONS_SET ]]) ); then
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
