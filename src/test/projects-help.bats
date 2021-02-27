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

@test 'liq projects : will result in help message' {
  run liq projects
  assert_failure
  # the output is colored
  assert_line --index 0 --regexp '^liq .*projects.* <action>'
  assert_line --index $(( ${#lines[@]} - 1)) --regexp '.*No action argument provided. See valid actions above\..*'
}
