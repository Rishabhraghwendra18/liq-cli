pre-options-liq-projects() {
  pre-options-liq
}

post-options-liq-projects() {
  post-options-liq
}

liq-projects-options-specify-project() {
  echo "PROJECT="
}

liq-projects-options-process-project() {
  # check call requirements
  local VAR_NAME # TODO: move this to bash-toolkit
  for VAR_NAME in PROJECT_PATH; do
    declare -p ${VAR_NAME} >/dev/null \
      || echoerrandexit "'${VAR_NAME}' not declared as expected."
  done

  if [[ -z "${PROJECT}" ]]; then # let's infer it
    [[ -n "${PACKAGE_NAME}" ]] || requirePackage
    PROJECT="${PACKAGE_NAME}"
  fi
  PROJECT="${PROJECT/@/}" # normalise project name

  PROJECT_PATH="${LIQ_PLAYGROUND}/${PROJECT}"
  [[ -d "${PROJECT_PATH}" ]] \
    || echoerrandexit "Did not find project at '${PROJECT_PATH}'"
}
