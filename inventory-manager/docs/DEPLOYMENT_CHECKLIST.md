# ✅ Pre-Deployment Checklist

## Before You Deploy - Complete This Checklist

Use this checklist to ensure everything is ready for a successful multi-cluster deployment.

---

## 📋 Infrastructure Prerequisites

### ☸️ Kubernetes Clusters

- [ ] **pi-k8s cluster is accessible**
  ```bash
  kubectl cluster-info --context=pi-k8s
  kubectl get nodes --context=pi-k8s
  ```

- [ ] **k8s-k8s cluster is accessible**
  ```bash
  kubectl cluster-info --context=k8s-k8s
  kubectl get nodes --context=k8s-k8s
  ```

- [ ] **Both clusters have sufficient resources**
  ```bash
  kubectl top nodes --context=pi-k8s
  kubectl top nodes --context=k8s-k8s
  ```

- [ ] **Storage classes are available**
  ```bash
  kubectl get sc --context=pi-k8s
  kubectl get sc --context=k8s-k8s
  ```

### 🔧 Required Tools

- [ ] **Terraform installed** (>= 1.0)
  ```bash
  terraform version
  # Should show: Terraform v1.x.x or higher
  ```

- [ ] **kubectl installed and configured**
  ```bash
  kubectl version --client
  # Should show: Client Version: v1.x.x
  ```

- [ ] **Vault CLI installed** (optional but recommended)
  ```bash
  vault version
  # Should show: Vault v1.x.x
  ```

- [ ] **AWS CLI or MinIO client** (optional, for state verification)
  ```bash
  aws --version
  # OR
  mc --version
  ```

---

## 🐳 Container Images

- [ ] **Multi-arch image is built and available**
  ```bash
  docker manifest inspect ghcr.io/naidu72/inventory-backend:latest
  # Should show both amd64 and arm64 architectures
  ```

- [ ] **Can pull image on both architectures**
  ```bash
  # Test on amd64
  docker pull --platform linux/amd64 ghcr.io/naidu72/inventory-backend:latest
  
  # Test on arm64
  docker pull --platform linux/arm64 ghcr.io/naidu72/inventory-backend:latest
  ```

- [ ] **Image is accessible from clusters**
  - No GHCR authentication issues
  - Images are public or credentials are configured

---

## 🔐 Secrets Management

### MinIO (Terraform State Backend)

- [ ] **MinIO is accessible**
  ```bash
  curl -I https://s3.naidu72.info
  # Should return HTTP 200 or 403 (authenticated)
  ```

- [ ] **MinIO credentials are ready**
  - Access Key ID
  - Secret Access Key

- [ ] **Terraform state bucket exists**
  ```bash
  aws --endpoint-url=https://s3.naidu72.info s3 ls s3://terraform-state/
  # OR create it:
  aws --endpoint-url=https://s3.naidu72.info s3 mb s3://terraform-state
  ```

### HashiCorp Vault (Secrets)

- [ ] **Vault is accessible**
  ```bash
  curl -I https://vault.naidu72.info
  # Should return HTTP 200
  ```

- [ ] **Vault credentials/token is ready**
  ```bash
  export VAULT_ADDR="https://vault.naidu72.info"
  vault status
  # Should show Vault status
  ```

- [ ] **Required secrets are stored in Vault** (if using Vault method)
  ```bash
  # Check MinIO credentials
  vault kv get secret/minio/credentials
  
  # Check PostgreSQL password
  vault kv get secret/inventory-manager/postgres
  
  # Check JWT secret
  vault kv get secret/inventory-manager/jwt
  ```

### Manual Secrets (Alternative)

If not using Vault, prepare these values:

- [ ] **MinIO Access Key ID**: `_____________________`
- [ ] **MinIO Secret Access Key**: `_____________________`
- [ ] **PostgreSQL Password**: `_____________________`
- [ ] **JWT Secret Key**: `_____________________`

**Security Note:** Use strong, randomly generated values!

```bash
# Generate strong passwords
openssl rand -base64 32  # For PostgreSQL
openssl rand -base64 64  # For JWT Secret
```

---

## 📁 Project Files

- [ ] **Project directory exists and is accessible**
  ```bash
  cd /home/frontier/terraform/study_terraform/inventory-manager
  pwd
  ```

- [ ] **All Terraform files are present**
  ```bash
  ls terraform/
  # Should show: modules/ environments/ versions.tf providers.tf variables.tf main.tf outputs.tf
  ```

- [ ] **Environment configurations exist**
  ```bash
  ls terraform/environments/
  # Should show: pi-cluster/ k8s-cluster/
  ```

- [ ] **Deployment script is executable**
  ```bash
  ls -l scripts/deploy-with-vault.sh
  # Should show: -rwxr-xr-x (executable)
  ```

---

## 🌐 Network & DNS

- [ ] **Can reach external services**
  ```bash
  # MinIO
  ping -c 3 s3.naidu72.info
  
  # Vault
  ping -c 3 vault.naidu72.info
  
  # GHCR
  ping -c 3 ghcr.io
  ```

- [ ] **Cluster ingress is configured** (if using ingress)
  ```bash
  kubectl get ingressclass --context=pi-k8s
  kubectl get ingressclass --context=k8s-k8s
  ```

- [ ] **DNS resolution works from pods**
  ```bash
  kubectl run -it --rm debug --image=alpine --context=pi-k8s -- nslookup s3.naidu72.info
  ```

---

## 📊 Resource Requirements

### pi-k8s Cluster (ARM64)

- [ ] **At least 2 CPU cores available**
- [ ] **At least 4GB RAM available**
- [ ] **At least 10GB storage available** (5Gi PG + 2Gi Redis + overhead)

### k8s-k8s Cluster (AMD64)

- [ ] **At least 3 CPU cores available**
- [ ] **At least 6GB RAM available**
- [ ] **At least 20GB storage available** (10Gi PG + 5Gi Redis + overhead)

### Verify Resources

```bash
# Check available resources
kubectl describe nodes --context=pi-k8s | grep -A 5 "Allocated resources"
kubectl describe nodes --context=k8s-k8s | grep -A 5 "Allocated resources"
```

---

## 🔍 Pre-Deployment Verification

Run the preflight check script:

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/preflight-check.sh
```

Or manually verify:

- [ ] **Namespace doesn't already exist** (or you're OK overwriting)
  ```bash
  kubectl get namespace inventory-manager --context=pi-k8s
  kubectl get namespace inventory-manager --context=k8s-k8s
  # Should return "Error from server (NotFound)" if clean install
  ```

- [ ] **No conflicting resources exist**
  ```bash
  kubectl get all -n inventory-manager --context=pi-k8s
  kubectl get all -n inventory-manager --context=k8s-k8s
  ```

---

## 📝 Environment Variables (If Using Manual Secrets)

Before running deployment, export these:

```bash
# MinIO credentials
export AWS_ACCESS_KEY_ID="your_minio_access_key"
export AWS_SECRET_ACCESS_KEY="your_minio_secret_key"

# Application secrets
export TF_VAR_postgres_password="your_postgres_password"
export TF_VAR_jwt_secret_key="your_jwt_secret_key"

# Verify they're set
echo $AWS_ACCESS_KEY_ID
echo $TF_VAR_postgres_password
```

---

## 🎯 Deployment Target Selection

Decide which deployment option to use:

- [ ] **Option 1:** Deploy to both clusters sequentially
- [ ] **Option 2:** Deploy to pi-k8s only (ARM64)
- [ ] **Option 3:** Deploy to k8s-k8s only (AMD64)

---

## 🚀 Ready to Deploy!

When all items above are checked:

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/deploy-with-vault.sh
```

---

## 📋 Post-Deployment Checks

After deployment completes, verify:

- [ ] **All pods are running**
  ```bash
  kubectl get pods -n inventory-manager --context=pi-k8s
  kubectl get pods -n inventory-manager --context=k8s-k8s
  ```

- [ ] **Services are accessible**
  ```bash
  kubectl get svc -n inventory-manager --context=pi-k8s
  kubectl get svc -n inventory-manager --context=k8s-k8s
  ```

- [ ] **API health check passes**
  ```bash
  kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8000:8000 --context=pi-k8s &
  curl http://localhost:8000/health
  ```

- [ ] **API documentation is accessible**
  ```bash
  open http://localhost:8000/docs
  ```

- [ ] **Can create test item**
  ```bash
  curl -X POST http://localhost:8000/api/items \
    -H "Content-Type: application/json" \
    -d '{"name": "Test", "description": "Testing", "quantity": 10, "price": 99.99}'
  ```

- [ ] **Terraform state is stored in MinIO**
  ```bash
  aws --endpoint-url=https://s3.naidu72.info s3 ls s3://terraform-state/inventory-manager/
  ```

---

## 🛑 If Something Goes Wrong

### Quick Rollback

```bash
# Destroy deployment
cd terraform/environments/pi-cluster
terraform destroy

cd terraform/environments/k8s-cluster
terraform destroy

# Or delete namespace
kubectl delete namespace inventory-manager --context=pi-k8s
kubectl delete namespace inventory-manager --context=k8s-k8s
```

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Pod stuck in Pending** | Check PVC status, storage class availability |
| **ImagePullBackOff** | Verify GHCR credentials, image exists, network access |
| **CrashLoopBackOff** | Check pod logs: `kubectl logs <pod> -n inventory-manager` |
| **Init containers failing** | Database/Redis not ready - wait or check logs |
| **Terraform state lock** | Someone else deploying? Wait or break lock carefully |
| **Vault auth failed** | Re-authenticate: `vault login` |

### Get Help

- Check logs: `kubectl logs -n inventory-manager -l app=inventory-manager`
- Describe pod: `kubectl describe pod <pod-name> -n inventory-manager`
- Review documentation: [docs/MULTI_CLUSTER_DEPLOYMENT.md](MULTI_CLUSTER_DEPLOYMENT.md)

---

## ✅ Checklist Summary

Total Items: **~40+**

When you've checked all items above, you're ready for a successful deployment! 🚀

**Good luck!** 🎉

---

**Last Updated:** May 5, 2026  
**For:** Multi-Cluster Inventory Manager Deployment
