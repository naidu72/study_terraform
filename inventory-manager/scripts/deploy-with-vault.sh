#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🚀 Inventory Manager - Terraform Deployment Script 🚀     ║"
echo "║        with Vault & MinIO Integration                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Terraform found: $(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)${NC}"

if ! command -v vault &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vault CLI not found. Will use manual secret entry.${NC}"
    VAULT_AVAILABLE=false
else
    echo -e "${GREEN}✓ Vault CLI found${NC}"
    VAULT_AVAILABLE=true
fi

# Cluster selection
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🎯 Select target cluster:${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo "1) pi-k8s (arm64) - Raspberry Pi cluster"
echo "2) k8s-k8s (amd64) - Standard Kubernetes cluster"
echo "3) Both clusters (deploy to both sequentially)"
echo ""
read -p "Enter your choice (1-3): " cluster_choice

case $cluster_choice in
    1)
        TARGET_ENV="pi-cluster"
        CLUSTER_NAME="pi-k8s"
        CLUSTER_ARCH="arm64"
        ;;
    2)
        TARGET_ENV="k8s-cluster"
        CLUSTER_NAME="k8s-k8s"
        CLUSTER_ARCH="amd64"
        ;;
    3)
        echo -e "${YELLOW}📌 Will deploy to both clusters sequentially${NC}"
        DEPLOY_BOTH=true
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

# Function to deploy to a cluster
deploy_to_cluster() {
    local env_name=$1
    local cluster_name=$2
    local cluster_arch=$3
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🚀 Deploying to ${cluster_name} (${cluster_arch})${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    # Secret management choice
    echo ""
    echo -e "${YELLOW}🔐 How would you like to provide secrets?${NC}"
    echo "1) Fetch from Vault (vault.naidu72.info)"
    echo "2) Enter manually"
    echo ""
    read -p "Enter your choice (1-2): " secret_choice

    if [ "$secret_choice" == "1" ] && [ "$VAULT_AVAILABLE" == true ]; then
        echo -e "${BLUE}🔑 Using Vault for secrets...${NC}"
        
        # Set Vault address
        export VAULT_ADDR="https://vault.naidu72.info"
        echo -e "${GREEN}✓ Vault address set to: $VAULT_ADDR${NC}"
        
        # Check if already logged in
        if ! vault token lookup &> /dev/null; then
            echo -e "${YELLOW}⚠️  Not logged into Vault. Please authenticate:${NC}"
            vault login
        else
            echo -e "${GREEN}✓ Already logged into Vault${NC}"
        fi
        
        # Fetch MinIO credentials
        echo -e "${YELLOW}📦 Fetching MinIO credentials from Vault...${NC}"
        export AWS_ACCESS_KEY_ID=$(vault kv get -field=access_key_id secret/minio/credentials 2>/dev/null || echo "")
        export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secret_access_key secret/minio/credentials 2>/dev/null || echo "")
        
        if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
            echo -e "${RED}❌ Failed to fetch MinIO credentials from Vault${NC}"
            echo -e "${YELLOW}💡 Falling back to manual entry...${NC}"
            read -sp "Enter MinIO Access Key ID: " AWS_ACCESS_KEY_ID
            echo
            export AWS_ACCESS_KEY_ID
            read -sp "Enter MinIO Secret Access Key: " AWS_SECRET_ACCESS_KEY
            echo
            export AWS_SECRET_ACCESS_KEY
        else
            echo -e "${GREEN}✓ MinIO credentials fetched from Vault${NC}"
        fi
        
        # Fetch application secrets
        echo -e "${YELLOW}🔒 Fetching application secrets from Vault...${NC}"
        export TF_VAR_postgres_password=$(vault kv get -field=password secret/inventory-manager/postgres 2>/dev/null || echo "")
        export TF_VAR_jwt_secret_key=$(vault kv get -field=secret_key secret/inventory-manager/jwt 2>/dev/null || echo "")
        
        # Fetch GHCR credentials
        echo -e "${YELLOW}🐳 Fetching GHCR credentials from Vault...${NC}"
        export TF_VAR_ghcr_username=$(vault kv get -field=username secret/ghcr/credentials 2>/dev/null || echo "naidu72")
        export TF_VAR_ghcr_token=$(vault kv get -field=token secret/ghcr/credentials 2>/dev/null || echo "")
        
        if [ -z "$TF_VAR_postgres_password" ]; then
            echo -e "${YELLOW}⚠️  PostgreSQL password not found in Vault${NC}"
            read -sp "Enter PostgreSQL password: " TF_VAR_postgres_password
            echo
            export TF_VAR_postgres_password
        else
            echo -e "${GREEN}✓ PostgreSQL password fetched from Vault${NC}"
        fi
        
        if [ -z "$TF_VAR_jwt_secret_key" ]; then
            echo -e "${YELLOW}⚠️  JWT secret key not found in Vault${NC}"
            read -sp "Enter JWT secret key: " TF_VAR_jwt_secret_key
            echo
            export TF_VAR_jwt_secret_key
        else
            echo -e "${GREEN}✓ JWT secret key fetched from Vault${NC}"
        fi
        
        if [ -z "$TF_VAR_ghcr_token" ]; then
            echo -e "${YELLOW}⚠️  GHCR token not found in Vault${NC}"
            read -sp "Enter GHCR token: " TF_VAR_ghcr_token
            echo
            export TF_VAR_ghcr_token
        else
            echo -e "${GREEN}✓ GHCR credentials fetched from Vault${NC}"
        fi
        
    else
        # Manual secret entry
        echo -e "${BLUE}✍️  Manual secret entry mode${NC}"
        
        echo ""
        echo -e "${YELLOW}📦 MinIO Credentials (for state storage):${NC}"
        read -p "MinIO Access Key ID: " AWS_ACCESS_KEY_ID
        export AWS_ACCESS_KEY_ID
        read -sp "MinIO Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo
        export AWS_SECRET_ACCESS_KEY
        
        echo ""
        echo -e "${YELLOW}🔒 Application Secrets:${NC}"
        read -sp "PostgreSQL Password: " TF_VAR_postgres_password
        echo
        export TF_VAR_postgres_password
        
        read -sp "JWT Secret Key: " TF_VAR_jwt_secret_key
        echo
        export TF_VAR_jwt_secret_key
    fi

    # Verify all required secrets are set
    echo ""
    echo -e "${YELLOW}🔍 Verifying secrets...${NC}"
    
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo -e "${RED}❌ MinIO credentials are missing${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ MinIO credentials set${NC}"
    
    if [ -z "$TF_VAR_postgres_password" ] || [ -z "$TF_VAR_jwt_secret_key" ]; then
        echo -e "${RED}❌ Application secrets are missing${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Application secrets set${NC}"

    # Navigate to environment directory
    ENV_DIR="$(pwd)/terraform/environments/${env_name}"
    
    if [ ! -d "$ENV_DIR" ]; then
        echo -e "${RED}❌ Environment directory not found: $ENV_DIR${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}📂 Environment directory: $ENV_DIR${NC}"
    cd "$ENV_DIR"

    # Terraform workflow
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🔧 Running Terraform...${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    # Initialize
    echo ""
    echo -e "${YELLOW}1️⃣  Initializing Terraform...${NC}"
    if terraform init; then
        echo -e "${GREEN}✓ Terraform initialized successfully${NC}"
    else
        echo -e "${RED}❌ Terraform init failed${NC}"
        return 1
    fi
    
    # Validate
    echo ""
    echo -e "${YELLOW}2️⃣  Validating configuration...${NC}"
    if terraform validate; then
        echo -e "${GREEN}✓ Configuration is valid${NC}"
    else
        echo -e "${RED}❌ Configuration validation failed${NC}"
        return 1
    fi
    
    # Plan
    echo ""
    echo -e "${YELLOW}3️⃣  Generating execution plan...${NC}"
    if terraform plan -out=tfplan; then
        echo -e "${GREEN}✓ Plan generated successfully${NC}"
    else
        echo -e "${RED}❌ Plan generation failed${NC}"
        return 1
    fi
    
    # Apply
    echo ""
    echo -e "${YELLOW}4️⃣  Applying changes...${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠️  This will deploy resources to ${cluster_name}${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    read -p "Do you want to proceed? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}⏸️  Deployment cancelled${NC}"
        rm -f tfplan
        return 0
    fi
    
    if terraform apply tfplan; then
        echo -e "${GREEN}✓ Deployment successful!${NC}"
        rm -f tfplan
    else
        echo -e "${RED}❌ Deployment failed${NC}"
        rm -f tfplan
        return 1
    fi
    
    # Display outputs
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📊 Deployment Outputs:${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    terraform output
    
    # Post-deployment checks
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🔍 Post-Deployment Status:${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    NAMESPACE=$(terraform output -raw namespace 2>/dev/null || echo "inventory-manager")
    
    echo ""
    echo -e "${YELLOW}Checking pods...${NC}"
    kubectl get pods -n "$NAMESPACE" --context="$cluster_name" || echo -e "${YELLOW}⚠️  kubectl check failed${NC}"
    
    echo ""
    echo -e "${GREEN}✅ Deployment to ${cluster_name} completed!${NC}"
}

# Main execution
if [ "$DEPLOY_BOTH" == true ]; then
    # Deploy to pi-k8s first
    deploy_to_cluster "pi-cluster" "pi-k8s" "arm64"
    PI_RESULT=$?
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    # Deploy to k8s-k8s
    deploy_to_cluster "k8s-cluster" "k8s-k8s" "amd64"
    K8S_RESULT=$?
    
    # Summary
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📊 Deployment Summary:${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    if [ $PI_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ pi-k8s (arm64): SUCCESS${NC}"
    else
        echo -e "${RED}❌ pi-k8s (arm64): FAILED${NC}"
    fi
    
    if [ $K8S_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ k8s-k8s (amd64): SUCCESS${NC}"
    else
        echo -e "${RED}❌ k8s-k8s (amd64): FAILED${NC}"
    fi
    
    if [ $PI_RESULT -eq 0 ] && [ $K8S_RESULT -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
else
    # Deploy to single cluster
    deploy_to_cluster "$TARGET_ENV" "$CLUSTER_NAME" "$CLUSTER_ARCH"
fi

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║            🎉 Deployment Process Complete! 🎉                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
