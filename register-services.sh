#!/bin/bash

# Get container IPs
COUNTING_IPS=($(docker ps --filter "name=counting" --format "{{.Names}}" | sort | while read name; do docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $name; done))
DASHBOARD_IPS=($(docker ps --filter "name=dashboard" --format "{{.Names}}" | sort | while read name; do docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $name; done))

# Register counting services
for i in "${!COUNTING_IPS[@]}"; do
  SERVICE_ID="counting-$((i+1))"
  IP="${COUNTING_IPS[$i]}"
  
  echo "Registering $SERVICE_ID at $IP:9003"
  
  curl -s -X PUT -d "{
    \"ID\": \"$SERVICE_ID\",
    \"Name\": \"counting\",
    \"Address\": \"$IP\",
    \"Port\": 9003,
    \"Check\": {
      \"HTTP\": \"http://$IP:9003/health\",
      \"Interval\": \"10s\",
      \"Timeout\": \"2s\"
    }
  }" http://localhost:8500/v1/agent/service/register
  
  echo " ✓"
done

# Register dashboard services
for i in "${!DASHBOARD_IPS[@]}"; do
  SERVICE_ID="dashboard-$((i+1))"
  IP="${DASHBOARD_IPS[$i]}"
  
  echo "Registering $SERVICE_ID at $IP:9002"
  
  curl -s -X PUT -d "{
    \"ID\": \"$SERVICE_ID\",
    \"Name\": \"dashboard\",
    \"Address\": \"$IP\",
    \"Port\": 9002,
    \"Check\": {
      \"HTTP\": \"http://$IP:9002/health\",
      \"Interval\": \"10s\",
      \"Timeout\": \"2s\"
    }
  }" http://localhost:8500/v1/agent/service/register
  
  echo " ✓"
done

echo ""
echo "All services registered! Check http://localhost:8500/ui/dc1/services"
