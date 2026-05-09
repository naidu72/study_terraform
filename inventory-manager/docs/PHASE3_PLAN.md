# Phase 3 - Terraform Deployment Plan

## 🎯 Goals

Deploy the Inventory Manager application to Kubernetes clusters using Terraform Infrastructure as Code.

## 🏗️ Target Clusters

### Primary: Pi Cluster (arm64)
- **MCP Server**: `user-pi-k8s`
- **Architecture**: arm64 (Raspberry Pi)
- **Status**: ✅ Active (1 node)
- **Existing**: cert-manager, vault, minio, external-secrets
- **Image**: `ghcr.io/naidu72/inventory-backend:latest` (arm64)

### Secondary: K8s Cluster (amd64)
- **MCP Server**: `user-k8s-k8s`
- **Architecture**: amd64
- **Status**: ✅ Active
- **Image**: `ghcr.io/naidu72/inventory-backend:latest` (amd64)

## 📦 What We'll Deploy

### 1. Namespace
- `inventory-manager` namespace
- Labels and annotations
- Resource quotas (optional)

### 2. PostgreSQL StatefulSet
- PostgreSQL 15
- Persistent storage (PVC)
- Service (ClusterIP)
- ConfigMap for init scripts
- Secrets for credentials

### 3. Redis Deployment
- Redis 7
- Persistent storage (PVC)
- Service (ClusterIP)
- ConfigMap for configuration

### 4. Backend Deployment
- Multi-arch image: `ghcr.io/naidu72/inventory-backend:latest`
- 2 replicas
- Environment variables
- Health checks
- Resource limits
- Service (ClusterIP)

### 5. Ingress (Optional)
- Nginx or Istio ingress
- TLS with cert-manager
- Domain routing

## 🗂️ Terraform Structure

```
terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── backend.tf              # State backend (MinIO)
├── versions.tf             # Version constraints
│
├── modules/
│   ├── namespace/          # Namespace module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── postgresql/         # PostgreSQL module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── redis/              # Redis module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── backend/            # Backend app module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/           # Environment-specific configs
    ├── pi-cluster/         # Pi cluster (arm64)
    │   ├── main.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    │
    └── k8s-cluster/        # K8s cluster (amd64)
        ├── main.tf
        ├── terraform.tfvars
        └── backend.tf
```

## 🔧 State Management

### MinIO Backend
```hcl
terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "inventory-manager/terraform.tfstate"
    endpoint                    = "http://minio.minio.svc.cluster.local:9000"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
```

## 📋 Implementation Steps

### Step 1: Setup Terraform Structure ✅
- Create directory structure
- Configure providers
- Set up backend

### Step 2: Create Reusable Modules
- Namespace module
- PostgreSQL module
- Redis module
- Backend application module

### Step 3: Configure Environments
- Pi cluster configuration
- K8s cluster configuration
- Environment-specific variables

### Step 4: Deploy to Pi Cluster (Primary)
- Initialize Terraform
- Plan deployment
- Apply configuration
- Verify resources

### Step 5: Test Application
- Check pod status
- Test database connectivity
- Verify Redis connection
- Test API endpoints

### Step 6: Deploy to K8s Cluster (Optional)
- Same process for amd64 cluster

## 🔐 Secrets Management

Using Vault (already installed on Pi cluster):
- Database passwords
- Redis passwords
- JWT secrets
- API keys

Integration with External Secrets Operator:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
```

## 🎯 Success Criteria

- [x] Terraform structure created
- [ ] Modules implemented
- [ ] State backend configured
- [ ] Deployed to Pi cluster
- [ ] All pods running
- [ ] Database initialized
- [ ] API accessible
- [ ] Health checks passing

## ⏱️ Estimated Time

- Setup: 15 minutes
- Module creation: 30 minutes
- Deployment: 15 minutes
- Testing: 10 minutes
- **Total: ~70 minutes**

## 📚 Resources Needed

- ✅ Multi-arch image (Phase 2)
- ✅ Kubernetes clusters (pi-k8s, k8s-k8s)
- ✅ MinIO for state (already installed)
- ✅ Vault for secrets (already installed)
- ✅ cert-manager for TLS (already installed)

## 🚀 Let's Begin!

Ready to create the Terraform infrastructure!
