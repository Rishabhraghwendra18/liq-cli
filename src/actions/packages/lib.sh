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

packagesProjectLink() {
  local LINK_PROJECT="${1:-}"
  requireArgs "$LINK_PROJECT" || exit 1
  local PACKAGE_REL_PATH="${2:-}" # this one's optional

  local CURR_PROJECT_DIR="${BASE_DIR}"
  cd "${CURR_PROJECT_DIR}"
  local OUR_PACKAGE_DIR=`find . -name "package.json" -not -path "*/node_modules/*"`
  local PACKAGE_COUNT=`echo "$OUR_PACKAGE_DIR" | wc -l`
  if (( $PACKAGE_COUNT == 0 )); then
    echoerrandexit "Did not find local 'package.json'."
  elif (( $PACKAGE_COUNT > 1 )); then
    # TODO: requrie the user to be in the dir with the package.json
    echoerrandexit "Found multiple 'package.json' files; this is currently a limitation, perform linking manually."
  fi

  if [[ -z "$OUR_PACKAGE_DIR" ]]; then
    echoerrandexit "Did not find 'package.json' in current project"
  else
    OUR_PACKAGE_DIR=`dirname "$OUR_PACKAGE_DIR"`
  fi

  requireWorkspaceConfig
  cd "${BASE_DIR}" # now workspace base
  if [[ ! -d "$LINK_PROJECT" ]]; then
    echoerrandexit "Did not find project '${LINK_PROJECT}' to link."
  fi

  cd "$LINK_PROJECT"
  # determine the package-to-link's package.json
  local LINK_PACKAGE
  if [[ -n "$PACKAGE_REL_PATH" ]]; then
    if [[ -f "$PACKAGE_REL_PATH/package.json" ]]; then
      LINK_PACKAGE="$PACKAGE_REL_PATH/package.json"
    else
      echoerrandexit "Did not find 'package.json' under specified path '$PACKAGE_REL_PATH'."
    fi
  else
    LINK_PACKAGE=`find . -name "package.json" -not -path "*/node_modules/*"`
    local LINK_PACKAGE_COUNT=`echo "$LINK_PACKAGE" | wc -l`
    if (( $LINK_PACKAGE_COUNT == 0 )); then
      echoerrandexit "Did not find 'package.json' in '$LINK_PROJECT'."
    elif (( $LINK_PACKAGE_COUNT > 1 )); then
      echoerrandexit "Found multiple packages to link in '$LINK_PROJECT'; specify relative package path."
    fi
  fi

  local LINK_PACKAGE_NAME=`node -e "const fs = require('fs'); const package = JSON.parse(fs.readFileSync('${LINK_PACKAGE}')); console.log(package.name);"`
  npm -q link

  cd "$CURR_PROJECT_DIR"
  cd "$OUR_PACKAGE_DIR"
  npm -q link "$LINK_PACKAGE_NAME"

  echo "$LINK_PACKAGE_NAME"
}
