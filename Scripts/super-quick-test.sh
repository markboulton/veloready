#!/bin/bash

# VeloReady SUPER Quick Test - Solo Developer Speed Optimized
# Run this during rapid iteration - 20 seconds max
# Focus: Build validation only + 1 fast smoke test

set -e

# Set Xcode path for proper tool access
export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"

echo "⚡ VeloReady SUPER Quick Test (20 seconds max)"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -d "VeloReady.xcworkspace" ] && [ ! -d "VeloReady.xcodeproj" ]; then
    print_error "Please run this script from the VeloReady project root"
    exit 1
fi

# Start timer
start_time=$(date +%s)

echo "🎯 Running build check + 1 smoke test only"
echo ""

# 1. Build Check (15 seconds) - CRITICAL
echo "1️⃣  Building project..."
if xcodebuild build \
    -project VeloReady.xcodeproj \
    -scheme VeloReady \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -quiet \
    -hideShellScriptEnvironment \
    -skipPackagePluginValidation; then
    print_status "Build successful"
else
    print_error "Build failed - fix compilation errors first"
    exit 1
fi

# 2. One Fast Smoke Test (5 seconds) - SMOKE TEST
echo ""
echo "2️⃣  Running smoke test (logic validation)..."
if xcodebuild test \
    -project VeloReady.xcodeproj \
    -scheme VeloReady \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -only-testing:VeloReadyTests/Unit/TrainingLoadCalculatorTests \
    -quiet \
    -hideShellScriptEnvironment; then
    print_status "Smoke test passed"
else
    print_error "Smoke test failed - fix logic errors first"
    exit 1
fi

# Calculate elapsed time
end_time=$(date +%s)
elapsed=$((end_time - start_time))

echo ""
print_status "🎉 Super quick test completed in ${elapsed}s!"
echo ""
print_info "💡 For comprehensive testing before commit/push:"
echo "   • Run: ./Scripts/quick-test.sh (full test suite)"
echo ""
print_info "🚀 Rapid iteration workflow:"
echo "   1. Code your feature"
echo "   2. Run: ./Scripts/super-quick-test.sh (20s)"
echo "   3. Iterate fast"
echo "   4. Before commit: ./Scripts/quick-test.sh (90s)"
echo "   5. Push when all green"
echo ""
