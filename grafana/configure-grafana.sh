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
    echo "-r Name of the resource group"
    echo "-c Name of the CosmosDB"    
    echo "-l Artifacts location"
    echo "-h view this help content"
}

#Loop through options passed
while getopts A:p:S:T:i:s:r:c:l::h optname; do
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
    r)
      RESOURCE_GROUP="${OPTARG}"
      ;;   
    c)
      COMSOSDB_NAME="${OPTARG}"
      ;;   
    l)
      ARTIFACTS_LOCATION="${OPTARG}"
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

function retry_until_successful {
  counter=0
  "${@}"
  while [ $? -ne 0 ]; do
    if [[ "$counter" -gt 20 ]]; then
        exit 1
    else
        let counter++
    fi
    sleep 6
    "${@}"
  done;
}

function post_json() {
  curl -X POST http://admin:$ADMIN_PWD@localhost:$GRAFANA_PORT$1 \
     -H "Content-Type: application/json" \
     -d "$2"
}

#wait until Grafana gets started
retry_until_successful curl http://localhost:$GRAFANA_PORT

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
        "clientId":"${CLIENT_ID}"
    },
    "secureJsonData": {
        "clientSecret": "${CLIENT_SECRET}"
    }
}
EOF
)"

#create dashboard
dashboard_db=$(curl -s ${ARTIFACTS_LOCATION}/grafana/dashboard-db.json)
dashboard_db=${dashboard_db//'{RESOURCE-GROUP-PLACEHOLDER}'/${RESOURCE_GROUP}}
dashboard_db=${dashboard_db//'{COSMOSDB-NAME-PLACEHOLDER}'/${COMSOSDB_NAME}}

#dashboard_aks=$(curl -s ${ARTIFACTS_LOCATION}/grafana/dashboard-aks.json)

dashboard=$(curl -s ${ARTIFACTS_LOCATION}/grafana/dashboard.json)
dashboard=${dashboard//'"rows": []'/"rows": [${dashboard_aks}]}

post_json "/api/dashboards/db" "${dashboard}"