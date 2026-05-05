#!/bin/bash

# Registry Authentication Setup Script
# Helps configure authentication for GHCR and Docker Hub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Registry Authentication Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check Docker login status
check_registry_auth() {
    local REGISTRY=$1
    local NAME=$2
    
    if docker system info 2>/dev/null | grep -q "$REGISTRY"; then
        echo -e "${GREEN}✓ Already logged in to $NAME${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Not logged in to $NAME${NC}"
        return 1
    fi
}

# GitHub Container Registry
echo -e "${BLUE}1. GitHub Container Registry (ghcr.io)${NC}"
echo ""

if check_registry_auth "ghcr.io" "GHCR"; then
    echo ""
else
    echo -e "${YELLOW}To login to GHCR:${NC}"
    echo ""
    echo "  1. Create GitHub Personal Access Token:"
    echo "     https://github.com/settings/tokens/new"
    echo ""
    echo "  2. Select scopes:"
    echo "     • read:packages"
    echo "     • write:packages"
    echo "     • delete:packages (optional)"
    echo ""
    echo "  3. Login with token:"
    echo -e "     ${GREEN}export GITHUB_TOKEN=<your-token>${NC}"
    echo -e "     ${GREEN}echo \$GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin${NC}"
    echo ""
    
    read -p "Do you want to login now? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "GitHub username: " GITHUB_USER
        read -sp "GitHub token: " GITHUB_TOKEN
        echo ""
        
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Successfully logged in to GHCR${NC}"
        else
            echo -e "${RED}✗ Failed to login to GHCR${NC}"
        fi
    fi
    echo ""
fi

# Docker Hub
echo -e "${BLUE}2. Docker Hub${NC}"
echo ""

if check_registry_auth "docker.io" "Docker Hub"; then
    echo ""
else
    echo -e "${YELLOW}To login to Docker Hub:${NC}"
    echo ""
    echo -e "  ${GREEN}docker login${NC}"
    echo "  Enter your Docker Hub username and password"
    echo ""
    
    read -p "Do you want to login now? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker login
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Successfully logged in to Docker Hub${NC}"
        else
            echo -e "${RED}✗ Failed to login to Docker Hub${NC}"
        fi
    fi
    echo ""
fi

# Summary
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Authentication Summary${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

if check_registry_auth "ghcr.io" "GHCR" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ GHCR: Authenticated${NC}"
else
    echo -e "${RED}✗ GHCR: Not authenticated${NC}"
fi

if check_registry_auth "docker.io" "Docker Hub" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker Hub: Authenticated${NC}"
else
    echo -e "${RED}✗ Docker Hub: Not authenticated${NC}"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Ensure you're authenticated to both registries"
echo "  2. Run: ./scripts/build-multiarch.sh"
echo ""
