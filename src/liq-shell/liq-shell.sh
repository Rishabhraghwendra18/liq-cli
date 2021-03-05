#!/usr/bin/env bash

SETUP=$(cat <<'EOF'
[[ -e /etc/bash.bashrc ]] && source /etc/bash.bashrc
[[ -e "${HOME}/.bashrc" ]] && source "${HOME}/.bashrc"
[[ -e "${HOME}/.profile" ]] && source "${HOME}/.profile"

# Setup the ssh-agent expected by liq.
# TODO: we need to figure out where we do this stuff. Most likely incorporate into 'install.sh' to keep the docker and
# native users as similar as possible. Here, e would do a scan and insert, but let's look at all possible user init
# files in our scan.
SSHAGENT=/usr/bin/ssh-agent
SSHAGENTARGS="-s"
if [ -z "$SSH_AUTH_SOCK" -a -x "$SSHAGENT" ]; then
    eval `$SSHAGENT $SSHAGENTARGS`
    trap "kill $SSH_AGENT_PID" 0
fi

PS4='$(echo $(date +"%Y/%m/%d (%H:%M)") $(history 1) >> /tmp/trace.txt)'
PS1='liq> '
set show-all-if-ambiguous on
# the _liq function should have been sourced as part of the users
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
    eval ${1:1}
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
