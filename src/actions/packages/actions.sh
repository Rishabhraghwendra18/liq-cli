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
  local TMP
  TMP=$(setSimpleOptions FIX LIST UNLINK -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  # First, vet the option combinations
  if [[ -n "${FIX}" ]] && (( ( $_OPTS_COUNT + $# ) > 1 )); then
    contextHelp
    echoerrandexit "The '--fix' option is not compatible with other options and takes no arguments."
  elif [[ -n "${LIST}" ]] && (( ( $_OPTS_COUNT + $# ) > 1 )); then
    contextHelp
    echoerrandexit "The '--list' option is not compatible with other options and takes no arguments."
  elif [[ -n "${UNLINK}" ]] && (( $_OPTS_COUNT > 1 )); then
    contextHelp
    echoerrandexit "Cannot combine '--fix' with other options."
  #Now, execute based on the sub-action indicated by options
  elif [[ -n "${FIX}" ]]; then
    local ERROR_COUNT=0
    local NPM_ROOT=$(npm root)
    local LINKED_PACKAGE
    for LINKED_PACKAGE in $(packages-link-list); do
      echo -n "Checking '$LINKED_PACKAGE'... "
      if [[ ! -f "${NPM_ROOT}/${LINKED_PACKAGE}.prelink"/package.json ]]; then
        echoerr "\nThe 'prelink' archive seems to be corrupted! Fix manually."
        ERROR_COUNT=$(( $ERROR_COUNT + 1 ))
      else
        local IS_MOUNTED=$(mount | grep "${NPM_ROOT}/${LINKED_PACKAGE}" || true)
        if [[ -n "$IS_MOUNTED" ]]; then
          if [[ -f "${NPM_ROOT}/${LINKED_PACKAGE}"/package.json ]]; then
            echogreen "Looks good."
          else
            echoerr "'$LINKED_PACKAGE' appears mounted, but also corrupt. Fix manually."
            ERROR_COUNT=$(( $ERROR_COUNT + 1 ))
          fi
        else # not mounted
          echowarn "link has come un-mounted. Attempting fix..."
          if [[ -e "${NPM_ROOT}/${LINKED_PACKAGE}" ]] && [[ ! -d "${NPM_ROOT}/${LINKED_PACKAGE}" ]]; then
            echoerr "Expected link directory '${NPM_ROOT}/${LINKED_PACKAGE}' is not a directory as expected. Fix manually."
            ERROR_COUNT=$(( $ERROR_COUNT + 1 ))
          elif ! rmdir "${NPM_ROOT}/${LINKED_PACKAGE}"; then
            echoerr "Could not remove link directory '${NPM_ROOT}/${LINKED_PACKAGE}'. Check if empty and permissions. Automated fix failed."
            ERROR_COUNT=$(( $ERROR_COUNT + 1 ))
          elif ! mv "${NPM_ROOT}/${LINKED_PACKAGE}.prelink" "${NPM_ROOT}/${LINKED_PACKAGE}"; then
            echoerr "mv "${NPM_ROOT}/${LINKED_PACKAGE}.prelink" "${NPM_ROOT}/${LINKED_PACKAGE}" failed while attempting to re-link. Automated fix failed."
            ERROR_COUNT=$(( $ERROR_COUNT + 1 ))
          else
            packages-link $(basename "${LINKED_PACKAGE}")
          fi
        fi
      fi
    done
  elif [[ -n "${LIST}" ]]; then
    packages-link-list
  elif [[ -n "$UNLINK" ]] && (( $# == 0 )); then
    packagesUnlinkAll "$BASE_DIR"
  else # we need to link or unlink specific packages
    local LINK_SPEC
    for LINK_SPEC in "$@"; do
      local UNLINK_PACKAGE_FILE UNLINK_PACKAGE_NAME
      packages-find-package UNLINK_PACKAGE_FILE UNLINK_PACKAGE_NAME "$LINK_SPEC"

      local LINK_PACKAGE_DIR=$(dirname "$UNLINK_PACKAGE_FILE")
      local INSTALLED_PACKAGE_DIR="${BASE_DIR}/node_modules/${UNLINK_PACKAGE_NAME}"
      if [[ -z "$UNLINK" ]]; then
        packages-link-dolink "$INSTALLED_PACKAGE_DIR" "$LINK_PACKAGE_DIR"
      else
        packagesUnlink "${UNLINK_PACKAGE_NAME}"
      fi
    done
  fi
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
  TMP=$(setSimpleOptions TYPES= NO_DATA_RESET:D GO_RUN= -- "$@") \
    || ( contextHelp; echoerrandexit "Bad options." )
  eval "$TMP"

  # note that 'pretest' will be calaled before test and 'posttest' after
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" runPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\ncatalyst packages test --type=unit" $?
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
