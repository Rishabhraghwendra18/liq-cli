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
  local GROUP="${1}"
  local NAME_FIELD="${2}"
  local ID_FIELD="${3}"
  local FILTER="${4:-}"

  local QUERY="gcloud $GROUP list --format=\"value($NAME_FIELD,$ID_FIELD)[quote,separator=' ']\""
  if [[ -n "$FILTER" ]]; then
    QUERY="$QUERY --filter=\"$FILTER\""
  fi

  # expects 'NAMES' and 'IDS' to have been declared by caller
  local LINE NAME ID
  function split() {
    NAME="$1"
    ID="$2"
  }
  while read LINE; do
    eval "split $LINE"
    list-add-item NAMES "$NAME" "\n"
    list-add-item IDS "$ID" "\n"
  done < <(eval "$QUERY")
}
