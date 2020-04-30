# Generates a human readable description string based on audit parameters. The '--short' option guarantees a name compatible with branch naming conventions and suitable for use with 'liq work start'.
# outer vars: SCOPE DOMAIN TIME OWNER
function orgs-audits-describe() {
  eval "$(setSimpleOptions SHORT SET_SCOPE:c= SET_DOMAIN:d= SET_TIME:t= SET_OWNER:o= -- "$@")"
  [[ -n $SET_SCOPE ]] || SET_SCOPE="$SCOPE"
  [[ -n $SET_DOMAIN ]] || SET_DOMAIN="$DOMAIN"
  [[ -n $SET_TIME ]] || SET_TIME="$TIME"
  [[ -n $SET_OWNER ]] || SET_OWNER="$OWNER"

  if [[ -z $SHORT ]]; then
    echo "$(tr '[:lower:]' '[:upper:]' <<< ${SET_SCOPE:0:1})${SET_SCOPE:1} ${SET_DOMAIN} audit starting $(date -ujf %Y%m%d%H%M%S ${SET_TIME} +"%Y-%m-%d %H:%M UTC") by ${SET_OWNER}."
  else
    echo "$(tr '[:lower:]' '[:upper:]' <<< ${SET_SCOPE:0:1})${SET_SCOPE:1} ${SET_DOMAIN} audit $(date -ujf %Y%m%d%H%M%S ${SET_TIME} +"%Y-%m-%d %H%M UTC")"
  fi
}

# Finalizes the session by signing the log, committing the updates, and summarizing the session. Takes the records folder, key time, and commit message as first, second, and third arguments.
function orgs-audits-finalize-session() {
  local AUDIT_PATH="${1}"
  local TIME="${2}"
  local MESSAGE="${3}"

  orgs-audits-sign-log "${AUDIT_PATH}"
  (
    cd "${AUDIT_PATH}"
    work-stage .
    work-save -m "${MESSAGE}"
    work-submit --no-close
    orgs-audits-summarize-since "${AUDIT_PATH}" ${TIME}
    work-resume --pop
  )
}
