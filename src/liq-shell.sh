#!/usr/bin/env bash

SETUP=$(cat <<'EOF'
source "${HOME}/.bashrc"
source "${HOME}/.profile"
PS4='$(echo $(date +"%Y/%m/%d (%H:%M)") $(history 1) >> /tmp/trace.txt)'
PS1='liq> '
set show-all-if-ambiguous on
. ./src/completion.sh
# complete -E -F _liq
complete -D -F _liq
complete -I -F _liq

# bind "TAB:menu-complete"
bind "set show-all-if-ambiguous on"

preexec() {
  # handle or one special shell command
  if [[ "$1" == 'quit' ]] || [[ "$1" == 'q' ]]; then
    exit 0
  fi

  if [[ "${1}" == '\'* ]]; then
    ${1:1}
  else
    # echo -e "executing:\nliq ${1}"
    liq $1
  fi
  return 1
}

# enables command substitution when preexec returns 1
shopt -s extdebug

# https://github.com/rcaloras/bash-preexec 10b41c5ed8dc28fe5bb6970cb8e12e618aa5a998
source ./bash-preexec.sh
__bp_install
EOF
)

bash --init-file <(echo "${SETUP}") -i
