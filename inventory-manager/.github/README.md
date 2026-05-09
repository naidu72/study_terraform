# CI/CD Pipeline Documentation

Workflow definitions for Inventory Manager live in the **repository root** under `.github/workflows/` (files named `inventory-manager-*.yml`). GitHub Actions only picks up workflows from that root `.github/workflows/` folder, not from `inventory-manager/.github/workflows/`.

**Branches:** push-triggered jobs run on **`pipeline`**, **`main`**, and **`develop`**; image build and Kubernetes deploy run on push to **`pipeline`** or **`main`** (so you can iterate on `pipeline` without merging first).

This folder keeps Vault/JWT setup docs and helper scripts only.

## 🔄 Workflows Overview

### 1. Backend CI/CD (`inventory-manager-backend-ci-cd.yml`)

**Triggers:**
- Push to `pipeline`, `main`, or `develop` (paths under `inventory-manager/app/backend/`)
- Pull requests targeting `main` or `pipeline`

**Jobs:**
1. **Test**
   - Runs on: `ubuntu-latest`
   - Python linting with flake8
   - Unit tests with pytest
   - Code coverage reports

2. **Build and Push**
   - Runs on: `[self-hosted, pi5]`
   - Push to `main` or `pipeline`
   - Builds ARM64 Docker image
   - Pushes to GHCR (ghcr.io/naidu72/inventory-backend)

3. **Deploy**
   - Runs on: `[self-hosted, pi5]`
   - Terraform apply to pi-cluster
   - Waits for pod readiness
   - Verifies deployment

### 2. Frontend CI/CD (`inventory-manager-frontend-ci-cd.yml`)

**Triggers:**
- Push to `pipeline`, `main`, or `develop` (paths under `inventory-manager/app/frontend/`)
- Pull requests targeting `main` or `pipeline`

**Jobs:**
1. **Test**
   - Runs on: `ubuntu-latest`
   - Node.js linting
   - React tests
   - Production build verification

2. **Build and Push**
   - Runs on: `[self-hosted, pi5]`
   - Push to `main` or `pipeline`
   - Builds ARM64 Docker image
   - Pushes to GHCR (ghcr.io/naidu72/inventory-frontend)

3. **Deploy**
   - Runs on: `[self-hosted, pi5]`
   - Terraform apply to pi-cluster
   - Waits for pod readiness
   - Tests application endpoint

### 3. Full Stack Deploy (`inventory-manager-full-stack-deploy.yml`)

**Trigger:** Manual (`workflow_dispatch`)

**Inputs:**
- `environment`: Deployment target (pi-cluster/staging/production)
- `force_rebuild`: Force rebuild Docker images

**Jobs:**
1. **Build Backend** - Builds and pushes backend image
2. **Build Frontend** - Builds and pushes frontend image
3. **Deploy** - Deploys both services with Terraform

### 4. Terraform Plan on PR (`inventory-manager-terraform-plan.yml`)

**Trigger:** Pull requests to `main` (Terraform changes only)

**Jobs:**
1. **Plan**
   - Terraform format check
   - Terraform validate
   - Terraform plan
   - Comments plan output on PR

### 5. Destroy Infrastructure (`inventory-manager-destroy-infrastructure.yml`)

**Trigger:** Manual (`workflow_dispatch`) with confirmation

**Inputs:**
- `environment`: Environment to destroy
- `confirmation`: Must type "DESTROY" exactly

**Jobs:**
1. **Destroy** - Runs `terraform destroy` (only if confirmed)
2. **Abort** - Aborts if confirmation is incorrect

## 🔐 Secrets Management

### Using Vault JWT Authentication (Recommended)

The workflows use **HashiCorp Vault JWT/OIDC authentication** to fetch secrets automatically. This eliminates the need to store secrets in GitHub!

**Benefits:**
- ✅ No secrets to manage in GitHub
- ✅ Automatic authentication with OIDC tokens
- ✅ Short-lived credentials
- ✅ Centralized secret management in Vault
- ✅ Auditable access

**Setup:**
See [VAULT-JWT-SETUP.md](./VAULT-JWT-SETUP.md) for complete configuration instructions.

**Required Vault Secrets:**
All secrets are fetched from Vault automatically:
- `secret/minio/credentials` - MinIO access credentials
  - `access_key_id`
  - `secret_access_key`
- `secret/ghcr/credentials` - GitHub Container Registry token
  - `token`
- `secret/inventory-manager/postgres` - PostgreSQL password
  - `password`
- `secret/inventory-manager/jwt` - JWT secret key
  - `secret_key`

**Workflow Permissions:**
All workflows include these permissions for JWT auth:
```yaml
permissions:
  contents: read
  id-token: write  # Required for OIDC token
```

### Alternative: GitHub Secrets (Not Recommended)

If you prefer to use GitHub secrets instead of Vault:

1. Remove JWT auth steps from workflows
2. Configure these secrets in GitHub repository settings:
   - `MINIO_ACCESS_KEY`
   - `MINIO_SECRET_KEY`
   - `GHCR_TOKEN`
   - `POSTGRES_PASSWORD`
   - `JWT_SECRET_KEY`

⚠️ **Note:** Using GitHub secrets is less secure and harder to manage across multiple repositories.

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

1. **If using Vault JWT auth** (recommended):
   - Check Vault is accessible: `curl https://vault.naidu72.info/v1/sys/health`
   - Verify JWT role exists: `vault read auth/jwt/role/github-actions`
   - Check workflow has `id-token: write` permission
   - Review Vault audit logs for auth failures

2. **If using GitHub secrets** (alternative):
   - Go to Settings → Secrets and variables → Actions
   - Ensure all required secrets are set
   - Test secret access in workflow:
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
- **[Vault JWT/OIDC Setup Guide](./VAULT-JWT-SETUP.md)** ← Start here for secrets management
- [HashiCorp Vault Action](https://github.com/hashicorp/vault-action)
- [GitHub OIDC with Vault](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

## 🎯 Best Practices

1. **Always test in PR** before merging to main
2. **Use `workflow_dispatch`** for manual deployments
3. **Monitor workflow runs** for failures
4. **Keep secrets up to date** in GitHub settings
5. **Clean up runner** periodically to free disk space
6. **Review Terraform plans** before applying
7. **Use confirmation** for destructive operations
8. **Preserve state files** in MinIO for recovery
