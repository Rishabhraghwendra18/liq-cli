# TODO: instead, create simple spec; generate 'completion' options and 'docs' from spec.

help-meta-exts() {
  local SUMMARY="Manage liq extensions."

  handleSummary "${cyan_u}meta exts${reset} <action>: ${SUMMARY}" || cat <<EOF
${cyan_u}meta exts${reset} <action>:
  ${SUMMARY}
$(_help-actions-list meta-exts install list uninstall | indent)
EOF
}

help-meta-exts-install() {
  cat <<EOF | _help-func-summary install "[--local|-l] [--registry|-r] <pkg name[@version]...>"
Installs the named extension package. The '--local' option will use (aka, link to) the local package rather than installing via npm. The '--registry' option (which is the default) will install the package from the NPM registry.
EOF
}

help-meta-exts-list() {
  cat <<EOF | _help-func-summary list
Lists locally installed extensions.
EOF
}

help-meta-exts-uninstall() {
  cat <<EOF | _help-func-summary uninstall "<pkg name...>"
Removes the installed package. If the package is locally installed, the local package installation is untouched and it is simply no longer used by liq.
EOF
}
