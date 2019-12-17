orgs-issues() {
  local ACTION="${1}"; shift

  if [[ $(type -t "orgs-issues-${ACTION}" || echo '') == 'function' ]]; then
    orgs-issues-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" orgs issues
  fi
}

# see 'liq help org issues show'
orgs-issues-show() {
  eval "$(setSimpleOptions MINE -- "$@")"

  local URL
  URL=$(cat "$BASE_DIR/package.json" | jq -r '.bugs.url' )

  if [[ -n "$MINE" ]]; then
    local MY_GITHUB_NAME
    projectHubWhoami MY_GITHUB_NAME
    open "${URL}/assigned/${MY_GITHUB_NAME}"
  else
    open "${URL}"
  fi
}
