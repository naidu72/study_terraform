# Phase 3 - Terraform Deployment Guide

## 🎯 Goal
Deploy Inventory Manager to Pi Kubernetes cluster using Terraform Infrastructure as Code.

## 📋 Prerequisites Checklist

- [x] Phase 1: Backend application complete
- [x] Phase 2: Multi-arch images built and pushed
- [x] Kubernetes cluster accessible (pi-k8s)
- [x] kubectl configured
- [x] Terraform installed (>= 1.0)
- [x] MinIO running in cluster (for state)

## 🚀 Quick Deployment

### Step 1: Set Sensitive Variables

```bash
export TF_VAR_postgres_password="inventory_pass_secure123"
export TF_VAR_jwt_secret_key="your-super-secret-jwt-key-change-in-prod"
```

### Step 2: Navigate to Pi Cluster Environment

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager/terraform/environments/pi-cluster
```

### Step 3: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 4: Review the Plan

```bash
terraform plan
```

This shows what will be created:
- 1 Namespace
- 1 PostgreSQL StatefulSet + Service + PVC
- 1 Redis Deployment + Service + PVC
- 1 Backend Deployment + Service
- Secrets and ConfigMaps
- 1 Init Job for database

### Step 5: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted.

### Step 6: Wait for Deployment (~2-3 minutes)

```bash
watch kubectl get pods -n inventory-manager
```

Wait until all pods show `Running` or `Completed` (init job).

## 🧪 Testing the Deployment

### Check Pod Status

```bash
kubectl get pods -n inventory-manager
```

Expected output:
```
NAME                                      READY   STATUS      RESTARTS   AGE
inventory-manager-backend-xxx-yyy        1/1     Running     0          2m
inventory-manager-backend-xxx-zzz        1/1     Running     0          2m
inventory-manager-postgres-0              1/1     Running     0          2m
inventory-manager-redis-xxx-yyy          1/1     Running     0          2m
inventory-manager-init-db-xxx            0/1     Completed   0          2m
```

### Port-Forward to Access API

```bash
kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8000:8000
```

### Test the API

```bash
# Health check
curl http://localhost:8000/health

# API documentation
open http://localhost:8000/docs

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

## 📊 Terraform Outputs

View deployment information:

```bash
terraform output
```

Shows:
- Namespace name
- Service URLs
- Access instructions

## 🔍 Troubleshooting

### Init Container Stuck

If backend pods are stuck in `Init:0/2`:

```bash
# Check init container logs
kubectl logs -n inventory-manager <pod-name> -c wait-for-postgres
kubectl logs -n inventory-manager <pod-name> -c wait-for-redis
```

### Backend Pod CrashLoopBackOff

```bash
# Check backend logs
kubectl logs -n inventory-manager -l app=inventory-manager-backend

# Check database connection
kubectl exec -n inventory-manager inventory-manager-postgres-0 -- psql -U inventory_user -d inventory_db -c "SELECT 1"
```

### Database Init Job Failed

```bash
# Check init job logs
kubectl logs -n inventory-manager job/inventory-manager-init-db

# Delete and recreate
kubectl delete job -n inventory-manager inventory-manager-init-db
terraform apply
```

### Storage Issues

```bash
# Check PVCs
kubectl get pvc -n inventory-manager

# Describe PVC for details
kubectl describe pvc inventory-manager-postgres-pvc -n inventory-manager
```

## 🧹 Cleanup

To remove everything:

```bash
terraform destroy
```

Type `yes` when prompted.

This removes:
- All deployments
- All services
- All PVCs (data will be deleted!)
- Namespace

## 🎯 Success Criteria

- [ ] All pods running
- [ ] Init job completed
- [ ] API health check returns 200
- [ ] Can login via API
- [ ] Can access API documentation
- [ ] Database tables created
- [ ] Redis connection working

## 📚 Next Steps

After successful deployment:
1. Test all API endpoints
2. Verify data persistence
3. Check resource usage
4. Plan for Phase 4 (Vault integration)

## 🔗 Resources

- Terraform code: `terraform/`
- Module documentation: `terraform/modules/*/README.md`
- Full guide: `terraform/README.md`
