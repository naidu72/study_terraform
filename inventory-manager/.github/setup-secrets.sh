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
echo "║         GitHub Secrets Setup Helper                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed!${NC}"
    echo "Install it with: sudo apt install gh"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to GitHub${NC}"
    echo "Please login first:"
    gh auth login
    exit 1
fi

# Check if Vault is available
if ! command -v vault &> /dev/null; then
    echo -e "${RED}❌ Vault CLI not found!${NC}"
    exit 1
fi

export VAULT_ADDR="https://vault.naidu72.info"

# Login to Vault if needed
if ! vault token lookup &> /dev/null; then
    echo -e "${YELLOW}⚠️  Please login to Vault:${NC}"
    vault login
fi

echo -e "${BLUE}🔑 Fetching secrets from Vault...${NC}"
echo ""

# Fetch secrets
MINIO_ACCESS_KEY=$(vault kv get -field=access_key_id secret/minio/credentials)
MINIO_SECRET_KEY=$(vault kv get -field=secret_access_key secret/minio/credentials)
GHCR_USERNAME="naidu72"
GHCR_TOKEN=$(vault kv get -field=token secret/ghcr/credentials)
POSTGRES_PASSWORD=$(vault kv get -field=password secret/inventory-manager/postgres)
JWT_SECRET_KEY=$(vault kv get -field=secret_key secret/inventory-manager/jwt)

echo -e "${GREEN}✓ All secrets fetched from Vault${NC}"
echo ""

# Get repository
REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')

if [ -z "$REPO" ]; then
    echo -e "${RED}❌ Could not determine GitHub repository${NC}"
    echo "Please ensure you're in a Git repository with GitHub remote"
    exit 1
fi

echo -e "${BLUE}📦 Repository: ${REPO}${NC}"
echo ""

echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}The following secrets will be set in GitHub:${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  1. MINIO_ACCESS_KEY"
echo "  2. MINIO_SECRET_KEY"
echo "  3. GHCR_USERNAME"
echo "  4. GHCR_TOKEN"
echo "  5. POSTGRES_PASSWORD"
echo "  6. JWT_SECRET_KEY"
echo ""

read -p "Continue with setting secrets? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 Setting GitHub secrets...${NC}"
echo ""

# Set secrets
echo "Setting MINIO_ACCESS_KEY..."
echo "$MINIO_ACCESS_KEY" | gh secret set MINIO_ACCESS_KEY -R "$REPO"

echo "Setting MINIO_SECRET_KEY..."
echo "$MINIO_SECRET_KEY" | gh secret set MINIO_SECRET_KEY -R "$REPO"

echo "Setting GHCR_USERNAME..."
echo "$GHCR_USERNAME" | gh secret set GHCR_USERNAME -R "$REPO"

echo "Setting GHCR_TOKEN..."
echo "$GHCR_TOKEN" | gh secret set GHCR_TOKEN -R "$REPO"

echo "Setting POSTGRES_PASSWORD..."
echo "$POSTGRES_PASSWORD" | gh secret set POSTGRES_PASSWORD -R "$REPO"

echo "Setting JWT_SECRET_KEY..."
echo "$JWT_SECRET_KEY" | gh secret set JWT_SECRET_KEY -R "$REPO"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All secrets set successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# List secrets
echo -e "${BLUE}📋 Verifying secrets...${NC}"
gh secret list -R "$REPO"

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Commit and push your workflow files"
echo "  2. Go to GitHub Actions tab to see workflows"
echo "  3. Push code changes to trigger automatic deployment"
echo "  4. Or manually trigger 'Full Stack Deploy' workflow"
echo ""
