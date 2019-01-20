CATALYST_COMMAND_GROUPS=(project runtime work data)

help() {
  cat <<EOF
General Usage:

  catalyst <resource> <action> [...options...] [...selectors...]
  catalyst ${cyan_u}help${reset} [<group or resource> [<action>]

See below for valid ${underline}resource${reset} and the optional ${underline}action${reset} arguments.

Resources are organized into logical groups:
$(echo "${CATALYST_COMMAND_GROUPS[@]}" | tr " " "\n" | sed -Ee 's/^/*  /')

'${underline}catalyst help <group>${reset}' will provide group info.
EOF

  # We looked into dynamically generating based on a breadth-first sort with an
  # alpha sub-sort at each level. We did find this bit of perl to do the breadth
  # first sort, which could be augmented to provde the intra-level alpha sort,
  # but rather than get caught in another rabbit hole, we'll just statically
  # link for now.
  # find . -name "usage.sh" | perl -e 'print sort {$a=~s!/!/! <=> $b=~s!/!/!} <>'
  local GROUP
  for GROUP in ${CATALYST_COMMAND_GROUPS[@]}; do
    usage-${GROUP}
  done
}
