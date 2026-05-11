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
echo "║     Migrate Terraform State to MinIO Backend                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

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

echo -e "${BLUE}🔑 Fetching MinIO credentials from Vault...${NC}"
export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key_id secret/minio/credentials)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_access_key secret/minio/credentials)

echo -e "${GREEN}✓ MinIO credentials fetched${NC}"
echo ""

# Fetch other secrets needed for Terraform
echo -e "${BLUE}🔑 Fetching application secrets from Vault...${NC}"
export TF_VAR_ghcr_username="naidu72"
export TF_VAR_ghcr_token=$(vault kv get -field=token secret/ghcr/credentials)
export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres)
export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt)

echo -e "${GREEN}✓ All secrets fetched${NC}"
echo ""

echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}This will migrate your local state to MinIO remote backend${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Current state location: Local (terraform.tfstate)"
echo "Target state location:  MinIO S3 (s3.naidu72.info/terraform-state/inventory-manager/pi-cluster/)"
echo ""

read -p "Proceed with migration? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${GREEN}Migration cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 Initializing Terraform with new backend...${NC}"
echo ""

# Run terraform init to migrate state
terraform init -migrate-state

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ State migration completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "State is now stored in MinIO at:"
    echo "  Bucket: terraform-state"
    echo "  Key: inventory-manager/pi-cluster/terraform.tfstate"
    echo ""
    echo "You can now safely delete the local terraform.tfstate file"
else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}❌ State migration failed!${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
