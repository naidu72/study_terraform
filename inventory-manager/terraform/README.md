# Terraform Modules (Phase 3)

This directory will contain Infrastructure as Code (Terraform) modules for deploying the Inventory Manager to Kubernetes.

## 📅 Status: Phase 3 (Planned)

**Current Phase**: Phase 1 ✅ Complete  
**This Phase**: 🔜 Not started

## 📦 Planned Modules

### 1. `namespace/`
- Create Kubernetes namespace
- Resource quotas
- Network policies

### 2. `postgres/`
- PostgreSQL StatefulSet
- Persistent Volume Claims
- Service configuration
- Database initialization

### 3. `redis/`
- Redis Deployment
- Service configuration
- Optional persistence

### 4. `backend/`
- Backend API Deployment
- Service configuration
- Environment variables
- Health checks
- Resource limits

### 5. `frontend/`
- Frontend Deployment
- Nginx configuration
- Service configuration
- Ingress rules

## 🎯 What This Will Include

```hcl
terraform/
├── main.tf              # Root module
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── terraform.tfvars     # Variable values
└── modules/
    ├── namespace/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── postgres/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── redis/
    │   ├── main.tf
    │   └── variables.tf
    ├── backend/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── frontend/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔧 Configuration

### Backend State
- **Type**: S3-compatible (MinIO)
- **Bucket**: `terraform-state`
- **Key**: `inventory-manager/terraform.tfstate`
- **Endpoint**: `https://minio.naidu72.info`

### Target Cluster
- **Type**: Kubernetes on Raspberry Pi
- **Kubeconfig**: `~/.kube/config`
- **Context**: `pi-k8s` or similar

## 🚀 Usage (When Implemented)

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply to cluster
terraform apply

# Destroy resources
terraform destroy
```

## 📚 Documentation

See [docs/PROJECT_PLAN.md](../docs/PROJECT_PLAN.md) for detailed Phase 3 implementation plan.

---

**Ready to implement?** Check the PROJECT_PLAN.md for step-by-step instructions!
