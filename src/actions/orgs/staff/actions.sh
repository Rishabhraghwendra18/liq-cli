orgs-staff() {
  local ACTION="${1}"; shift
  local CMD="orgs-staff-${ACTION}"

  if [[ $(type -t "${CMD}" || echo '') == 'function' ]]; then
    ${CMD} "$@"
  else
    exitUnknownAction
  fi
}

orgs-staff-add() {
  local FIELDS="EMAIL FAMILY_NAME GIVEN_NAME START_DATE"
  local FIELDS_SPEC="${FIELDS}"
  FIELDS_SPEC="$(echo "$FIELDS_SPEC" | sed -e 's/ /= /g')="
  eval "$(setSimpleOptions $FIELDS_SPEC NO_CONFIRM:C -- "$@")"

  source "${CURR_ORG_DIR}/public/settings.sh"

  local ALL_SPECIFIED FIELD
  ALL_SPECIFIED=true
  for FIELD in $FIELDS; do
    if [[ -z "${!FIELD}" ]]; then ALL_SPECIFIED=''; break; fi
  done

  if [[ -z "$ALL_SPECIFIED" ]] || [[ -z "$NO_CONFIRM" ]]; then
    prompter() {
      local FIELD="$1"
      local LABEL="$2"
      if [[ "$FIELD" == 'START_DATE' ]]; then
        echo "$LABEL (YYYY-MM-DD): "
      else
        echo "$LABEL: "
      fi
    }

    echo "Adding staff member to ${ORG_COMMON_NAME}..."
    local OPTS='--prompter=prompter'
    if [[ -z "$NO_CONFIRM" ]]; then OPTS="${OPTS} --verify"; fi
    gather-answers ${OPTS} "$FIELDS"
  fi

  local STAFF_FILE="${CURR_ORG_DIR}/sensitive/staff.tsv"
  [[ -f "$STAFF_FILE" ]] || touch "$STAFF_FILE"

  trap - ERR
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "try {
      const { Staff } = require('${LIQ_DIST_DIR}');
      const staff = new Staff('${STAFF_FILE}');
      staff.add({ email: '${EMAIL}',
                  familyName: '${FAMILY_NAME}',
                  givenName: '${GIVEN_NAME}',
                  startDate: '${START_DATE}'});
      staff.write();
    } catch (e) { console.error(e.message); process.exit(1); }
    console.log(\"Staff memebr '${EMAIL}' added.\");" 2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done)
  orgsStaffCommit
}

orgs-staff-list() {
  eval "$(setSimpleOptions ENUMERATE -- "$@")"
  local STAFF_FILE="${CURR_ORG_DIR}/sensitive/staff.tsv"
  if [[ -z "$ENUMERATE" ]]; then
    column -s $'\t' -t "${STAFF_FILE}"
  else
    (echo -e "Entry #\t$(head -n 1 "${STAFF_FILE}")"; tail +2 "${STAFF_FILE}" | cat -ne ) \
      | column -s $'\t' -t
  fi
}

orgs-staff-remove() {
  local EMAIL="${1}"
  local STAFF_FILE="${CURR_ORG_DIR}/sensitive/staff.tsv"

  trap - ERR
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "
    const { Staff } = require('${LIQ_DIST_DIR}');
    const staff = new Staff('${STAFF_FILE}');
    if (staff.remove('${EMAIL}')) { staff.write(); }
    else { console.error(\"No such staff member '${EMAIL}'.\"); process.exit(1); }
    console.log(\"Staff member '${EMAIL}' removed.\");" 2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done)
  orgsStaffCommit
}
