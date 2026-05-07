#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Vault JWT Authentication Setup for GitHub Actions         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check Vault CLI
if ! command -v vault &> /dev/null; then
    echo -e "${RED}❌ Vault CLI not found!${NC}"
    echo "Install from: https://www.vaultproject.io/downloads"
    exit 1
fi

export VAULT_ADDR="https://vault.naidu72.info"

# Login to Vault
if ! vault token lookup &> /dev/null; then
    echo -e "${YELLOW}⚠️  Please login to Vault:${NC}"
    vault login
fi

echo ""
echo -e "${BLUE}📋 Configuration Parameters${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get repository information
read -p "Enter your GitHub organization/username: " GITHUB_ORG
read -p "Enter your repository name: " REPO_NAME

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Organization: $GITHUB_ORG"
echo "  Repository: $GITHUB_ORG/$REPO_NAME"
echo "  Vault Address: $VAULT_ADDR"

echo ""
read -p "Proceed with this configuration? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Setup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔧 Step 1: Enable JWT Auth Method${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if vault auth list | grep -q "jwt/"; then
    echo -e "${GREEN}✓ JWT auth already enabled${NC}"
else
    vault auth enable jwt
    echo -e "${GREEN}✓ JWT auth enabled${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Step 2: Configure JWT Auth${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

vault write auth/jwt/config \
    bound_issuer="https://token.actions.githubusercontent.com" \
    oidc_discovery_url="https://token.actions.githubusercontent.com"

echo -e "${GREEN}✓ JWT auth configured for GitHub Actions${NC}"

echo ""
echo -e "${BLUE}🔧 Step 3: Create Vault Policy${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /tmp/github-actions-policy.hcl <<EOF
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

# Pi cluster kubeconfig (GitHub Actions -> kubectl/terraform)
path "secret/data/homelab/pi-kubeconfig" {
  capabilities = ["read"]
}
EOF

vault policy write github-actions /tmp/github-actions-policy.hcl
rm /tmp/github-actions-policy.hcl

echo -e "${GREEN}✓ Policy 'github-actions' created${NC}"

echo ""
echo -e "${BLUE}🔧 Step 4: Create JWT Role${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Existing JWT roles (if any):"
if vault list auth/jwt/role 2>/dev/null; then
    if vault read auth/jwt/role/github-actions &>/dev/null; then
        echo -e "${YELLOW}Note: role 'github-actions' already exists — it will be overwritten.${NC}"
        vault read auth/jwt/role/github-actions
    fi
else
    echo "(none)"
fi
echo ""

# bound_claims MUST be sent as a JSON map. Inline shell strings are parsed as a
# plain string and Vault returns: expected a map, got 'string'.
BOUND_CLAIMS_FILE=$(mktemp)
printf '{"repository":"%s/%s"}\n' "$GITHUB_ORG" "$REPO_NAME" > "$BOUND_CLAIMS_FILE"

vault write auth/jwt/role/github-actions \
    role_type="jwt" \
    bound_audiences="https://github.com/$GITHUB_ORG" \
    user_claim="actor" \
    bound_claims_type="glob" \
    policies="github-actions" \
    ttl="10m" \
    bound_claims=@"$BOUND_CLAIMS_FILE"

rm -f "$BOUND_CLAIMS_FILE"

echo -e "${GREEN}✓ Role 'github-actions' created${NC}"

echo ""
echo -e "${BLUE}🔍 Step 5: Verify Configuration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "JWT Auth Config:"
vault read auth/jwt/config

echo ""
echo "JWT Role:"
vault read auth/jwt/role/github-actions

echo ""
echo "Policy:"
vault policy read github-actions

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Vault JWT authentication setup complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo ""
echo "1. Ensure all required secrets exist in Vault:"
echo "   - secret/minio/credentials (access_key_id, secret_access_key)"
echo "   - secret/ghcr/credentials (token)"
echo "   - secret/inventory-manager/postgres (password)"
echo "   - secret/inventory-manager/jwt (secret_key)"
echo ""
echo "2. Push your workflow files to GitHub"
echo ""
echo "3. Workflows will automatically authenticate with Vault!"
echo ""
echo -e "${YELLOW}⚠️  Important: Workflows must have this permission:${NC}"
echo "   permissions:"
echo "     id-token: write"
echo ""
echo -e "${BLUE}📚 For more details, see:${NC}"
echo "   .github/VAULT-JWT-SETUP.md"
