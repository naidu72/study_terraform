# Complete Application Stack - Architecture Overview

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    🌐 INTERNET / PUBLIC ACCESS                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                      │
                                      │ HTTPS/TLS
                                      │
                        ┌─────────────▼────────────────┐
                        │                               │
                        │  🔒 nginx-ingress-controller  │
                        │  (cert-manager for TLS)       │
                        │                               │
                        └───────────┬───────────────────┘
                                    │
                    ┌───────────────┼───────────────────┐
                    │               │                   │
         ┌──────────▼────────┐     │      ┌───────────▼──────────┐
         │                   │     │      │                      │
         │  Frontend Ingress │     │      │   Backend Ingress    │
         │  inventory-pi     │     │      │   (Optional)         │
         │  .naidu72.info    │     │      │                      │
         │                   │     │      │                      │
         └────────┬──────────┘     │      └──────────┬───────────┘
                  │                │                 │
        ┌─────────▼─────────┐     │        ┌────────▼────────┐
        │ Path: /*          │     │        │ Path: /api/*    │
        │ → Frontend:80     │     │        │ → Backend:8000  │
        └───────────────────┘     │        └─────────────────┘
                                  │
╔═════════════════════════════════▼═════════════════════════════════════════════╗
║                  📦 KUBERNETES CLUSTER (pi-k8s / ARM64)                       ║
║                        Namespace: inventory-manager                           ║
║                                                                               ║
║  ┌─────────────────────────────────────────────────────────────────────────┐ ║
║  │                         🎨 FRONTEND TIER                                 │ ║
║  │  ┌───────────────────────────────────────────────────────────────────┐  │ ║
║  │  │  Service: inventory-manager-frontend-service (ClusterIP:80)       │  │ ║
║  │  └─────────────────────────────┬───────────────────────────────────┬─┘  │ ║
║  │                                 │                                   │    │ ║
║  │  ┌──────────────────────────────┴─┐          ┌─────────────────────┴─┐  │ ║
║  │  │  Pod: frontend-xxx              │          │  Pod: frontend-yyy    │  │ ║
║  │  │  ┌────────────────────────────┐ │          │  ┌──────────────────┐ │  │ ║
║  │  │  │  Container: Nginx          │ │          │  │  Container: Nginx│ │  │ ║
║  │  │  │  Image: ghcr.io/naidu72/   │ │          │  │  Image: ghcr.io/ │ │  │ ║
║  │  │  │    inventory-frontend      │ │          │  │    inventory-    │ │  │ ║
║  │  │  │    :latest (arm64)         │ │          │  │    frontend      │ │  │ ║
║  │  │  │                            │ │          │  │    :latest       │ │  │ ║
║  │  │  │  Serves: React Static Files│ │          │  │                  │ │  │ ║
║  │  │  │  Port: 80                  │ │          │  │  Port: 80        │ │  │ ║
║  │  │  │  Resources:                │ │          │  │  Resources:      │ │  │ ║
║  │  │  │    CPU: 50m-200m           │ │          │  │    CPU: 50m-200m │ │  │ ║
║  │  │  │    Mem: 64Mi-128Mi         │ │          │  │    Mem: 64Mi-128Mi│ │ ║
║  │  │  └────────────────────────────┘ │          │  └──────────────────┘ │  │ ║
║  │  └────────────────────────────────┘          └───────────────────────┘  │ ║
║  │                                                                          │ ║
║  │  HPA: 2-6 replicas (CPU/Memory based auto-scaling)                      │ ║
║  └──────────────────────────────────────────────────────────────────────────┘ ║
║                                                                               ║
║  ┌─────────────────────────────────────────────────────────────────────────┐ ║
║  │                         ⚙️  BACKEND TIER                                 │ ║
║  │  ┌───────────────────────────────────────────────────────────────────┐  │ ║
║  │  │  Service: inventory-manager-backend-service (ClusterIP:8000)      │  │ ║
║  │  └─────────────────────────────┬───────────────────────────────────┬─┘  │ ║
║  │                                 │                                   │    │ ║
║  │  ┌──────────────────────────────┴─┐          ┌─────────────────────┴─┐  │ ║
║  │  │  Pod: backend-xxx               │          │  Pod: backend-yyy     │  │ ║
║  │  │  ┌────────────────────────────┐ │          │  ┌──────────────────┐ │  │ ║
║  │  │  │  Container: FastAPI        │ │          │  │  Container:      │ │  │ ║
║  │  │  │  Image: ghcr.io/naidu72/   │ │          │  │    FastAPI       │ │  │ ║
║  │  │  │    inventory-backend       │ │          │  │                  │ │  │ ║
║  │  │  │    :latest (arm64)         │ │          │  │                  │ │  │ ║
║  │  │  │                            │ │          │  │                  │ │  │ ║
║  │  │  │  API: /api/v1/*            │ │          │  │  Port: 8000      │ │  │ ║
║  │  │  │  Port: 8000                │ │          │  │  Resources:      │ │  │ ║
║  │  │  │  Resources:                │ │          │  │    CPU:100m-500m │ │  │ ║
║  │  │  │    CPU: 100m-500m          │ │          │  │    Mem:256Mi-512Mi│ │ ║
║  │  │  │    Mem: 256Mi-512Mi        │ │          │  │                  │ │  │ ║
║  │  │  └────────┬─────────┬─────────┘ │          │  └─┬──────┬─────────┘ │  │ ║
║  │  └───────────┼─────────┼───────────┘          └────┼──────┼───────────┘  │ ║
║  └──────────────┼─────────┼──────────────────────────┼──────┼──────────────┘ ║
║                 │         │                          │      │                ║
║                 │         │                          │      │                ║
║  ┌──────────────▼─────────┼──────────────────────────▼──────┼──────────────┐ ║
║  │                        │  💾 DATA TIER             │      │              │ ║
║  │  ┌─────────────────────▼───────────┐   ┌──────────▼──────▼───────────┐  │ ║
║  │  │                                  │   │                             │  │ ║
║  │  │  📊 PostgreSQL StatefulSet       │   │  🔴 Redis Deployment        │  │ ║
║  │  │                                  │   │                             │  │ ║
║  │  │  Pod: postgres-0                 │   │  Pod: redis-xxx             │  │ ║
║  │  │  ┌──────────────────────────┐    │   │  ┌─────────────────────┐   │  │ ║
║  │  │  │  Container: PostgreSQL   │    │   │  │  Container: Redis   │   │  │ ║
║  │  │  │  Image: postgres:15-alpine│   │   │  │  Image: redis:7-    │   │  ║
║  │  │  │  Port: 5432              │    │   │  │    alpine           │   │  │ ║
║  │  │  │                          │    │   │  │  Port: 6379         │   │  │ ║
║  │  │  │  PVC: 5Gi                │    │   │  │  PVC: 2Gi           │   │  │ ║
║  │  │  │  Storage: local-path     │    │   │  │  Storage: local-path│   │  │ ║
║  │  │  └──────────────────────────┘    │   │  └─────────────────────┘   │  │ ║
║  │  │                                  │   │                             │  │ ║
║  │  │  Service: inventory-manager-    │   │  Service: inventory-manager-│  │ ║
║  │  │    postgres-service              │   │    redis-service            │  │ ║
║  │  │    ClusterIP:5432                │   │    ClusterIP:6379           │  │ ║
║  │  └──────────────────────────────────┘   │                             │  │ ║
║  │                                         └─────────────────────────────┘  │ ║
║  └─────────────────────────────────────────────────────────────────────────┘ ║
║                                                                               ║
║  🔐 Secrets:                                                                  ║
║    - ghcr-secret (Image pull)                                                ║
║    - inventory-manager-backend-secret (DB password, JWT secret)              ║
║                                                                               ║
║  📊 Monitoring:                                                               ║
║    - Health checks (liveness + readiness)                                    ║
║    - HPA metrics (CPU + Memory)                                              ║
║    - Resource limits enforced                                                ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝


═══════════════════════════════════════════════════════════════════════════════
                          📋 DEPLOYMENT SUMMARY
═══════════════════════════════════════════════════════════════════════════════

✅ PHASE 1 - App Development
   ├─ ✅ FastAPI Backend (Python 3.11)
   ├─ ✅ PostgreSQL Models (SQLAlchemy)
   ├─ ✅ Redis Cache Integration
   └─ ✅ React Frontend (TypeScript + Material-UI)

✅ PHASE 2 - Containerization
   ├─ ✅ Backend Multi-arch Image (amd64 + arm64)
   │     → ghcr.io/naidu72/inventory-backend:latest
   │     → naidu72/inventory-backend:latest
   └─ ✅ Frontend Multi-arch Image (amd64 + arm64)
         → ghcr.io/naidu72/inventory-frontend:latest
         → naidu72/inventory-frontend:latest

✅ PHASE 3 - Terraform Configuration
   ├─ ✅ Namespace Module
   ├─ ✅ PostgreSQL Module (StatefulSet + PVC)
   ├─ ✅ Redis Module (Deployment + PVC)
   ├─ ✅ Backend Module (Deployment + Service + Ingress)
   └─ ✅ Frontend Module (Deployment + Service + Ingress)

🚀 READY TO DEPLOY:
   - Pi Cluster (arm64): inventory-pi.naidu72.info
   - K8s Cluster (amd64): inventory-k8s.naidu72.info

🔜 NEXT PHASES:
   - Phase 4: Vault Integration (External Secrets Operator)
   - Phase 5: GitHub Actions CI/CD
   - Phase 6: ArgoCD GitOps

═══════════════════════════════════════════════════════════════════════════════
                          🎯 KEY FEATURES
═══════════════════════════════════════════════════════════════════════════════

🌐 Multi-Architecture Support
   - Runs on ARM64 (Raspberry Pi) and AMD64 (standard servers)
   - Single image supports both architectures

🔐 Security
   - HTTPS/TLS via cert-manager
   - JWT authentication
   - Kubernetes secrets for sensitive data
   - Image pull secrets for private registry

⚡ High Availability
   - Frontend: 2-6 replicas (auto-scaling)
   - Backend: 2 replicas
   - Rolling updates (zero downtime)
   - Health checks (liveness + readiness)

📊 Observability
   - Resource limits enforced
   - HPA metrics collection
   - Pod health monitoring
   - Ingress access logs

🎨 Modern Stack
   - React 18 + TypeScript
   - Material-UI components
   - FastAPI + Pydantic
   - PostgreSQL 15
   - Redis 7

═══════════════════════════════════════════════════════════════════════════════
                          📖 ACCESS POINTS
═══════════════════════════════════════════════════════════════════════════════

🌐 Frontend (UI):
   https://inventory-pi.naidu72.info
   ├─ Login: admin / admin123
   ├─ Dashboard: Real-time inventory stats
   ├─ Products: Full CRUD operations
   ├─ Categories: Manage product categories
   └─ Stock Movements: Track inventory changes

🔌 Backend (API):
   https://inventory-pi.naidu72.info/api
   └─ Swagger Docs: https://inventory-pi.naidu72.info/api/v1/docs

═══════════════════════════════════════════════════════════════════════════════
