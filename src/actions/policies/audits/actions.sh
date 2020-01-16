policies-audits() {
  local ACTION="${1}"; shift

  if [[ $(type -t "policies-audits-${ACTION}" || echo '') == 'function' ]]; then
    policies-audits-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" policies audits
  fi
}

policies-audits-start() {
  eval $(setSimpleOptions CHANGE_CONTROL FULL NO_CONFIRM:C -- "$@")

  local SCOPE TIME AUTHOR FILE_NAME FILES
  policy-audit-start-prep "$@"

  FILES="$(policiesGetPolicyFiles --find-options "-path './policies/$DOMAIN/standards/*items.tsv'")"

  # TODO: continue
  echo "bookmark output; found:"
  while read -e FILE; do
    echo "$FILE"
  done <<< "$FILES"
  echoerrandexit "Not implemented."
}
