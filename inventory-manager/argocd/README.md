# ArgoCD Configuration (Phase 6)

This directory contains ArgoCD Application definitions for GitOps deployment.

## 📅 Status: Phase 6 (Planned)

**Current Phase**: Phase 1 ✅ Complete  
**This Phase**: 🔜 Not started

## 📦 What Will Be Here

```
argocd/
├── application.yaml        # Main application definition
├── application-dev.yaml    # Development environment
└── application-prod.yaml   # Production environment
```

## 🎯 ArgoCD Application

This will deploy the Inventory Manager to Kubernetes using GitOps principles:

### Main Application (application.yaml)
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
    path: inventory-manager/helm/inventory-manager
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

## 🔄 GitOps Workflow

1. **Code Change**: Push to Git repository
2. **ArgoCD Detects**: Monitors repo for changes
3. **Auto Sync**: Applies changes to cluster
4. **Self Heal**: Reverts manual cluster changes
5. **Prune**: Removes orphaned resources

## 🚀 Deployment Process

### Initial Setup
```bash
# Apply ArgoCD application
kubectl apply -f argocd/application.yaml

# View application status
argocd app get inventory-manager

# Sync manually (if auto-sync disabled)
argocd app sync inventory-manager
```

### Manage Application
```bash
# View application details
argocd app get inventory-manager

# View application logs
argocd app logs inventory-manager

# Refresh application (check for changes)
argocd app refresh inventory-manager

# Delete application
argocd app delete inventory-manager
```

## 🎯 Benefits of GitOps

- **Single Source of Truth**: Git is the source of truth
- **Declarative**: Describe desired state
- **Automated**: Auto-sync from Git
- **Auditable**: Git history tracks all changes
- **Rollback**: Easy rollback via Git revert
- **Self-Healing**: Auto-corrects drift

## 📊 ArgoCD UI

Once deployed, access ArgoCD UI at:
- **URL**: https://argocd.naidu72.info
- **View**: Application status, sync status, resources
- **Actions**: Sync, refresh, rollback, delete

## 🔐 Security

ArgoCD will use:
- **ServiceAccount**: `inventory-sa`
- **RBAC**: Limited to inventory-manager namespace
- **Vault Integration**: via External Secrets Operator
- **TLS**: cert-manager certificates

## 📚 Documentation

See [docs/PROJECT_PLAN.md](../docs/PROJECT_PLAN.md) for detailed Phase 6 implementation plan.

---

**Ready to implement?** Check the PROJECT_PLAN.md for ArgoCD setup instructions!
