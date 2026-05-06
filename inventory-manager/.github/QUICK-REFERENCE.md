# Vault JWT Quick Reference

## 🚀 Quick Setup

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager/.github
./setup-vault-jwt.sh
```

## 🔐 Vault Commands

### Check Configuration
```bash
export VAULT_ADDR="https://vault.naidu72.info"

# List auth methods
vault auth list

# Check JWT config
vault read auth/jwt/config

# Check role
vault read auth/jwt/role/github-actions

# Check policy
vault policy read github-actions
```

### Verify Secrets
```bash
# List all secrets
vault kv list secret/

# Check specific secrets
vault kv get secret/minio/credentials
vault kv get secret/ghcr/credentials
vault kv get secret/inventory-manager/postgres
vault kv get secret/inventory-manager/jwt
```

## 📋 Workflow Syntax

### Minimal Setup
```yaml
permissions:
  id-token: write

steps:
  - uses: hashicorp/vault-action@v3
    with:
      url: https://vault.naidu72.info
      method: jwt
      role: github-actions
      secrets: |
        secret/data/minio/credentials access_key_id | AWS_ACCESS_KEY_ID
```

### Multiple Secrets
```yaml
- uses: hashicorp/vault-action@v3
  with:
    url: https://vault.naidu72.info
    method: jwt
    role: github-actions
    secrets: |
      secret/data/minio/credentials access_key_id | AWS_ACCESS_KEY_ID ;
      secret/data/minio/credentials secret_access_key | AWS_SECRET_ACCESS_KEY ;
      secret/data/ghcr/credentials token | GHCR_TOKEN
```

**Note**: Use `;` to separate multiple secrets

## 🧪 Testing

### Test Workflow
```bash
gh workflow run full-stack-deploy.yml \
    -f environment=pi-cluster \
    -f force_rebuild=false
```

### Watch Workflow
```bash
gh run watch
```

### Check Logs
Look for: `✓ Successfully retrieved secret from Vault`

## 🐛 Troubleshooting

### Error: "permission denied"
```bash
# Update policy to include secret path
vault policy write github-actions github-actions-policy.hcl
```

### Error: "failed to fetch OIDC token"
```yaml
# Add to workflow
permissions:
  id-token: write
```

### Error: "expected a map, got 'string'" (bound_claims)

Vault needs `bound_claims` as a JSON **object**, not a quoted CLI string. Use a file:

```bash
echo '{"repository":"YOUR_ORG/YOUR_REPO"}' > /tmp/bc.json
vault write auth/jwt/role/github-actions ... bound_claims=@/tmp/bc.json
```

### Error: "bound audience not satisfied"
```bash
# Update audience to match your org
vault write auth/jwt/role/github-actions \
    bound_audiences="https://github.com/YOUR_ORG"
```

## 📊 Workflow Files

All workflows updated with JWT auth:
- ✅ `backend-ci-cd.yml`
- ✅ `frontend-ci-cd.yml`
- ✅ `full-stack-deploy.yml`
- ✅ `terraform-plan.yml`
- ✅ `destroy-infrastructure.yml`

## 🔑 Required Secrets in Vault

| Path | Field | Used For |
|------|-------|----------|
| `secret/minio/credentials` | `access_key_id` | Terraform backend |
| `secret/minio/credentials` | `secret_access_key` | Terraform backend |
| `secret/ghcr/credentials` | `token` | Docker registry |
| `secret/inventory-manager/postgres` | `password` | Database |
| `secret/inventory-manager/jwt` | `secret_key` | API auth |

## 📝 Policy Template

```hcl
# MinIO credentials
path "secret/data/minio/credentials" {
  capabilities = ["read"]
}

# GHCR credentials
path "secret/data/ghcr/credentials" {
  capabilities = ["read"]
}

# Application secrets
path "secret/data/inventory-manager/*" {
  capabilities = ["read"]
}
```

## 🔧 Role Configuration

Use a JSON file for `bound_claims` (inline quotes often trigger `expected a map, got 'string'`):

```bash
echo '{"repository":"YOUR_ORG/YOUR_REPO"}' > /tmp/bound-claims.json
vault write auth/jwt/role/github-actions \
    role_type="jwt" \
    bound_audiences="https://github.com/YOUR_ORG" \
    user_claim="actor" \
    bound_claims_type="glob" \
    policies="github-actions" \
    ttl="10m" \
    bound_claims=@/tmp/bound-claims.json
rm -f /tmp/bound-claims.json
```

## 📚 Documentation

- **Setup Guide**: [VAULT-JWT-SETUP.md](./VAULT-JWT-SETUP.md)
- **Migration**: [VAULT-JWT-MIGRATION.md](./VAULT-JWT-MIGRATION.md)
- **Summary**: [SUMMARY.md](./SUMMARY.md)
- **CI/CD**: [README.md](./README.md)

## ✅ Verification Checklist

- [ ] JWT auth enabled in Vault
- [ ] Policy created
- [ ] Role created
- [ ] All secrets exist
- [ ] Workflows have `id-token: write`
- [ ] Test workflow succeeds

## 🎯 Benefits

- ✅ No GitHub secrets to manage
- ✅ Automatic authentication
- ✅ Short-lived tokens (10 min)
- ✅ Centralized in Vault
- ✅ Fully auditable
- ✅ Repository-scoped
