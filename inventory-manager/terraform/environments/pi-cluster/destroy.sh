#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     ⚠️  TERRAFORM DESTROY - REMOVE ALL RESOURCES ⚠️           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if Vault is available
if ! command -v vault &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vault CLI not found. Will use manual entry.${NC}"
    VAULT_AVAILABLE=false
else
    VAULT_AVAILABLE=true
fi

# Fetch secrets from Vault
if [ "$VAULT_AVAILABLE" == true ]; then
    export VAULT_ADDR="https://vault.naidu72.info"
    echo -e "${BLUE}🔑 Fetching secrets from Vault...${NC}"
    
    if ! vault token lookup &> /dev/null; then
        echo -e "${YELLOW}⚠️  Please login to Vault:${NC}"
        vault login
    fi
    
    # MinIO credentials for Terraform backend
    export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key_id secret/minio/credentials)
    export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_access_key secret/minio/credentials)
    
    echo -e "${GREEN}✓ Fetching GHCR credentials...${NC}"
    export TF_VAR_ghcr_username="naidu72"
    export TF_VAR_ghcr_token=$(vault kv get -field=token secret/ghcr/credentials 2>/dev/null || echo "")
    
    echo -e "${GREEN}✓ Fetching PostgreSQL password...${NC}"
    export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres 2>/dev/null || echo "")
    
    echo -e "${GREEN}✓ Fetching JWT secret...${NC}"
    export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt 2>/dev/null || echo "")
else
    echo -e "${YELLOW}⚠️  Please set environment variables manually${NC}"
fi

echo ""
echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}⚠️  WARNING: This will DESTROY all resources in pi-k8s cluster!${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Resources to be destroyed:"
echo "  - Frontend Deployment & Service & Ingress"
echo "  - Backend Deployment & Service & Ingress"
echo "  - PostgreSQL StatefulSet & PVC"
echo "  - Redis Deployment & PVC"
echo "  - Namespace: inventory-manager"
echo "  - All secrets and configmaps"
echo ""
echo -e "${BLUE}📝 State in MinIO:${NC} s3://terraform-state/inventory-manager/pi-cluster/terraform.tfstate"
echo -e "${YELLOW}(State will be preserved in MinIO)${NC}"
echo ""
echo -e "${YELLOW}This action cannot be undone!${NC}"
echo ""
read -p "Are you sure you want to destroy? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${GREEN}Destroy cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}🗑️  Starting destroy...${NC}"
echo ""

# Run terraform destroy
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Destroy completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "All resources have been removed from the cluster."
    echo ""
    echo -e "${BLUE}📝 State still preserved in MinIO:${NC}"
    echo "   s3://terraform-state/inventory-manager/pi-cluster/terraform.tfstate"
else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}❌ Destroy failed!${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
