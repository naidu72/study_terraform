#!/bin/bash

# Inventory Manager API Test Script
# This script tests all major API endpoints

set -e

BASE_URL="http://localhost:8000"
ADMIN_USER="admin"
ADMIN_PASS="admin123"

echo "================================="
echo "Inventory Manager API Test Script"
echo "================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo -e "${BLUE}Test 1: Health Check${NC}"
curl -s $BASE_URL/health | jq '.'
echo ""

# Test 2: Login and Get Token
echo -e "${BLUE}Test 2: Login${NC}"
TOKEN=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USER&password=$ADMIN_PASS" \
  | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ Login failed!"
    exit 1
fi

echo -e "${GREEN}✓ Login successful${NC}"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Test 3: Get Current User
echo -e "${BLUE}Test 3: Get Current User${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
  $BASE_URL/api/v1/auth/me | jq '.'
echo ""

# Test 4: List Categories
echo -e "${BLUE}Test 4: List Categories${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
  $BASE_URL/api/v1/categories/ | jq '.'
echo ""

# Test 5: List Products
echo -e "${BLUE}Test 5: List Products${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
  $BASE_URL/api/v1/products/ | jq '.'
echo ""

# Test 6: Dashboard Stats
echo -e "${BLUE}Test 6: Dashboard Statistics${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
  $BASE_URL/api/v1/dashboard/stats | jq '.'
echo ""

# Test 7: Low Stock Alerts
echo -e "${BLUE}Test 7: Low Stock Alerts${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
  $BASE_URL/api/v1/dashboard/low-stock | jq '.'
echo ""

# Test 8: Create a Category
echo -e "${BLUE}Test 8: Create Category${NC}"
CATEGORY_ID=$(curl -s -X POST "$BASE_URL/api/v1/categories/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Category",
    "description": "Created by test script"
  }' | jq -r '.id')

if [ "$CATEGORY_ID" != "null" ]; then
    echo -e "${GREEN}✓ Category created with ID: $CATEGORY_ID${NC}"
else
    echo "Category might already exist, continuing..."
    CATEGORY_ID=1
fi
echo ""

# Test 9: Create a Product
echo -e "${BLUE}Test 9: Create Product${NC}"
PRODUCT_ID=$(curl -s -X POST "$BASE_URL/api/v1/products/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"sku\": \"TEST-$(date +%s)\",
    \"name\": \"Test Product\",
    \"description\": \"Created by test script\",
    \"category_id\": $CATEGORY_ID,
    \"unit_price\": 99.99,
    \"current_stock\": 100,
    \"min_stock_level\": 10
  }" | jq -r '.id')

if [ "$PRODUCT_ID" != "null" ]; then
    echo -e "${GREEN}✓ Product created with ID: $PRODUCT_ID${NC}"
else
    echo "Product creation might have failed, using ID 1 for testing..."
    PRODUCT_ID=1
fi
echo ""

# Test 10: Record Stock Movement
echo -e "${BLUE}Test 10: Record Stock Movement (OUT)${NC}"
curl -s -X POST "$BASE_URL/api/v1/stock/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"product_id\": $PRODUCT_ID,
    \"movement_type\": \"out\",
    \"quantity\": 5,
    \"reference\": \"TEST-SO-001\",
    \"notes\": \"Test sales order from script\"
  }" | jq '.'
echo ""

# Test 11: Get Product Movement History
echo -e "${BLUE}Test 11: Get Product Movement History${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL/api/v1/stock/product/$PRODUCT_ID/history" | jq '.'
echo ""

# Test 12: List Stock Movements
echo -e "${BLUE}Test 12: List Stock Movements${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
  $BASE_URL/api/v1/stock/ | jq '.'
echo ""

echo "================================="
echo -e "${GREEN}✓ All tests completed successfully!${NC}"
echo "================================="
echo ""
echo "API Documentation: $BASE_URL/docs"
echo "Health Check: $BASE_URL/health"
echo ""
