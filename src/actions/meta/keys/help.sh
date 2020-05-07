# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-meta-keys() {
  local SUMMARY="Manage user keys."

  handleSummary "${cyan_u}meta keys${reset} <action>: ${SUMMARY}" || cat <<EOF
${cyan_u}meta keys${reset} <action>:
  ${SUMMARY}
$(_help-actions-list meta-keys create | indent)
EOF
}

help-meta-keys-create() {
  cat <<EOF | _help-func-summary create "[--import|-i] [--user|-u <email>] [--full-name|-f <full name>]"
Creates a PGP key appropriate for use with liq. The user (email) and their full name will be extracted from the git config 'user.email' and 'user.name' if not specified. In general, you should configure the git parameters because that's what will be used by other liq funcitons.
EOF
}
