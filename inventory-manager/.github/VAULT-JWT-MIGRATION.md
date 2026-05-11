# Vault JWT Authentication Migration Summary

## 🎯 What Changed

All GitHub Actions workflows have been updated to use **Vault JWT/OIDC authentication** instead of requiring GitHub secrets or manual Vault login.

## ✅ Updated Files

### Workflows
All 5 workflows now use JWT auth:

1. **`.github/workflows/backend-ci-cd.yml`**
   - Added `permissions: { id-token: write }`
   - Uses `hashicorp/vault-action@v3` with JWT method
   - Automatically fetches all secrets from Vault

2. **`.github/workflows/frontend-ci-cd.yml`**
   - Added `permissions: { id-token: write }`
   - Uses `hashicorp/vault-action@v3` with JWT method
   - Automatically fetches all secrets from Vault

3. **`.github/workflows/full-stack-deploy.yml`**
   - Added `permissions: { id-token: write }`
   - Uses `hashicorp/vault-action@v3` with JWT method
   - Fetches secrets for both backend and frontend builds

4. **`.github/workflows/terraform-plan.yml`**
   - Added `permissions: { id-token: write, pull-requests: write }`
   - Uses `hashicorp/vault-action@v3` with JWT method
   - Fetches secrets for Terraform operations

5. **`.github/workflows/destroy-infrastructure.yml`**
   - Added `permissions: { id-token: write }`
   - Uses `hashicorp/vault-action@v3` with JWT method
   - Fetches secrets for Terraform destroy

### Documentation

1. **`.github/VAULT-JWT-SETUP.md`** (NEW)
   - Complete guide for setting up Vault JWT auth
   - Step-by-step Vault configuration
   - Troubleshooting guide
   - Security best practices

2. **`.github/README.md`** (UPDATED)
   - Replaced "Required GitHub Secrets" section
   - Now documents Vault JWT as primary method
   - Added Vault troubleshooting steps
   - Links to JWT setup guide

### Scripts

1. **`.github/setup-vault-jwt.sh`** (NEW)
   - Automated Vault configuration script
   - Interactive setup for JWT auth
   - Creates policies and roles
   - Verifies configuration

## 🔐 Secrets Flow (Before vs After)

### Before (Manual/GitHub Secrets)
```
┌─────────────────────┐
│  GitHub Workflow    │
│                     │
│  Needs:             │
│  • Manual vault     │
│    login OR         │
│  • GitHub secrets   │
│                     │
│  ❌ Static secrets  │
│  ❌ Manual rotation │
│  ❌ Multiple copies │
└─────────────────────┘
```

### After (Vault JWT)
```
┌─────────────────────┐      ┌─────────────────────┐
│  GitHub Workflow    │      │  HashiCorp Vault    │
│                     │      │                     │
│  1. Get OIDC token  │─────>│  2. Validate JWT    │
│     from GitHub     │      │     (auto)          │
│                     │      │                     │
│  4. Use secrets     │<─────│  3. Return secrets  │
│     in workflow     │      │     (short-lived)   │
│                     │      │                     │
│  ✅ No static creds │      │  ✅ Centralized     │
│  ✅ Auto auth       │      │  ✅ Auditable       │
│  ✅ Short-lived     │      │  ✅ Secure          │
└─────────────────────┘      └─────────────────────┘
```

## 📋 Vault Configuration Required

Run this script to configure Vault:

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager/.github
./setup-vault-jwt.sh
```

The script will:
1. Enable JWT auth method
2. Configure GitHub OIDC
3. Create `github-actions` policy
4. Create `github-actions` role
5. Verify configuration

## 🔑 Secrets in Vault

Ensure these secrets exist in Vault before running workflows:

```bash
# MinIO credentials
vault kv put secret/minio/credentials \
    access_key_id="..." \
    secret_access_key="..."

# GHCR token
vault kv put secret/ghcr/credentials \
    token="ghp_..."

# PostgreSQL password
vault kv put secret/inventory-manager/postgres \
    password="..."

# JWT secret
vault kv put secret/inventory-manager/jwt \
    secret_key="..."
```

## 🚀 Testing the Setup

### 1. Manual Workflow Test

Trigger a manual workflow to test JWT auth:

```bash
gh workflow run full-stack-deploy.yml \
    -f environment=pi-cluster \
    -f force_rebuild=false
```

### 2. Check Workflow Logs

Look for:
```
✓ Successfully retrieved secret from Vault
```

### 3. Verify Vault Audit Logs

```bash
# On Vault server
vault audit enable file file_path=/var/log/vault-audit.log

# Check for GitHub Actions authentication
tail -f /var/log/vault-audit.log | grep github-actions
```

## 📊 Benefits

| Aspect | Before | After |
|--------|--------|-------|
| **Secret Storage** | GitHub (per repo) | Vault (centralized) |
| **Authentication** | Static tokens | Dynamic JWT tokens |
| **Credential Lifetime** | Indefinite | 10 minutes |
| **Setup Complexity** | Manual per repo | One-time Vault config |
| **Audit Trail** | GitHub audit log only | GitHub + Vault audit logs |
| **Rotation** | Manual | Automatic (token-based) |
| **Multi-repo** | Duplicate secrets | Shared Vault instance |

## 🔍 Verification Checklist

After setup, verify:

- [ ] Vault JWT auth enabled (`vault auth list`)
- [ ] JWT configured for GitHub (`vault read auth/jwt/config`)
- [ ] Policy created (`vault policy read github-actions`)
- [ ] Role created (`vault read auth/jwt/role/github-actions`)
- [ ] All secrets exist in Vault (`vault kv list secret/`)
- [ ] Workflows have `id-token: write` permission
- [ ] Test workflow completes successfully
- [ ] Application deploys and works

## 🎓 Learn More

- **Setup Guide**: `.github/VAULT-JWT-SETUP.md`
- **CI/CD Docs**: `.github/README.md`
- **Vault Docs**: [JWT Auth](https://developer.hashicorp.com/vault/docs/auth/jwt)
- **GitHub Docs**: [OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

## 🆘 Troubleshooting

### Workflow fails with "permission denied"

**Fix**: Update Vault policy to include the secret path.

### Workflow fails with "failed to fetch OIDC token"

**Fix**: Add `permissions: { id-token: write }` to workflow.

### Workflow fails with "claim does not match"

**Fix**: Update JWT role with correct repository name:
```bash
vault write auth/jwt/role/github-actions \
    bound_claims="{\"repository\":\"YOUR_ORG/YOUR_REPO\"}"
```

## ✨ Next Steps

1. **Run Setup Script**: `./setup-vault-jwt.sh`
2. **Verify Secrets**: Check all secrets exist in Vault
3. **Test Workflow**: Run a manual workflow
4. **Monitor**: Check workflow logs for successful auth
5. **Deploy**: Push to main to trigger automated deployment

---

**Migration Date**: May 6, 2026  
**Status**: ✅ Complete - All workflows updated for JWT authentication
