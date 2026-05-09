# 🚀 Multi-Cluster Deployment Guide

## Phase 3: Deploying to Both Kubernetes Clusters

This guide covers deploying the Inventory Manager to both your **pi-k8s (arm64)** Raspberry Pi cluster and **k8s-k8s (amd64)** standard Kubernetes cluster.

---

## ✅ Prerequisites Confirmed

- [x] **Docker images built** - `ghcr.io/naidu72/inventory-backend:latest` (multi-arch: amd64, arm64)
- [x] **MinIO backend** - `https://s3.naidu72.info` for Terraform state
- [x] **Vault secrets** - `vault.naidu72.info` for credentials management
- [x] **Both clusters active**:
  - `pi-k8s` (arm64) - Raspberry Pi cluster
  - `k8s-k8s` (amd64) - Standard Kubernetes cluster

---

## 🎯 Deployment Options

### Option 1: Deploy to a Single Cluster

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/deploy-with-vault.sh
```

When prompted, choose:
- **1** for pi-k8s (arm64)
- **2** for k8s-k8s (amd64)

### Option 2: Deploy to Both Clusters Sequentially

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/deploy-with-vault.sh
```

When prompted, choose **3** to deploy to both clusters automatically.

---

## 🔐 Secrets Management

The deployment script supports two methods:

### Method 1: Vault (Recommended)

The script will automatically fetch secrets from your Vault instance if configured:

**MinIO Credentials:**
- Path: `secret/minio/credentials`
- Fields: `access_key_id`, `secret_access_key`

**PostgreSQL Password:**
- Path: `secret/inventory-manager/postgres`
- Field: `password`

**JWT Secret:**
- Path: `secret/inventory-manager/jwt`
- Field: `secret_key`

**Setup Vault Secrets (One-time):**
```bash
export VAULT_ADDR="https://vault.naidu72.info"
vault login

# MinIO credentials
vault kv put secret/minio/credentials \
  access_key_id="YOUR_MINIO_ACCESS_KEY" \
  secret_access_key="YOUR_MINIO_SECRET_KEY"

# PostgreSQL password
vault kv put secret/inventory-manager/postgres \
  password="YOUR_POSTGRES_PASSWORD"

# JWT secret
vault kv put secret/inventory-manager/jwt \
  secret_key="YOUR_JWT_SECRET_KEY"
```

### Method 2: Manual Entry

If Vault is not available or you prefer manual entry, the script will prompt you for:
- MinIO Access Key ID
- MinIO Secret Access Key
- PostgreSQL Password
- JWT Secret Key

---

## 📋 Deployment Steps

### 1. Run the Deployment Script

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/deploy-with-vault.sh
```

### 2. Follow the Prompts

The script will:
1. ✅ Check prerequisites (Terraform, Vault CLI)
2. 🎯 Ask which cluster(s) to deploy to
3. 🔐 Fetch or prompt for secrets
4. 🔧 Run Terraform workflow:
   - `terraform init` (configure MinIO backend)
   - `terraform validate` (check configuration)
   - `terraform plan` (preview changes)
   - `terraform apply` (deploy resources)
5. 📊 Display deployment outputs
6. 🔍 Check pod status

### 3. Verify Deployment

**Check pods:**
```bash
# For pi-k8s
kubectl get pods -n inventory-manager --context=pi-k8s

# For k8s-k8s
kubectl get pods -n inventory-manager --context=k8s-k8s
```

**Check all resources:**
```bash
# For pi-k8s
kubectl get all -n inventory-manager --context=pi-k8s

# For k8s-k8s
kubectl get all -n inventory-manager --context=k8s-k8s
```

---

## 🧪 Testing the Deployment

### Access via Port-Forward

**pi-k8s cluster:**
```bash
kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8000:8000 --context=pi-k8s
```

**k8s-k8s cluster:**
```bash
kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8001:8000 --context=k8s-k8s
```

### Test the API

**pi-k8s (port 8000):**
```bash
# Health check
curl http://localhost:8000/health

# API docs
open http://localhost:8000/docs
```

**k8s-k8s (port 8001):**
```bash
# Health check
curl http://localhost:8001/health

# API docs
open http://localhost:8001/docs
```

### Create Test Data

```bash
# Create an item (pi-k8s)
curl -X POST http://localhost:8000/api/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Raspberry Pi 5",
    "description": "Latest Pi model",
    "quantity": 10,
    "price": 79.99
  }'

# Create an item (k8s-k8s)
curl -X POST http://localhost:8001/api/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Intel NUC",
    "description": "Mini PC",
    "quantity": 5,
    "price": 399.99
  }'

# List items
curl http://localhost:8000/api/items  # pi-k8s
curl http://localhost:8001/api/items  # k8s-k8s
```

---

## 📊 Cluster Comparison

| Feature | pi-k8s (arm64) | k8s-k8s (amd64) |
|---------|----------------|-----------------|
| **Architecture** | ARM64 | AMD64 |
| **Backend Replicas** | 2 | 3 |
| **PostgreSQL Storage** | 5Gi | 10Gi |
| **Redis Storage** | 2Gi | 5Gi |
| **Resource Limits** | Conservative | Higher |
| **State File** | `pi-cluster/terraform.tfstate` | `k8s-cluster/terraform.tfstate` |
| **Ingress Host** | `inventory-manager-pi.local` | `inventory-manager-k8s.local` |

---

## 🔧 Manual Terraform Commands

If you prefer to run Terraform manually:

### Deploy to pi-k8s

```bash
cd terraform/environments/pi-cluster

# Set environment variables
export AWS_ACCESS_KEY_ID="your_minio_key"
export AWS_SECRET_ACCESS_KEY="your_minio_secret"
export TF_VAR_postgres_password="your_postgres_password"
export TF_VAR_jwt_secret_key="your_jwt_secret"

# Terraform workflow
terraform init
terraform validate
terraform plan
terraform apply
```

### Deploy to k8s-k8s

```bash
cd terraform/environments/k8s-cluster

# Set environment variables (same as above)
export AWS_ACCESS_KEY_ID="your_minio_key"
export AWS_SECRET_ACCESS_KEY="your_minio_secret"
export TF_VAR_postgres_password="your_postgres_password"
export TF_VAR_jwt_secret_key="your_jwt_secret"

# Terraform workflow
terraform init
terraform validate
terraform plan
terraform apply
```

---

## 📈 Monitoring

### View Logs

**Backend logs:**
```bash
# pi-k8s
kubectl logs -n inventory-manager -l app=inventory-manager --context=pi-k8s -f

# k8s-k8s
kubectl logs -n inventory-manager -l app=inventory-manager --context=k8s-k8s -f
```

**PostgreSQL logs:**
```bash
# pi-k8s
kubectl logs -n inventory-manager -l app=postgresql --context=pi-k8s -f

# k8s-k8s
kubectl logs -n inventory-manager -l app=postgresql --context=k8s-k8s -f
```

### Resource Usage

```bash
# pi-k8s
kubectl top pods -n inventory-manager --context=pi-k8s

# k8s-k8s
kubectl top pods -n inventory-manager --context=k8s-k8s
```

---

## 🛠️ Troubleshooting

### Pods Not Starting

**Check pod status:**
```bash
kubectl describe pod <pod-name> -n inventory-manager --context=<cluster>
```

**Common issues:**
- Image pull errors: Verify GHCR credentials
- Init container failures: Check PostgreSQL/Redis connectivity
- Resource constraints: Review resource limits for your cluster

### Database Connection Issues

**Check PostgreSQL pod:**
```bash
kubectl logs -n inventory-manager -l app=postgresql --context=<cluster>
```

**Test connection:**
```bash
kubectl exec -it -n inventory-manager <backend-pod> --context=<cluster> -- \
  python -c "import asyncpg; print('Connection OK')"
```

### State File Issues

**Verify MinIO access:**
```bash
# Using AWS CLI
aws --endpoint-url=https://s3.naidu72.info s3 ls s3://terraform-state/inventory-manager/

# Or check in MinIO web UI
open https://s3.naidu72.info/login
```

---

## 🧹 Cleanup

### Destroy Deployment

**Single cluster:**
```bash
cd terraform/environments/<pi-cluster or k8s-cluster>
terraform destroy
```

**Both clusters:**
```bash
# pi-k8s
cd terraform/environments/pi-cluster
terraform destroy

# k8s-k8s
cd terraform/environments/k8s-cluster
terraform destroy
```

### Delete Namespace (if needed)

```bash
kubectl delete namespace inventory-manager --context=pi-k8s
kubectl delete namespace inventory-manager --context=k8s-k8s
```

---

## 📁 Terraform State Files

State files are stored in MinIO at `https://s3.naidu72.info`:

- **pi-k8s**: `s3://terraform-state/inventory-manager/pi-cluster/terraform.tfstate`
- **k8s-k8s**: `s3://terraform-state/inventory-manager/k8s-cluster/terraform.tfstate`

This allows:
- ✅ Team collaboration
- ✅ State locking
- ✅ Version history
- ✅ Backup and recovery

---

## 🎯 Next Steps

1. ✅ Deploy to both clusters
2. ⚡ Set up Ingress with TLS certificates
3. 📊 Configure monitoring (Prometheus/Grafana)
4. 🔄 Implement CI/CD pipeline
5. 🔐 Enable HTTPS for MinIO and Vault
6. 📈 Scale backend replicas based on load
7. 🗄️ Set up database backups
8. 🌐 Configure external access (LoadBalancer/NodePort)

---

## 📚 Related Documentation

- [Phase 3 Plan](PHASE3_PLAN.md)
- [Terraform README](../terraform/README.md)
- [Vault Integration Guide](VAULT_INTEGRATION_GUIDE.md)
- [Phase 3 Ready](PHASE3_READY.md)

---

## ✅ Success Criteria

Deployment is successful when:

- [x] All pods are in `Running` state
- [x] PostgreSQL database is initialized
- [x] Backend API responds to health checks
- [x] API documentation is accessible
- [x] Test items can be created/retrieved
- [x] Terraform state is stored in MinIO
- [x] Resources are deployed to both clusters (if chosen)

---

**Last Updated:** $(date)  
**Terraform Version:** >= 1.0  
**Kubernetes Provider:** ~> 2.23
