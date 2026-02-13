#!/bin/bash

PROXY_HOST="localhost"
PROXY_PORT="8080"
PROXY_URL="${PROXY_HOST}:${PROXY_PORT}"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

run_test() {
    TEST_COUNT=$((TEST_COUNT + 1))
    DESCRIPTION=$1
    EXPECTED_STATUS=$2
    COMMAND=$3

    echo -n "Running test ${TEST_COUNT}: ${DESCRIPTION}... "
    
    # Execute the command and capture HTTP status code
    HTTP_STATUS=$(eval "$COMMAND" -o /dev/null -w "%{http_code}" -s)
    
    if [ "$HTTP_STATUS" == "$EXPECTED_STATUS" ]; then
        echo -e "${GREEN}PASS${NC} (Status: ${HTTP_STATUS})"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${NC} (Expected: ${EXPECTED_STATUS}, Got: ${HTTP_STATUS})"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo "Starting Nginx Proxy Integration Tests..."
echo "-----------------------------------------"

# Test Case 1: Allow HTTPS CONNECT request
run_test "Allow HTTPS CONNECT request" "200" "curl -v -x http://${PROXY_URL} https://github.com"

echo "-----------------------------------------"
echo "Test Summary:"
echo "Total Tests: ${TEST_COUNT}"
echo -e "Passed: ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed: ${RED}${FAIL_COUNT}${NC}"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
