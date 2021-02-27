#!/usr/bin/env bats

load "../lib/bats-support/load"
load "../lib/bats-assert/load"

ORIG_HOME="${HOME}"

setup() {
  HOME="${ORIG_HOME}/$(uuidgen)"
}

teardown() {
  # let's be a little cautios and not delete the real HOME or /
  [[ "${HOME}" == "${ORIG_HOME}" ]] \
    || [[ "${HOME}" == "/" ]] \
    || rm -rf "${HOME}"
}

verify-setup() {
  local PLAYGROUND="${1:-}"

  assert_success
  refute_output --partial 'Playground path must be absolute.'

  local DIR
  for DIR in '.liq' '.liq/playground' '.liq/exts' '.liq/work' '.liq/exts'; do
    assert [ -d "${HOME}/${DIR}" ]
  done
  assert [ -f "${HOME}/.liq/settings.sh" ]
  [ -z "${PLAYGROUND}" ] || assert [ -L "${HOME}/${PLAYGROUND}" ]
  [ -n "${PLAYGROUND}" ] || refute [ -e "${HOME}/playground" ]
}

@test 'meta init : should initialize default local liq DB' {
  run liq meta init
  verify-setup playground
}

@test 'meta init -p "${HOME}/sandbox" : should set visible playground link' {
  run liq meta init -p "${HOME}/sandbox"
  verify-setup sandbox
}

@test 'meta init --playground "${HOME}/sandbox" : should set visible playground link' {
  run liq meta init -p "${HOME}/sandbox"
  verify-setup sandbox
}

@test 'meta init --no-playground : should not create a visible playground link' {
  run liq meta init --no-playground
  verify-setup
}

@test 'meta init -P : should not create a visible playground link' {
  run liq meta init -P
  verify-setup
}

@test 'meta init -p sandbox : should fail with non-absolute path' {
  run liq meta init -p sandbox
  assert_output --partial 'Playground path must be absolute.'
}

@test 'initializing unwritable HOME will result in an error' {
  HOME=/
  run liq meta init
  assert_failure
  assert_output --partial 'Permission denied'
}
