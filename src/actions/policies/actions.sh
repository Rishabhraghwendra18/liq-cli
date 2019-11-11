requirements-policies() {
  :
}

policies-import() {
  eval "$(setSimpleOptions FORK -- "$@")"

  local CURR_ORG PROJ_NAME PROJ_URL IMPORT_URL
  IMPORT_URL="${1}"
  CURR_ORG="$(orgsCurrentOrg --require-sensitive)"

  if [[ -n "$FORK" ]]; then
    project-import --set-name="PROJ_NAME" "$IMPORT_URL"
  else # default
    project-import --set-name="PROJ_NAME" --no-fork "$IMPORT_URL"
  fi

  cd "${LIQ_ORG_DB}/${CURR_ORG}/sensitive"
  PROJ_URL=$(projectsGetUpstreamUrl "${PROJ_NAME}")
  # first, check to see if policy is already registered
  local REGISTRATION REG_URL
  if [[ -f 'policies.tsv' ]]; then
    REGISTRATION="$(grep -E "^$PROJ_NAME" policies.tsv || true)"
  fi

  if [[ -n "$REGISTRATION" ]]; then
    REG_URL=$(echo "$REGISTRATION" | awk -F, '{print $2}')
    if [[ "$REG_URL" != "$PROJ_URL" ]]; then
      echowarn "Policy is already registered, but the registered URL and project upstream URL differ. This may be merely a syntax difference, but it should be checked and fixed."
    elif [[ "$REG_URL" != "$IMPORT_URL" ]]; then
      echo "Policy is already registered, but under a different URL than requested: '$REG_URL'"
    else
      echo "Policy is already registered."
    fi
  else # policy is not registered
		mkdir -p policies
	    echo -e "$PROJ_NAME\t$PROJ_URL" >> policies/policies.tsv
			git add --policies/policies.tsv
		local ROLES
		ROLES="$(find "${LIQ_PLAYGROUND}/${CURR_ORG}/${PROJ_NAME}" -name 'roles.tsv')"
		if [[ -n "$ROLES" ]]; then
			if [[ -f policies/roles ]]; then
				echoerr "Newly imported policies defines roles ('${PROJ_NAME}/${ROLES}'), but we found existing 'roles' reference for: $(cat policies/roles)".
			else
				echo -n "${PROJ_NAME}/${ROLES}" > policies/roles
				git add policies/roles
				echo "Found and regitered roles definition."
			fi
		fi
    git commit --quiet -am "Added policy '$PROJ_NAME'"
    git push --quiet
  fi
}
