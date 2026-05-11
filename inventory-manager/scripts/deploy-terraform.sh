#!/bin/bash

# Phase 3 - Terraform Deployment Script
# Deploys Inventory Manager to Kubernetes using Terraform

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TF_DIR="$PROJECT_ROOT/terraform/environments/pi-cluster"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Phase 3 - Terraform Deployment${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform not found${NC}"
    echo "Install: https://www.terraform.io/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed: $(terraform version -json | jq -r '.terraform_version')${NC}"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl installed${NC}"

# Check environment variables
if [ -z "$TF_VAR_postgres_password" ]; then
    echo -e "${YELLOW}⚠ TF_VAR_postgres_password not set${NC}"
    read -sp "Enter PostgreSQL password: " POSTGRES_PASS
    echo ""
    export TF_VAR_postgres_password="$POSTGRES_PASS"
fi

if [ -z "$TF_VAR_jwt_secret_key" ]; then
    echo -e "${YELLOW}⚠ TF_VAR_jwt_secret_key not set${NC}"
    read -sp "Enter JWT secret key: " JWT_SECRET
    echo ""
    export TF_VAR_jwt_secret_key="$JWT_SECRET"
fi

echo -e "${GREEN}✓ Environment variables set${NC}"
echo ""

# Change to Terraform directory
cd "$TF_DIR"

# Initialize Terraform
echo -e "${BLUE}Step 1: Initializing Terraform...${NC}"
terraform init

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Terraform initialized${NC}"
else
    echo -e "${RED}✗ Terraform initialization failed${NC}"
    exit 1
fi

echo ""

# Validate configuration
echo -e "${BLUE}Step 2: Validating configuration...${NC}"
terraform validate

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configuration valid${NC}"
else
    echo -e "${RED}✗ Configuration invalid${NC}"
    exit 1
fi

echo ""

# Plan deployment
echo -e "${BLUE}Step 3: Planning deployment...${NC}"
terraform plan -out=tfplan

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Plan created${NC}"
else
    echo -e "${RED}✗ Planning failed${NC}"
    exit 1
fi

echo ""

# Ask for confirmation
read -p "Do you want to apply this plan? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    rm -f tfplan
    exit 0
fi

echo ""

# Apply configuration
echo -e "${BLUE}Step 4: Applying configuration...${NC}"
terraform apply tfplan

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment successful${NC}"
    rm -f tfplan
else
    echo -e "${RED}✗ Deployment failed${NC}"
    rm -f tfplan
    exit 1
fi

echo ""

# Show outputs
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Deployment Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

terraform output

echo ""

# Check pod status
echo -e "${BLUE}Checking pod status...${NC}"
kubectl get pods -n inventory-manager

echo ""

# Provide next steps
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Next Steps${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "1. Wait for all pods to be Running:"
echo "   ${BLUE}watch kubectl get pods -n inventory-manager${NC}"
echo ""
echo "2. Port-forward to access API:"
echo "   ${BLUE}kubectl port-forward -n inventory-manager svc/inventory-manager-backend 8000:8000${NC}"
echo ""
echo "3. Test the API:"
echo "   ${BLUE}curl http://localhost:8000/health${NC}"
echo "   ${BLUE}open http://localhost:8000/docs${NC}"
echo ""
echo -e "${GREEN}✓ Phase 3 deployment complete!${NC}"
