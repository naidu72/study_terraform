# Terraform Infrastructure for Inventory Manager

## 📁 Structure

```
terraform/
├── main.tf              # Main configuration using modules
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── versions.tf          # Version constraints
│
├── modules/
│   ├── namespace/       # Namespace module
│   ├── postgresql/      # PostgreSQL StatefulSet module
│   ├── redis/           # Redis Deployment module
│   └── backend/         # Backend application module
│
└── environments/
    ├── pi-cluster/      # Pi cluster (arm64) configuration
    └── k8s-cluster/     # K8s cluster (amd64) configuration
```

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.0
- kubectl configured with access to your cluster
- Multi-arch image: `ghcr.io/naidu72/inventory-backend:latest`

### Deploy to Pi Cluster

```bash
cd environments/pi-cluster

# Set sensitive variables
export TF_VAR_postgres_password="your-secure-password"
export TF_VAR_jwt_secret_key="your-jwt-secret"

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply configuration
terraform apply
```

## 📋 Modules

### Namespace Module
Creates and manages the Kubernetes namespace with optional resource quotas.

**Resources:**
- Namespace
- Resource Quota (optional)
- Limit Range (optional)

### PostgreSQL Module
Deploys PostgreSQL as a StatefulSet with persistent storage.

**Resources:**
- StatefulSet
- Service (ClusterIP)
- PersistentVolumeClaim
- Secret (credentials)
- ConfigMap (init scripts)

**Features:**
- Persistent storage
- Health checks (liveness/readiness)
- Resource limits
- Initialization scripts

### Redis Module
Deploys Redis with persistent storage and AOF enabled.

**Resources:**
- Deployment
- Service (ClusterIP)
- PersistentVolumeClaim

**Features:**
- Persistent storage
- AOF persistence
- Health checks
- Resource limits

### Backend Module
Deploys the FastAPI backend application.

**Resources:**
- Deployment (with rolling updates)
- Service (ClusterIP)
- Secret (database URL, JWT secret)
- ConfigMap (app configuration)
- Ingress (optional)
- Init Job (database initialization)

**Features:**
- Multi-replica deployment
- Health checks (startup/liveness/readiness)
- Init containers (wait for dependencies)
- Automatic database initialization
- Rolling updates
- Resource limits
- Optional ingress with TLS

## 🔧 Configuration

### Required Variables

```hcl
namespace          = "inventory-manager"
kubeconfig_context = "pi-k8s"
backend_image      = "ghcr.io/naidu72/inventory-backend:latest"
```

### Sensitive Variables (via environment)

```bash
export TF_VAR_postgres_password="secure-password"
export TF_VAR_jwt_secret_key="secure-jwt-secret"
```

### Storage Configuration

```hcl
postgres_storage_size  = "5Gi"
redis_storage_size     = "2Gi"
postgres_storage_class = "local-path"  # Adjust for your cluster
```

### Resource Limits

```hcl
backend_cpu_request    = "100m"
backend_cpu_limit      = "500m"
backend_memory_request = "256Mi"
backend_memory_limit   = "512Mi"
```

## 📊 State Management

State is stored in MinIO (S3-compatible):

```hcl
backend "s3" {
  bucket   = "terraform-state"
  key      = "inventory-manager/pi-cluster/terraform.tfstate"
  endpoint = "http://minio.minio.svc.cluster.local:9000"
}
```

**Note:** MinIO must be accessible from where you run Terraform.

## 🔐 Secrets Management

### Current: Terraform Variables
Secrets are passed as Terraform variables (encrypted in state).

### Future: Vault Integration (Phase 4)
Will use External Secrets Operator to sync from Vault.

## 🎯 Deployment Order

1. **Namespace** - Created first
2. **PostgreSQL** - Database with persistent storage
3. **Redis** - Cache with persistent storage
4. **Backend** - Application (waits for dependencies)
5. **Init Job** - Database initialization

Init containers ensure proper startup order.

## 📝 Common Commands

### Initialize
```bash
terraform init
```

### Plan
```bash
terraform plan
```

### Apply
```bash
terraform apply
```

### Destroy
```bash
terraform destroy
```

### View Outputs
```bash
terraform output
```

### Format Code
```bash
terraform fmt -recursive
```

### Validate
```bash
terraform validate
```

## 🧪 Testing

After deployment:

```bash
# Check pods
kubectl get pods -n inventory-manager

# Check services
kubectl get svc -n inventory-manager

# Port-forward backend
kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8000:8000

# Access API
curl http://localhost:8000/health
open http://localhost:8000/docs
```

## 🔍 Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n inventory-manager
kubectl logs <pod-name> -n inventory-manager
```

### Init containers stuck
```bash
kubectl logs <pod-name> -n inventory-manager -c wait-for-postgres
kubectl logs <pod-name> -n inventory-manager -c wait-for-redis
```

### Database init job failed
```bash
kubectl logs -n inventory-manager job/inventory-manager-init-db
kubectl delete job -n inventory-manager inventory-manager-init-db
terraform apply  # Recreates the job
```

### Storage issues
```bash
kubectl get pvc -n inventory-manager
kubectl describe pvc <pvc-name> -n inventory-manager
```

## 🎯 Next Steps (Phase 4)

- Integrate with Vault for secrets
- Use External Secrets Operator
- Add monitoring (Prometheus/Grafana)
- Add logging (Loki)
- Set up alerts

## 📚 References

- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Phase 2: Multi-arch Images](../../docs/PHASE2_COMPLETE.md)
- [Application Documentation](../../docs/APP_README.md)
