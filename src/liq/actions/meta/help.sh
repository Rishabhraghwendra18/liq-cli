META_GROUPS="exts"

help-meta() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}meta${reset} <action>: Handles liq self-config and meta operations." \
   || cat <<EOF
${PREFIX}${cyan_u}meta${reset} <action>:
  Manages local liq configurations and non-liq user resources.
$(_help-actions-list meta bash-config init next | indent)
$(_help-sub-group-list meta META_GROUPS)
EOF
}

help-meta-bash-config() {
  cat <<EOF | _help-func-summary bash-config
Prints bash configuration. Try:\neval "\$(liq meta bash-config)"
EOF
}

help-meta-init() {
  cat <<EOF | _help-func-summary init "[--silent|-s] [--playground|-p <absolute path>] [--no-playground|-P]"
Initialize the liq database in ~/.liq. By default, will expose the "playground" as ~/playground. The playground can be relocated with the '--playground' parameter. Alternatively, you can supress exposing the playground with the '--no-playground' option. In that case, ~/.liq/playground will still be created and used by liq, it just won't be "exposed" as a non-hidden link. If --no-playground is set, then --playground is ignored.
EOF
}

help-meta-next() {
  cat <<EOF | _help-func-summary next "[--tech-detail|-t] [--error|-e]"
Analyzes current state of play and suggests what to do next. '--tech-detail' may provide additional technical information for the curious or liq developers.

Regular users can ignore the '--error' option. It's an internal option allowing the 'next' action to be leveraged to for error information and hints when appropriate.
EOF
}
