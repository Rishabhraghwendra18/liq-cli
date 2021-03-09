#!/usr/bin/env bash

# Not sure why 'repo' access is needed for the token, but as of the 2021-02-27 github required it in order to download
# packages.
[ -f "${HOME}/.npmrc" ] && grep -qE '^@bats-core:registry=https://npm.pkg.github.com/$' ~/.npmrc \
  || { # the \033... bit sets the color to red
    echo -e \
"\033[0;31mDid not find '@bats-core' registry config in '$<'.
Add these line to the file:

grep -@bats-core:registry=https://npm.pkg.github.com/
//npm.pkg.github.com/:_authToken=abcdef12345

Replace the 'authToken' with a personal access token with 'package read' and 'repo' access.

To create your access token:
https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token
\033[0m" >&2 # reset the color

    exit 1
  }
