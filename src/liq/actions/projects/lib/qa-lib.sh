_QA_OPTIONS_SPEC="UPDATE OPTIONS="

## Main lib functions

# Assumes we are already in the BASE_DIR of the target project.
projectsNpmAudit() {
  eval "$(setSimpleOptions $_QA_OPTIONS_SPEC -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -n "$UPDATE" ]]; then
    npm audit fix
  else npm audit; fi
}

# Assumes we are already in the BASE_DIR of the target project.
projectsLint() {
  eval "$(setSimpleOptions $_QA_OPTIONS_SPEC -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -z "$UPDATE" ]]; then
    projectsRunPackageScript lint
  else projectsRunPackageScript lint-fix; fi
}

# Runs checks that 'package.json' conforms to Liquid Project standards. This is very much non-exhaustive.
projectsLiqCheck() {
  findBase
  if ! [[ -f "${BASE_DIR}/package.json" ]]; then
    echoerr "No 'package.json' found."
    return 1
  fi
  local ORG_BASE

  ORG_BASE="$(cat "${BASE_DIR}/package.json" | jq ".${LIQ_NPM_KEY}.orgBase" | tr -d '"')"
  # no idea why, but this is outputting 'null' on blanks, even though direct testing doesn't
  ORG_BASE=${ORG_BASE/null/}
  if [[ -z "$ORG_BASE" ]]; then
    # TODO: provide reference to docs.
    echoerr "Did not find '.${LIQ_NPM_KEY}.orgBase' in 'package.json'. Add this to your 'package.json' to define the NPM package name or URL pointing to the base, public org repository."
  fi
}

projectsVersionCheck() {
  projectsRequireNpmCheck
  requirePackage
  # we are temporarily disabling the config manegement options
  # see https://github.com/liquid-labs/liq-cli/issues/94
  # IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS=
  eval "$(setSimpleOptions $_QA_OPTIONS_SPEC IGNORE UNIGNORE:I SHOW_CONFIG:c UPDATE OPTIONS= -- "$@")" \
    || ( help-projects; echoerrandexit "Bad options." )

  local IGNORED_PACKAGES=""
  # the '@sh' breaks '-e'; https://github.com/stedolan/jq/issues/1792
  if echo "$PACKAGE" | jq -e --raw-output '.liq.versionCheck.ignore' > /dev/null; then
    IGNORED_PACKAGES=$(echo "$PACKAGE" | jq --raw-output '.liq.versionCheck.ignore | @sh' | tr -d "'" | sort)
  fi
  local CMD_OPTS="$OPTIONS"
  if [[ -z "$CMD_OPTS" ]] && echo "$PACKAGE" | jq -e --raw-output '.liq.versionCheck.options' > /dev/null; then
    CMD_OPTS=$(echo "$PACKAGE" | jq --raw-output '.liq.versionCheck.options | .[]')
  fi

  if [[ -n "$UPDATE" ]] \
      && ( (( ${_OPTS_COUNT} > 2 )) || ( (( ${_OPTS_COUNT} == 2 )) && [[ -z $OPTIONS_SET ]]) ); then
    echoerrandexit "'--update' option may only be combined with '--options'."
  elif [[ -n "$IGNORE" ]] || [[ -n "$UNIGNORE" ]]; then
    if [[ -n "$IGNORE" ]] && [[ -n "$UNIGNORE" ]]; then
      echoerrandexit "Cannot 'ignore' and 'unignore' projects in same command."
    fi

    projectsVersionCheckManageIgnored
  elif [[ -n "$SHOW_CONFIG" ]]; then
    projectsVersionCheckShowConfig "${CMD_OPTS}"
  elif [[ -n "$OPTIONS_SET" ]] && (( $_OPTS_COUNT == 1 )); then
    projectsVersionCheckSetOptions
  else # actually do the check
    projectsVersionCheckDo "${CMD_OPTS}"
  fi
}

## helper functions

projectsRequireNpmCheck() {
  # TODO: offer to install
  if ! which -s npm-check; then
    echoerr "'npm-check' not found; could not check package status. Install with:"
    echoerr ''
    echoerr '    npm install -g npm-check'
    echoerr ''
    exit 10
  fi
}

projectsVersionCheckManageIgnored() {
  local IPACKAGES IPACKAGE
  if [[ -n "$IGNORE" ]]; then
    local LIVE_PACKAGES=`echo "$PACKAGE" | jq --raw-output '.dependencies | keys | @sh' | tr -d "'"`
    for IPACKAGE in $IGNORED_PACKAGES; do
      LIVE_PACKAGES=$(echo "$LIVE_PACKAGES" | sed -Ee 's~(^| +)'$IPACKAGE'( +|$)~~')
    done
    if (( $# == 0 )); then # interactive add
      PS3="Exclude package: "
      selectDoneCancel IPACKAGES LIVE_PACKAGES
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
          PACKAGE=`echo "$PACKAGE" | jq 'setpath(["liq","versionCheck","ignore"]; ["'$IPACKAGE'"])'`
        else
          PACKAGE=`echo "$PACKAGE" | jq 'setpath(["liq","versionCheck","ignore"]; getpath(["liq","versionCheck","ignore"]) + ["'$IPACKAGE'"])'`
        fi
        IGNORED_PACKAGES="${IGNORED_PACKAGES} ${IPACKAGE}"
      fi
    done
  elif [[ -n "$UNIGNORE" ]]; then
    if [[ -z "$IGNORED_PACKAGES" ]]; then
      if (( $# > 0 )); then
        echoerr "No projects currently ignored."
      else
        echo "No projects currently ignored."
      fi
      exit
    fi
    if (( $# == 0 )); then # interactive add
      PS3="Include package: "
      selectDoneCancelAll IPACKAGES IGNORED_PACKAGES
    else
      IPACKAGES="$@"
    fi

    for IPACKAGE in $IPACKAGES; do
      if ! echo "$IGNORED_PACKAGES" | grep -Eq '(^| +)'$IPACKAGE'( +|$)'; then
        echoerr "Package '$IPACKAGE' is not currently ignored."
      else
        PACKAGE=`echo "$PACKAGE" | jq 'setpath(["liq","versionCheck","ignore"]; getpath(["liq","versionCheck","ignore"]) | map(select(. != "'$IPACKAGE'")))'`
      fi
    done
  fi

  # TODO: cleanup empty bits
  echo "$PACKAGE" > "$PACKAGE_FILE"

  if [[ -n "$SHOW_CONFIG" ]]; then
    projectsVersionCheck -c
  fi
}

projectsVersionCheckShowConfig() {
  local CMD_OPTS="${1:-}"

  if [[ -z "$IGNORED_PACKAGES" ]]; then
    echo "Ignored projects: none"
  else
    echo "Ignored projects:"
    echo "$IGNORED_PACKAGES" | tr " " "\n" | sed -E 's/^/  /'
  fi
  if [[ -z "$CMD_OPTS" ]]; then
    echo "Additional options: none"
  else
    echo "Additional options: $CMD_OPTS"
  fi
}

projectsVersionCheckSetOptions() {
  if [[ -n "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'setpath(["liq","versionCheck","options"]; "'$OPTIONS'")')
  elif [[ -z "$OPTIONS" ]]; then
    PACKAGE=$(echo "$PACKAGE" | jq 'del(.liq.versionCheck.options)')
  fi
  echo "$PACKAGE" > "$PACKAGE_FILE"
}

projectsVersionCheckDo() {
  local CMD_OPTS="${1:-}"

  for IPACKAGE in $IGNORED_PACKAGES; do
    CMD_OPTS="${CMD_OPTS} -i ${IPACKAGE}"
  done
  if [[ -n "$UPDATE" ]]; then
    CMD_OPTS="${CMD_OPTS} -u"
  fi
  npm-check ${CMD_OPTS} || true
}
