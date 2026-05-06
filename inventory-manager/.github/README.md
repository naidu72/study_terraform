# CI/CD Pipeline Documentation

This directory contains GitHub Actions workflows for automated building, testing, and deployment of the Inventory Manager application.

## 🔄 Workflows Overview

### 1. Backend CI/CD (`backend-ci-cd.yml`)

**Triggers:**
- Push to `main` or `develop` branches (backend changes only)
- Pull requests to `main` (backend changes only)

**Jobs:**
1. **Test**
   - Runs on: `ubuntu-latest`
   - Python linting with flake8
   - Unit tests with pytest
   - Code coverage reports

2. **Build and Push**
   - Runs on: `[self-hosted, pi5]`
   - Only on push to `main`
   - Builds ARM64 Docker image
   - Pushes to GHCR (ghcr.io/naidu72/inventory-backend)

3. **Deploy**
   - Runs on: `[self-hosted, pi5]`
   - Terraform apply to pi-cluster
   - Waits for pod readiness
   - Verifies deployment

### 2. Frontend CI/CD (`frontend-ci-cd.yml`)

**Triggers:**
- Push to `main` or `develop` branches (frontend changes only)
- Pull requests to `main` (frontend changes only)

**Jobs:**
1. **Test**
   - Runs on: `ubuntu-latest`
   - Node.js linting
   - React tests
   - Production build verification

2. **Build and Push**
   - Runs on: `[self-hosted, pi5]`
   - Only on push to `main`
   - Builds ARM64 Docker image
   - Pushes to GHCR (ghcr.io/naidu72/inventory-frontend)

3. **Deploy**
   - Runs on: `[self-hosted, pi5]`
   - Terraform apply to pi-cluster
   - Waits for pod readiness
   - Tests application endpoint

### 3. Full Stack Deploy (`full-stack-deploy.yml`)

**Trigger:** Manual (`workflow_dispatch`)

**Inputs:**
- `environment`: Deployment target (pi-cluster/staging/production)
- `force_rebuild`: Force rebuild Docker images

**Jobs:**
1. **Build Backend** - Builds and pushes backend image
2. **Build Frontend** - Builds and pushes frontend image
3. **Deploy** - Deploys both services with Terraform

### 4. Terraform Plan on PR (`terraform-plan.yml`)

**Trigger:** Pull requests to `main` (Terraform changes only)

**Jobs:**
1. **Plan**
   - Terraform format check
   - Terraform validate
   - Terraform plan
   - Comments plan output on PR

### 5. Destroy Infrastructure (`destroy-infrastructure.yml`)

**Trigger:** Manual (`workflow_dispatch`) with confirmation

**Inputs:**
- `environment`: Environment to destroy
- `confirmation`: Must type "DESTROY" exactly

**Jobs:**
1. **Destroy** - Runs `terraform destroy` (only if confirmed)
2. **Abort** - Aborts if confirmation is incorrect

## 🔐 Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

### Docker Registry
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

### MinIO Backend
- `MINIO_ACCESS_KEY` - MinIO access key ID
- `MINIO_SECRET_KEY` - MinIO secret access key

### Application Secrets
- `GHCR_USERNAME` - GitHub Container Registry username (naidu72)
- `GHCR_TOKEN` - GHCR personal access token
- `POSTGRES_PASSWORD` - PostgreSQL database password
- `JWT_SECRET_KEY` - JWT secret key for authentication

## 🖥️ Self-Hosted Runner Setup

The workflows use a self-hosted runner on Pi5 with the label `[self-hosted, pi5]`.

### Runner Requirements

1. **Docker** - For building images
2. **kubectl** - Configured for pi-k8s cluster
3. **Terraform** - Installed via setup-terraform action
4. **AWS CLI** - For MinIO S3 backend

### Runner Configuration

```bash
# On the Pi5 host
cd /home/frontier/actions-runner
./run.sh
```

**Labels:** `self-hosted`, `Linux`, `ARM64`, `pi5`

## 📊 Workflow Execution Flow

### Automatic Deployment (Push to main)

```
┌─────────────────────┐
│  Push to main       │
│  (backend changed)  │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│  Test (Ubuntu)      │
│  - Linting          │
│  - Unit tests       │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│  Build (Pi5)        │
│  - Docker build     │
│  - Push to GHCR     │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│  Deploy (Pi5)       │
│  - Terraform apply  │
│  - Verify pods      │
└─────────────────────┘
```

### Pull Request Review

```
┌─────────────────────┐
│  PR to main         │
│  (terraform changed)│
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│  Terraform Plan     │
│  - Format check     │
│  - Validate         │
│  - Plan output      │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│  Comment on PR      │
│  with plan details  │
└─────────────────────┘
```

## 🚀 Manual Deployment

### Deploy Full Stack

1. Go to **Actions** tab
2. Select **Full Stack Deploy** workflow
3. Click **Run workflow**
4. Choose:
   - Environment: `pi-cluster`
   - Force rebuild: `true` (to rebuild images) or `false` (use existing)
5. Click **Run workflow**

### Destroy Infrastructure

1. Go to **Actions** tab
2. Select **Destroy Infrastructure** workflow
3. Click **Run workflow**
4. Choose environment: `pi-cluster`
5. Type **exactly**: `DESTROY`
6. Click **Run workflow**

⚠️ **Warning**: This will destroy all resources. State file is preserved in MinIO.

## 🔍 Monitoring Deployments

### View Workflow Runs

```bash
# List recent workflow runs
gh run list --limit 10

# View specific run details
gh run view <run-id>

# Watch a running workflow
gh run watch <run-id>
```

### Check Deployment Status

```bash
# Check pods
kubectl get pods -n inventory-manager

# Check logs
kubectl logs -n inventory-manager -l app=inventory-manager-backend --tail=100
kubectl logs -n inventory-manager -l app=inventory-manager-frontend --tail=100

# Check ingress
kubectl get ingress -n inventory-manager
```

### Verify Application

```bash
# Test frontend
curl -I https://inventory-pi.naidu72.info/

# Test backend API
curl https://inventory-pi.naidu72.info/api/v1/health
```

## 🛠️ Troubleshooting

### Workflow Failed on Build

1. Check Docker daemon on runner:
   ```bash
   docker ps
   docker images
   ```

2. Check disk space:
   ```bash
   df -h
   docker system df
   ```

3. Clean up if needed:
   ```bash
   docker system prune -a -f
   ```

### Workflow Failed on Deploy

1. Check Terraform state:
   ```bash
   cd terraform/environments/pi-cluster
   terraform init
   terraform plan
   ```

2. Check MinIO access:
   ```bash
   aws --endpoint-url http://192.168.0.151:30900 s3 ls s3://terraform-state/
   ```

3. Check kubectl access:
   ```bash
   kubectl get nodes
   kubectl get pods -n inventory-manager
   ```

### Secrets Not Working

1. Verify secrets in GitHub:
   - Go to Settings → Secrets and variables → Actions
   - Ensure all required secrets are set

2. Test secret access in workflow:
   ```yaml
   - name: Test secrets
     run: |
       echo "Testing secret access..."
       [ -n "${{ secrets.MINIO_ACCESS_KEY }}" ] && echo "✓ MINIO_ACCESS_KEY set"
   ```

## 📈 Performance Optimizations

### Docker Build Cache

- Uses registry cache: `type=registry,ref=...:buildcache`
- Significantly reduces build times
- Shared across workflow runs

### Selective Workflows

- Path filters prevent unnecessary runs
- Backend changes don't trigger frontend workflows
- Frontend changes don't trigger backend workflows

### Parallel Jobs

- Test jobs run on `ubuntu-latest` (faster)
- Build jobs run on `[self-hosted, pi5]` (ARM64 native)
- Multiple workflows can run in parallel

## 🔄 Updating Workflows

### Modify a Workflow

1. Edit the workflow file
2. Commit and push to a feature branch
3. Create PR to `main`
4. Review changes
5. Merge when approved

### Test Workflow Changes

Use a separate branch and test with `workflow_dispatch`:

```yaml
on:
  workflow_dispatch:  # Add for testing
  push:
    branches: [ main ]
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)

## 🎯 Best Practices

1. **Always test in PR** before merging to main
2. **Use `workflow_dispatch`** for manual deployments
3. **Monitor workflow runs** for failures
4. **Keep secrets up to date** in GitHub settings
5. **Clean up runner** periodically to free disk space
6. **Review Terraform plans** before applying
7. **Use confirmation** for destructive operations
8. **Preserve state files** in MinIO for recovery
