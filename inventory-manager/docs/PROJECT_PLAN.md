# Inventory Manager - Complete Implementation Plan

## Project Overview

**Enterprise-Grade Inventory Management System** deployed on Raspberry Pi Kubernetes cluster using Infrastructure as Code (Terraform), GitOps (ArgoCD), and secure secrets management (Vault).

**Goal**: Build a real-world enterprise application that demonstrates all aspects of modern cloud-native deployment.

---

## 🎯 Complete Tech Stack

### Application Layer
- **Frontend**: React + TypeScript + Nginx
- **Backend**: FastAPI (Python) + SQLAlchemy
- **Database**: PostgreSQL 15 (persistent PVC)
- **Cache**: Redis 7 (sessions + alerts)
- **Auth**: JWT tokens with role-based access

### Infrastructure Layer
- **Container**: Docker (multi-arch: amd64 + arm64)
- **Registry**: GitHub Container Registry (ghcr.io) + Docker Hub
- **IaC**: Terraform with modular structure
- **GitOps**: ArgoCD (auto-sync from Git)
- **Secrets**: HashiCorp Vault + External Secrets Operator
- **TLS**: cert-manager (Let's Encrypt)
- **Ingress**: Cloudflare Tunnel (already configured)
- **CI/CD**: GitHub Actions (build → test → deploy)

---

## 📁 Repository Structure

```
study_terraform/
├── app/
│   ├── backend/                    ✅ COMPLETED
│   │   ├── main.py                # FastAPI application
│   │   ├── config.py              # Settings & environment
│   │   ├── database.py            # DB connection & session
│   │   ├── models.py              # SQLAlchemy models
│   │   ├── schemas.py             # Pydantic validation
│   │   ├── auth.py                # JWT authentication
│   │   ├── cache.py               # Redis cache service
│   │   ├── routes/
│   │   │   ├── auth.py            # User management
│   │   │   ├── products.py        # Product CRUD
│   │   │   ├── categories.py     # Category CRUD
│   │   │   ├── stock.py           # Stock movements
│   │   │   └── dashboard.py       # Dashboard stats
│   │   ├── Dockerfile             # Multi-stage build
│   │   ├── requirements.txt       # Python dependencies
│   │   ├── init_db.py             # Database initialization
│   │   └── .env.example           # Environment template
│   ├── frontend/                   🔜 PHASE 1 (Continued)
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── nginx.conf
│   └── docker-compose.yml          ✅ COMPLETED
│
├── terraform/                      🔜 PHASE 3
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── namespace/
│       ├── postgres/
│       ├── redis/
│       ├── backend/
│       └── frontend/
│
├── helm/                           🔜 PHASE 6
│   └── inventory-manager/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           └── externalsecret.yaml
│
├── .github/                        🔜 PHASE 5
│   └── workflows/
│       ├── build-push.yaml
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
│
└── argocd/                         🔜 PHASE 6
    └── application.yaml
```

---

## 🚀 Implementation Phases

### ✅ Phase 1 — App Development (IN PROGRESS)

**Status**: Backend completed, Frontend next

**Backend Completed:**
- ✅ FastAPI application with async support
- ✅ PostgreSQL models (Users, Products, Categories, Stock, Audit)
- ✅ Redis caching for performance
- ✅ JWT authentication with role-based access
- ✅ CRUD APIs for all entities
- ✅ Stock movement tracking
- ✅ Low stock alerts
- ✅ Dashboard statistics
- ✅ Docker multi-stage build
- ✅ docker-compose for local development

**Next: Frontend (React)**
```bash
# Create React app with TypeScript
cd /home/frontier/terraform/study_terraform/study/app/frontend
npx create-react-app . --template typescript

# Install dependencies
npm install react-router-dom axios @mui/material @emotion/react @emotion/styled
npm install recharts react-query

# Build components
# - Login/Auth
# - Dashboard with stats
# - Product management
# - Stock movements
# - Low stock alerts
```

**Testing Phase 1:**
```bash
# Start all services
docker-compose up -d

# Initialize database
docker exec -it inventory_backend python init_db.py

# Test API
curl http://localhost:8000/health
curl http://localhost:8000/docs

# Login and get token
curl -X POST http://localhost:8000/api/v1/auth/login \
  -d "username=admin&password=admin123"
```

---

### 🔜 Phase 2 — Containerize + Multi-Registry Push

**Goals:**
- Multi-arch Docker builds (amd64 + arm64 for Pi cluster)
- Push to both GitHub Container Registry AND Docker Hub
- Optimize image sizes
- Set up build pipelines

**Implementation:**

1. **Multi-Arch Dockerfile** (Already created, but optimize)

2. **Build Script** (`scripts/build-multiarch.sh`):
```bash
#!/bin/bash
# Build multi-arch images for both registries

VERSION=${1:-latest}

# Backend
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/naidu72/inventory-backend:$VERSION \
  -t naidu72/inventory-backend:$VERSION \
  --push \
  ./app/backend

# Frontend
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/naidu72/inventory-frontend:$VERSION \
  -t naidu72/inventory-frontend:$VERSION \
  --push \
  ./app/frontend
```

3. **Test on Pi Cluster:**
```bash
kubectl run test-backend --image=ghcr.io/naidu72/inventory-backend:latest \
  --restart=Never -n default
```

---

### 🔜 Phase 3 — Terraform Manual Deploy

**Goals:**
- Create reusable Terraform modules
- Deploy to Pi Kubernetes cluster
- Manage state in MinIO
- Use Terraform best practices

**Module Structure:**

```
terraform/modules/
├── namespace/
│   ├── main.tf (create namespace + resource quotas)
│   └── variables.tf
├── postgres/
│   ├── main.tf (StatefulSet + PVC + Service)
│   ├── variables.tf
│   └── outputs.tf
├── redis/
│   ├── main.tf (Deployment + Service)
│   └── variables.tf
├── backend/
│   ├── main.tf (Deployment + Service)
│   ├── variables.tf
│   └── outputs.tf
└── frontend/
    ├── main.tf (Deployment + Service + Ingress)
    └── variables.tf
```

**Root `main.tf`:**
```hcl
terraform {
  backend "s3" {
    endpoint = "https://minio.naidu72.info"
    bucket = "terraform-state"
    key = "inventory-manager/terraform.tfstate"
    region = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_region_validation = true
    force_path_style = true
  }
}

module "namespace" {
  source = "./modules/namespace"
  name   = "inventory-manager"
}

module "postgres" {
  source    = "./modules/postgres"
  namespace = module.namespace.name
  pvc_size  = "10Gi"
}

module "redis" {
  source    = "./modules/redis"
  namespace = module.namespace.name
}

module "backend" {
  source        = "./modules/backend"
  namespace     = module.namespace.name
  image         = "ghcr.io/naidu72/inventory-backend:latest"
  db_host       = module.postgres.service_name
  redis_host    = module.redis.service_name
}

module "frontend" {
  source     = "./modules/frontend"
  namespace  = module.namespace.name
  image      = "ghcr.io/naidu72/inventory-frontend:latest"
  api_url    = "https://inventory-api.naidu72.info"
  ingress_host = "inventory.naidu72.info"
}
```

**Deploy Manually:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

---

### 🔜 Phase 4 — Vault Integration

**Goals:**
- Store sensitive data in Vault
- Use External Secrets Operator
- Rotate secrets automatically

**Secrets to Store:**
1. PostgreSQL password
2. JWT secret key
3. Redis password (optional)

**Vault Setup:**
```bash
# Enable KV v2 secrets engine
vault secrets enable -path=inventory kv-v2

# Store secrets
vault kv put inventory/database \
  username=inventory_user \
  password=SecurePassword123!

vault kv put inventory/jwt \
  secret_key=SuperSecretJWTKey123!

# Create policy
vault policy write inventory-policy - <<EOF
path "inventory/data/*" {
  capabilities = ["read"]
}
EOF

# Enable Kubernetes auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://192.168.1.100:6443"

vault write auth/kubernetes/role/inventory \
  bound_service_account_names=inventory-sa \
  bound_service_account_namespaces=inventory-manager \
  policies=inventory-policy \
  ttl=24h
```

**External Secret:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: inventory-manager
spec:
  provider:
    vault:
      server: "https://vault.naidu72.info"
      path: "inventory"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "inventory"
          serviceAccountRef:
            name: "inventory-sa"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: inventory-secrets
  namespace: inventory-manager
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: inventory-app-secrets
    creationPolicy: Owner
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: database
        property: password
    - secretKey: JWT_SECRET
      remoteRef:
        key: jwt
        property: secret_key
```

**Update Terraform to use secrets from Vault**

---

### 🔜 Phase 5 — GitHub Actions CI/CD

**Goals:**
- Automated builds on push
- Terraform plan on PR
- Terraform apply on merge
- Push to both registries

**Workflow 1: Build & Push** (`.github/workflows/build-push.yaml`)
```yaml
name: Build and Push Images

on:
  push:
    branches: [main]
    paths:
      - 'app/**'

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
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      
      - name: Build and push backend
        uses: docker/build-push-action@v4
        with:
          context: ./app/backend
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/inventory-backend:latest
            ghcr.io/${{ github.repository_owner }}/inventory-backend:${{ github.sha }}
            naidu72/inventory-backend:latest
            naidu72/inventory-backend:${{ github.sha }}
```

**Workflow 2: Terraform Plan** (`.github/workflows/terraform-plan.yaml`)
```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'

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
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.MINIO_ACCESS_KEY }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.MINIO_SECRET_KEY }}
      
      - name: Terraform Plan
        run: terraform plan
        working-directory: ./terraform
```

**Workflow 3: Terraform Apply** (`.github/workflows/terraform-apply.yaml`)
```yaml
name: Terraform Apply

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'

jobs:
  apply:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform
```

---

### 🔜 Phase 6 — ArgoCD GitOps

**Goals:**
- Convert to Helm chart
- Set up ArgoCD application
- Auto-sync from Git
- GitOps workflow

**Helm Chart Structure:**
```
helm/inventory-manager/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-prod.yaml
└── templates/
    ├── namespace.yaml
    ├── postgres-statefulset.yaml
    ├── postgres-service.yaml
    ├── postgres-pvc.yaml
    ├── redis-deployment.yaml
    ├── redis-service.yaml
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    ├── ingress.yaml
    ├── secretstore.yaml
    └── externalsecret.yaml
```

**ArgoCD Application:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: inventory-manager
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/naidu72/study_terraform
    targetRevision: HEAD
    path: helm/inventory-manager
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: inventory-manager
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Deploy:**
```bash
kubectl apply -f argocd/application.yaml
```

---

## 🔒 Security Considerations

1. **Secrets Management**
   - All passwords in Vault
   - No hardcoded credentials
   - Rotate secrets regularly

2. **Network Policies**
   - Restrict pod-to-pod communication
   - Only allow necessary traffic

3. **RBAC**
   - Least privilege access
   - Service accounts per component

4. **Image Security**
   - Scan with Trivy
   - Use distroless images
   - Sign images with Cosign

---

## 📊 What This Demonstrates

| Topic | Implementation |
|-------|---------------|
| **Infrastructure as Code** | Terraform modules, state management |
| **Container Orchestration** | Kubernetes deployments, services, ingress |
| **GitOps** | ArgoCD auto-sync from Git |
| **Secrets Management** | Vault + External Secrets Operator |
| **CI/CD** | GitHub Actions pipelines |
| **Multi-Registry** | GHCR + Docker Hub |
| **Multi-Arch** | amd64 + arm64 builds |
| **Persistent Storage** | StatefulSets, PVC for PostgreSQL |
| **Caching** | Redis for performance |
| **Authentication** | JWT with RBAC |
| **TLS/HTTPS** | cert-manager + Let's Encrypt |
| **Monitoring** | Health checks, readiness/liveness probes |
| **High Availability** | Multiple replicas, auto-healing |

---

## 🎯 Current Status

**✅ Completed:**
- Phase 1 Backend (FastAPI + PostgreSQL + Redis + JWT)
- Docker Compose for local development
- Multi-stage Dockerfile
- Comprehensive README

**🔄 In Progress:**
- Phase 1 Frontend (React)

**📅 Next Steps:**
1. Complete React frontend
2. Test full application locally
3. Build multi-arch images
4. Create Terraform modules
5. Manual Terraform deployment to Pi cluster
6. Integrate Vault secrets
7. Set up GitHub Actions
8. Create Helm chart
9. Deploy via ArgoCD

---

## 🌐 Access URLs (After Deployment)

- Frontend: `https://inventory.naidu72.info`
- Backend API: `https://inventory-api.naidu72.info`
- API Docs: `https://inventory-api.naidu72.info/docs`
- ArgoCD: `https://argocd.naidu72.info`
- Vault: `https://vault.naidu72.info`

---

## 📚 Learning Outcomes

By completing this project, you will demonstrate expertise in:

1. **Backend Development** - FastAPI, SQLAlchemy, PostgreSQL
2. **Frontend Development** - React, TypeScript, Material-UI
3. **Containerization** - Docker, multi-stage builds, multi-arch
4. **Kubernetes** - Deployments, Services, Ingress, PVC, StatefulSets
5. **Infrastructure as Code** - Terraform modules, state management
6. **GitOps** - ArgoCD application delivery
7. **Secrets Management** - Vault, External Secrets Operator
8. **CI/CD** - GitHub Actions, automated deployments
9. **Security** - JWT auth, RBAC, network policies, TLS
10. **Monitoring** - Health checks, logging, metrics

---

**Ready to continue with Phase 1 Frontend? Let me know!**
