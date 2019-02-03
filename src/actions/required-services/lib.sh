reqServDefine() {
  local IFACE_CLASS="$1"
  local SERVICE_DEF=$(cat <<EOF
{
  "iface": "${IFACE_CLASS}",
  "params-req": [],
  "params-opt": [],
  "config-const": {}
}
EOF
)

  defineParameters SERVICE_DEF

  PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_REQ_SERVICES_KEY\" : ( .\"$CAT_REQ_SERVICES_KEY\" + [ $SERVICE_DEF ] ) }"`
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}
