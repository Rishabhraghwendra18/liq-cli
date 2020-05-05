# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-meta-exts() {
  local SUMMARY="Manage liq extensions."

  handleSummary "${cyan_u}exts${reset} <action>: ${SUMMARY}" || cat <<EOF
${cyan_u}meta exts${reset} <action>:
  ${SUMMARY}
$(_help-actions-list meta-exts install list | indent)
EOF
}

help-meta-exts-install() {
  cat <<EOF | _help-func-summary install
Installs the named extension package.
EOF
}

help-meta-exts-list() {
  cat <<EOF | _help-func-summary list
Lists locally installed extensions.
EOF
}
