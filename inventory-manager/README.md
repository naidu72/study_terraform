# 🚀 Inventory Manager - Multi-Cluster Kubernetes Application

A production-ready inventory management system with JWT authentication, deployed across multiple Kubernetes clusters using Terraform, with state management in MinIO and secrets in Vault.

[![Build Status](https://github.com/naidu72/inventory-manager/workflows/CI/badge.svg)](https://github.com/naidu72/inventory-manager/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🌟 Key Features

### Application
- 🔐 **JWT Authentication** with user registration and login
- 📦 **CRUD Operations** for inventory items
- 🐘 **PostgreSQL** for persistent data storage
- 🔴 **Redis** for caching and session management
- ⚡ **FastAPI** high-performance async backend
- 📊 **Interactive API Documentation** (Swagger/ReDoc)

### Infrastructure
- ☸️ **Multi-Cluster Kubernetes** support (ARM64 + AMD64)
- 🏗️ **Terraform Infrastructure as Code** (modular design)
- 🐳 **Multi-Architecture Docker Images** (Raspberry Pi + x86)
- 🔄 **GitHub Actions CI/CD** pipeline
- 💾 **MinIO Backend** for Terraform state management
- 🔐 **HashiCorp Vault** for secrets management
- 🚀 **Zero-downtime deployments** with rolling updates
- 📈 **Production-ready** with health checks and monitoring

---

## 📋 Quick Start

### Option 1: Deploy to Kubernetes (Both Clusters)

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/deploy-with-vault.sh
# Choose option 3: Deploy to both clusters
```

### Option 2: Local Development with Docker Compose

```bash
cd app
docker-compose up -d

# Test the API
curl http://localhost:8000/health
open http://localhost:8000/docs
```

### Option 3: Manual Terraform Deployment

```bash
# For pi-k8s (ARM64)
cd terraform/environments/pi-cluster
terraform init && terraform apply

# For k8s-k8s (AMD64)
cd terraform/environments/k8s-cluster
terraform init && terraform apply
```

---

## 📚 Documentation

### 🎯 Start Here
- **[START_HERE.md](docs/START_HERE.md)** - Project overview and navigation
- **[VISUAL_SUMMARY.md](docs/VISUAL_SUMMARY.md)** - Complete visual guide
- **[QUICKSTART.md](docs/QUICKSTART.md)** - Fast setup instructions

### 📖 Phase Guides
- **[PHASE1_SUMMARY.md](docs/PHASE1_SUMMARY.md)** - Application development
- **[PHASE2_FINAL_SUMMARY.md](docs/PHASE2_FINAL_SUMMARY.md)** - CI/CD and containers
- **[PHASE3_COMPLETE.md](docs/PHASE3_COMPLETE.md)** - Kubernetes deployment

### 🚀 Deployment Guides
- **[MULTI_CLUSTER_DEPLOYMENT.md](docs/MULTI_CLUSTER_DEPLOYMENT.md)** ⭐ **Main deployment guide**
- **[VAULT_INTEGRATION_GUIDE.md](docs/VAULT_INTEGRATION_GUIDE.md)** - Secrets management
- **[terraform/README.md](terraform/README.md)** - Terraform structure

### 🔐 Authentication
- **[AUTHENTICATION_GUIDE.md](docs/AUTHENTICATION_GUIDE.md)** - JWT setup and usage

---

## 🏗️ Architecture

### Application Stack
```
┌─────────────────────────────────────┐
│         FastAPI Backend             │
│    (Python 3.11, Async/Await)       │
├─────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐│
│  │  PostgreSQL  │  │    Redis     ││
│  │  (Database)  │  │   (Cache)    ││
│  └──────────────┘  └──────────────┘│
└─────────────────────────────────────┘
```

### Deployment Architecture
```
┌──────────────┐    ┌──────────────┐
│   pi-k8s     │    │  k8s-k8s     │
│   (ARM64)    │    │  (AMD64)     │
│  2 replicas  │    │ 3 replicas   │
└──────┬───────┘    └──────┬───────┘
       │                   │
       └───────────┬───────┘
                   ▼
       ┌───────────────────────┐
       │  ghcr.io/naidu72/     │
       │  inventory-backend    │
       │  (Multi-arch Image)   │
       └───────────────────────┘
                   │
       ┌───────────┴───────────┐
       │                       │
       ▼                       ▼
┌─────────────┐       ┌──────────────┐
│    MinIO    │       │    Vault     │
│   (State)   │       │  (Secrets)   │
└─────────────┘       └──────────────┘
```

---

## 🎯 Supported Clusters

### 1️⃣ pi-k8s (ARM64)
- **Architecture:** ARM64 (Raspberry Pi)
- **Backend Replicas:** 2
- **PostgreSQL Storage:** 5Gi
- **Redis Storage:** 2Gi
- **Environment:** Development

### 2️⃣ k8s-k8s (AMD64)
- **Architecture:** AMD64 (x86_64)
- **Backend Replicas:** 3
- **PostgreSQL Storage:** 10Gi
- **Redis Storage:** 5Gi
- **Environment:** Production

---

## 📦 Project Structure

```
inventory-manager/
├── app/                    # Phase 1: Application
│   ├── backend/            # FastAPI backend
│   │   ├── routes/         # API endpoints
│   │   ├── Dockerfile      # Multi-stage build
│   │   ├── main.py         # Application entry
│   │   ├── models.py       # Database models
│   │   ├── auth.py         # JWT authentication
│   │   └── ...
│   └── docker-compose.yml  # Local development
│
├── terraform/              # Phase 3: Infrastructure
│   ├── modules/            # Reusable Terraform modules
│   │   ├── namespace/
│   │   ├── postgresql/
│   │   ├── redis/
│   │   └── backend/
│   └── environments/
│       ├── pi-cluster/     # ARM64 configuration
│       └── k8s-cluster/    # AMD64 configuration
│
├── scripts/                # Automation scripts
│   ├── build-multiarch.sh  # Build Docker images
│   ├── deploy-with-vault.sh # Deploy with Vault
│   └── ...
│
├── docs/                   # Comprehensive documentation
│   ├── START_HERE.md
│   ├── MULTI_CLUSTER_DEPLOYMENT.md
│   ├── VISUAL_SUMMARY.md
│   └── ...
│
├── .github/workflows/      # Phase 2: CI/CD
│   ├── ci.yml              # Build and test
│   └── cd.yml              # Deploy pipeline
│
└── README.md               # This file
```

---

## 🚀 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get JWT token
- `GET /api/auth/me` - Get current user info

### Items
- `GET /api/items` - List all items
- `POST /api/items` - Create new item
- `GET /api/items/{id}` - Get item by ID
- `PUT /api/items/{id}` - Update item
- `DELETE /api/items/{id}` - Delete item

### System
- `GET /health` - Health check
- `GET /docs` - Swagger UI documentation
- `GET /redoc` - ReDoc documentation

---

## 🔐 Environment Variables

### Required Secrets

```bash
# Database
POSTGRES_USER=inventory_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=inventory_db
DATABASE_URL=postgresql+asyncpg://...

# Redis
REDIS_URL=redis://redis:6379

# Security
JWT_SECRET_KEY=your_secret_key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# MinIO (for Terraform state)
AWS_ACCESS_KEY_ID=your_minio_access_key
AWS_SECRET_ACCESS_KEY=your_minio_secret_key
```

### Vault Paths

```yaml
secret/minio/credentials:
  access_key_id: "..."
  secret_access_key: "..."

secret/inventory-manager/postgres:
  password: "..."

secret/inventory-manager/jwt:
  secret_key: "..."
```

---

## 🧪 Testing

### Local Testing (Docker Compose)

```bash
cd app
docker-compose up -d

# Run tests
docker-compose exec backend pytest

# Manual API testing
./test-api.sh
```

### Kubernetes Testing

```bash
# Port forward to access API
kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8000:8000

# Test endpoints
curl http://localhost:8000/health
curl http://localhost:8000/docs

# Create test item
curl -X POST http://localhost:8000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Item", "description": "Testing", "quantity": 10, "price": 99.99}'
```

---

## 📊 Kubernetes Resources

Per cluster deployment includes:

- **1 Namespace** - `inventory-manager`
- **1 StatefulSet** - PostgreSQL with PVC
- **2 Deployments** - Redis + Backend (2-3 replicas)
- **3 Services** - PostgreSQL, Redis, Backend (ClusterIP)
- **2 PVCs** - PostgreSQL data + Redis data
- **3 Secrets** - Database, Redis, Backend credentials
- **2 ConfigMaps** - PostgreSQL init scripts + Backend config
- **1 Init Job** - Database initialization
- **1 Ingress** (optional) - External access with TLS

---

## 🛠️ Technology Stack

| Layer | Technology |
|-------|------------|
| **Backend** | FastAPI, Python 3.11, Pydantic, SQLAlchemy |
| **Database** | PostgreSQL 16, asyncpg |
| **Cache** | Redis 7, aioredis |
| **Authentication** | JWT (python-jose), bcrypt |
| **Containerization** | Docker, Docker Compose, Multi-arch builds |
| **Orchestration** | Kubernetes, kubectl, kustomize |
| **IaC** | Terraform 1.0+, Kubernetes Provider |
| **CI/CD** | GitHub Actions |
| **State Management** | MinIO (S3-compatible) |
| **Secrets** | HashiCorp Vault |
| **Monitoring** | Kubernetes health probes, liveness/readiness |

---

## 🔄 CI/CD Pipeline

GitHub Actions workflow automatically:

1. ✅ Runs tests on pull requests
2. 🏗️ Builds multi-architecture Docker images
3. 📤 Pushes images to GHCR and Docker Hub
4. 🏷️ Tags releases
5. 📦 Deploys to Kubernetes (optional)

---

## 📈 Monitoring & Maintenance

### Check Deployment Status

```bash
# Check all resources
kubectl get all -n inventory-manager

# Check pod logs
kubectl logs -n inventory-manager -l app=inventory-manager -f

# Check resource usage
kubectl top pods -n inventory-manager
kubectl top nodes
```

### Scaling

```bash
# Scale backend replicas
kubectl scale deployment inventory-manager-backend -n inventory-manager --replicas=5

# Or use Terraform
cd terraform/environments/k8s-cluster
# Update replicas in terraform.tfvars
terraform apply
```

### Backup & Restore

```bash
# Backup PostgreSQL
kubectl exec -n inventory-manager inventory-manager-postgresql-0 -- \
  pg_dump -U inventory_user inventory_db > backup.sql

# Restore PostgreSQL
kubectl exec -i -n inventory-manager inventory-manager-postgresql-0 -- \
  psql -U inventory_user inventory_db < backup.sql
```

---

## 🎯 Development Workflow

1. **Local Development**
   ```bash
   cd app
   docker-compose up -d
   # Make changes to app/backend/
   docker-compose restart backend
   ```

2. **Build Multi-arch Images**
   ```bash
   ./scripts/build-multiarch.sh
   ```

3. **Deploy to Kubernetes**
   ```bash
   ./scripts/deploy-with-vault.sh
   ```

4. **Test Deployment**
   ```bash
   kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8000:8000
   curl http://localhost:8000/docs
   ```

---

## 🚨 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n inventory-manager
kubectl describe pod <pod-name> -n inventory-manager

# Check logs
kubectl logs <pod-name> -n inventory-manager
```

### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl logs -n inventory-manager inventory-manager-postgresql-0

# Test connection
kubectl exec -it -n inventory-manager <backend-pod> -- \
  python -c "import asyncpg; print('OK')"
```

### Terraform State Issues

```bash
# Verify MinIO access
aws --endpoint-url=https://s3.naidu72.info s3 ls s3://terraform-state/

# Re-initialize if needed
cd terraform/environments/pi-cluster
terraform init -reconfigure
```

---

## 🧹 Cleanup

### Destroy Kubernetes Resources

```bash
# Using Terraform
cd terraform/environments/pi-cluster
terraform destroy

cd terraform/environments/k8s-cluster
terraform destroy

# Or manually
kubectl delete namespace inventory-manager
```

### Clean Local Docker Resources

```bash
cd app
docker-compose down -v
docker system prune -a
```

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📞 Support

- 📧 Email: naidu72@example.com
- 📝 Issues: [GitHub Issues](https://github.com/naidu72/inventory-manager/issues)
- 📚 Documentation: [docs/](docs/)

---

## 🎉 Acknowledgments

- FastAPI framework by Sebastián Ramírez
- PostgreSQL community
- Redis community
- Kubernetes community
- Terraform by HashiCorp
- GitHub Actions

---

## 📊 Project Status

- ✅ **Phase 1:** Application Development - **COMPLETE**
- ✅ **Phase 2:** CI/CD & Containers - **COMPLETE**
- ✅ **Phase 3:** Multi-Cluster Kubernetes - **COMPLETE**

**Status:** 🚀 **Production Ready**

---

## 🔗 Quick Links

- [Deploy to Kubernetes](docs/MULTI_CLUSTER_DEPLOYMENT.md)
- [Local Development Setup](docs/QUICKSTART.md)
- [API Documentation](http://localhost:8000/docs)
- [Terraform Modules](terraform/README.md)
- [Authentication Guide](docs/AUTHENTICATION_GUIDE.md)
- [Visual Summary](docs/VISUAL_SUMMARY.md)

---

**Built with ❤️ using FastAPI, Kubernetes, and Terraform**

**Last Updated:** May 5, 2026
