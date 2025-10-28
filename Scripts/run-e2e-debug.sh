#!/bin/bash

# E2E Test Debug Script
# Run this to debug E2E issues locally with controlled output

set -e

echo "🔍 VeloReady E2E Debug Script"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -d "VeloReady.xcworkspace" ] && [ ! -d "VeloReady.xcodeproj" ]; then
    print_error "Please run this script from the VeloReady project root"
    exit 1
fi

# Check if Maestro is installed
if ! command -v maestro &> /dev/null; then
    print_error "Maestro is not installed. Please install it first:"
    echo "  brew tap mobile-dev-inc/tap"
    echo "  brew install maestro"
    exit 1
fi

# Check if Java is available
if ! command -v java &> /dev/null; then
    print_error "Java is not installed. Please install it first:"
    echo "  brew install openjdk@17"
    echo "  export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
    exit 1
fi

echo "📋 Running E2E Debug Tests..."
echo ""

# Create results directory
mkdir -p maestro-results/

# Set log level
export MAESTRO_LOG_LEVEL=INFO  # More verbose for debugging

# Run individual test scenarios with detailed output
echo "1️⃣  Testing Training Load scenario..."
if maestro test tests/e2e/scenarios/training-load.yaml --format junit --output maestro-results/; then
    print_status "Training Load test passed"
else
    print_error "Training Load test failed"
    echo "Check maestro-results/ for detailed logs"
fi

echo ""
echo "2️⃣  Testing Onboarding scenario..."
if maestro test tests/e2e/scenarios/onboarding.yaml --format junit --output maestro-results/; then
    print_status "Onboarding test passed"
else
    print_error "Onboarding test failed"
    echo "Check maestro-results/ for detailed logs"
fi

echo ""
echo "3️⃣  Testing Activity Sync scenario..."
if maestro test tests/e2e/scenarios/activity-sync.yaml --format junit --output maestro-results/; then
    print_status "Activity Sync test passed"
else
    print_error "Activity Sync test failed"
    echo "Check maestro-results/ for detailed logs"
fi

echo ""
echo "4️⃣  Testing AI Brief scenario..."
if maestro test tests/e2e/scenarios/ai-brief.yaml --format junit --output maestro-results/; then
    print_status "AI Brief test passed"
else
    print_error "AI Brief test failed"
    echo "Check maestro-results/ for detailed logs"
fi

echo ""
echo "5️⃣  Testing Recovery Score scenario..."
if maestro test tests/e2e/scenarios/recovery-score.yaml --format junit --output maestro-results/; then
    print_status "Recovery Score test passed"
else
    print_error "Recovery Score test failed"
    echo "Check maestro-results/ for detailed logs"
fi

echo ""
echo "📊 Test Results Summary:"
echo "========================"
if [ -d "maestro-results/" ]; then
    echo "Results saved to: maestro-results/"
    ls -la maestro-results/
else
    echo "No results directory found"
fi

echo ""
echo "💡 Debug Tips:"
echo "   • Check maestro-results/ for detailed test logs"
echo "   • Ensure iOS Simulator is running"
echo "   • Verify the app is built and installed"
echo "   • Check that backend services are running"
echo ""
echo "🔧 To run specific tests:"
echo "   maestro test tests/e2e/scenarios/training-load.yaml"
echo "   maestro test tests/e2e/scenarios/onboarding.yaml"
