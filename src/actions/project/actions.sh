requirements-project() {
  if [[ "${ACTION}" != "init" ]]; then
    sourceCatalystfile
  fi
}

project-init() {
  echoerrandexit "The 'init' action is disabled in this version pending further testing."
  local FOUND_PROJECT=Y
  sourceCatalystfile 2> /dev/null || FOUND_PROJECT=N
  if [[ $FOUND_PROJECT == Y ]]; then
    echoerr "It looks like there's already a '.catalyst' file in place. Bailing out..."
    exit 1
  else
    BASE_DIR="$PWD"
  fi
  # TODO: verify that the parent directory is a workspace?

  projectGitSetup
}

project-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}
