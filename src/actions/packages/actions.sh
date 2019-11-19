requirements-packages() {
  requireCatalystfile
  # Requiring 'the' NPM package here (rather than based on command parameters)
  # is an artifact of the alpha-version limitation to a single package.
  requirePackage
}

packages-build() {
  runPackageScript build
}

packages-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'liq go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

packages-link() {
  echoerrandexit "Linking currently disabled."
}
