#!/bin/bash

# Comprehensive test suite for payload processing utilities
# Tests all new functions and scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

function print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

function print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

function print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

function run_test() {
    local test_name=$1
    shift
    print_test "$test_name"
    if "$@" >/dev/null 2>&1; then
        print_pass "$test_name"
        return 0
    else
        print_fail "$test_name"
        return 1
    fi
}

echo "========================================"
echo "Payload Processing Test Suite"
echo "========================================"
echo ""

# Test 1: Script permissions
print_test "Checking script permissions"
for script in inspect_payload.sh payload_functions.sh payload_advanced.sh payload_common.sh extract_payload_metadata.sh; do
    if [[ -x "$SCRIPT_DIR/$script" ]]; then
        print_pass "$script is executable"
    else
        print_fail "$script is NOT executable"
    fi
done
echo ""

# Test 2: Syntax validation
print_test "Validating script syntax"
for script in inspect_payload.sh payload_functions.sh payload_advanced.sh payload_common.sh extract_payload_metadata.sh; do
    if bash -n "$SCRIPT_DIR/$script" 2>/dev/null; then
        print_pass "$script syntax is valid"
    else
        print_fail "$script syntax is INVALID"
    fi
done
if bash -n "$PROJECT_DIR/dumper.sh" 2>/dev/null; then
    print_pass "dumper.sh syntax is valid"
else
    print_fail "dumper.sh syntax is INVALID"
fi
echo ""

# Test 3: Function loading
print_test "Testing function loading"
cd "$PROJECT_DIR"
if source utils/payload_common.sh 2>/dev/null; then
    print_pass "payload_common.sh loads successfully"
else
    print_fail "payload_common.sh failed to load"
fi
if source utils/payload_functions.sh 2>/dev/null; then
    print_pass "payload_functions.sh loads successfully"
else
    print_fail "payload_functions.sh failed to load"
fi
if source utils/payload_advanced.sh 2>/dev/null; then
    print_pass "payload_advanced.sh loads successfully"
else
    print_fail "payload_advanced.sh failed to load"
fi
echo ""

# Test 4: Common functions
print_test "Testing common utility functions"
source utils/payload_common.sh
if type read_uint64 >/dev/null 2>&1; then
    print_pass "read_uint64 function exists"
else
    print_fail "read_uint64 function NOT found"
fi
if type read_uint32 >/dev/null 2>&1; then
    print_pass "read_uint32 function exists"
else
    print_fail "read_uint32 function NOT found"
fi
if type get_file_size >/dev/null 2>&1; then
    print_pass "get_file_size function exists"
else
    print_fail "get_file_size function NOT found"
fi
echo ""

# Test 5: Payload functions
print_test "Testing payload processing functions"
source utils/payload_functions.sh
functions=(validate_payload_header get_payload_version get_payload_version_info extract_payload_safe list_payload_partitions)
for func in "${functions[@]}"; do
    if type "$func" >/dev/null 2>&1; then
        print_pass "$func function exists"
    else
        print_fail "$func function NOT found"
    fi
done
echo ""

# Test 6: Advanced functions
print_test "Testing advanced payload functions"
source utils/payload_advanced.sh
adv_functions=(verify_partition_checksum estimate_extraction_time check_disk_space extract_with_progress extract_with_retry create_extraction_report)
for func in "${adv_functions[@]}"; do
    if type "$func" >/dev/null 2>&1; then
        print_pass "$func function exists"
    else
        print_fail "$func function NOT found"
    fi
done
echo ""

# Test 7: Version info
print_test "Testing version info function"
source utils/payload_functions.sh
for version in 2 3 4; do
    info=$(get_payload_version_info "$version")
    if [[ -n "$info" ]]; then
        print_pass "Version $version info: $info"
    else
        print_fail "Version $version info is empty"
    fi
done
echo ""

# Test 8: Documentation
print_test "Checking documentation files"
docs=(README.md PAYLOAD_SUPPORT.md PAYLOAD_QUICK_REFERENCE.md)
for doc in "${docs[@]}"; do
    if [[ -f "$PROJECT_DIR/$doc" ]]; then
        lines=$(wc -l < "$PROJECT_DIR/$doc")
        print_pass "$doc exists ($lines lines)"
    else
        print_fail "$doc NOT found"
    fi
done
echo ""

# Summary
echo "========================================"
echo "Test Results Summary"
echo "========================================"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "========================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
