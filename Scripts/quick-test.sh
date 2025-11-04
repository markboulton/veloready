#!/bin/bash

# VeloReady Quick Test - Single Developer Optimized
# Run this before pushing - 90 seconds max
# Focus: Build + Critical Unit Tests + Essential Lint

set -e

# Set Xcode path for proper tool access
export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"

echo "⚡ VeloReady Quick Test (90 seconds max)"
echo "========================================"

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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
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

echo "🎯 Running essential tests only (build + critical unit tests + lint)"
echo ""

# 1. Build Check (30 seconds) - CRITICAL
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

# 2. Critical Unit Tests Only (60 seconds) - CRITICAL
echo ""
echo "2️⃣  Running critical unit tests..."
if xcodebuild test \
    -project VeloReady.xcodeproj \
    -scheme VeloReady \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -only-testing:VeloReadyTests/Unit/CoreDataPersistenceTests \
    -only-testing:VeloReadyTests/Unit/TrainingLoadCalculatorTests \
    -only-testing:VeloReadyTests/Unit/RecoveryScoreTests \
    -only-testing:VeloReadyTests/Unit/CacheManagerTests \
    -only-testing:VeloReadyTests/Unit/MLModelRegistryTests \
    -quiet \
    -hideShellScriptEnvironment; then
    print_status "Critical unit tests passed"
else
    print_error "Critical unit tests failed - fix logic errors first"
    exit 1
fi

# 3. Essential Lint Check (15 seconds) - NICE TO HAVE
echo ""
echo "3️⃣  Running essential lint check..."
if command -v swiftlint &> /dev/null; then
    # Only check critical rules, skip style issues
    if swiftlint --quiet --config .swiftlint-essential.yml 2>/dev/null || swiftlint --quiet --disable unused_import,trailing_whitespace,line_length; then
        print_status "Essential lint check passed"
    else
        print_warning "Lint issues found - fix if critical (non-blocking)"
    fi
else
    print_warning "SwiftLint not installed - skipping"
fi

# Calculate elapsed time
end_time=$(date +%s)
elapsed=$((end_time - start_time))

echo ""
print_status "🎉 Quick test completed successfully in ${elapsed}s!"
echo ""
print_info "💡 Next steps:"
echo "   • Push your changes: git push"
echo "   • CI will run additional tests (5-10 min)"
echo "   • Ship when CI passes"
echo ""
print_info "⚡ For even faster feedback:"
echo "   • Build only: xcodebuild build -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet -skipPackagePluginValidation"
echo "   • Critical tests only: xcodebuild test -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VeloReadyTests/Unit/TrainingLoadCalculatorTests -quiet"
echo ""
print_info "🚀 Development workflow:"
echo "   1. Code your feature"
echo "   2. Run: ./Scripts/quick-test.sh (90s)"
echo "   3. Push when green"
echo "   4. Ship when CI passes"
