project-packages() {
  requirePackage

  if [[ $# -eq 0 ]]; then
    usage-project-packages
    echoerrandexit "Missing action argument. See usage above."
  else
    local ACTION="$1"; shift
    if type -t ${GROUP}-${SUBGROUP}-${ACTION} | grep -q 'function'; then
      ${GROUP}-${SUBGROUP}-${ACTION} "$@"
    else
      exitUnknownAction
    fi
  fi
}

project-packages-build() {
  _project_script build
}

project-packages-audit() {
  cd "${BASE_DIR}"
  npm audit
}

project-packages-lint() {
  local TMP
  TMP=$(setSimpleOptions FIX -- "$@") \
    || ( usage-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  if [[ -z "$FIX" ]]; then
    _project_script lint
  else
    _project_script lint-fix
  fi
}

_require-npm-check() {
  # TODO: offer to install
  if ! which -s npm-check; then
    echoerr "'npm-check' not found; could not check package status. Install with:"
    echoerr ''
    echoerr '    npm install -g npm-check'
    echoerr ''
    exit 10
  fi
}

project-packages-version-check() {
  _require-npm-check

  local TMP
  TMP=$(setSimpleOptions IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS= -- "$@") \
    || ( usage-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  local IGNORED_PACKAGES IPACKAGE
  # the '@sh' breaks '-e'; https://github.com/stedolan/jq/issues/1792
  if echo "$PACKAGE" | jq -e --raw-output '.catalyst."version-check".ignore' > /dev/null; then
    IGNORED_PACKAGES=`echo "$PACKAGE" | jq -e --raw-output '.catalyst."version-check".ignore | @sh' 2> /dev/null | tr -d "'"`
  fi

  if [[ -n "$UPDATE" ]] \
      && ( (( ${_OPTS_COUNT} > 2 )) || ( (( ${_OPTS_COUNT} == 1 )) && [[ -z $OPTIONS ]]) ); then
    echoerrandexit "The 'update' option can only be combined with '--options'."
  elif [[ -n "$IGNORE" ]] || [[ -n "$UNIGNORE" ]]; then
    if [[ -n "$IGNORE" ]] && [[ -n "$UNIGNORE" ]]; then
      echoerrandexit "Cannot 'ignore' and 'unignore' packages in same command."
    fi

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
      echo "$PACKAGE" > "$PACKAGE_FILE"
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
      # TODO: cleanup empty bits
      echo "$PACKAGE" > "$PACKAGE_FILE"
    fi

    if [[ -n "$SHOW_CONFIG" ]]; then
      echo -e "\nIgnored packages now: "
      project-packages-version-check -l
    fi
  elif [[ -n "$SHOW_CONFIG" ]]; then
    # on error, assume there's nothing to show
    echo "$PACKAGE" | jq --raw-output 'getpath(["catalyst","version-check","ignore"]) | @sh' | tr -d "'" | sort | tr " " "\n" \
      || echo ""
  else # actually do the check
    local CHECK_OPTS
    for IPACKAGE in $IGNORED_PACKAGES; do
      CHECK_OPTS="${CHECK_OPTS} -i ${IPACKAGE}"
    done
    if [[ -n "$UPDATE" ]]; then
      CHECK_OPTS="${CHECK_OPTS} -u"
    else
      npm-check ${CHECK_OPTS} || true
    fi
  fi
}
