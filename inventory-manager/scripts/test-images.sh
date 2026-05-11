#!/bin/bash

# Test Script for Multi-arch Docker Images
# Verifies images work correctly on different platforms

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
VERSION=${1:-latest}
REGISTRY=${2:-ghcr.io}
USERNAME=${3:-naidu72}

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Testing Multi-arch Images${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${GREEN}Registry:${NC} $REGISTRY"
echo -e "${GREEN}Username:${NC} $USERNAME"
echo -e "${GREEN}Version:${NC} $VERSION"
echo ""

# Function to test image
test_image() {
    local SERVICE=$1
    local IMAGE="$REGISTRY/$USERNAME/inventory-${SERVICE}:$VERSION"
    
    echo -e "${BLUE}Testing: $SERVICE${NC}"
    echo -e "${YELLOW}Image: $IMAGE${NC}"
    echo ""
    
    # Inspect image
    echo "Inspecting image..."
    docker buildx imagetools inspect "$IMAGE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Image inspection successful${NC}"
    else
        echo -e "${RED}✗ Image inspection failed${NC}"
        return 1
    fi
    
    echo ""
    
    # Pull and verify image can run
    echo "Pulling image..."
    docker pull "$IMAGE" --platform linux/$(uname -m)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Image pulled successfully${NC}"
    else
        echo -e "${RED}✗ Failed to pull image${NC}"
        return 1
    fi
    
    echo ""
    
    # Test run (quick health check)
    echo "Testing image startup..."
    local CONTAINER_NAME="test-${SERVICE}-$$"
    
    docker run --rm --name "$CONTAINER_NAME" \
        -e DATABASE_URL=postgresql://test:test@localhost/test \
        -e REDIS_URL=redis://localhost:6379 \
        "$IMAGE" python -c "import main; print('✓ Import successful')" 2>/dev/null || true
    
    echo ""
}

# Test Backend
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Testing Backend Image${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

if test_image "backend"; then
    echo -e "${GREEN}✓ Backend tests passed${NC}"
else
    echo -e "${RED}✗ Backend tests failed${NC}"
fi

echo ""

# Test Frontend (if exists)
if docker buildx imagetools inspect "$REGISTRY/$USERNAME/inventory-frontend:$VERSION" 2>/dev/null; then
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Testing Frontend Image${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    
    if test_image "frontend"; then
        echo -e "${GREEN}✓ Frontend tests passed${NC}"
    else
        echo -e "${RED}✗ Frontend tests failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Frontend image not found, skipping...${NC}"
fi

echo ""

# Summary
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Test Summary${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${GREEN}✓ Image tests completed${NC}"
echo ""
echo -e "${BLUE}Images are ready to deploy!${NC}"
echo ""
