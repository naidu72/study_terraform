# Frontend Deployment Checklist ✅

Before deploying the frontend, verify these requirements:

## Prerequisites

### 1. Backend Infrastructure ✅
- [ ] Backend pods are running
- [ ] PostgreSQL is accessible
- [ ] Redis is accessible
- [ ] Backend API responds to health checks

**Verify:**
```bash
kubectl get pods -n inventory-manager --kubeconfig=~/.kube/pi-cluster --context=pi-k8s
curl https://inventory-api-pi.naidu72.info/api/v1/health
```

### 2. Frontend Image ✅
- [ ] Frontend Docker image built
- [ ] Multi-arch (amd64 + arm64) support
- [ ] Image pushed to GHCR
- [ ] Image pushed to Docker Hub (optional)

**Verify:**
```bash
docker manifest inspect ghcr.io/naidu72/inventory-frontend:latest
```

### 3. Secrets in Vault ✅
- [ ] GHCR token stored in Vault
- [ ] PostgreSQL password in Vault
- [ ] JWT secret in Vault

**Verify:**
```bash
vault kv get secret/inventory-manager/ghcr
vault kv get secret/inventory-manager/postgres
vault kv get secret/inventory-manager/jwt
```

### 4. Kubernetes Cluster ✅
- [ ] Cluster is accessible
- [ ] Kubeconfig is correct (~/.kube/pi-cluster)
- [ ] Context is set (pi-k8s)
- [ ] nginx-ingress-controller installed
- [ ] cert-manager installed

**Verify:**
```bash
kubectl cluster-info --kubeconfig=~/.kube/pi-cluster --context=pi-k8s
kubectl get pods -n ingress-nginx --kubeconfig=~/.kube/pi-cluster --context=pi-k8s
kubectl get pods -n cert-manager --kubeconfig=~/.kube/pi-cluster --context=pi-k8s
```

### 5. DNS Configuration ✅
- [ ] DNS record exists for inventory-pi.naidu72.info
- [ ] Points to cluster ingress IP

**Verify:**
```bash
nslookup inventory-pi.naidu72.info
```

### 6. Terraform State ✅
- [ ] MinIO is accessible
- [ ] State backend configured
- [ ] Previous backend deployment state exists

**Verify:**
```bash
# MinIO should be accessible
curl -I https://s3api.naidu72.info

# State file should exist
# (Will be verified during terraform init)
```

## Deployment Steps

### Step 1: Navigate to Project
```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
```

### Step 2: Run Deployment Script
```bash
./scripts/deploy-with-vault.sh
```

### Step 3: Select Options
- Select cluster: **1) pi-k8s**
- Select secret source: **1) Fetch from Vault**

### Step 4: Review Plan
- Review the Terraform plan output
- Verify resources to be created:
  - kubernetes_secret.ghcr
  - kubernetes_config_map.frontend
  - kubernetes_deployment.frontend (2 replicas)
  - kubernetes_service.frontend
  - kubernetes_ingress_v1.frontend
  - kubernetes_horizontal_pod_autoscaler_v2.frontend

### Step 5: Confirm Apply
- Type **yes** when prompted

### Step 6: Wait for Deployment
- Terraform will create resources (~1-2 minutes)
- Watch for "Apply complete!" message

## Post-Deployment Verification

### 1. Check Pods
```bash
kubectl get pods -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Expected: 2 frontend pods in Running state
# inventory-manager-frontend-xxx   1/1   Running
# inventory-manager-frontend-xxx   1/1   Running
```

### 2. Check Services
```bash
kubectl get svc -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s \
  | grep frontend

# Expected:
# inventory-manager-frontend-service   ClusterIP   10.x.x.x   <none>   80/TCP
```

### 3. Check Ingress
```bash
kubectl get ingress -n inventory-manager \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s

# Expected:
# inventory-manager-frontend-ingress   inventory-pi.naidu72.info   80, 443
```

### 4. Check Logs
```bash
kubectl logs -n inventory-manager \
  -l app=inventory-manager-frontend \
  --tail=50 \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s
```

### 5. Test HTTP Response
```bash
curl -I https://inventory-pi.naidu72.info

# Expected: HTTP/2 200
```

### 6. Test API Proxy
```bash
curl https://inventory-pi.naidu72.info/api/v1/health

# Expected: {"status":"healthy"}
```

### 7. Test in Browser
Open: https://inventory-pi.naidu72.info

- [ ] Page loads successfully
- [ ] Login page appears
- [ ] Can login with admin/admin123
- [ ] Dashboard displays data
- [ ] Products page works
- [ ] Categories page works
- [ ] Stock movements page works

## Troubleshooting

### Issue: Pods Not Starting

**Check:**
```bash
kubectl describe pod -n inventory-manager \
  -l app=inventory-manager-frontend \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s
```

**Common causes:**
- ImagePullBackOff → Check GHCR credentials
- CrashLoopBackOff → Check logs
- Pending → Check resources/PVC

### Issue: 503 Service Temporarily Unavailable

**Check:**
```bash
# Check if pods are ready
kubectl get pods -n inventory-manager

# Check ingress
kubectl describe ingress -n inventory-manager \
  inventory-manager-frontend-ingress \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s
```

**Common causes:**
- Pods not ready yet (wait 30 seconds)
- Service selector mismatch
- Ingress controller issues

### Issue: Cannot Connect to Backend

**Check:**
```bash
# From within frontend pod
kubectl exec -n inventory-manager \
  -it deployment/inventory-manager-frontend \
  --kubeconfig=~/.kube/pi-cluster \
  --context=pi-k8s \
  -- wget -O- http://inventory-manager-backend-service:8000/api/v1/health
```

**Common causes:**
- Backend not running
- Service name incorrect
- Network policy blocking

## Success Criteria ✅

Your deployment is successful when:

- [x] All pods are Running (2 frontend + 2 backend + 1 postgres + 1 redis)
- [x] Frontend service is ClusterIP on port 80
- [x] Ingress exists with correct hostname
- [x] HTTPS works (cert issued)
- [x] Frontend loads in browser
- [x] Can login successfully
- [x] Dashboard shows data
- [x] API calls work

## Rollback (if needed)

If something goes wrong:

```bash
cd terraform/environments/pi-cluster

# Destroy only frontend
terraform destroy -target=module.inventory_manager.module.frontend

# Or rollback to previous state
terraform apply -target=module.inventory_manager.module.frontend
```

## Next Steps After Success 🎉

1. **Test thoroughly** - Try all features
2. **Monitor resources** - Watch CPU/Memory usage
3. **Check HPA** - Verify auto-scaling works
4. **Move to Phase 4** - External Secrets Operator
5. **Set up monitoring** - Prometheus/Grafana
6. **Configure alerts** - For production readiness

---

**Ready to deploy? Let's do this! 🚀**

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/deploy-with-vault.sh
```
