# Phase 3: Frontend Terraform Configuration - COMPLETE! ✅

## Overview

Terraform configuration for deploying the React frontend to Kubernetes has been created. The frontend module integrates seamlessly with the existing backend infrastructure.

## Files Created

### 1. Frontend Module (`terraform/modules/frontend/`)

#### `variables.tf` ✅
Defines all input variables for the frontend module:
- Namespace and app configuration
- Docker image settings
- Replica configuration
- Backend service URL (internal connection)
- Ingress configuration (hostname, TLS, class)
- GHCR image pull credentials
- Labels

#### `main.tf` ✅
Complete Kubernetes resources for frontend:
- **Secret**: GHCR image pull secret (for private registry)
- **ConfigMap**: Frontend configuration (backend URL)
- **Deployment**: Frontend pods with:
  - Multi-arch image support (amd64 + arm64)
  - Resource limits (CPU: 50m-200m, Memory: 64Mi-128Mi)
  - Liveness & readiness probes
  - Rolling update strategy
  - Image pull secrets
- **Service**: ClusterIP service on port 80
- **Ingress**: External access with:
  - HTTPS/TLS support
  - cert-manager integration
  - API proxy to backend
  - SPA client-side routing support
- **HPA**: Horizontal Pod Autoscaler (scales 2-6 replicas based on CPU/memory)

#### `outputs.tf` ✅
Exports:
- Deployment and service names
- Internal service URL
- Ingress hostname and public URL
- Replica count

### 2. Root Configuration Updates

#### `terraform/main.tf` ✅
Added frontend module call:
```hcl
module "frontend" {
  source = "./modules/frontend"
  
  namespace            = module.namespace.name
  image                = var.frontend_image
  replicas             = var.frontend_replicas
  backend_service_url  = "http://${module.backend.service_name}:${module.backend.service_port}"
  ghcr_username        = var.ghcr_username
  ghcr_token           = var.ghcr_token
  labels               = var.common_labels
  enable_ingress       = var.enable_frontend_ingress
  ingress_host         = var.frontend_ingress_host
  ingress_class        = var.ingress_class
  enable_tls           = var.enable_tls
  tls_secret_name      = var.frontend_tls_secret_name
  
  depends_on = [module.namespace, module.backend]
}
```

#### `terraform/variables.tf` ✅
Added frontend variables:
- `frontend_image` (default: `ghcr.io/naidu72/inventory-frontend:latest`)
- `frontend_replicas` (default: 2)
- `enable_frontend_ingress` (default: true)
- `frontend_ingress_host` (default: `inventory.naidu72.info`)
- `frontend_tls_secret_name`

#### `terraform/outputs.tf` ✅
Added frontend outputs:
- Frontend service name and URL
- Frontend ingress host and public URL
- Updated application info with frontend details

### 3. Environment-Specific Updates

#### `terraform/environments/pi-cluster/terraform.tfvars` ✅
Added frontend configuration:
```hcl
frontend_image           = "ghcr.io/naidu72/inventory-frontend:latest"
frontend_replicas        = 2
enable_frontend_ingress  = true
frontend_ingress_host    = "inventory-pi.naidu72.info"
frontend_tls_secret_name = "inventory-frontend-pi-tls"
```

#### `terraform/environments/pi-cluster/variables.tf` ✅
Added all frontend variable definitions.

#### `terraform/environments/pi-cluster/main.tf` ✅
Updated to pass frontend variables to root module.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          Namespace: inventory-manager                   │ │
│  │                                                          │ │
│  │  ┌──────────────────────┐    ┌──────────────────────┐  │ │
│  │  │  Frontend Service    │    │  Backend Service     │  │ │
│  │  │  ClusterIP:80        │────│  ClusterIP:8000      │  │ │
│  │  └──────────────────────┘    └──────────────────────┘  │ │
│  │           ▲                            ▲                 │ │
│  │           │                            │                 │ │
│  │  ┌────────┴─────────┐       ┌────────┴─────────┐       │ │
│  │  │ Frontend Pods    │       │ Backend Pods     │       │ │
│  │  │ (2 replicas)     │       │ (2 replicas)     │       │ │
│  │  │ Nginx + React    │       │ FastAPI          │       │ │
│  │  │ 64Mi-128Mi       │       │ 256Mi-512Mi      │       │ │
│  │  └──────────────────┘       └──────────────────┘       │ │
│  │                                       ▲                  │ │
│  │                              ┌────────┴────────┐        │ │
│  │                              │  PostgreSQL     │        │ │
│  │                              │  StatefulSet    │        │ │
│  │                              │  5Gi PVC        │        │ │
│  │                              └─────────────────┘        │ │
│  │                                                          │ │
│  │  ┌────────────────────────────────────────────┐        │ │
│  │  │  Ingress (inventory-pi.naidu72.info)       │        │ │
│  │  │  - / → Frontend Service:80                 │        │ │
│  │  │  - /api/* → Backend Service:8000           │        │ │
│  │  │  - TLS/HTTPS (cert-manager)                │        │ │
│  │  └────────────────────────────────────────────┘        │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Multi-Arch Support
- ✅ Works on both amd64 (k8s-k8s) and arm64 (pi-k8s)
- Uses multi-arch image: `ghcr.io/naidu72/inventory-frontend:latest`

### 2. Secure Image Pull
- GHCR credentials managed via Terraform
- Kubernetes `dockerconfigjson` secret
- No hardcoded credentials

### 3. Internal Backend Communication
- Frontend connects to backend via internal ClusterIP service
- Service discovery: `http://inventory-manager-backend-service:8000`
- No external API calls needed

### 4. External Access via Ingress
- **Frontend**: `https://inventory-pi.naidu72.info`
- **API Proxy**: `https://inventory-pi.naidu72.info/api/*` → Backend
- Single domain for entire application
- TLS/HTTPS support via cert-manager
- SPA routing support (fallback to index.html)

### 5. High Availability
- 2 replicas by default
- Horizontal Pod Autoscaler (2-6 replicas)
- Rolling updates (zero downtime)
- Health checks (liveness + readiness)

### 6. Resource Efficiency
- Optimized for Pi cluster:
  - CPU: 50m request, 200m limit
  - Memory: 64Mi request, 128Mi limit
- Static files (Nginx) = lightweight!

### 7. Production Ready
- Health checks configured
- Resource limits set
- Rolling update strategy
- Auto-scaling enabled
- TLS/HTTPS support
- Proper labels and selectors

## Deployment Commands

### Deploy Frontend to Pi Cluster

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager

# Option 1: Use automated script (recommended)
./scripts/deploy-with-vault.sh

# Select:
# 1) pi-k8s cluster
# 1) Fetch from Vault

# Option 2: Manual Terraform
cd terraform/environments/pi-cluster

# Initialize (if needed)
terraform init

# Plan (review changes)
terraform plan

# Apply (deploy)
terraform apply
```

### Expected Output

After successful deployment:

```
Outputs:

application_info = {
  "backend_image" = "ghcr.io/naidu72/inventory-backend:latest"
  "backend_replicas" = 2
  "environment" = "pi-cluster"
  "frontend_image" = "ghcr.io/naidu72/inventory-frontend:latest"
  "frontend_replicas" = 2
  "namespace" = "inventory-manager"
}
backend_service = "inventory-manager-backend-service"
backend_service_url = "http://inventory-manager-backend-service.inventory-manager.svc.cluster.local:8000"
frontend_ingress_host = "inventory-pi.naidu72.info"
frontend_ingress_url = "https://inventory-pi.naidu72.info"
frontend_service = "inventory-manager-frontend-service"
frontend_service_url = "http://inventory-manager-frontend-service.inventory-manager.svc.cluster.local"
```

## Verification Steps

### 1. Check Deployment Status

```bash
# Check all pods
kubectl get pods -n inventory-manager --kubeconfig=~/.kube/pi-cluster --context=pi-k8s

# Expected output:
# inventory-manager-frontend-xxx   1/1   Running
# inventory-manager-frontend-xxx   1/1   Running
# inventory-manager-backend-xxx    1/1   Running
# inventory-manager-backend-xxx    1/1   Running
# inventory-manager-postgres-0     1/1   Running
# inventory-manager-redis-xxx      1/1   Running
```

### 2. Check Services

```bash
kubectl get svc -n inventory-manager --kubeconfig=~/.kube/pi-cluster --context=pi-k8s

# Expected:
# inventory-manager-frontend-service   ClusterIP   10.x.x.x   80/TCP
# inventory-manager-backend-service    ClusterIP   10.x.x.x   8000/TCP
```

### 3. Check Ingress

```bash
kubectl get ingress -n inventory-manager --kubeconfig=~/.kube/pi-cluster --context=pi-k8s

# Expected:
# inventory-manager-frontend-ingress   inventory-pi.naidu72.info   80, 443
```

### 4. Test Application

```bash
# Test frontend (from browser or curl)
curl -I https://inventory-pi.naidu72.info

# Expected: 200 OK with HTML content

# Test API proxy
curl https://inventory-pi.naidu72.info/api/v1/health

# Expected: {"status":"healthy"}
```

## What's Next?

With frontend Terraform configuration complete:

✅ **Phase 1**: App Development (Backend + Frontend) - COMPLETE
✅ **Phase 2**: Containerization (Multi-arch images) - COMPLETE  
✅ **Phase 3**: Terraform Configuration (Backend + Frontend) - COMPLETE

**Ready for:**
- 🚀 Deploy frontend to pi-k8s cluster
- 🚀 Test complete application end-to-end
- 🔜 Phase 4: Vault Integration (External Secrets Operator)
- 🔜 Phase 5: GitHub Actions CI/CD
- 🔜 Phase 6: ArgoCD GitOps

## Configuration Files Summary

```
terraform/
├── main.tf                          ✅ Updated (added frontend module)
├── variables.tf                     ✅ Updated (added frontend vars)
├── outputs.tf                       ✅ Updated (added frontend outputs)
├── modules/
│   └── frontend/                    ✅ NEW
│       ├── main.tf                  ✅ Complete deployment config
│       ├── variables.tf             ✅ All variables defined
│       └── outputs.tf               ✅ All outputs defined
└── environments/
    └── pi-cluster/                  ✅ Updated for frontend
        ├── main.tf                  ✅ Passes frontend vars
        ├── variables.tf             ✅ Frontend vars added
        └── terraform.tfvars         ✅ Frontend config added
```

---

**🎉 Frontend Terraform Configuration Complete!**

Ready to deploy the complete application stack to Kubernetes! 🚀
