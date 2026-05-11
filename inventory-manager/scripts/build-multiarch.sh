#!/bin/bash

# Multi-arch Docker Build Script for Inventory Manager
# Builds images for amd64 and arm64, pushes to GHCR and Docker Hub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VERSION=${1:-latest}
GITHUB_USERNAME=${GITHUB_USERNAME:-naidu72}
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-naidu72}
PLATFORMS="linux/amd64,linux/arm64"
BUILDER_NAME="inventory-builder"

# Project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_ROOT/app"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Multi-arch Docker Build - Inventory Manager${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${GREEN}Version:${NC} $VERSION"
echo -e "${GREEN}Platforms:${NC} $PLATFORMS"
echo -e "${GREEN}Builder:${NC} $BUILDER_NAME"
echo ""

# Check if builder exists
if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
    echo -e "${YELLOW}Creating builder: $BUILDER_NAME${NC}"
    docker buildx create --name $BUILDER_NAME --platform $PLATFORMS --use
    docker buildx inspect --bootstrap
else
    echo -e "${GREEN}Using existing builder: $BUILDER_NAME${NC}"
    docker buildx use $BUILDER_NAME
fi

echo ""

# Function to build and push image
build_and_push() {
    local SERVICE=$1
    local CONTEXT=$2
    local DOCKERFILE=$3
    
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Building: $SERVICE${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    # Image tags
    GHCR_IMAGE="ghcr.io/${GITHUB_USERNAME}/inventory-${SERVICE}"
    DOCKERHUB_IMAGE="${DOCKERHUB_USERNAME}/inventory-${SERVICE}"
    
    echo -e "${YELLOW}Building for platforms: $PLATFORMS${NC}"
    echo -e "${YELLOW}GHCR: $GHCR_IMAGE:$VERSION${NC}"
    echo -e "${YELLOW}Docker Hub: $DOCKERHUB_IMAGE:$VERSION${NC}"
    echo ""
    
    # Build and push
    docker buildx build \
        --platform $PLATFORMS \
        --tag "${GHCR_IMAGE}:${VERSION}" \
        --tag "${DOCKERHUB_IMAGE}:${VERSION}" \
        --file "$DOCKERFILE" \
        --push \
        "$CONTEXT"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully built and pushed: $SERVICE${NC}"
        echo -e "${GREEN}  GHCR: $GHCR_IMAGE:$VERSION${NC}"
        echo -e "${GREEN}  Docker Hub: $DOCKERHUB_IMAGE:$VERSION${NC}"
    else
        echo -e "${RED}✗ Failed to build: $SERVICE${NC}"
        return 1
    fi
    
    echo ""
}

# Build Backend
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Step 1: Building Backend${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

if build_and_push "backend" "$APP_DIR/backend" "$APP_DIR/backend/Dockerfile"; then
    echo -e "${GREEN}✓ Backend build completed${NC}"
else
    echo -e "${RED}✗ Backend build failed${NC}"
    exit 1
fi

# Build Frontend (if Dockerfile exists)
if [ -f "$APP_DIR/frontend/Dockerfile" ]; then
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Step 2: Building Frontend${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    
    if build_and_push "frontend" "$APP_DIR/frontend" "$APP_DIR/frontend/Dockerfile"; then
        echo -e "${GREEN}✓ Frontend build completed${NC}"
    else
        echo -e "${RED}✗ Frontend build failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ Frontend Dockerfile not found, skipping...${NC}"
    echo ""
fi

# Summary
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "Version: ${GREEN}$VERSION${NC}"
echo -e "Platforms: ${GREEN}$PLATFORMS${NC}"
echo ""
echo -e "${BLUE}Images pushed to:${NC}"
echo -e "  • GitHub Container Registry (ghcr.io)"
echo -e "  • Docker Hub"
echo ""
echo -e "${GREEN}✓ All builds completed successfully!${NC}"
echo ""
echo -e "${BLUE}To pull images:${NC}"
echo -e "  docker pull ghcr.io/${GITHUB_USERNAME}/inventory-backend:$VERSION"
echo -e "  docker pull ${DOCKERHUB_USERNAME}/inventory-backend:$VERSION"
echo ""
echo -e "${BLUE}To test on Pi cluster:${NC}"
echo -e "  kubectl run test-backend --image=ghcr.io/${GITHUB_USERNAME}/inventory-backend:$VERSION -n default"
echo ""
