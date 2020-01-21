meta-keys() {
  local ACTION="${1}"; shift

  if [[ $(type -t "meta-keys-${ACTION}" || echo '') == 'function' ]]; then
    meta-keys-${ACTION} "$@"
  else
    exitUnknownHelpTopic "$ACTION" meta keys
  fi
}

meta-keys-create() {
  eval "$(setSimpleOptions IMPORT USER= FULL_NAME= -- "$@")"

  if [[ -z "$USER" ]]; then
    USER="$(git config user.email)"
    if [[ -z "$USER" ]]; then
      echoerrandexit "Must set git 'user.email' or specify '--user' to create key."
    fi
  fi

  if [[ -z "${FULL_NAME}" ]]; then
    FULL_NAME="$(git config user.email)"
    if [[ -z "$FULL_NAME" ]]; then
      echoerrandexit "Must set git 'user.name' or specify '--full-name' to create key."
    fi
  fi

  # Does the key already exist?
  if gpg2 --list-secret-keys "$USER" 2> /dev/null; then
    echoerrandexit "Key for '${USER}' already exists in default secret keyring. Bailing out..."
  fi

  local BITS=4096
  local ALGO=rsa
  local EXPIRY_YEARS=5
  gpg2 --batch --gen-key <<<"%echo Generating ${ALGO}${BITS} key for '${USER}'; expires in ${EXPIRY_YEARS} years.
Key-Type: RSA
Key-Length: 4096
Name-Real: ${FULL_NAME}
Name-Comment: General purpose key.
Name-Email: ${USER}
Expire-Date: ${EXPIRY_YEARS}y
%ask-passphrase
%commit"
}
