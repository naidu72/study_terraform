# Frontend Deployment Quick Reference

## Prerequisites

✅ Backend already deployed and running
✅ Frontend Docker image pushed to GHCR
✅ GHCR credentials in Vault
✅ Kubernetes cluster accessible
✅ nginx-ingress-controller installed

## Quick Deploy to Pi Cluster

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager

# Use automated script
./scripts/deploy-with-vault.sh

# Select:
# 1) pi-k8s cluster
# 1) Fetch from Vault
```

The script will:
1. Fetch GHCR credentials from Vault
2. Fetch PostgreSQL password from Vault
3. Fetch JWT secret from Vault
4. Initialize Terraform
5. Create plan
6. Apply (after confirmation)

## Manual Deployment

```bash
cd terraform/environments/pi-cluster

# 1. Set environment variables
export TF_VAR_ghcr_username="naidu72"
export TF_VAR_ghcr_token="your-ghcr-token"
export TF_VAR_postgres_password="your-db-password"
export TF_VAR_jwt_secret_key="your-jwt-secret"

# 2. Initialize (if not done)
terraform init

# 3. Plan (review changes)
terraform plan

# 4. Apply
terraform apply
```

## Verify Deployment

```bash
# Check pods
kubectl get pods -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Expected: 2 frontend pods running
# inventory-manager-frontend-xxx   1/1   Running
# inventory-manager-frontend-xxx   1/1   Running

# Check service
kubectl get svc -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s \
  | grep frontend

# Expected: 
# inventory-manager-frontend-service   ClusterIP   10.x.x.x   <none>   80/TCP

# Check ingress
kubectl get ingress -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Expected:
# inventory-manager-frontend-ingress   inventory-pi.naidu72.info   80, 443

# View pod logs
kubectl logs -n inventory-manager \
  -l app=inventory-manager-frontend \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Check HPA status
kubectl get hpa -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s
```

## Test Application

### From Command Line

```bash
# Test frontend home page
curl -I https://inventory-pi.naidu72.info

# Expected: 200 OK

# Test API proxy
curl https://inventory-pi.naidu72.info/api/v1/health

# Expected: {"status":"healthy"}

# Test with authentication
curl -X POST https://inventory-pi.naidu72.info/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Expected: JWT token response
```

### From Browser

1. Open: `https://inventory-pi.naidu72.info`
2. Login with:
   - Username: `admin`
   - Password: `admin123`
3. Navigate through:
   - Dashboard (stats and charts)
   - Products (CRUD operations)
   - Categories (manage categories)
   - Stock Movements (track inventory)

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n inventory-manager \
  -l app=inventory-manager-frontend \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Common issues:
# - ImagePullBackOff: Check GHCR credentials
# - CrashLoopBackOff: Check logs for errors
```

### Image Pull Errors

```bash
# Verify GHCR secret exists
kubectl get secret ghcr-secret -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# If missing, recreate:
kubectl delete secret ghcr-secret -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

terraform apply -replace="module.inventory_manager.module.frontend.kubernetes_secret.ghcr"
```

### Ingress Not Working

```bash
# Check ingress status
kubectl describe ingress -n inventory-manager \
  inventory-manager-frontend-ingress \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Check nginx-ingress logs
kubectl logs -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Verify DNS
nslookup inventory-pi.naidu72.info
```

### Backend Connection Issues

```bash
# Check if backend is reachable from frontend pod
kubectl exec -n inventory-manager \
  -it deployment/inventory-manager-frontend \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s \
  -- wget -O- http://inventory-manager-backend-service:8000/api/v1/health

# Expected: {"status":"healthy"}
```

## Scaling

### Manual Scaling

```bash
# Scale to 3 replicas
kubectl scale deployment inventory-manager-frontend \
  -n inventory-manager \
  --replicas=3 \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Note: HPA will override this if enabled
```

### Update HPA Settings

Edit `terraform/modules/frontend/main.tf`:
```hcl
resource "kubernetes_horizontal_pod_autoscaler_v2" "frontend" {
  # ...
  spec {
    min_replicas = 2  # Change this
    max_replicas = 10 # Change this
    # ...
  }
}
```

Then apply:
```bash
terraform apply
```

## Rolling Update

To deploy a new frontend version:

```bash
# 1. Build and push new image
cd app/frontend
./scripts/quick-build-frontend.sh

# 2. Update Terraform to use new tag (if using versioned tags)
# Or keep using :latest for auto-update

# 3. Force update (if using :latest)
kubectl rollout restart deployment/inventory-manager-frontend \
  -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# 4. Monitor rollout
kubectl rollout status deployment/inventory-manager-frontend \
  -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s
```

## Cleanup

```bash
# Remove frontend only (keep backend, DB, Redis)
cd terraform/environments/pi-cluster
terraform destroy -target=module.inventory_manager.module.frontend

# Remove entire stack
terraform destroy
```

## Next Steps

After successful frontend deployment:

1. ✅ Test complete application end-to-end
2. 🔜 Configure custom domain (if needed)
3. 🔜 Set up monitoring (Prometheus/Grafana)
4. 🔜 Implement External Secrets Operator (Phase 4)
5. 🔜 Set up GitHub Actions CI/CD (Phase 5)
6. 🔜 Deploy ArgoCD GitOps (Phase 6)

## Useful Commands

```bash
# Port-forward frontend locally
kubectl port-forward -n inventory-manager \
  svc/inventory-manager-frontend-service 8080:80 \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Then access: http://localhost:8080

# Get all resources
kubectl get all -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Get resource usage
kubectl top pods -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s
```

---

**🎉 Happy Deploying!**
