# Consul CI/CD Demo

This project demonstrates a multi-architecture Docker CI/CD pipeline with Consul service discovery. It shows how to build, deploy, and register microservices in Consul for monitoring and visibility.

## Features
- **GitHub Actions CI/CD** builds and pushes multi-platform images for:
  - Linux AMD64 (Standard servers)
  - Linux ARM64 (ARM servers, Apple Silicon)
- **Docker Compose** launches:
  - 3 `counting-service` containers
  - 3 `dashboard-service` containers
  - 1 Consul agent for service registration/monitoring
  - 1 Registrator container for automatic service registration
- **Automatic Consul Registration**: All service containers are registered with Consul via a custom script with health checks

## 📋 Prerequisites

1. **GitHub Account** - Repository where code is hosted
2. **Docker Hub Account** - For storing Docker images
3. **Local Development Environment** - Docker and Docker Compose installed

## 🚀 Setup Instructions

### Step 1: Push Code to GitHub

```bash
# Initialize git repository (if not already done)
git init

# Add remote repository
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Add all files
git add .

# Commit
git commit -m "Initial commit with CI/CD setup"

# Push to GitHub
git push -u origin main
```

### Step 2: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secret:

- **Name:** `DOCKER_PASSWORD`
- **Value:** Your Docker Hub password or access token

> 💡 **Tip:** Use Docker Hub Access Tokens instead of your password for better security.
> Create one at: https://hub.docker.com/settings/security

### Step 3: Update Docker Hub Username (Optional)

If you're not using `aunghtetlwin` as your Docker Hub username:

1. Edit [.github/workflows/ci-cd.yaml](.github/workflows/ci-cd.yaml)
2. Change the `DOCKER_USERNAME` environment variable to your username
3. Update [docker-compose.yaml](docker-compose.yaml) image names

### Step 4: Test Locally (Optional)

```bash
# Build images locally
docker build -t aunghtetlwin/counting-service:latest ./counting-service
docker build -t aunghtetlwin/dashboard-service:latest ./dashboard-service

# Push to Docker Hub
docker push aunghtetlwin/counting-service:latest
docker push aunghtetlwin/dashboard-service:latest
```

## 🏃 Quick Start - Running with Consul

### 1. Start the Stack

Run the following command to start 3 instances of each service with Consul:

```bash
docker compose up -d --scale counting=3 --scale dashboard=3
```

This will start:
- 3 `counting-service` containers (port 9003)
- 3 `dashboard-service` containers (port 9002)
- 1 Consul agent (port 8500 - UI accessible at http://localhost:8500)
- 1 registrator container to auto-register services in Consul

### 2. Inspect Docker Network

Check the network configuration and container IPs:

```bash
# List networks
docker network ls

# Inspect the application network
docker network inspect ci-cd-demo_appnet
```

Example output:
```json
{
  "Name": "ci-cd-demo_appnet",
  "Driver": "bridge",
  "Subnet": "172.18.0.0/16",
  "Gateway": "172.18.0.1",
  "Containers": {
    "ci-cd-demo-consul-1": { "IPv4Address": "172.18.0.2/16" },
    "ci-cd-demo-counting-1": { "IPv4Address": "172.18.0.3/16" },
    "ci-cd-demo-counting-2": { "IPv4Address": "172.18.0.4/16" },
    "ci-cd-demo-counting-3": { "IPv4Address": "172.18.0.5/16" },
    "ci-cd-demo-dashboard-1": { "IPv4Address": "172.18.0.6/16" },
    "ci-cd-demo-dashboard-2": { "IPv4Address": "172.18.0.7/16" },
    "ci-cd-demo-dashboard-3": { "IPv4Address": "172.18.0.8/16" }
  }
}
```

### 3. Verify Consul Registration

Wait a few seconds for the registrator to complete, then check the logs:

```bash
docker logs ci-cd-demo-registrator-1
```

Expected output:
```
Registering counting-1 at 172.18.0.3:9003
 ✓
Registering counting-2 at 172.18.0.4:9003
 ✓
Registering counting-3 at 172.18.0.5:9003
 ✓
Registering dashboard-1 at 172.18.0.6:9002
 ✓
Registering dashboard-2 at 172.18.0.7:9002
 ✓
Registering dashboard-3 at 172.18.0.8:9002
 ✓

All services registered! Check http://localhost:8500/ui/dc1/services
```

### 4. Access Consul UI

Open your browser and navigate to:
```
http://localhost:8500
```

You should see all 6 services registered (3 counting + 3 dashboard) with their health check status.

### 5. Verify Service Health

Check if services are passing health checks:

```bash
# Query Consul API for counting service
curl http://localhost:8500/v1/health/service/counting?passing

# Query Consul API for dashboard service
curl http://localhost:8500/v1/health/service/dashboard?passing
```

### 6. Stop the Stack

When you're done:

```bash
# Stop and remove all containers
docker compose down

# Stop and remove containers + volumes
docker compose down -v
```

## 🔄 How CI/CD Works

### Triggers
Workflow runs automatically when:
```bash
git push origin main        # Push to main branch
```
Or when creating a Pull Request to `main`/`master`

### Build Process (Parallel Jobs)

**Matrix Strategy** - Runs 2 jobs in parallel:

```bash
# Job 1: counting-service
- Checkout code
- Setup QEMU (for multi-platform support)
- Setup Docker Buildx
- Login to Docker Hub
- Build image for AMD64 & ARM64 → aunghtetlwin/counting-service:latest
- Tag with commit SHA → aunghtetlwin/counting-service:main-abc1234
- Push to Docker Hub

# Job 2: dashboard-service  
- Same steps for dashboard-service
```

**Multi-Platform Support:**
```bash
# Images built for both architectures:
- linux/amd64  # Standard servers (AWS EC2, DigitalOcean, etc.)
- linux/arm64  # ARM servers (Raspberry Pi, AWS Graviton, Apple Silicon)
```

### What Gets Built

Each push creates images with 2 tags:
```bash
# Latest tag
aunghtetlwin/counting-service:latest
aunghtetlwin/dashboard-service:latest

# Commit SHA tag (for rollback)
aunghtetlwin/counting-service:main-cd08791
aunghtetlwin/dashboard-service:main-cd08791
```

### Deploy Process

After successful build:
```bash
# Currently just shows notification
echo "Images pushed successfully"

# Can be extended to auto-deploy:
docker-compose pull    # Pull new images
docker-compose up -d   # Restart containers
```

Example:
- `aunghtetlwin/counting-service:latest`
- `aunghtetlwin/counting-service:main-abc1234`

## 📦 Project Structure

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

## 🔍 How It Works

### Service Registration Flow

1. **Docker Compose starts** all containers (Consul, counting, dashboard services)
2. **Containers get IPs** from the Docker bridge network (`appnet`)
3. **Registrator container** waits 10 seconds for services to be ready
4. **Registration script** (`register-services.sh`) runs:
   - Discovers all running counting/dashboard containers
   - Extracts their IP addresses from Docker network
   - Registers each instance with Consul API
   - Configures HTTP health checks for each service
5. **Consul monitors** all registered services via health checks every 10 seconds
6. **Consul UI** displays real-time service health and status

## 🔐 Security Best Practices

1. ✅ Never commit secrets to Git
2. ✅ Use GitHub Secrets for sensitive data
3. ✅ Use Docker Hub Access Tokens instead of passwords
4. ✅ Review pull requests before merging
5. ✅ Enable branch protection rules

## 🚀 Extending Deployment

### Deploy to Server via SSH

Uncomment the deployment section in [.github/workflows/ci-cd.yaml](.github/workflows/ci-cd.yaml) and add these secrets:

- `SERVER_HOST` - Your server IP or hostname
- `SERVER_USER` - SSH username
- `SERVER_SSH_KEY` - Private SSH key for authentication

### Deploy to Cloud Platforms

**AWS ECS:**
```yaml
- name: Deploy to ECS
  uses: aws-actions/amazon-ecs-deploy-task-definition@v1
```

**Azure Container Apps:**
```yaml
- name: Deploy to Azure
  uses: azure/container-apps-deploy-action@v1
```

**Kubernetes:**
```yaml
- name: Deploy to Kubernetes
  uses: azure/k8s-deploy@v1
```

## 📊 Monitoring Workflow

1. Go to your GitHub repository
2. Click **Actions** tab
3. You'll see all workflow runs
4. Click on any run to see detailed logs

## 🐛 Troubleshooting

### Build Fails
- Check if binaries exist in service folders
- Verify Dockerfile syntax

### Docker Hub Push Fails
- Verify `DOCKER_PASSWORD` secret is set correctly
- Check Docker Hub username in workflow

### Deployment Fails
- Verify SSH credentials
- Check server accessibility
- Ensure docker-compose is installed on server

## 📝 Notes

- Images are cached to speed up subsequent builds
- Deployment only runs on `main`/`master` branch pushes
- Pull requests will build but not deploy

## 🎯 Next Steps

1. Add automated tests to the workflow
2. Implement rolling deployments
3. Add Slack/Discord notifications
4. Set up staging and production environments
5. Add monitoring and alerting
