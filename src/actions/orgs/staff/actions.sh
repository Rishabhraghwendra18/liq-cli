orgs-staff() {
  local ACTION="${1}"; shift
  local CMD="orgs-staff-${ACTION}"

  if [[ $(type -t "${CMD}" || echo '') == 'function' ]]; then
    ${CMD} "$@"
  else
    exitUnknownHelpTopic "$ACTION" orgs staff
  fi
}

orgs-staff-add() {
  local FIELDS="EMAIL FAMILY_NAME GIVEN_NAME START_DATE PRIMARY_ROLES SECONDARY_ROLES"
  local FIELDS_SPEC="${FIELDS}"
  FIELDS_SPEC="$(echo "$FIELDS_SPEC" | sed -e 's/ /= /g')="
  eval "$(setSimpleOptions $FIELDS_SPEC NO_VERIFY:V NO_COMMIT:C -- "$@")"

  orgsStaffRepo

  local ALL_SPECIFIED FIELD
  ALL_SPECIFIED=true
  for FIELD in $FIELDS; do
    if [[ -z "${!FIELD}" ]]; then ALL_SPECIFIED=''; break; fi
  done

  # not all specified or confirmation not skipped
  if [[ -z "$ALL_SPECIFIED" ]] || [[ -z "$NO_VERIFY" ]]; then
    [[ -n "$ORG_STRUCTURE" ]] || echoerrandexit "You must define 'ORG_STRUCTURE' to point to a valid JSON file in the 'settings.sh' file."
    [[ -f "$ORG_STRUCTURE" ]] || echoerrandexit "'ORG_STRUCTURE' defnied, but does not point to a file."

    local ROLE_OPTS
    ROLE_OPTS="$(cat "$ORG_STRUCTURE" | jq -r ".[] | .[0]")" || echoerrandexit "Could not parse '$ORG_STRUCTURE' as a valid JSON/org structure file."

    prompter() {
      local FIELD="$1"
      local LABEL="$2"
      if [[ "$FIELD" == 'START_DATE' ]]; then
        echo "$LABEL (YYYY-MM-DD): "
      else
        echo "$LABEL: "
      fi
    }

    selector() {
      local FIELD="$1"
      if [[ "$FIELD" == 'PRIMARY_ROLES' ]] || [[ "$FIELD" == 'SECONDARY_ROLES' ]]; then
        echo "$ROLE_OPTS"
      fi
    }

    echo "Adding staff member to ${ORG_COMMON_NAME}..."
    local OPTS='--prompter=prompter --selector=selector'
    if [[ -z "$NO_VERIFY" ]]; then OPTS="${OPTS} --verify"; fi
    gather-answers ${OPTS} "$FIELDS"
  fi

  local STAFF_FILE="${LIQ_PLAYGROUND}/${ORG_STAFF_REPO/@/}/staff.tsv"
  [[ -f "$STAFF_FILE" ]] || touch "$STAFF_FILE"

  trap - ERR # TODO: document why this is here...
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "try {
      const { Staff } = require('@liquid-labs/policies-model');
      const staff = new Staff('${STAFF_FILE}');
      staff.add({ email: '${EMAIL}',
                  familyName: '${FAMILY_NAME}',
                  givenName: '${GIVEN_NAME}',
                  startDate: '${START_DATE}',
                  primaryRoles: \`${PRIMARY_ROLES}\`.split(/\\n/),
                  secondaryRoles: \`${SECONDARY_ROLES}\`.split(/\\n/)});
      staff.write();
    } catch (e) { console.error(e.message); process.exit(1); }
    console.log(\"Staff member '${EMAIL}' added.\");" \
      2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done; \
           [[ -z "$line" ]] || echoerrandexit "Problem loading staff data.")
  if [[ -n "$NO_COMMIT" ]]; then
    echowarn "Updates have not been committed. Manually commit and push when ready."
  else
    orgsStaffCommit
  fi
}

orgs-staff-list() {
  eval "$(setSimpleOptions ENUMERATE -- "$@")"
  orgsStaffRepo
  local STAFF_FILE="${ORG_STAFF_REPO}/staff.tsv"
  if [[ -z "$ENUMERATE" ]]; then
    column -s $'\t' -t "${STAFF_FILE}"
  else
    (echo -e "Entry #\t$(head -n 1 "${STAFF_FILE}")"; tail +2 "${STAFF_FILE}" | cat -ne ) \
      | column -s $'\t' -t
  fi
}

orgs-staff-remove() {
  local EMAIL="${1}"
  orgsStaffRepo
  local STAFF_FILE="${ORG_STAFF_REPO}/staff.tsv"

  trap - ERR
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "
    const { Staff } = require('${LIQ_DIST_DIR}');
    const staff = new Staff('${STAFF_FILE}');
    if (staff.remove('${EMAIL}')) { staff.write(); }
    else { console.error(\"No such staff member '${EMAIL}'.\"); process.exit(1); }
    console.log(\"Staff member '${EMAIL}' removed.\");" 2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done)
  orgsStaffCommit
}
