# Utility Log Command
log()
{
    echo "`date -u +'%Y-%m-%d %H:%M:%S'`: ${1}"
}

help()
{
    echo "This script installs Grafana cluster on Ubuntu"
    echo "Parameters:"
    echo "-A admin password"
    echo "-p port to host grafana-server"
    echo "-S Azure subscription id"
    echo "-T Azure tenant id"
    echo "-i Azure service principal client id"
    echo "-s Azure service principal client secret"
    echo "-h view this help content"
}

# Parameters
ADMIN_PWD="admin"

#Loop through options passed
while getopts A:p:S:T:i:s::h optname; do
  log "Option $optname set"
  case $optname in
    A)
      ADMIN_PWD="${OPTARG}"
      ;;
    p) #port number for local grafana server
      GRAFANA_PORT="${OPTARG}"
      ;;
    S) 
      SUBSCRIPTION_ID="${OPTARG}"
      ;;
    T)
      TENANT_ID="${OPTARG}"
      ;;    
    i)
      CLIENT_ID="${OPTARG}"
      ;;    
    s)
      CLIENT_SECRET="${OPTARG}"
      ;;
    h) #show help
      help
      exit 2
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

function post_json() {
   curl -X POST http://admin:$ADMIN_PWD@localhost:$GRAFANA_PORT$1 \
     -H "Content-Type: application/json" \
     -d "$2"
}

#add Azure Monitor data source
post_json "/api/datasources" "$(cat <<EOF
{
    "name":"Azure Monitor",
    "type":"grafana-azure-monitor-datasource",
    "url":"https://management.azure.com",
    "access": "proxy",
    "isDefault":true,
    "jsonData": {
        "subscriptionId": "${SUBSCRIPTION_ID}",
        "tenantId":"${TENANT_ID}",
        "clientId":"${CLIENT_ID}",
        "clientSecret": "${CLIENT_SECRET}}"
    }
}
EOF
)"