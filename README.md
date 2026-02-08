# Consul CI/CD Demo

This project demonstrates a multi-architecture Docker CI/CD pipeline. It includes a flexible load-balanced dashboard service using Nginx, leveraging Docker DNS for automatic service discovery. All services are registered in Consul for monitoring and visibility.

## Architecture
![Diagram](assets/architecture.png)

## Features
- **GitHub Actions CI/CD** builds and pushes multi-platform images for:
  - Linux AMD64 (Standard servers)
  - Linux ARM64 (ARM servers, Apple Silicon)
- **Docker Compose** launches:
  - 3 `counting-service` containers
  - 3 `dashboard-service` containers
  - 1 Consul agent for service registration/monitoring
  - 1 Registrator container for automatic service registration
  - 1 Nginx load balancer for dashboard service (auto-load balances all dashboard instances)
- **Automatic Consul Registration**: All service containers are registered with Consul via a custom script with health checks
- **Flexible Service Discovery**: Nginx uses Docker DNS to dynamically route traffic to all dashboard-service containers, supporting scaling and zero manual IP configuration
- **Consul DNS Integration**: 
  - Consul agent configured with DNS recursion (`-recursor=8.8.8.8`) to resolve external domains
  - Consul DNS server exposed on port 53 for container DNS queries
  - Static IP address (`172.20.0.100`) assigned to Consul for reliable DNS resolution
  - All service containers configured to use Consul as their DNS server, enabling `.service.consul` domain resolution

## Prerequisites

1. **GitHub Account** - Repository where code is hosted
2. **Docker Hub Account** - For storing Docker images
3. **Local Development Environment** - Docker and Docker Compose installed

## Quick Start

### 1. Build & Push Images (CI/CD)
Images are built and pushed to Docker Hub automatically via GitHub Actions when you push to the `main` or `loadbalancer` branch.

- See `.github/workflows/ci-cd.yaml` for workflow details
- Images are multi-arch (amd64, arm64) and compatible with Linux and Apple Silicon
- Each push creates images with `latest` tag and commit SHA tag

### 2. Configure GitHub Secrets (First Time Only)

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secret:
- **Name:** `DOCKER_PASSWORD`
- **Value:** Your Docker Hub password or access token

If using a different Docker Hub username, update `DOCKER_USERNAME` in `.github/workflows/ci-cd.yaml`

### 3. Run the Stack

```sh
docker compose up -d --scale counting=3 --scale dashboard=3
```

This will start:
- 3 `counting-service` containers (port 9003)
- 3 `dashboard-service` containers (port 9002)
- 1 Consul agent (port 8500)
- 1 registrator container to auto-register services in Consul
- 1 Nginx load balancer for dashboard service (port 8080)
- 1 registrator container to auto-register services in Consul

### 4. Inspect Docker Network

```sh
docker network ls
docker network inspect ci-cd-demo_appnet
```

Example output:
```json
{
  "Name": "ci-cd-demo_appnet",
  "Driver": "bridge",
  "Subnet": "172.19.0.0/16",
  "Gateway": "172.19.0.1",
  "Containers": {
    "ci-cd-demo-consul-1": { "IPv4Address": "172.19.0.2/16" },
    "ci-cd-demo-counting-2": { "IPv4Address": "172.19.0.3/16" },
    "ci-cd-demo-counting-3": { "IPv4Address": "172.19.0.4/16" },
    "ci-cd-demo-counting-1": { "IPv4Address": "172.19.0.5/16" },
    "ci-cd-demo-dashboard-2": { "IPv4Address": "172.19.0.6/16" },
    "ci-cd-demo-dashboard-3": { "IPv4Address": "172.19.0.7/16" },
    "ci-cd-demo-dashboard-1": { "IPv4Address": "172.19.0.8/16" }
  }
}
```

### 5. Check Consul Registration

Wait a few seconds for the registrator to complete, then check the logs:

```sh
docker logs ci-cd-demo-registrator-1
```

Example output:
```
Registering counting-1 at 172.20.0.2:9003
 ✓
Registering counting-2 at 172.20.0.3:9003
 ✓
Registering counting-3 at 172.20.0.4:9003
 ✓
Registering dashboard-1 at 172.20.0.5:9002
 ✓
Registering dashboard-2 at 172.20.0.6:9002
 ✓
Registering dashboard-3 at 172.20.0.7:9002
 ✓

All services registered! Check http://localhost:8500/ui/dc1/services
```

You should see all services registered in the Consul UI.

![Consul UI](assets/consul-UI.png)

### 6. Dashboard Load Balancer (Nginx)

The dashboard service is accessible through an Nginx load balancer, which provides a single entry point and automatically distributes requests across all running dashboard-service containers. Nginx uses Docker DNS for dynamic service discovery and load balancing.

**Access the dashboard**: http://localhost:8080

![Dashboard via Load Balancer](assets/lb.png)

### 7. Testing Fault Tolerance by Scaling Down Counting Service

You can test fault tolerance and service discovery by reducing the number of counting-service containers. For example, you can stop containers individually:

```sh
docker stop ci-cd-demo-counting-1
# ...or...
docker stop ci-cd-demo-counting-3
```

Or scale down using Docker Compose:

```sh
docker compose up -d --scale counting=1 --scale dashboard=3
```

After scaling down, the dashboard will continue to work and route requests to the remaining counting-service instance automatically. Consul UI will reflect the change in registered services, and Docker DNS ensures requests are always sent to available containers.

This demonstrates the resilience of your architecture: services remain available even when some containers are stopped or removed, with no manual reconfiguration required.

![Scaling Down Counting Service](assets/scale-down-counting.png)
![Dashboard Still Works](assets/dashboard-still-works.png)

### 8. Stop the Stack

When you're done:

```sh
docker compose down
```

## Project Structure

```
ci-cd-demo/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml              # GitHub Actions workflow
├── counting-service/
│   ├── Dockerfile                  # Multi-platform Dockerfile
│   └── counting-service            # Go binary
├── dashboard-service/
│   ├── Dockerfile                  # Multi-platform Dockerfile
│   └── dashboard-service           # Go binary
├── docker-compose.yaml             # Consul + Services orchestration
├── register-services.sh            # Automatic Consul registration script
└── README.md
```

## How It Works

### CI/CD Pipeline
1. Push code to GitHub `main` branch
2. GitHub Actions triggers workflow
3. Builds Docker images for both AMD64 and ARM64 architectures
4. Pushes images to Docker Hub with `latest` and commit SHA tags

### Service Registration Flow
1. Docker Compose starts all containers (Consul, counting, dashboard services)
2. Containers get IPs from the Docker bridge network (`appnet`)
3. Registrator container waits 10 seconds for services to be ready
4. Registration script (`register-services.sh`) runs:
   - Discovers all running counting/dashboard containers
   - Extracts their IP addresses from Docker network
   - Registers each instance with Consul API
   - Configures HTTP health checks for each service
5. Consul monitors all registered services via health checks every 10 seconds
6. Consul UI displays real-time service health and status

