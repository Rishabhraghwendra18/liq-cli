# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

source ../shared/common-globals.sh

# TODO: we could generate this from the help docs... make the spec central!
_liq() {
  # Most of this fuction is setup for various handler functions. The actual dispatch is at the very end.
  local GLOBAL_ACTIONS="help ?"
  # Using 'GROUPS' was causing errors; set by some magic.
  local ACTION_GROUPS="meta orgs projects work"

  local TOKEN COMP_FUNC CUR OPTS PREV WORK_COUNT TOKEN_COUNT IS_LIQ_ENV
  if [[ -n "${COMP_WORDS}" ]]; then
    CUR="${COMP_WORDS[COMP_CWORD]}"
    PREV="${COMP_WORDS[COMP_CWORD-1]}"
  fi
  if [[ -n "${COMP_WORDS}" ]]; then
    WORD_COUNT=${#COMP_WORDS[@]}
  else
    WORD_COUND=0
  fi

  if [[ "$CUR" == '?' ]]; then
    CUR='help'
  fi

  no-opts() {
    COMPREPLY=( $(compgen -W "" -- ${CUR}) )
  }

  std-reply() {
    COMPREPLY=( $(compgen -W "${OPTS}" -- ${CUR}) )
  }

  proj-paths-reply() {
    local MATCH="${1}"

    if [[ "${CUR}" != */* ]]; then
      COMPREPLY=( $(compgen -o nospace -W "$(find "${LIQ_ORG_DB}" -maxdepth 1 -mindepth 1 -type l -not -name ".*" | awk -F/ '{ print $NF"/" }')" -- ${CUR}) )
    else
      # TODO: check that 'MATCH' matches /^[a-z0-9-_ *?]$/i
      # TODO: source and use LIQ_PLAYGROUND
      COMPREPLY=( $(compgen -W "$(ls -d "${LIQ_PLAYGROUND}/${CUR}"${MATCH} | awk -F/ '{ print $(NF - 1)"/"$NF }')" -- ${CUR}) )
    fi
  }

  comp-liq() {
    OPTS="${GLOBAL_ACTIONS} ${ACTION_GROUPS}"
    [[ "${IS_LIQ_ENV}" == true ]] && OPTS="${OPTS} quit"
    std-reply
  }

  comp-liq-help() {
    OPTS="${ACTION_GROUPS}"; std-reply
  }

  comp-func-builder() {
    local TOKEN_PATH="${1}"
    local VAR_KEY="${2}"
    local NO_SQUASH_ACTIONS="${3:-}"
    local OPT
    local ACTIONS_VAR="${VAR_KEY}_ACTIONS"
    local GROUPS_VAR="${VAR_KEY}_GROUPS"
    # These functions are dynamic based on the ACTION and GROUP vars so don't need to be overriden; doing so may kill
    # custom completion functions. Note that this means that a previously defined function with a new def needs to be
    # unset first.
    if ! type -t comp-liq-${TOKEN_PATH} | grep -q 'function'; then
      # tThe double escape is first for this string, and then when it goes through 'eval'. This way we keep the function
      # response dynamic rather than freezing it at the point in time when it's built.
      echo "comp-liq-${TOKEN_PATH}() { OPTS=\"\\\${${ACTIONS_VAR}:-} \\\${${GROUPS_VAR}:-}\"; std-reply; }"
    fi
    if ! type -t comp-liq-help-${TOKEN_PATH} | grep -q 'function'; then
      echo "comp-liq-help-${TOKEN_PATH}() { OPTS=\"\\\${${ACTIONS_VAR}:-} \\\${${GROUPS_VAR}:-}\"; std-reply; }"
    fi
    for OPT in ${!ACTIONS_VAR}; do
      if [[ -z "$NO_SQUASH_ACTIONS" ]] || ! type -t comp-liq-${TOKEN_PATH}-${OPT} | grep -q 'function'; then
        echo "function comp-liq-${TOKEN_PATH}-${OPT}() { no-opts; }"
        echo "function comp-liq-help-${TOKEN_PATH}-${OPT}() { no-opts; }"
      fi
    done
  }

  # environments group
  local ENVIRONMENTS_ACTIONS="add delete deselect list select set show update"
  eval "$(comp-func-builder 'environments' 'ENVIRONMENTS')"

  # meta group
  local META_ACTIONS="bash-config init next"
  local META_GROUPS="exts"
  eval "$(comp-func-builder 'meta' 'META')"

  META_EXTS_ACTIONS="install list uninstall"
  eval "$(comp-func-builder 'meta-exts' 'META_EXTS')"
  comp-liq-meta-exts-install() {
    if [[ "${PREV}" == 'install' ]]; then
      COMPREPLY=( $(compgen -W "--local --registry" -- ${CUR}) )
    elif [[ "${PREV}" == "--local" ]]; then
      proj-paths-reply "*-ext-*"
    fi
    # Currently no completion for registry packages.
  }

  comp-liq-meta-exts-uninstall() {
    # TODO: this is essentially the same logic aas 'liq meta exts list'; change completion to use 'rollup-bash' and share code
    if [[ -f ${LIQ_DB}/exts/exts.sh ]]; then
      COMPREPLY=( $(compgen -W "$(cat "${LIQ_DB}/exts/exts.sh" | awk -F/ 'NF { print $(NF-3)"/"$(NF-2) }')" -- ${CUR}) )
    else
      return 0
    fi
  }

  local ORGS_ACTIONS="affiliate create list refresh show select"
  local ORGS_GROUPS=""
  # will override the 'comp-liq-orgs', but want to generate the 'help' completer
  eval "$(comp-func-builder 'orgs' 'ORGS')"

  local PROJECTS_ACTIONS="build close create edit focus list publish qa sync test"
  local PROJECTS_GROUPS=""
  eval "$(comp-func-builder 'projects' 'PROJECTS')"
  comp-liq-projects-create() {
    if [[ "${PREV}" == "create" ]]; then
      COMPREPLY=( $(compgen -W "--new --source" -- ${CUR}) )
    elif [[ "${PREV}" == "--new" ]] || [[ "${PREV}" == "-n" ]]; then
      COMPREPLY=( $(compgen -W "raw" -- ${CUR}) )
    fi
  }

  comp-liq-projects-close() {
    if [[ "${COMP_LINE}" != *'/'? ]]; then
      proj-paths-reply '*'
    fi
  }

  comp-liq-projects-focus() {
    if [[ "${COMP_LINE}" != *'/'? ]]; then
      proj-paths-reply '*'
    fi
  }

  local WORK_ACTIONS="diff edit ignore-rest involve list merge qa report resume save stage start status stop submit sync"
  local WORK_GROUPS="issues links"
  eval "$(comp-func-builder 'work' 'WORK')"
  comp-liq-work-stage() {
    # TODO: 'nospace' is very unfortunately innefective (on MacOS 10.x AFAIK)
    COMPREPLY=( $(compgen -o nospace -W "$(for d in ${CUR}*; do [[ -d "$d" ]] && echo "$d/" || echo "$d"; done)" -- ${CUR}) )
  }

  local WORK_ISSUES_ACTIONS="--add --list --remove"
  eval "$(comp-func-builder 'work-issues' 'WORK_ISSUES')"

  local WORK_LINKS_ACTIONS="add list remove"
  eval "$(comp-func-builder 'work-links' 'WORK_LINKS')"
  comp-liq-work-links-remove() {
    OPTS="$(yalc check || true)"
    # TODO: code adapated from 'work-links-list'; once we build completion, let's share
    OPTS="$(echo "$OPTS" | awk -F: '{print $2}' | tr "'" '"' | jq -r '.[]')"
    std-reply
  }
  comp-liq-work-status() {
    local EX_OPTS="--list-projects --list-issues --pr-ready"
    local COMMON_OPTS="--no-fetch"

    local i
    for i in $COMMON_OPTS; do
      [[ $COMP_LINE != *" ${i}"* ]]  && OPTS="${i} ${OPTS}"
    done

    local EXES=false
    for i in $EX_OPTS; do
      if [[ $COMP_LINE == *" ${i}"* ]]; then EXES=true; break; fi
    done
    [[ "${EXES}" == 'false' ]] && OPTS="${EX_OPTS} ${OPTS}"

    # have they specified work?
    local AFTER
    AFTER="${COMP_LINE/* status/}"
    AFTER="${AFTER%$CUR}"

    if [[ "${PREV}" == 'status' ]] || ! { echo "${AFTER}" | grep -qE '(^| )[a-zA-Z0-9][a-zA-Z0-9_.-]*( |$)'; }; then
      OPTS="${OPTS} $(find "${LIQ_DB}/work" -type f -maxdepth 1 -exec basename {} \;)"
    fi

    std-reply
  }

  # TODO: Should we use LIQ_EXTS_DB here? This way, we're sidestepping the need to 'build' the completion script...
  source "${LIQ_DB}/exts/comps.sh"

  TOKEN_COUNT=0
  if [[ "${COMP_LINE}" != 'liq '* ]]; then # we are in the 'shell' case, which omits the leading 'liq'
    COMP_FUNC='comp-liq'
    IS_LIQ_ENV=true
  else
    COMP_FUNC='comp'
    IS_LIQ_ENV=false
  fi

  # Now we've registered all the local and modular completion functions. We'll analyze the token stream to figure out
  # which completion function to call:
  [[ -n "${COMP_WORDS}" ]] && for TOKEN in ${COMP_WORDS[@]}; do
    if [[ "$TOKEN" != -* ]] && { (( $TOKEN_COUNT + 1 < $WORD_COUNT )) || [[ "${TOKEN}" == 'liq' ]]; }; then
      if [[ "$(type -t "${COMP_FUNC}-${TOKEN}")" == 'function' ]]; then
        COMP_FUNC="${COMP_FUNC}-${TOKEN}"
        TOKEN_COUNT=$(( $TOKEN_COUNT + 1 ))
      fi
    else
      TOKEN_COUNT=$(( $TOKEN_COUNT + 1 ))
    fi
  done

  # Execute the compeltion function determined above:
  $COMP_FUNC
  return 0
}

### GLOBAL HELPERS
# Note these functions are declared outside of the main _liq function because they are used by the liq extensions
# copmletion funcitons.

# helper funtion for '--org' option values
comp-selector-orgs() {
  COMPREPLY=( $(compgen -W "$(find ~/${LIQ_DB_BASENAME}/orgs -maxdepth 1 -mindepth 1 -type l -exec basename {} \;)" -- ${CUR}) )
}

# Handles generating COMPREPLY when using common orgs parameters. Returns true (0) if COMPREPLY is generated and false
# if the caller still needs to generate COMPREPLY. If COMPREPLY is not set, then this function may update 'OPTS',
# which should be declared locally before invoking comp-builder-ors-common-params. Thus, the general usage is
# something like:
# ```
# local OPTS="--foo --bar"
# comp-builder-orgs-common-params || std-reply
# ```
comp-builder-orgs-common-params() {
  if [[ "${PREV}" == "--org" ]]; then
    comp-selector-orgs
    return 0 # bash true; meaning "the COMPREPLY has been handled"
  else
    if [[ "${COMP_LINE}" != *--org* ]]; then
      if [[ -z "${OPTS}" ]]; then OPTS="--org"; else OPTS="${OPTS} --org"; fi
    fi
    return 1 # bash false; mening "the COMPREPLY has not been handled"
  fi
}

complete -F _liq liq
# complete -F _liq
