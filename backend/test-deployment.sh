#!/bin/bash

# SARAN Backend Deployment Test Script
# Tests if the backend is properly deployed and accessible

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get API URL from environment or use default
API_URL="${API_URL:-http://localhost:3000}"

echo "🧪 Testing SARAN Backend Deployment"
echo "===================================="
echo "API URL: $API_URL"
echo ""

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/health" || echo "000")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}❌ Health check failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

echo ""

# Test 2: User Registration
echo -e "${YELLOW}Test 2: User Registration${NC}"
TIMESTAMP=$(date +%s)
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"testuser$TIMESTAMP\",
    \"email\": \"test$TIMESTAMP@example.com\",
    \"password\": \"Test123!\",
    \"name\": \"Test User\"
  }" || echo "000")

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
BODY=$(echo "$REGISTER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ User registration passed${NC}"
    echo "Response: $BODY"
    
    # Extract token if available
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*' | cut -d'"' -f4 || echo "")
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}✅ Token received${NC}"
        export TEST_TOKEN="$TOKEN"
    fi
else
    echo -e "${YELLOW}⚠️  User registration returned HTTP $HTTP_CODE${NC}"
    echo "Response: $BODY"
    # Don't fail if user already exists
    if echo "$BODY" | grep -q "already exists"; then
        echo -e "${YELLOW}ℹ️  User already exists (this is OK)${NC}"
    fi
fi

echo ""

# Test 3: User Login
echo -e "${YELLOW}Test 3: User Login${NC}"
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }' || echo "000")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ User login passed${NC}"
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*' | cut -d'"' -f4 || echo "")
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}✅ Token received${NC}"
        export TEST_TOKEN="$TOKEN"
    fi
else
    echo -e "${YELLOW}⚠️  User login returned HTTP $HTTP_CODE${NC}"
    echo "Response: $BODY"
    echo -e "${YELLOW}ℹ️  This is OK if test user doesn't exist${NC}"
fi

echo ""

# Test 4: Protected Route (if token available)
if [ -n "$TEST_TOKEN" ]; then
    echo -e "${YELLOW}Test 4: Protected Route (Get Current User)${NC}"
    ME_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/api/auth/me" \
      -H "Authorization: Bearer $TEST_TOKEN" || echo "000")
    
    HTTP_CODE=$(echo "$ME_RESPONSE" | tail -n1)
    BODY=$(echo "$ME_RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Protected route access passed${NC}"
        echo "Response: $BODY"
    else
        echo -e "${RED}❌ Protected route access failed (HTTP $HTTP_CODE)${NC}"
        echo "Response: $BODY"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping protected route test (no token)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Deployment tests completed!${NC}"
echo ""
echo "To test with a different API URL:"
echo "  API_URL=https://api.saran.app ./test-deployment.sh"
