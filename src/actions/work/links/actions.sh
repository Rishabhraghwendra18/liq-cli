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
  eval "$(setSimpleOptions IMPORT PROJECT= -- "$@")"
  local SOURCE_PROJ="${1}"

  local SOURCE_PROJ_DIR="${LIQ_PLAYGROUND}/${SOURCE_PROJ}"
  if ! [[ -d "${SOURCE_PROJ_DIR}" ]]; then
    if [[ -n "${IMPORT}" ]]; then
      projects-import "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
    elif [[ -z "${REMOVE}" ]]; then
      echoerrandexit "No such target project '${SOURCE_PROJ}'."
    fi
  fi
  cd "${SOURCE_PROJ_DIR}"
  yalc publish

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set

  for TARGET_PROJ in $INVOLVED_PROJECTS; do
    cd "${LIQ_PLAYGROUND}/${TARGET_PROJ/@/}"
    yalc add "@${SOURCE_PROJ/@/}" # TODO: regularize reference style
  done

  echo "Successfully linked '${SOURCE_PROJ}'."
}

work-links-list() {
  eval "$(setSimpleOptions PROJECT= -- "$@")"

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set

  for TARGET_PROJ in $INVOLVED_PROJECTS; do
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
  eval "$(setSimpleOptions NO_UPDATE:U PROJECT= -- "$@")"
  local SOURCE_PROJ="${1}"

  local INVOLVED_PROJECTS TARGET_PROJ
  work-links-lib-working-set

  for TARGET_PROJ in $INVOLVED_PROJECTS; do
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
