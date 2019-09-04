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
  echoerrandexit "Linking currently disabled."
}

packages-lint() {
  local TMP
  TMP=$(setSimpleOptions FIX -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -z "$FIX" ]]; then
    runPackageScript lint
  else
    runPackageScript lint-fix
  fi
}

packages-test() {
  local TMP
  # TODO https://github.com/Liquid-Labs/catalyst-cli/issues/27
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
        echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\ncatalyst packages test --types=unit\ncatalyst services start"
      fi
    else
      echo "${green}looks good.${reset}"
    fi
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" runPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\ncatalyst packages test --type=unit" $?
}

packages-version-check() {
  requireNpmCheck

  local TMP
  TMP=$(setSimpleOptions IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS= -- "$@") \
    || ( help-packages; echoerrandexit "Bad options." )
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
