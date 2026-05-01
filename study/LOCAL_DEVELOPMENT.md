# Local Development Guide

## Problem

Your `backend.tf` is configured to use MinIO (S3-compatible) with credentials that don't work with real AWS:

```hcl
backend "s3" {
  bucket   = "tf-state"
  endpoint = "http://localhost:9000"
  access_key = "admin"
  secret_key = "password"
  ...
}
```

This causes errors when running `terraform init` locally.

## Solutions

### Option 1: Use Local Backend (Recommended for Development)

**Quick Start:**
```bash
./use-local-backend.sh
terraform init -migrate-state
```

This switches to a local backend that stores state in `terraform.tfstate` file.

**Advantages:**
- ✅ No MinIO dependency
- ✅ Simple and fast
- ✅ Works immediately
- ✅ Same as CI/CD pipeline

**Disadvantages:**
- ⚠️ State stored locally (not shared)
- ⚠️ No remote backup

---

### Option 2: Use MinIO (S3-Compatible Storage)

If you want to use MinIO for local development:

**Step 1: Start MinIO**
```bash
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  --name minio \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=password \
  -v ~/minio-data:/data \
  quay.io/minio/minio server /data --console-address ":9001"
```

**Step 2: Create Bucket**
1. Open MinIO Console: http://localhost:9001
2. Login: admin / password
3. Create bucket: `tf-state`

**Step 3: Fix Backend Configuration**

Update `backend.tf` to use the new `endpoints` parameter:

```hcl
terraform {
  backend "s3" {
    bucket                      = "tf-state"
    key                         = "phase1-project/terraform.tfstate"
    region                      = "us-east-1"
    
    # NEW: Use endpoints instead of endpoint
    endpoints = {
      s3 = "http://localhost:9000"
    }
    
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
    
    access_key = "admin"
    secret_key = "password"
  }
}
```

**Step 4: Initialize**
```bash
terraform init -migrate-state
```

**Advantages:**
- ✅ S3-compatible remote state
- ✅ Closer to production setup
- ✅ State can be shared (if MinIO accessible)

**Disadvantages:**
- ⚠️ Requires MinIO running
- ⚠️ More complex setup

---

### Option 3: Use Terraform Cloud (Best for Teams)

**Step 1: Create Terraform Cloud Account**
1. Go to https://app.terraform.io
2. Create free account
3. Create organization and workspace

**Step 2: Update Backend**
```hcl
terraform {
  backend "remote" {
    organization = "your-org-name"
    
    workspaces {
      name = "study-terraform"
    }
  }
}
```

**Step 3: Login and Initialize**
```bash
terraform login
terraform init -migrate-state
```

**Advantages:**
- ✅ Free for small teams
- ✅ Remote state with locking
- ✅ State versioning and rollback
- ✅ Secure credential storage
- ✅ Works from anywhere

**Disadvantages:**
- ⚠️ Requires internet connection
- ⚠️ External dependency

---

## Quick Commands

### Switch to Local Backend
```bash
./use-local-backend.sh
terraform init -migrate-state
```

### Switch to S3 Backend
```bash
./use-s3-backend.sh
terraform init -migrate-state
```

### Check Current Backend
```bash
terraform show
# or
cat backend.tf
```

### List Workspaces
```bash
terraform workspace list
```

### Select Workspace
```bash
terraform workspace select wsl
# or
terraform workspace select pi
```

---

## Recommended Setup

**For Local Development:**
```bash
# Use local backend
./use-local-backend.sh
terraform init -migrate-state

# Select workspace
terraform workspace select wsl

# Work normally
terraform plan
terraform apply
```

**For CI/CD:**
- The GitHub Actions workflow automatically uses local backend
- Each workspace gets its own state file
- State files are uploaded as artifacts

---

## Troubleshooting

### Error: AWS account ID not found
**Cause:** Using S3 backend with invalid AWS credentials

**Fix:** Switch to local backend:
```bash
./use-local-backend.sh
terraform init -migrate-state
```

### Error: Backend configuration changed
**Cause:** Switching between backends

**Fix:** Use `-migrate-state` flag:
```bash
terraform init -migrate-state
```

### Error: Failed to read variables file
**Cause:** Missing .tfvars files (they're in .gitignore)

**Fix:** Don't use -var-file flag. The workspace name automatically determines docker_host via locals.tf:
```bash
# Don't do this:
terraform plan -var-file="wsl.tfvars"

# Do this instead:
terraform workspace select wsl
terraform plan
```

---

## State Management

### Where is State Stored?

**Local Backend:**
- File: `terraform.tfstate`
- Workspace states: `terraform.tfstate.d/{workspace}/terraform.tfstate`

**S3 Backend (MinIO):**
- Bucket: `tf-state`
- Key: `phase1-project/terraform.tfstate`

**CI/CD:**
- Temporary local files during workflow
- Uploaded as GitHub Actions artifacts
- Separate state per workspace

### Backup State
```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Or for workspace state
cp terraform.tfstate.d/wsl/terraform.tfstate terraform.tfstate.d/wsl/terraform.tfstate.backup
```

---

## Summary

**Recommended for most users:**
1. Use local backend for development: `./use-local-backend.sh`
2. Let CI/CD handle deployments (already configured)
3. State is managed automatically

**For advanced users:**
- Use MinIO if you need S3-compatible storage
- Use Terraform Cloud for team collaboration
