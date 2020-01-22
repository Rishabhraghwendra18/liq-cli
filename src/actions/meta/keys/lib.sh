meta-keys-user-has-key() {
  local USER
  USER="$(git config user.email)"
  if [[ -z "$USER" ]]; then
    echoerrandexit "git 'user.email' not set; needed for digital signing."
  fi

  if ! command -v gpg2 > /dev/null; then
    echoerrandexit "'gpg2' not found in path; please install. This is needed for digital signing."
  fi

  if ! gpg2 --list-secret-keys "$USER" > /dev/null; then
    echoerrandexit "No PGP key found for '$USER'. Either update git 'user.email' configuration, or add a key. To add a key, use:\nliq meta keys create"
  fi
}
