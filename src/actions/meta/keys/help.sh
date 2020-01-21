# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-meta-keys() {
  handleSummary "${cyan_u}keys${reset} <action>: Manage user keys." || cat <<EOF
${cyan_u}meta keys${reset} <action>:
$(help-meta-keys-create | sed -e 's/^/  /')
EOF
} #$'' HACK to reset Atom Beutifier

help-meta-keys-create() {
  cat <<EOF
${underline}create${reset} [--import|-i] [--user|-u <email>] [--full-name|-f <full name>] :
  Creates a PGP key appropriate for use with liq. The user (email) and their full name will be extracted from the
  git config 'user.email' and 'user.name' if not specified. In general, you should configure the git parameters
  because that's what will be used by other liq funcitons.
EOF
}
