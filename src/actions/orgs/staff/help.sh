help-orgs-staff() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}orgs staff${reset} <action>: Manages organizations staff." || cat <<EOF
${PREFIX}${cyan_u}orgs staff${reset} <action>:
  Manages organization staff.
$(_help-actions-list orgs-staff add list remove org-chart | indent)
EOF
}

help-orgs-staff-add() {
  cat <<EOF | _help-func-summary add "[--email|-e <email>] [--family-name|-f <name>] [--given-name|-g <name>] [--start-date|-s <YYY-MM-DD>] [--commit|-c]"
Adds a staff member to the organization.
EOF
}

help-orgs-staff-list() {
  cat <<EOF | _help-func-summary list "[--email|-e] [--family-name|-f] [--given-name|-g] [--start-date|-s] [--primary-roles|-p] [--secondary-roles|-S] [--enumerate|-n]"
Lists staff. By default lists all columns for CLI display using 'column'. If any data options are given, only those fields are listed. The '--enumerate' option includes a record number as the first column.
EOF
}

help-orgs-staff-remove() {
  cat <<EOF | _help-func-summary remove
Removes the staff member as indicated by their email.
EOF
}

help-orgs-staff-org-chart() {
  cat <<EOF | _help-func-summary org-chart "[<style>] <blah>"
Launches browser to display an org chart. The default style is 'debang/OrgChart+collapsed'.
EOF
}
