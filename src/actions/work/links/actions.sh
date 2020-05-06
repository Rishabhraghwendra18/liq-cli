work-links() {
  local ACTION="${1}"; shift

  if [[ $(type -t "work-links-${ACTION}" || echo '') == 'function' ]]; then
    work-links-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" work links
  fi
}

# see liq help work links add
work-links-add() {
  eval "$(setSimpleOptions IMPORT PROJECTS= FORCE: -- "$@")"
  local SOURCE_PROJ="${1}"

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set # sets PROJECTS

  # preflight checks
  for TARGET_PROJ in $PROJECTS; do
    [[ -d "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}" ]] || echoerrandexit "No such target project: ${TARGET_PROJ}"
  done

  # ensure the source project is present
  local SOURCE_PROJ_DIR="${LIQ_PLAYGROUND}/${SOURCE_PROJ//@/}"
  if ! [[ -d "${SOURCE_PROJ_DIR}" ]]; then
    if [[ -n "${IMPORT}" ]]; then
      projects-import "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
    fi
  fi
  # publish the source
  cd "${SOURCE_PROJ_DIR}"
  yalc publish

  # link to targets
  for TARGET_PROJ in $PROJECTS; do
    cd "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}"
    echo -n "Checking '${TARGET_PROJ}'... "
    if [[ -n "${FORCE}" ]] || projects-lib-has-any-dep "${SOURCE_PROJ}"; then
      echo "linking..."
      yalc add "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
    else
      echo "skipping (no dependency)."
    fi
  done

  echo "Successfully linked '${SOURCE_PROJ}'."
}

work-links-list() {
  eval "$(setSimpleOptions PROJECTS= -- "$@")"

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set # sets PROJECTS

  for TARGET_PROJ in $PROJECTS; do
    cd "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}" # TODO: regularize reference style
    echo -n "${TARGET_PROJ/@/}: " # TODO: regularize reference style
    local YALC_CHECK="$(yalc check || true)"
    if [[ -z "$YALC_CHECK" ]]; then
      echo "none"
    else
      echo
      echo "$YALC_CHECK" | awk -F: '{print $2}' | tr "'" '"' | jq -r '.[]' | sed -E 's/^/- /'
    fi
    echo
  done
}

# see liq help work links remove
work-links-remove() {
  eval "$(setSimpleOptions NO_UPDATE:U PROJECTS= -- "$@")"
  local SOURCE_PROJ="${1}"

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set # sets PROJECTS

  for TARGET_PROJ in $PROJECTS; do
    cd "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}"
    if { yalc check || true; } | grep -q "${SOURCE_PROJ}"; then
      yalc remove "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
      if [[ -z "${NO_UPDATE}" ]]; then
        npm i "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
      fi
    fi
  done

  echo "Successfully unlinked '${SOURCE_PROJ}'."
}
