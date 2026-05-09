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
echo "║     Inventory Manager - Terraform Deploy (MinIO Backend)      ║"
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

echo -e "${BLUE}🔑 Fetching secrets from Vault...${NC}"

# MinIO credentials for Terraform backend
export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key_id secret/minio/credentials)
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_access_key secret/minio/credentials)

# Application secrets
export TF_VAR_ghcr_username="naidu72"
export TF_VAR_ghcr_token=$(vault kv get -field=token secret/ghcr/credentials)
export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres)
export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt)

echo -e "${GREEN}✓ All secrets fetched successfully${NC}"
echo ""

# Initialize Terraform if needed
if [ ! -d ".terraform" ] || [ ! -f ".terraform/terraform.tfstate" ]; then
    echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
    terraform init
    echo ""
fi

# Run Terraform plan
echo -e "${BLUE}📋 Running Terraform plan...${NC}"
echo ""
terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Review the plan above. Ready to apply?${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
echo ""

read -p "Apply the plan? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    rm -f tfplan
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 Applying Terraform configuration...${NC}"
echo ""

# Apply Terraform
terraform apply tfplan

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Application Details:${NC}"
    terraform output -json | jq -r '
        if .application_info.value then
            "Namespace: " + .application_info.value.namespace,
            "Frontend: " + .application_info.value.frontend_image + " (" + (.application_info.value.frontend_replicas | tostring) + " replicas)",
            "Backend: " + .application_info.value.backend_image + " (" + (.application_info.value.backend_replicas | tostring) + " replicas)"
        else
            "No application info available"
        end
    '
    echo ""
    echo -e "${BLUE}📝 State stored in MinIO:${NC} s3://terraform-state/inventory-manager/pi-cluster/terraform.tfstate"
    echo ""
    echo -e "${BLUE}🌐 Access the application:${NC}"
    echo "   Frontend: https://inventory-pi.naidu72.info"
    echo ""
else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}❌ Deployment failed!${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
