# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

# TODO: we could generate this from the help docs... make the spec central!
_liq() {
  local GLOBAL_ACTIONS="help"
  # Using 'GROUPS' was causing errors; set by some magic.
  local ACTION_GROUPS="environments meta orgs projects services work"

  local TOKEN COMP_FUNC CUR
  CUR="${COMP_WORDS[COMP_CWORD]}"
  COMP_FUNC='comp'
  local WORD_COUNT=${#COMP_WORDS[@]}
  local TOKEN_COUNT=0

  no-opts() {
    COMPREPLY=( $(compgen -W "" -- ${CUR}) )
  }

  std-reply() {
    COMPREPLY=( $(compgen -W "${OPTS}" -- ${CUR}) )
  }

  # TODO: Should we use LIQ_EXTS_DB here? We're sidestepping the need to 'build' the completion script...
  source "${HOME}/.liquid-development/exts/comps.sh"

  comp-liq() {
    OPTS="${GLOBAL_ACTIONS} ${ACTION_GROUPS}"; std-reply
  }

  comp-liq-help() {
    OPTS="${ACTION_GROUPS}"; std-reply
  }

  comp-func-builder() {
    local TOKEN_PATH="${1}"
    local VAR_KEY="${2}"
    local OPT
    local ACTIONS_VAR="${VAR_KEY}_ACTIONS"
    local GROUPS_VAR="${VAR_KEY}_GROUPS"
    echo "comp-liq-${TOKEN_PATH}() { OPTS=\"${!ACTIONS_VAR:-} ${!GROUPS_VAR:-}\"; std-reply; }"
    echo "comp-liq-help-${TOKEN_PATH}() { comp-liq-${TOKEN_PATH}; }"
    for OPT in ${!ACTIONS_VAR}; do
      echo "function comp-liq-${TOKEN_PATH}-${OPT}() { no-opts; }"
      echo "function comp-liq-help-${TOKEN_PATH}-${OPT}() { no-opts; }"
    done
  }

  # environments group
  local ENVIRONMENTS_ACTIONS="add delete deselect list select set show update"
  eval "$(comp-func-builder 'environments' 'ENVIRONMENTS')"

  # meta group
  local META_ACTIONS="bash-config init"
  local META_GROUPS="exts keys"
  eval "$(comp-func-builder 'meta' 'META')"

  META_EXTS_ACTIONS="install list uninstall"
  eval "$(comp-func-builder 'meta-exts' 'META_EXTS')"
  comp-liq-meta-exts-uninstall() {
    # TODO: this is essentially the same logic aas 'liq meta exts list'; change completion to use 'rollup-bash' and share code
    if [[ -f ${HOME}/.liquid-development/exts/exts.sh ]]; then
      COMPREPLY=( $(compgen -W "$(cat "${HOME}/.liquid-development/exts/exts.sh" | awk -F/ 'NF { print $(NF-3)"/"$(NF-2) }')" -- ${CUR}) )
    else
      return 0
    fi
  }

  META_KEYS_ACTIONS="create"
  eval "$(comp-func-builder 'meta-keys' 'META_KEYS')"

  local ORGS_ACTIONS="affiliate create list show select"
  local ORGS_GROUPS="audits policies staff"
  eval "$(comp-func-builder 'orgs' 'ORGS')"
  comp-liq-orgs-select() {
    COMPREPLY=( $(compgen -W "$(find ~/.liquid-development/orgs -maxdepth 1 -mindepth 1 -type l -exec basename {} \;)" -- ${CUR}) )
  }

  local ORGS_STAFF_ACTIONS="add list remove org-chart"
  eval "$(comp-func-builder 'orgs-staff' 'ORGS_STAFF')"

  local ORGS_POLICIES_ACTIONS="document update"
  eval "$(comp-func-builder 'orgs-policies' 'ORGS_POLICIES')"

  local ORGS_AUDITS_ACTIONS="start"
  eval "$(comp-func-builder 'orgs-audits' 'ORGS_AUDITS')"
  # TODO: support 'code' and 'network' type completion for start

  local PROJECTS_ACTIONS="build close create publish qa sync test"
  local PROJECTS_GROUPS="issues sevices"
  eval "$(comp-func-builder 'projects' 'PROJECTS')"

  local PROJECTS_ISSUES_ACTIONS="show"
  eval "$(comp-func-builder 'projects-issues' 'PROJECTS_ISSUES')"

  local PROJECTS_SERVICES_ACTIONS="add list delete show"
  eval "$(comp-func-builder 'projects-services' 'PROJECTS_SERVICES')"

  local SERVICES_ACTIONS="connect err-log list log restart start stop"
  eval "$(comp-func-builder 'services' 'SERVICES')"

  local WORK_ACTIONS="diff-master edit ignore-rest involve list merge qa report resume save stage start status stop submit sync"
  local WORK_GROUPS="issues links"
  eval "$(comp-func-builder 'work' 'WORK')"
  comp-liq-work-stage() {
    # TODO: 'nospace' is very unfortunately innefective (on MacOS 10.x AFAIK)
    COMPREPLY=( $(compgen -o nospace -W "$(for d in ${CUR}*; do [[ -d "$d" ]] && echo "$d/" || echo "$d"; done)" -- ${CUR}) )
  }

  local WORK_ISSUES_ACTIONS="add list remove"
  eval "$(comp-func-builder 'work-issues' 'WORK_ISSUES')"

  local WORK_LINKS_ACTIONS="add list remove"
  eval "$(comp-func-builder 'work-links' 'WORK_LINKS')"

  for TOKEN in ${COMP_WORDS[@]}; do
    if [[ "$TOKEN" != -* ]] && (( $TOKEN_COUNT + 1 < $WORD_COUNT )); then
      local TYPE="$(type -t "${COMP_FUNC}-${TOKEN}" || echo '')"
      if [[ "${TYPE}" == 'function' ]]; then
        COMP_FUNC="${COMP_FUNC}-${TOKEN}"
        TOKEN_COUNT=$(( $TOKEN_COUNT + 1 ))
      fi
    else
      TOKEN_COUNT=$(( $TOKEN_COUNT + 1 ))
    fi
  done

  $COMP_FUNC
  return 0
}

complete -F _liq liq
