# Inventory Manager - Terraform Deployment

This directory contains the Terraform configuration for deploying the Inventory Manager application to the Pi Kubernetes cluster with remote state storage in MinIO.

## Architecture

- **Frontend**: React application with Nginx (2 replicas)
- **Backend**: FastAPI application (2 replicas)
- **Database**: PostgreSQL (StatefulSet with PVC)
- **Cache**: Redis (Deployment with PVC)
- **Ingress**: Cloudflare Tunnel for external access
- **Remote State**: MinIO S3-compatible storage

## Prerequisites

1. **Vault CLI** - For secrets management
   ```bash
   vault login
   ```

2. **kubectl** - Configured for pi-k8s cluster
   ```bash
   export KUBECONFIG=~/.kube/pi-cluster
   ```

3. **MinIO** - Running on the cluster with NodePort service
   - API Endpoint: `http://192.168.0.151:30900` (NodePort 30900)
   - Bucket: `terraform-state`

## Remote State Configuration

Terraform state is stored remotely in MinIO using the S3 backend:

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "inventory-manager/pi-cluster/terraform.tfstate"
    region = "us-east-1"
    
    endpoints = {
      s3 = "http://192.168.0.151:30900"  # MinIO NodePort
    }
    
    workspace_key_prefix        = ""
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
```

**Why NodePort instead of Ingress?**
- Terraform's AWS SDK v2 has signature compatibility issues with MinIO through HTTPS proxies (Cloudflare Tunnel)
- Direct NodePort access bypasses the proxy and works reliably
- Only Terraform needs this access - the application itself doesn't interact with MinIO

## Secrets Management

All sensitive values are stored in HashiCorp Vault:

- `secret/ghcr/credentials` - GitHub Container Registry token
- `secret/inventory-manager/postgres` - PostgreSQL password
- `secret/inventory-manager/jwt` - JWT secret key
- `secret/minio/credentials` - MinIO access/secret keys (for Terraform backend)

## Deployment

### Option 1: Using the deployment script (Recommended)

```bash
./deploy.sh
```

The script will:
1. Fetch secrets from Vault
2. Initialize Terraform with MinIO backend
3. Run `terraform plan`
4. Prompt for confirmation
5. Apply the configuration

### Option 2: Manual deployment

```bash
# Export secrets from Vault
export VAULT_ADDR="https://vault.naidu72.info"
export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key_id secret/minio/credentials)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_access_key secret/minio/credentials)
export TF_VAR_ghcr_username="naidu72"
export TF_VAR_ghcr_token=$(vault kv get -field=token secret/ghcr/credentials)
export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres)
export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt)

# Initialize Terraform
terraform init

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

## Destroying Resources

```bash
./destroy.sh
```

**Note**: The destroy script preserves the state file in MinIO. Only the Kubernetes resources are destroyed.

## Accessing the Application

- **Frontend**: https://inventory-pi.naidu72.info
- **Backend API**: https://inventory-pi.naidu72.info/api/v1/docs

### Default Credentials

- Username: `admin`
- Password: `admin123`

## Verifying State Storage

Check the state file in MinIO:

```bash
export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key_id secret/minio/credentials)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_access_key secret/minio/credentials)

# List bucket contents
aws --endpoint-url http://192.168.0.151:30900 s3 ls s3://terraform-state/inventory-manager/pi-cluster/

# Download state file
aws --endpoint-url http://192.168.0.151:30900 s3 cp \
  s3://terraform-state/inventory-manager/pi-cluster/terraform.tfstate \
  ./terraform.tfstate.backup
```

## Troubleshooting

### State Lock Issues

If Terraform state is locked, you can force unlock:

```bash
terraform force-unlock <lock-id>
```

### Backend Reinitialization

If backend configuration changes:

```bash
terraform init -reconfigure
```

### Connection Issues

Verify MinIO is accessible:

```bash
# Check MinIO service
kubectl get svc -n minio minio-api-service

# Test connection
aws --endpoint-url http://192.168.0.151:30900 s3 ls
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│           Cloudflare Tunnel Ingress             │
│         inventory-pi.naidu72.info               │
└─────────────────┬───────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼────────┐  ┌──────▼───────┐
│   Frontend     │  │   Backend    │
│  (Nginx+React) │  │  (FastAPI)   │
│   2 replicas   │  │  2 replicas  │
└────────────────┘  └──────┬───────┘
                           │
                  ┌────────┴────────┐
                  │                 │
          ┌───────▼────────┐ ┌─────▼──────┐
          │  PostgreSQL    │ │   Redis    │
          │  (StatefulSet) │ │ (Deployment)│
          └────────────────┘ └────────────┘

┌─────────────────────────────────────────────────┐
│            Terraform State Storage              │
│                                                 │
│  MinIO S3 (NodePort 30900)                     │
│  s3://terraform-state/inventory-manager/       │
└─────────────────────────────────────────────────┘
```

## File Structure

```
pi-cluster/
├── backend.tf              # MinIO S3 backend configuration
├── main.tf                 # Root module configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars        # Variable values
├── deploy.sh               # Deployment script
├── destroy.sh              # Destroy script
├── migrate-state.sh        # State migration helper
└── README.md              # This file
```

## Resources Created

- 1 Namespace (`inventory-manager`)
- 2 Frontend Pods + Service + Ingress + HPA
- 2 Backend Pods + Service + HPA
- 1 PostgreSQL StatefulSet + Service + PVC
- 1 Redis Deployment + Service + PVC
- 1 Init Job (database initialization)
- Various ConfigMaps and Secrets

**Total**: 20 Kubernetes resources

## Notes

- The application uses the latest images from GHCR (`ghcr.io/naidu72/*:latest`)
- Frontend has a custom nginx configuration for API proxying
- Backend connects to PostgreSQL and Redis
- All credentials are managed through Vault
- State is versioned and locked in MinIO
- Ingress uses Cloudflare Tunnel for secure external access
