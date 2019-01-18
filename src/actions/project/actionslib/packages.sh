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
  TMP=$(setSimpleOptions IGNORE UNIGNORE:I LIST_IGNORED UPDATE -- "$@") \
    || ( usage-project-packages; echoerrandexit "Bad options." )
  eval "$TMP"

  local IGNORED_PACKAGES
  # echo "$PACKAGE" | jq --raw-output '.catalyst."version-check".ignore | @sh' | tr -d "'"
  IGNORED_PACKAGES=`echo "$PACKAGE" | jq --raw-output '.catalyst."version-check".ignore | @sh' 2> /dev/null | tr -d "'"`

  if [[ -n "$UPDATE" ]] && (( ${_OPTS_COUNT} > 1 )); then
      echoerrandexit "The 'update' option cannot be combined with other options."
  elif [[ -n "$IGNORE" ]] || [[ -n "$UNIGNORE" ]]; then
    if [[ -n "$IGNORE" ]] && [[ -n "$UNIGNORE" ]]; then
      echoerrandexit "Cannot 'ignore' and 'unignore' packages in same command."
    fi

    if [[ -n "$IGNORE" ]]; then
      local IPACKAGES
      local LIVE_PACKAGES=`echo "$PACKAGE" | jq --raw-output '.dependencies | keys | @sh' | tr -d "'"`
      for IPACKAGE in $IGNORED_PACKAGES; do
        LIVE_PACKAGES=$(echo "$LIVE_PACKAGES" | sed -Ee 's/(^| +)'$IPACKAGE'( +|$)//')
      done
      if (( $# == 0 )); then # interactive add
        PS3="Exclude package: "
        selectDoneCancel IPACKAGES $LIVE_PACKAGES
      else
        IPACKAGES="$@"
      fi

      local IPACKAGE
      for IPACKAGE in $IPACKAGES; do
        if ! echo "$LIVE_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
          echoerr "No such package '$IPACKAGE' in dependencies."
        elif echo "$IGNORED_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
          echoerr "Package '$IPACKAGE' already ignored."
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
      echo "UNIGNORE"
    fi

    if [[ -n "$LIST_IGNORED" ]]; then
      echo "UI LIST IGNORED"
    fi
  elif [[ -n "$LIST_IGNORED" ]]; then
    echo "LIST IGNORED"
  else # actually do the check
    set_npm_check_opts
    if [[ -n "$UPDATE" ]]; then
      npm-check ${NPM_CHECK_OPTS:-} -u || true
    else
      npm-check ${NPM_CHECK_OPTS:-} || true
    fi
  fi
}
