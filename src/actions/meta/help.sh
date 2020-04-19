help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles liq self-config and meta operations." \
   || cat <<EOF
${PREFIX}${cyan_u}meta${reset} <action>:
  Manages local liq configurations and non-liq user resources.
$(_help-actions-list meta next init bash-config | indent)

  ${bold}Sub-resources${reset}:
    * $( SUMMARY_ONLY=true; help-meta-keys )
EOF
}

help-meta-bash-config() {
  cat <<EOF | _help-func-summary bash-config
Prints bash configuration. Try:\neval "\$(liq meta bash-config)"
EOF
}

help-meta-init() {
  cat <<EOF | _help-func-summary init "[--silent|-s] [--playground|-p <absolute path>]"
Creates the Liquid Development DB (a local directory) and playground.
EOF
}

help-meta-next() {
  cat <<EOF | _help-func-summary next "[--tech-detail|-t] [--error|-e]"
Analyzes current state of play and suggests what to do next. '--tech-detail' may provide additional technical information for the curious or liq developers.

Regular users can ignore the '--error' option. It's an internal option allowing the 'next' action to be leveraged to for error information and hints when appropriate.
EOF
}
