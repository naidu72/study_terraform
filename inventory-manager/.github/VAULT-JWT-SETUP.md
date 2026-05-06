# Vault JWT/OIDC Authentication Setup for GitHub Actions

This guide explains how to configure HashiCorp Vault to authenticate GitHub Actions workflows using JWT/OIDC tokens.

## 🔐 Overview

GitHub Actions can authenticate with Vault using OIDC tokens instead of requiring manual login or static tokens. This provides:

- **No secrets to manage** - GitHub generates tokens automatically
- **Short-lived credentials** - Tokens expire quickly
- **Auditable** - All access is logged with repository/workflow context
- **Secure** - Tokens are bound to specific repositories and branches

## 📋 Prerequisites

1. Vault server accessible at `https://vault.naidu72.info`
2. Vault admin access to configure JWT auth
3. GitHub repository with Actions enabled

## 🚀 Setup Steps

### Step 1: Enable JWT Auth Method in Vault

```bash
export VAULT_ADDR="https://vault.naidu72.info"
vault login

# Enable JWT auth method
vault auth enable jwt

# Configure JWT auth to use GitHub's OIDC
vault write auth/jwt/config \
    bound_issuer="https://token.actions.githubusercontent.com" \
    oidc_discovery_url="https://token.actions.githubusercontent.com"
```

### Step 2: Create Vault Policy

Create a policy that grants access to the secrets your workflows need:

```bash
# Create policy file
cat > github-actions-policy.hcl <<EOF
# MinIO credentials for Terraform backend
path "secret/data/minio/credentials" {
  capabilities = ["read"]
}

# GHCR credentials for Docker registry
path "secret/data/ghcr/credentials" {
  capabilities = ["read"]
}

# Application secrets
path "secret/data/inventory-manager/*" {
  capabilities = ["read"]
}
EOF

# Apply the policy
vault policy write github-actions github-actions-policy.hcl
```

### Step 3: Create JWT Role for GitHub Actions

Configure a role that maps GitHub OIDC tokens to Vault policies.

**Check whether the role already exists:**

```bash
vault list auth/jwt/role
vault read auth/jwt/role/github-actions   # omit key if role missing
```

Re-running `vault write` with the same role name **overwrites** the role.

**Important:** `bound_claims` must be a JSON **object** (map). Passing it inline on the CLI often sends a **string**, which fails with: `expected a map, got 'string'`. Use a small JSON file and `bound_claims=@path`:

```bash
# Replace YOUR_GITHUB_ORG / YOUR_REPO_NAME with your repo (e.g. naidu72/inventory-manager)
cat > /tmp/bound-claims.json <<'EOF'
{"repository":"YOUR_GITHUB_ORG/YOUR_REPO_NAME"}
EOF

vault write auth/jwt/role/github-actions \
    role_type="jwt" \
    bound_audiences="https://github.com/YOUR_GITHUB_ORG" \
    user_claim="actor" \
    bound_claims_type="glob" \
    policies="github-actions" \
    ttl="10m" \
    bound_claims=@/tmp/bound-claims.json

rm -f /tmp/bound-claims.json
```

**Parameters explained:**
- `role_type="jwt"` - Use JWT tokens (not OIDC login)
- `bound_audiences` - Restricts to your GitHub organization
- `user_claim="actor"` - Uses GitHub actor as the Vault user
- `bound_claims` - Restricts to specific repository
- `policies` - Assigns the github-actions policy
- `ttl="10m"` - Token valid for 10 minutes

### Step 4: Test Authentication

Test the setup manually:

```bash
# Get a GitHub OIDC token (from a workflow run)
# This is automatically available as $ACTIONS_ID_TOKEN_REQUEST_TOKEN in workflows

# Test authentication
vault write auth/jwt/login \
    role=github-actions \
    jwt="<GITHUB_OIDC_TOKEN>"
```

## 🔧 Workflow Configuration

### Required Permissions

Add this to your workflow files:

```yaml
permissions:
  contents: read
  id-token: write  # Required for OIDC token
```

### Using Vault Action

```yaml
- name: Import Vault Secrets
  uses: hashicorp/vault-action@v3
  with:
    url: https://vault.naidu72.info
    method: jwt
    role: github-actions
    secrets: |
      secret/data/minio/credentials access_key_id | AWS_ACCESS_KEY_ID ;
      secret/data/minio/credentials secret_access_key | AWS_SECRET_ACCESS_KEY ;
      secret/data/ghcr/credentials token | GHCR_TOKEN
```

**Syntax:**
- `secret/data/` - KV v2 path prefix (required)
- `access_key_id` - Field name in the secret
- `AWS_ACCESS_KEY_ID` - Environment variable name
- `;` - Separator between multiple secrets

## 📝 Complete Example

Here's a complete workflow example:

```yaml
name: Deploy with Vault JWT

on:
  push:
    branches: [ main ]

env:
  VAULT_ADDR: https://vault.naidu72.info

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    runs-on: [self-hosted, pi5]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Import Vault Secrets
        uses: hashicorp/vault-action@v3
        with:
          url: ${{ env.VAULT_ADDR }}
          method: jwt
          role: github-actions
          secrets: |
            secret/data/minio/credentials access_key_id | AWS_ACCESS_KEY_ID ;
            secret/data/minio/credentials secret_access_key | AWS_SECRET_ACCESS_KEY
      
      - name: Use secrets
        run: |
          echo "Secrets loaded successfully"
          # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are now available
```

## 🔍 Verification

### Check JWT Auth Configuration

```bash
# List JWT roles
vault list auth/jwt/role

# Read role configuration
vault read auth/jwt/role/github-actions

# Check policy
vault policy read github-actions
```

### Test from Workflow

1. Push a commit to trigger the workflow
2. Check workflow logs for "Import Vault Secrets" step
3. Should see: "Successfully retrieved secret from Vault"

## 🐛 Troubleshooting

### Error: "permission denied"

**Cause:** Policy doesn't grant access to the secret path

**Fix:** Update the policy to include the secret path:
```bash
vault policy write github-actions github-actions-policy.hcl
```

### Error: "failed to fetch OIDC token"

**Cause:** Missing `id-token: write` permission

**Fix:** Add to workflow:
```yaml
permissions:
  id-token: write
```

### Error: "expected a map, got 'string'" (bound_claims)

**Cause:** The Vault CLI treated `bound_claims` as a literal string instead of a JSON object.

**Fix:** Pass claims from a file:

```bash
echo '{"repository":"YOUR_ORG/YOUR_REPO"}' > /tmp/bound-claims.json
vault write auth/jwt/role/github-actions \
    role_type=jwt \
    bound_audiences="https://github.com/YOUR_ORG" \
    user_claim=actor \
    bound_claims_type=glob \
    policies=github-actions \
    ttl=10m \
    bound_claims=@/tmp/bound-claims.json
rm -f /tmp/bound-claims.json
```

Or use the updated `setup-vault-jwt.sh`, which writes `bound_claims` from a temp JSON file.

### Error: "claim does not match"

**Cause:** Repository name mismatch in role configuration

**Fix:** Update `bound_claims` with the correct `owner/repo` (use a JSON file as above):

```bash
echo '{"repository":"YOUR_GITHUB_ORG/YOUR_REPO_NAME"}' > /tmp/bound-claims.json
vault write auth/jwt/role/github-actions \
    bound_claims=@/tmp/bound-claims.json
rm -f /tmp/bound-claims.json
```

(Re-include other role fields if you are replacing the whole role; simplest is to re-run the full `vault write` from Step 3 with all fields.)

### Error: "bound audience not satisfied"

**Cause:** Audience mismatch

**Fix:** Ensure `bound_audiences` matches your GitHub organization:
```bash
vault write auth/jwt/role/github-actions \
    bound_audiences="https://github.com/YOUR_GITHUB_ORG"
```

## 🔐 Security Best Practices

1. **Principle of Least Privilege**
   - Only grant read access to specific secrets
   - Don't use wildcard paths unless necessary

2. **Repository Restrictions**
   - Use `bound_claims` to restrict to specific repos
   - Don't allow all repositories in your org

3. **Branch Protection**
   - Add branch claims for production deployments:
   ```bash
   bound_claims='{"repository":"org/repo","ref":"refs/heads/main"}'
   ```

4. **Short TTLs**
   - Use short token lifetimes (5-15 minutes)
   - Workflows should complete within TTL

5. **Audit Logging**
   - Enable Vault audit logging
   - Review access logs regularly

## 📊 Advanced Configuration

### Multiple Environments

Create separate roles for different environments:

```bash
# Production role - restricted to main branch
vault write auth/jwt/role/github-actions-prod \
    role_type="jwt" \
    bound_audiences="https://github.com/YOUR_GITHUB_ORG" \
    user_claim="actor" \
    bound_claims='{"repository":"org/repo","ref":"refs/heads/main"}' \
    policies="github-actions-prod" \
    ttl="5m"

# Staging role - allows develop branch
vault write auth/jwt/role/github-actions-staging \
    role_type="jwt" \
    bound_audiences="https://github.com/YOUR_GITHUB_ORG" \
    user_claim="actor" \
    bound_claims='{"repository":"org/repo","ref":"refs/heads/develop"}' \
    policies="github-actions-staging" \
    ttl="10m"
```

### Dynamic Secrets

Use Vault's dynamic secrets for even better security:

```hcl
# Database policy with dynamic credentials
path "database/creds/readonly" {
  capabilities = ["read"]
}
```

## 📚 Additional Resources

- [Vault JWT Auth Documentation](https://developer.hashicorp.com/vault/docs/auth/jwt)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Vault Action GitHub](https://github.com/hashicorp/vault-action)

## ✅ Summary

After completing this setup:
- ✅ No GitHub secrets needed (except GITHUB_TOKEN)
- ✅ Workflows authenticate automatically with Vault
- ✅ Short-lived credentials for better security
- ✅ Auditable access to secrets
- ✅ Repository and branch restrictions enforced

The workflows in this repository are already configured to use JWT auth!
