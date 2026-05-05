# GitHub Actions CI/CD (Phase 5)

This directory contains GitHub Actions workflows for automated build and deployment.

## 📅 Status: Phase 5 (Planned)

**Current Phase**: Phase 1 ✅ Complete  
**This Phase**: 🔜 Not started

## 📦 Workflow Files

```
.github/workflows/
├── build-push.yaml         # Build and push Docker images
├── terraform-plan.yaml     # Terraform plan on PR
├── terraform-apply.yaml    # Terraform apply on merge
└── test.yaml              # Run tests
```

## 🎯 CI/CD Pipeline

### 1. Build & Push (build-push.yaml)
**Trigger**: Push to `main` branch  
**Actions**:
- Build multi-arch Docker images (amd64 + arm64)
- Push to GitHub Container Registry (ghcr.io)
- Push to Docker Hub
- Tag with commit SHA and `latest`

### 2. Terraform Plan (terraform-plan.yaml)
**Trigger**: Pull Request  
**Actions**:
- Run `terraform plan`
- Comment plan output on PR
- Validate Terraform syntax
- Check formatting

### 3. Terraform Apply (terraform-apply.yaml)
**Trigger**: Merge to `main` branch  
**Actions**:
- Run `terraform apply`
- Deploy to Pi Kubernetes cluster
- Update deployment status

### 4. Tests (test.yaml)
**Trigger**: Push or PR  
**Actions**:
- Run backend unit tests
- Run integration tests
- Code quality checks
- Security scanning

## 🔧 Required Secrets

Set these in GitHub repository secrets:

```
DOCKERHUB_USERNAME          # Docker Hub username
DOCKERHUB_TOKEN            # Docker Hub access token
MINIO_ACCESS_KEY           # MinIO for Terraform state
MINIO_SECRET_KEY           # MinIO secret
KUBECONFIG                 # Kubernetes config for Pi cluster
VAULT_ADDR                 # Vault address
VAULT_TOKEN                # Vault token
```

## 🚀 Workflow Examples

### Build and Push
```yaml
name: Build and Push Images

on:
  push:
    branches: [main]
    paths: ['app/**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to GHCR
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push backend
        uses: docker/build-push-action@v4
        with:
          context: ./app/backend
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/inventory-backend:latest
            ghcr.io/${{ github.repository_owner }}/inventory-backend:${{ github.sha }}
```

### Terraform Plan
```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [main]
    paths: ['terraform/**']

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ./terraform
```

## 📊 Pipeline Flow

```
┌─────────────┐
│ Git Push    │
└──────┬──────┘
       │
       v
┌─────────────┐
│ Run Tests   │
└──────┬──────┘
       │
       v
┌─────────────┐
│ Build Images│
└──────┬──────┘
       │
       v
┌─────────────┐
│ Push to     │
│ Registries  │
└──────┬──────┘
       │
       v
┌─────────────┐
│ Terraform   │
│ Apply       │
└──────┬──────┘
       │
       v
┌─────────────┐
│ Deploy to   │
│ Pi Cluster  │
└─────────────┘
```

## 🔍 Monitoring

Each workflow will:
- Report status to GitHub
- Send notifications on failure
- Generate build artifacts
- Create deployment reports

## 📚 Documentation

See [docs/PROJECT_PLAN.md](../docs/PROJECT_PLAN.md) for detailed Phase 5 implementation plan.

---

**Ready to implement?** Check the PROJECT_PLAN.md for complete workflow examples!
