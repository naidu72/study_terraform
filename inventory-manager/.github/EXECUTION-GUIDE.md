# Vault JWT Setup - Execution Guide

This guide walks you through setting up Vault JWT authentication for GitHub Actions **right now**.

## ⏱️ Time Required: ~10 minutes

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Vault CLI installed (`vault --version`)
- [ ] Access to Vault at `https://vault.naidu72.info`
- [ ] Vault admin credentials (for login)
- [ ] GitHub repository owner/admin access
- [ ] All secrets already in Vault (MinIO, GHCR, Postgres, JWT)

## 🚀 Step-by-Step Execution

### Step 1: Run the Automated Setup Script

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager/.github
./setup-vault-jwt.sh
```

**What it will ask:**
1. Your GitHub organization/username (e.g., `naidu72`)
2. Your repository name (e.g., `inventory-manager`)
3. Confirmation to proceed

**What it will do:**
1. ✅ Enable JWT auth method in Vault
2. ✅ Configure GitHub OIDC integration
3. ✅ Create `github-actions` policy
4. ✅ Create `github-actions` role
5. ✅ Verify configuration

**Expected output:**
```
╔════════════════════════════════════════════════════════════════╗
║     Vault JWT Authentication Setup for GitHub Actions         ║
╚════════════════════════════════════════════════════════════════╝

Enter your GitHub organization/username: naidu72
Enter your repository name: inventory-manager

Configuration:
  Organization: naidu72
  Repository: naidu72/inventory-manager
  Vault Address: https://vault.naidu72.info

Proceed with this configuration? (yes/no): yes

🔧 Step 1: Enable JWT Auth Method
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ JWT auth enabled

🔧 Step 2: Configure JWT Auth
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ JWT auth configured for GitHub Actions

🔧 Step 3: Create Vault Policy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Policy 'github-actions' created

🔧 Step 4: Create JWT Role
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Role 'github-actions' created

════════════════════════════════════════════════════════════════
✅ Vault JWT authentication setup complete!
════════════════════════════════════════════════════════════════
```

### Step 2: Verify Vault Configuration

```bash
export VAULT_ADDR="https://vault.naidu72.info"

# 1. Check JWT auth is enabled
vault auth list | grep jwt

# 2. Check JWT configuration
vault read auth/jwt/config

# 3. Check role exists
vault read auth/jwt/role/github-actions

# 4. Check policy
vault policy read github-actions
```

**Expected results:**
- JWT auth method listed
- Configuration shows GitHub issuer
- Role shows your repository restriction
- Policy grants read access to secrets

### Step 3: Verify All Required Secrets

```bash
# Check each required secret
echo "Checking MinIO credentials..."
vault kv get secret/minio/credentials

echo "Checking GHCR token..."
vault kv get secret/ghcr/credentials

echo "Checking Postgres password..."
vault kv get secret/inventory-manager/postgres

echo "Checking JWT secret..."
vault kv get secret/inventory-manager/jwt
```

**If any secret is missing:**
```bash
# Example: Add GHCR token
vault kv put secret/ghcr/credentials token="ghp_YOUR_TOKEN_HERE"

# Example: Add MinIO credentials
vault kv put secret/minio/credentials \
    access_key_id="YOUR_ACCESS_KEY" \
    secret_access_key="YOUR_SECRET_KEY"
```

### Step 4: Commit and Push Workflow Changes

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager

# Check what files changed
git status

# Add all workflow and documentation changes
git add .github/

# Commit
git commit -m "feat: Add Vault JWT/OIDC authentication for GitHub Actions

- Update all 5 workflows to use hashicorp/vault-action@v3 with JWT auth
- Add id-token: write permission to all workflows
- Remove dependency on GitHub secrets (now using Vault)
- Add comprehensive documentation for JWT setup
- Add automated setup script for Vault configuration

Benefits:
- No static secrets in GitHub
- Automatic authentication with Vault
- Short-lived tokens (10 min TTL)
- Centralized secret management
- Full audit trail"

# Push to GitHub
git push origin main
```

### Step 5: Test with Manual Workflow

```bash
# Trigger a manual deployment
gh workflow run full-stack-deploy.yml \
    -f environment=pi-cluster \
    -f force_rebuild=false

# Watch the workflow run
gh run watch
```

**What to look for in logs:**
```
✓ Import Vault Secrets
  ✓ Successfully retrieved secret from Vault
  ✓ Exported AWS_ACCESS_KEY_ID
  ✓ Exported AWS_SECRET_ACCESS_KEY
  ✓ Exported TF_VAR_ghcr_token
  ...
```

### Step 6: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n inventory-manager

# Check application is accessible
curl -I https://inventory-pi.naidu72.info/

# Check backend API
curl https://inventory-pi.naidu72.info/api/v1/health
```

## ✅ Success Criteria

You're done when:

1. ✅ Vault JWT auth is configured
2. ✅ All 5 workflows updated with JWT auth
3. ✅ All required secrets exist in Vault
4. ✅ Test workflow runs successfully
5. ✅ Workflow logs show "Successfully retrieved secret from Vault"
6. ✅ Application deploys and works

## 🎉 Congratulations!

Your GitHub Actions workflows now automatically authenticate with Vault using JWT tokens!

**What changed:**
- ❌ No more manual `vault login` in workflows
- ❌ No more GitHub secrets to manage
- ✅ Automatic authentication with OIDC
- ✅ Short-lived tokens (10 min)
- ✅ Centralized secrets in Vault
- ✅ Full audit trail

## 📚 Next Steps

1. **Monitor workflows** - Check a few runs to ensure JWT auth works
2. **Review audit logs** - Enable Vault audit logging to track access
3. **Add more repos** - Use the same Vault setup for other repositories
4. **Enhance security** - Add branch restrictions, shorter TTLs, etc.

## 🆘 If Something Goes Wrong

### Workflow fails with "permission denied"

**Fix:**
```bash
# Update policy to include the secret path
vault policy write github-actions github-actions-policy.hcl
```

### Workflow fails with "failed to fetch OIDC token"

**Fix:** Check workflow file has:
```yaml
permissions:
  id-token: write
```

### Workflow fails with "claim does not match"

**Fix:**
```bash
# Update role with correct repository
vault write auth/jwt/role/github-actions \
    bound_claims='{"repository":"naidu72/inventory-manager"}'
```

### Still stuck?

1. Check [VAULT-JWT-SETUP.md](./VAULT-JWT-SETUP.md) troubleshooting section
2. Review workflow logs for specific error messages
3. Check Vault audit logs if enabled
4. Verify all permissions in Vault role and policy

## 📖 Documentation

- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Quick commands
- **[VAULT-JWT-SETUP.md](./VAULT-JWT-SETUP.md)** - Complete guide
- **[SUMMARY.md](./SUMMARY.md)** - Overview and benefits
- **[README.md](./README.md)** - CI/CD pipeline docs

---

**Ready to start?** Run `./setup-vault-jwt.sh` now! 🚀
