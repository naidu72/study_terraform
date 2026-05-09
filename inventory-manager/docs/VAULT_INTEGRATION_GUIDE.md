# Vault Integration Guide - Phase 3

## 🎯 Overview

Your infrastructure has:
- **MinIO**: https://s3.naidu72.info (for Terraform state)
- **Vault**: https://vault.naidu72.info (for secrets management)

This guide shows how to use Vault to retrieve credentials for:
1. MinIO (Terraform state backend)
2. PostgreSQL password
3. JWT secret key

---

## 🔐 Using Vault for Secrets

### Step 1: Login to Vault

```bash
# Set Vault address
export VAULT_ADDR="https://vault.naidu72.info"

# Login (interactive)
vault login

# Or use token
export VAULT_TOKEN="your-vault-token"
```

### Step 2: Store Secrets in Vault (One-time Setup)

```bash
# Store MinIO credentials
vault kv put secret/minio/terraform \
  access_key="your-minio-access-key" \
  secret_key="your-minio-secret-key"

# Store PostgreSQL credentials
vault kv put secret/inventory-manager/postgres \
  password="your-secure-postgres-password"

# Store JWT secret
vault kv put secret/inventory-manager/jwt \
  secret_key="your-jwt-secret-key"
```

### Step 3: Retrieve Secrets for Terraform

```bash
# Get MinIO credentials
export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key secret/minio/terraform)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_key secret/minio/terraform)

# Get PostgreSQL password
export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres)

# Get JWT secret
export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt)
```

---

## 🚀 Deployment with Vault

### Complete Workflow

```bash
#!/bin/bash
# deploy-with-vault.sh

set -e

# 1. Configure Vault
export VAULT_ADDR="https://vault.naidu72.info"

# 2. Login to Vault (will prompt)
echo "Logging into Vault..."
vault login

# 3. Retrieve MinIO credentials for Terraform state
echo "Retrieving MinIO credentials..."
export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key secret/minio/terraform)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_key secret/minio/terraform)

# 4. Retrieve application secrets
echo "Retrieving application secrets..."
export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres)
export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt)

# 5. Navigate to Terraform directory
cd /home/frontier/terraform/study_terraform/inventory-manager/terraform/environments/pi-cluster

# 6. Initialize Terraform (will use MinIO backend)
echo "Initializing Terraform with MinIO backend..."
terraform init

# 7. Plan deployment
echo "Planning deployment..."
terraform plan

# 8. Apply (with confirmation)
echo "Ready to deploy!"
terraform apply
```

---

## 📝 Alternative: Manual Secrets (Quick Start)

If you want to deploy quickly without Vault integration:

```bash
# Set MinIO credentials
export AWS_ACCESS_KEY_ID="your-minio-access-key"
export AWS_SECRET_ACCESS_KEY="your-minio-secret-key"

# Set application secrets
export TF_VAR_postgres_password="your-postgres-password"
export TF_VAR_jwt_secret_key="your-jwt-secret"

# Deploy
cd /home/frontier/terraform/study_terraform/inventory-manager/terraform/environments/pi-cluster
terraform init
terraform plan
terraform apply
```

---

## 🏗️ MinIO State Backend Configuration

Your Terraform backend is configured to use:

```hcl
backend "s3" {
  bucket   = "terraform-state"
  key      = "inventory-manager/pi-cluster/terraform.tfstate"
  endpoint = "https://s3.naidu72.info"
  
  # Credentials via environment variables:
  # AWS_ACCESS_KEY_ID
  # AWS_SECRET_ACCESS_KEY
}
```

### Create the Bucket in MinIO

1. **Via MinIO Console**: https://s3.naidu72.info/login
   - Login with your MinIO credentials
   - Create bucket: `terraform-state`
   - Enable versioning (recommended)

2. **Via MinIO CLI** (`mc`):
   ```bash
   mc alias set myminio https://s3.naidu72.info ACCESS_KEY SECRET_KEY
   mc mb myminio/terraform-state
   mc version enable myminio/terraform-state
   ```

---

## 🔒 Security Best Practices

### 1. Never Hardcode Secrets
❌ Don't do this:
```hcl
postgres_password = "my-password"  # WRONG!
```

✅ Do this:
```bash
export TF_VAR_postgres_password=$(vault kv get -field=password secret/...)
```

### 2. Use Vault for All Secrets
- MinIO credentials
- Database passwords
- JWT secrets
- API keys

### 3. Enable Audit Logging
Monitor secret access in Vault:
```bash
vault audit enable file file_path=/var/log/vault-audit.log
```

### 4. Use Vault Policies
Restrict access to secrets:
```hcl
# inventory-manager-policy.hcl
path "secret/data/inventory-manager/*" {
  capabilities = ["read"]
}

path "secret/data/minio/terraform" {
  capabilities = ["read"]
}
```

---

## 🎯 Phase 4 Preview

In Phase 4, we'll fully integrate Vault using **External Secrets Operator**:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: inventory-manager
spec:
  provider:
    vault:
      server: "https://vault.naidu72.info"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "inventory-manager"
```

Then secrets will automatically sync from Vault to Kubernetes!

---

## 🧪 Testing Vault Connection

```bash
# Test Vault connection
export VAULT_ADDR="https://vault.naidu72.info"
vault status

# Test secret retrieval
vault kv get secret/inventory-manager/postgres

# Test MinIO connection
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
aws s3 ls s3://terraform-state --endpoint-url https://s3.naidu72.info
```

---

## 📚 Quick Reference

### Vault Commands
```bash
# Login
vault login

# Store secret
vault kv put secret/path key=value

# Read secret
vault kv get secret/path

# Get specific field
vault kv get -field=key secret/path

# List secrets
vault kv list secret/
```

### MinIO Commands
```bash
# Configure mc client
mc alias set minio https://s3.naidu72.info ACCESS_KEY SECRET_KEY

# List buckets
mc ls minio/

# Create bucket
mc mb minio/bucket-name

# List objects
mc ls minio/terraform-state/
```

---

## 🚀 Ready to Deploy!

**With Vault:**
```bash
export VAULT_ADDR="https://vault.naidu72.info"
vault login
export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key secret/minio/terraform)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_key secret/minio/terraform)
export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres)
export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt)

cd terraform/environments/pi-cluster
terraform init
terraform apply
```

**Without Vault (Quick):**
```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export TF_VAR_postgres_password="your-password"
export TF_VAR_jwt_secret_key="your-jwt-secret"

cd terraform/environments/pi-cluster
terraform init
terraform apply
```

---

**Choose your approach and let's deploy!** 🎉
