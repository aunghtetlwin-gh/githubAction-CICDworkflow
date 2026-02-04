# CI/CD Demo with GitHub Actions

This project demonstrates CI/CD automation using GitHub Actions for microservices (counting-service and dashboard-service).

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

# Run with docker-compose
docker-compose up -d

# Test services
curl http://localhost:9003  # counting-service
curl http://localhost:9002  # dashboard-service

# Stop services
docker-compose down
```

## 🔄 How CI/CD Works

### Triggers
- **Push** to `main` or `master` branch
- **Pull Request** to `main` or `master` branch

### Workflow Steps

1. **Checkout Code** - Gets your code from GitHub
2. **Setup Docker Buildx** - Prepares Docker build environment
3. **Login to Docker Hub** - Authenticates with Docker Hub
4. **Extract Metadata** - Creates tags for Docker images
5. **Build & Push Images** - Builds both services and pushes to Docker Hub
6. **Deploy** - Notification step (can be extended for actual deployment)

### What Gets Built

Each push creates Docker images with two tags:
- `latest` - Always points to the most recent build
- `<branch>-<git-sha>` - Specific version tag for rollback capability

Example:
- `aunghtetlwin/counting-service:latest`
- `aunghtetlwin/counting-service:main-abc1234`

## 📦 Project Structure

```
ci-cd-demo/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml          # GitHub Actions workflow
├── counting-service/
│   ├── Dockerfile
│   └── counting-service        # Binary
├── dashboard-service/
│   ├── Dockerfile
│   └── dashboard-service       # Binary
├── docker-compose.yaml         # Local development
└── README.md
```

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
