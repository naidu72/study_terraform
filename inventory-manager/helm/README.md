# Helm Charts (Phase 6)

This directory will contain Helm charts for GitOps deployment via ArgoCD.

## 📅 Status: Phase 6 (Planned)

**Current Phase**: Phase 1 ✅ Complete  
**This Phase**: 🔜 Not started

## 📦 Helm Chart Structure

```
inventory-manager/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Development values
├── values-prod.yaml        # Production values
└── templates/
    ├── namespace.yaml      # Namespace definition
    ├── postgres/
    │   ├── statefulset.yaml
    │   ├── service.yaml
    │   └── pvc.yaml
    ├── redis/
    │   ├── deployment.yaml
    │   └── service.yaml
    ├── backend/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── hpa.yaml
    ├── frontend/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── hpa.yaml
    ├── ingress.yaml        # Ingress rules
    ├── secretstore.yaml    # External Secrets config
    └── externalsecret.yaml # Secret definitions
```

## 🎯 What This Will Include

### Chart Metadata (Chart.yaml)
```yaml
apiVersion: v2
name: inventory-manager
description: Enterprise Inventory Management System
version: 1.0.0
appVersion: "1.0.0"
```

### Values Configuration
- Environment-specific configurations
- Resource limits and requests
- Replica counts
- Image tags
- Ingress hosts
- Secret references

### Templates
- Kubernetes manifests with templating
- ConfigMaps for configuration
- Secrets for sensitive data
- Services for networking
- Deployments for applications
- StatefulSets for databases
- Ingress for external access

## 🚀 Usage (When Implemented)

```bash
# Install chart
helm install inventory-manager ./helm/inventory-manager \
  -f helm/inventory-manager/values-dev.yaml \
  -n inventory-manager

# Upgrade chart
helm upgrade inventory-manager ./helm/inventory-manager \
  -f helm/inventory-manager/values-dev.yaml \
  -n inventory-manager

# Uninstall
helm uninstall inventory-manager -n inventory-manager

# Lint chart
helm lint ./helm/inventory-manager

# Template (dry-run)
helm template inventory-manager ./helm/inventory-manager
```

## 🔄 ArgoCD Integration

Once created, this chart will be deployed via ArgoCD:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: inventory-manager
spec:
  source:
    path: helm/inventory-manager
    targetRevision: HEAD
  destination:
    namespace: inventory-manager
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 📚 Documentation

See [docs/PROJECT_PLAN.md](../docs/PROJECT_PLAN.md) for detailed Phase 6 implementation plan.

---

**Ready to implement?** Check the PROJECT_PLAN.md for Helm chart examples!
