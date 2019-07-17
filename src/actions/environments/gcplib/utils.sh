function gcpNameToId() {
  echo "$1" | tr ' ' '-' | tr '[:upper:]' '[:lower:]'
}

function environmentsCheckCloudSDK() {
  command -v gcloud >/dev/null || \
    echoerrandexit "Required 'gcloud' command not found. Refer to:\nhttps://cloud.google.com/sdk/docs/"

  # beta needed for billing management and it's easier to just install rather
  # than deal with whether or not they need billing management
  local COM
  for COM in beta ; do
    if [ 0 -eq `gcloud --verbosity error components list --filter="Status='Installed'" --format="value(ID)" 2>/dev/null | grep $COM | wc -l` ]; then
      gcloud components install $COM
    fi
  done
}

function environmentsGoogleCloudOptions() {
  # TODO: can't use setSimpleOptions because it doesn't handle input with spaces correctly.
  # local TMP # see https://unix.stackexchange.com/a/88338/84520
  # TMP=$(setSimpleOptions FILTER= -- "$@") \
  #  || ( contextHelp; echoerrandexit "Bad options." )
  # eval "$TMP"

  local GROUP="${1}"; shift
  local NAME_FIELD="${1}"; shift
  local ID_FIELD="${1}"; shift
  local FILTER="${1:-}"
  if (( $# > 0 )); then shift; fi

  local QUERY="gcloud $GROUP list --format=\"value($NAME_FIELD,$ID_FIELD)[quote,separator=' ']\""
  if [[ -n "$FILTER" ]]; then
    QUERY="$QUERY --filter=\"$FILTER\""
  fi
  if [[ "$GROUP" != 'projects' ]] && [[ "$GROUP" != 'organizations' ]]; then
    QUERY="$QUERY --project='${GCP_PROJECT_ID}'"
  fi

  # expects 'NAMES' and 'IDS' to have been declared by caller
  local LINE NAME ID
  function split() {
    NAME="$1"
    ID="$2"
  }
  while read LINE; do
    eval "split $LINE"
    list-add-item NAMES "$NAME"
    list-add-item IDS "$ID"
  done < <(eval "$QUERY" "$@")
}

function environmentsGcpEnsureProjectId() {
  if [[ -z $GCP_PROJECT_ID ]]; then
    echoerrandexit "'GCP_PROJECT_ID' unset; likely program error."
  fi
}
