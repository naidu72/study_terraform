#!/bin/bash

# Pre-flight Check Script
# Verifies everything is ready before building multi-arch images

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Phase 2 Pre-flight Check${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Function to check status
check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ $2${NC}"
        ((CHECKS_FAILED++))
    fi
}

# Check Docker
echo -e "${BLUE}Checking Docker...${NC}"
docker --version > /dev/null 2>&1
check $? "Docker is installed"

# Check Docker Buildx
docker buildx version > /dev/null 2>&1
check $? "Docker Buildx is available"

# Check builder
if docker buildx ls | grep -q "inventory-builder"; then
    check 0 "Multi-arch builder (inventory-builder) exists"
    
    # Check platforms
    if docker buildx inspect inventory-builder | grep -q "linux/amd64" && \
       docker buildx inspect inventory-builder | grep -q "linux/arm64"; then
        check 0 "Builder supports amd64 and arm64"
    else
        check 1 "Builder doesn't support required platforms"
    fi
else
    check 1 "Multi-arch builder not found"
    echo -e "${YELLOW}  Run: docker buildx create --name inventory-builder --platform linux/amd64,linux/arm64 --use${NC}"
fi

echo ""

# Check Registry Authentication
echo -e "${BLUE}Checking Registry Authentication...${NC}"

# GHCR
if cat ~/.docker/config.json 2>/dev/null | grep -q "ghcr.io"; then
    check 0 "GitHub Container Registry (ghcr.io) - Authenticated"
else
    check 1 "GitHub Container Registry (ghcr.io) - Not authenticated"
    echo -e "${YELLOW}  See: docs/AUTHENTICATION_GUIDE.md${NC}"
fi

# Docker Hub
if cat ~/.docker/config.json 2>/dev/null | grep -q "index.docker.io"; then
    check 0 "Docker Hub - Authenticated"
else
    check 1 "Docker Hub - Not authenticated (optional)"
    echo -e "${YELLOW}  Run: docker login${NC}"
fi

echo ""

# Check Dockerfile
echo -e "${BLUE}Checking Project Files...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_ROOT/app/backend/Dockerfile" ]; then
    check 0 "Backend Dockerfile exists"
else
    check 1 "Backend Dockerfile not found"
fi

if [ -f "$PROJECT_ROOT/app/backend/requirements.txt" ]; then
    check 0 "Backend requirements.txt exists"
else
    check 1 "Backend requirements.txt not found"
fi

echo ""

# Check Environment
echo -e "${BLUE}Checking Environment Variables...${NC}"

if [ -n "$GITHUB_USERNAME" ]; then
    echo -e "${GREEN}✓ GITHUB_USERNAME: $GITHUB_USERNAME${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠ GITHUB_USERNAME not set (will use default: naidu72)${NC}"
fi

if [ -n "$DOCKERHUB_USERNAME" ]; then
    echo -e "${GREEN}✓ DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠ DOCKERHUB_USERNAME not set (will use default: naidu72)${NC}"
fi

echo ""

# Disk Space Check
echo -e "${BLUE}Checking Disk Space...${NC}"
AVAILABLE_SPACE=$(df -BG "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')

if [ "$AVAILABLE_SPACE" -gt 5 ]; then
    check 0 "Sufficient disk space (${AVAILABLE_SPACE}GB available)"
else
    check 1 "Low disk space (${AVAILABLE_SPACE}GB available, recommend 5GB+)"
fi

echo ""

# Summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

echo -e "${GREEN}Checks Passed: $CHECKS_PASSED${NC}"
echo -e "${RED}Checks Failed: $CHECKS_FAILED${NC}"

echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready to build.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Run: ./scripts/build-multiarch.sh"
    echo "  2. Or with version: ./scripts/build-multiarch.sh v1.0.0"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠ Some checks failed. Please fix the issues above before building.${NC}"
    echo ""
    echo -e "${BLUE}Common fixes:${NC}"
    echo "  • Authentication: ./scripts/setup-registry-auth.sh"
    echo "  • Builder setup: docker buildx create --name inventory-builder --platform linux/amd64,linux/arm64 --use"
    echo ""
    exit 1
fi
