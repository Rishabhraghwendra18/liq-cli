projects-issues() {
  local ACTION="${1}"; shift

  if [[ $(type -t "projects-issues-${ACTION}" || echo '') == 'function' ]]; then
    projects-issues-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" projects issues
  fi
}

# see 'liq help org issues show'
projects-issues-show() {
  eval "$(setSimpleOptions MINE -- "$@")"

  findBase

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
