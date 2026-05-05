# Inventory Manager - Enterprise Cloud Native Application

> A complete enterprise-grade inventory management system demonstrating modern DevOps practices, Infrastructure as Code (Terraform), GitOps (ArgoCD), and Kubernetes deployment on Raspberry Pi cluster.

## 📁 Project Structure

```
study/
├── app/                    # Application code
│   ├── backend/           # FastAPI backend (Phase 1 ✅)
│   ├── frontend/          # React frontend (Phase 1 🔜)
│   └── docker-compose.yml # Local development
│
├── terraform/             # Infrastructure as Code (Phase 3 🔜)
│   └── modules/          # Reusable Terraform modules
│
├── helm/                  # Helm charts (Phase 6 🔜)
│   └── inventory-manager/
│
├── .github/              # CI/CD pipelines (Phase 5 🔜)
│   └── workflows/
│
├── argocd/               # GitOps configuration (Phase 6 🔜)
│
└── docs/                 # 📚 All documentation
    ├── SUCCESS.md        # Current status & quick test
    ├── QUICKSTART.md     # Get started in 5 minutes
    ├── APP_README.md     # Application details
    ├── PROJECT_PLAN.md   # Complete 6-phase roadmap
    └── ...
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose V2
- Linux/WSL2 environment

### Start the Application (Phase 1 Backend)

```bash
cd app
docker compose up -d
docker exec inventory_backend python init_db.py
```

### Test It
```bash
# Health check
curl http://localhost:8000/health

# API Documentation
open http://localhost:8000/docs

# Run full tests
./test-api.sh
```

**Login:** `admin` / `admin123`

## 📚 Documentation

All documentation is in the [`docs/`](./docs/) folder:

| Document | Description |
|----------|-------------|
| [SUCCESS.md](docs/SUCCESS.md) | ✅ Phase 1 - What's working now |
| [QUICKSTART.md](docs/QUICKSTART.md) | Get started in 5 minutes |
| [APP_README.md](docs/APP_README.md) | Application architecture & API docs |
| [PROJECT_PLAN.md](docs/PROJECT_PLAN.md) | Complete 6-phase implementation plan |
| [PHASE1_SUMMARY.md](docs/PHASE1_SUMMARY.md) | Phase 1 completion details |
| [PHASE2_COMPLETE.md](docs/PHASE2_COMPLETE.md) | ✅ Phase 2 completion report |
| [PHASE2_README.md](docs/PHASE2_README.md) | Phase 2 multi-arch builds guide |
| [START_HERE.md](docs/START_HERE.md) | Quick execution guide |

**👉 Start here: [docs/SUCCESS.md](docs/SUCCESS.md)** for current status and testing instructions.

## 🎯 Implementation Phases

### ✅ Phase 1 — App Development (COMPLETED)
- **Backend**: FastAPI + PostgreSQL + Redis + JWT
- **Status**: Running on `localhost:8000`
- **Docs**: See [SUCCESS.md](docs/SUCCESS.md)

### ✅ Phase 2 — Containerize + Multi-Registry (COMPLETE)
- ✅ Multi-arch Docker buildx configured (amd64 + arm64)
- ✅ Build scripts created and tested
- ✅ Images built for both platforms
- ✅ Pushed to GitHub Container Registry (ghcr.io)
- ✅ Pushed to Docker Hub
- ✅ Multi-platform manifest verified
- **Image**: `ghcr.io/naidu72/inventory-backend:latest`
- **Docs**: See [PHASE2_COMPLETE.md](docs/PHASE2_COMPLETE.md)

### 🔜 Phase 3 — Terraform Manual Deploy
- Create Terraform modules
- Deploy to Pi Kubernetes cluster
- Manage state in MinIO

### 🔜 Phase 4 — Vault Integration
- Store secrets in Vault
- Use External Secrets Operator
- Auto-sync to Kubernetes

### 🔜 Phase 5 — GitHub Actions CI/CD
- Automated builds on push
- Terraform plan on PR
- Terraform apply on merge

### 🔜 Phase 6 — ArgoCD GitOps
- Create Helm chart
- Set up ArgoCD application
- Auto-sync from Git

## 🛠 Tech Stack

### Application
- **Backend**: FastAPI (Python)
- **Frontend**: React + TypeScript (planned)
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Auth**: JWT with RBAC

### Infrastructure
- **Container**: Docker (multi-arch)
- **Orchestration**: Kubernetes (Pi cluster)
- **IaC**: Terraform
- **GitOps**: ArgoCD
- **Secrets**: HashiCorp Vault
- **Registry**: GitHub Container Registry + Docker Hub
- **CI/CD**: GitHub Actions
- **TLS**: cert-manager
- **Ingress**: Cloudflare Tunnel

## 🎓 Learning Objectives

This project demonstrates:
- ✅ Backend API development (FastAPI)
- ✅ Database design & ORM (SQLAlchemy)
- ✅ Authentication & Authorization (JWT + RBAC)
- ✅ Caching strategies (Redis)
- ✅ Docker containerization
- 🔜 Infrastructure as Code (Terraform)
- 🔜 Kubernetes deployment
- 🔜 Secrets management (Vault)
- 🔜 CI/CD pipelines (GitHub Actions)
- 🔜 GitOps workflows (ArgoCD)

## 📊 Current Status

**Phase 1 Backend: ✅ COMPLETE**
- 24 API endpoints working
- PostgreSQL with 5 tables
- Redis caching operational
- JWT authentication with 3 roles
- Docker Compose environment
- Sample data loaded

**Phase 2 Multi-arch Builds: ✅ COMPLETE**
- Multi-arch images built (amd64 + arm64)
- Published to GitHub Container Registry
- Published to Docker Hub
- Image: `ghcr.io/naidu72/inventory-backend:latest`
- Size: ~334MB optimized
- Ready for Kubernetes deployment

**Ready for:** Phase 3 (Terraform deployment to Pi cluster)

## 🌐 Production Deployment (Future)

After all phases are complete:

```
https://inventory.naidu72.info       → Frontend
https://inventory-api.naidu72.info   → Backend API
```

Deployed on Raspberry Pi Kubernetes cluster with:
- TLS certificates (cert-manager)
- Cloudflare Tunnel ingress
- Vault-managed secrets
- ArgoCD auto-sync

## 📝 Notes

### Docker Compose Command
- ✅ Use: `docker compose` (V2)
- ❌ Don't use: `docker-compose` (V1 - compatibility issues)

### Repository
This is a study project for the `study_terraform` repository:
https://github.com/naidu72/study_terraform

## 🤝 Contributing

This is a personal learning project. Feel free to fork and adapt for your own use.

## 📄 License

MIT License - See LICENSE file for details

---

**Current Focus:** Phase 3 Terraform Deployment 🚀 Ready to Start  
**Phase 1:** ✅ Backend Complete  
**Phase 2:** ✅ Multi-arch Images Complete  
**Next Step:** Deploy to Pi Kubernetes cluster with Terraform  
**Documentation:** All docs in [`docs/`](./docs/) folder

**📖 Phase 2 Complete:** See [docs/PHASE2_COMPLETE.md](docs/PHASE2_COMPLETE.md) for details.  
**🚀 Next Phase:** Terraform modules and K8s deployment to Pi cluster.
