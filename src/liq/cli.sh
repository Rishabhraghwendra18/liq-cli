#!/usr/bin/env bash

source ./exec-preamble.sh

liq-init-exts "$@"

liq-dispatch "$@"

exit 0
