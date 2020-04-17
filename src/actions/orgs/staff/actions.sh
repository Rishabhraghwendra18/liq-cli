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

  list-from-csv PRIMARY_ROLES
  list-from-csv SECONDARY_ROLES

  orgsStaffRepo

  local ALL_SPECIFIED FIELD
  ALL_SPECIFIED=true
  for FIELD in $FIELDS; do
    if [[ -z "${!FIELD:-}" ]]; then ALL_SPECIFIED=''; break; fi
  done

  # not all specified or confirmation not skipped
  if [[ -z "$ALL_SPECIFIED" ]] || [[ -z "$NO_VERIFY" ]]; then
    orgs-staff-lib-check-org-structure

    local ROLE_OPTS
    ROLE_OPTS="$(cat "$ORG_STRUCTURE" | jq -r ".[] | .[0]" | sort)" || echoerrandexit "Could not parse '$ORG_STRUCTURE' as a valid JSON/org structure file."

    local STAFF_FILE="${LIQ_PLAYGROUND}/${ORG_STAFF_REPO/@/}/staff.tsv"
    [[ -f "$STAFF_FILE" ]] || touch "$STAFF_FILE"
    local CANDIDATE_MANAGERS

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

  local ROLE_DEF
  exec 10<<< "$PRIMARY_ROLES"
  while read -u 10 -r ROLE_DEF; do
    local ROLE MANAGER CANDIDATE_MANAGERS
    ROLE="$(echo "$ROLE_DEF" | awk -F/ '{print $1}')"
    MANAGER="$(echo "$ROLE_DEF" | awk -F/ '{print $2}')"
    if [[ -z "$MANAGER" ]]; then
      # trap - ERR # without this, an error causes the entire node script to print, which is cumbersome
      CANDIDATE_MANAGERS="$(NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e \
        "try {
          const fs = require('fs');
          const { Staff } = require('@liquid-labs/policies-model');
          const staff = new Staff('${STAFF_FILE}');
          const org_struct = JSON.parse(fs.readFileSync('${ORG_STRUCTURE}'));

          const role_def = org_struct.find(el => el[0] == '${ROLE}')
          if (role_def === undefined) {
            throw new Error(\`No such role '${ROLE}' defined for organization.\`);
          }
          if (role_def[1] == '') { console.log('n/a'); }
          else {
            let found = false;
            let s;
            if (\`${PRIMARY_ROLES}\`.match(new RegExp(\`(\$|\\s*)\${role_def[1]}(\\s*|^)\`))) {
              console.log('self - ${EMAIL}');
              found = true;
            }
            while ((s = staff.next()) !== undefined) {
              if (s['primaryRoles'].findIndex(r => r.match(new RegExp(\`^\${role_def[1]}\`))) != -1) {
                console.log(s['email']);
                found = true;
              }
            }
            if (!found) {
              console.log(\`!!NONE:\${role_def[1]}\`)
            }
          }
        }
        catch (e) { console.error(e.message); process.exit(1); }" | sort \
        2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done; \
             [[ -z "$line" ]] || echoerrandexit "Problem Processing managers."))"
      if [[ "$CANDIDATE_MANAGERS" != 'n/a' ]] ; then
        if [[ "$CANDIDATE_MANAGERS" == "!!NONE:"* ]]; then
          local NEEDED="${CANDIDATE_MANAGERS:7}"
          echoerrandexit "Could not find valid manager for role '$ROLE'. Try adding '${NEEDED}' staff and try again."
        fi
        PS3="Manager (as $ROLE): "
        selectOneCancel MANAGER CANDIDATE_MANAGERS
      fi
      [[ "$MANAGER" != "self - "* ]] || MANAGER=${MANAGER:7}
      PRIMARY_ROLES="$(echo "$PRIMARY_ROLES" | sed -E "s|${ROLE}/?|${ROLE}/${MANAGER:-}|")"
    fi
  done # <<< "$PRIMARY_ROLES"
  exec 10<&-

  trap - ERR # without this, an error causes the entire node script to print, which is cumbersome
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "try {
      const { Staff } = require('@liquid-labs/policies-model');
      const staff = new Staff('${STAFF_FILE}');
      staff.add({ email: '${EMAIL}',
                  familyName: '${FAMILY_NAME}',
                  givenName: '${GIVEN_NAME}',
                  startDate: '${START_DATE}',
                  primaryRoles: \`${PRIMARY_ROLES:-}\`.split(/\\n/),
                  secondaryRoles: \`${SECONDARY_ROLES:-}\`.split(/\\n/)});
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
  local COLS="EMAIL FAMILY_NAME GIVEN_NAME START_DATE PRIMARY_ROLES SECONDARY_ROLES:S"
  eval "$(setSimpleOptions ENUMERATE:n $COLS -- "$@")"
  orgsStaffRepo
  local STAFF_FILE="${LIQ_PLAYGROUND}/${ORG_STAFF_REPO/@/}/staff.tsv"

  local EMAIL_COL=1
  local FAMILY_NAME_COL=2
  local GIVEN_NAME_COL=3
  local START_DATE_COL=4
  local PRIMARY_ROLES_COL=5
  local SECONDARY_ROLES_COL=6

  local HEADER
  local AWK_CMD='{print '
  local COL_OFFSET=0
  if [[ -n "$ENUMERATE" ]]; then
    HEADER="$(echo -en "Entry #\t")"
    AWK_CMD="${AWK_CMD}\$1,\"\\t\","
    COL_OFFSET=1
  fi

  local ALL_COLS=true
  for i in $COLS; do
    if [[ -n "${!i%:*}" ]]; then
      ALL_COLS=false
    fi
  done

  if [[ "$ALL_COLS" == "true" ]]; then
    for i in $COLS; do
      eval "${i%:*}=true"
    done
  fi

  # now we can setup the awk print command
  shopt -s extglob
  for i in $COLS; do
    if [[ -n "${!i%:*}" ]]; then
      HEADER="${HEADER}$(echo -e "$(field-to-label "${i}")\t")"
      local COL="${i}_COL"
      AWK_CMD="${AWK_CMD}\$$((${!COL} + $COL_OFFSET)),\"\t\","
    fi
  done
  AWK_CMD="${AWK_CMD%,\"\\t\",} }"
  HEADER="${HEADER%+([[:space]])}"
  shopt -u extglob

  # and finally, we are ready to print
  echo -e "$HEADER"
  tail +2 "${STAFF_FILE}" \
    | cat -e $([[ -z "$ENUMERATE" ]] || echo "-n") \
    | awk "$AWK_CMD" \
    | column -s $'\t' -t
}

orgs-staff-org-chart() {
  orgsStaffRepo # picks up ORG_STRUCTURE
  orgs-staff-lib-check-org-structure

  echo "ORG_STRUCTURE: $ORG_STRUCTURE"
  local ROLES_DEF="${LIQ_PLAYGROUND}/${ORG_POLICY_REPO/@/}/node_modules/@liquid-labs/policy-core/policy/roles.tsv"
  local STAFF_FILE="${LIQ_PLAYGROUND}/${ORG_STAFF_REPO/@/}/staff.tsv"

  trap - ERR
  NODE_PATH="${LIQ_DIST_DIR}/../node_modules" node -e "
    const { Organization } = require('@liquid-labs/policies-model');
    const org = new Organization(
      '${ROLES_DEF}',
      '${STAFF_FILE}',
      '${ORG_STRUCTURE}')

    console.log(JSON.stringify(org.generateOrgChartData('debang/OrgChart')))"
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
    else {
      (\"No such staff member '${EMAIL}'.\"); process.exit(1); }
    console.log(\"Staff member '${EMAIL}' removed.\");" 2> >(while read line; do echo -e "${red}${line}${reset}" >&2; done)
  orgsStaffCommit
}
