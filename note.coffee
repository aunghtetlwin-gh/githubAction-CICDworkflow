https://github.com/hashicorp/demo-consul-101/releases

curl -LO https://github.com/hashicorp/demo-consul-101/releases/download/v0.0.5/counting-service_linux_amd64.zip
unzip counting-service_linux_amd64.zip
mv counting-service_linux_amd64 counting-service
chmod +x counting-service


curl -LO https://github.com/hashicorp/demo-consul-101/releases/download/v0.0.5/dashboard-service_linux_amd64.zip
unzip dashboard-service_linux_amd64.zip
rm -rf dashboard-service_linux_amd64.zip
mv dashboard-service_linux_amd64 dashboard-service
chmod +x dashboard-service


export PORT=9002
export COUNTING_SERVICE_URL="http://localhost:9003"
./dashboard-service

# another way to run as a single line
PORT=9002 COUNTING_SERVICE_URL="http://localhost:9003" ./dashboard-service

upstream - counting microservice 

export PORT=9003
./counting-service



# Build dashboard-service  
cd ../dashboard-service && docker build -t dashboard-service:latest .
docker tag dashboard-service:latest aunghtetlwin/dashboard-service:latest
docker push aunghtetlwin/dashboard-service:latest

# Build counting-service
cd counting-service && docker build -t counting-service:latest .
docker tag counting-service:latest aunghtetlwin/counting-service:latest
docker push aunghtetlwin/counting-service:latest


# Pull the images
docker pull aunghtetlwin/counting-service:latest
docker pull aunghtetlwin/dashboard-service:latest

# Create a network for the services
docker network create consul-demo

# Run counting-service
docker run -d \
  --name counting-service \
  --network consul-demo \
  -p 9003:9003 \
  -e PORT=9003 \
  aunghtetlwin/counting-service:latest

# Run dashboard-service
docker run -d \
  --name dashboard-service \
  --network consul-demo \
  -p 9002:9002 \
  -e PORT=9002 \
  -e COUNTING_SERVICE_URL="http://counting-service:9003" \
  aunghtetlwin/dashboard-service:latest

docker ps 

docker logs counting-service
docker logs dashboard-service

# Access: http://localhost:9002


# Exec into dashboard container
docker exec -it dashboard-service sh

# Inside container, test the tools:
curl http://counting-service:9003
nslookup counting-service
ping -c 3 counting-service
exit


## To stop and remove containers:
docker stop counting-service  dashboard-service
docker rm counting-service dashboard-service
docker network rm consul-demo

docker compose up -d
docker compose logs -f
or 
docker compose logs -f counting-service
docker compose logs -f dashboard-service

docker compose down



docker compose up -d --scale counting=3 --scale dashboard=3
