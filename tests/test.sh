#!/bin/bash

PROXY_HOST="localhost"
PROXY_PORT="8080"
PROXY_URL="${PROXY_HOST}:${PROXY_PORT}"
AUTH_USER1="user1"
AUTH_PASS1="password"
AUTH_USER2="user2"
AUTH_PASS2="password"
WRONG_USER="wronguser"
WRONG_PASS="wrongpass"

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

# Test Case 1: Reject unauthenticated HTTP request
run_test "Reject unauthenticated HTTP request" "401" "curl -x http://${PROXY_URL} http://example.com"

# Test Case 2: Reject unauthenticated HTTPS CONNECT request
run_test "Reject unauthenticated HTTPS CONNECT request" "401" "curl -x http://${PROXY_URL} -I https://example.com"

# Test Case 3: Reject HTTP request with wrong credentials
run_test "Reject HTTP request with wrong credentials" "401" "curl -x http://${PROXY_URL} -U ${WRONG_USER}:${WRONG_PASS} http://example.com"

# Test Case 4: Reject HTTPS CONNECT request with wrong credentials
run_test "Reject HTTPS CONNECT request with wrong credentials" "401" "curl -x http://${PROXY_URL} -U ${WRONG_USER}:${WRONG_PASS} -I https://example.com"

# Test Case 5: Allow HTTP request with correct credentials (user1, github.com)
run_test "Allow HTTP request with correct credentials (user1, github.com)" "200" "curl -v -x http://${PROXY_URL} -U ${AUTH_USER1}:${AUTH_PASS1} http://github.com"

# Test Case 6: Allow HTTPS CONNECT request with correct credentials (user1, github.com)
run_test "Allow HTTPS CONNECT request with correct credentials (user1, github.com)" "200" "curl -x http://${PROXY_URL} -U ${AUTH_USER1}:${AUTH_PASS1} -I https://github.com"

# Test Case 7: Allow HTTPS CONNECT request with correct credentials (user1, sub.github.com)
run_test "Allow HTTPS CONNECT request with correct credentials (user1, sub.github.com)" "200" "curl -x http://${PROXY_URL} -U ${AUTH_USER1}:${AUTH_PASS1} -I https://docs.github.com"

# Test Case 8: Reject HTTPS CONNECT request with correct credentials (user1, example.com - not whitelisted)
run_test "Reject HTTPS CONNECT request with correct credentials (user1, example.com - not whitelisted)" "403" "curl -x http://${PROXY_URL} -U ${AUTH_USER1}:${AUTH_PASS1} -I https://example.com"

# Test Case 9: Allow HTTPS CONNECT request with correct credentials (user2, example.com)
run_test "Allow HTTPS CONNECT request with correct credentials (user2, example.com)" "200" "curl -x http://${PROXY_URL} -U ${AUTH_USER2}:${AUTH_PASS2} -I https://example.com"

# Test Case 10: Reject HTTPS CONNECT request with correct credentials (user2, github.com - not whitelisted)
run_test "Reject HTTPS CONNECT request with correct credentials (user2, github.com - not whitelisted)" "403" "curl -x http://${PROXY_URL} -U ${AUTH_USER2}:${AUTH_PASS2} -I https://github.com"

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
