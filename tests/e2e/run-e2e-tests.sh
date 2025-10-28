#!/bin/bash

# Phase 2 E2E Test Runner
# Runs all E2E tests with proper environment setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set up Java environment for Maestro
export JAVA_HOME=/opt/homebrew/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home

# Test scenarios directory
SCENARIOS_DIR="tests/e2e/scenarios"

echo -e "${YELLOW}🚀 Starting Phase 2 E2E Tests...${NC}"
echo ""

# Check if Maestro is installed
if ! command -v maestro &> /dev/null; then
    echo -e "${RED}❌ Maestro is not installed. Please install it first:${NC}"
    echo "brew tap mobile-dev-inc/tap"
    echo "brew install maestro"
    exit 1
fi

# Check if iOS Simulator is running
if ! xcrun simctl list devices | grep -q "Booted"; then
    echo -e "${YELLOW}⚠️  No iOS Simulator is running. Starting iPhone 17 simulator...${NC}"
    xcrun simctl boot "iPhone 17" || echo -e "${RED}❌ Failed to start simulator${NC}"
    sleep 5
fi

# Function to run a single test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .yaml)
    
    echo -e "${YELLOW}🧪 Running test: $test_name${NC}"
    
    if maestro test "$test_file"; then
        echo -e "${GREEN}✅ $test_name passed${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name failed${NC}"
        return 1
    fi
}

# Run all E2E tests
echo -e "${YELLOW}📱 Running E2E tests against iOS Simulator...${NC}"
echo ""

failed_tests=()
passed_tests=()

# Run each test scenario
for test_file in "$SCENARIOS_DIR"/*.yaml; do
    if [ -f "$test_file" ]; then
        if run_test "$test_file"; then
            passed_tests+=("$(basename "$test_file" .yaml)")
        else
            failed_tests+=("$(basename "$test_file" .yaml)")
        fi
        echo ""
    fi
done

# Summary
echo -e "${YELLOW}📊 Test Summary:${NC}"
echo -e "${GREEN}✅ Passed: ${#passed_tests[@]}${NC}"
echo -e "${RED}❌ Failed: ${#failed_tests[@]}${NC}"

if [ ${#passed_tests[@]} -gt 0 ]; then
    echo -e "${GREEN}Passed tests:${NC}"
    for test in "${passed_tests[@]}"; do
        echo "  - $test"
    done
fi

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo -e "${RED}Failed tests:${NC}"
    for test in "${failed_tests[@]}"; do
        echo "  - $test"
    done
    exit 1
fi

echo -e "${GREEN}🎉 All E2E tests passed!${NC}"
