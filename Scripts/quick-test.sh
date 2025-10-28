#!/bin/bash

# Quick Test Script for Single Developer
# Run this before pushing - 2-3 minutes max

set -e

echo "⚡ VeloReady Quick Test (2-3 minutes)"
echo "====================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Check if we're in the right directory
if [ ! -d "VeloReady.xcworkspace" ] && [ ! -d "VeloReady.xcodeproj" ]; then
    print_error "Please run this script from the VeloReady project root"
    exit 1
fi

echo "🔍 Running essential tests only..."
echo ""

# 1. Build Check (30 seconds)
echo "1️⃣  Building project..."
if xcodebuild build \
    -project VeloReady.xcodeproj \
    -scheme VeloReady \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -quiet \
    -hideShellScriptEnvironment; then
    print_status "Build successful"
else
    print_error "Build failed - fix compilation errors first"
    exit 1
fi

# 2. Unit Tests (1-2 minutes)
echo ""
echo "2️⃣  Running unit tests..."
if xcodebuild test \
    -project VeloReady.xcodeproj \
    -scheme VeloReady \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:VeloReadyTests/Unit \
    -quiet \
    -hideShellScriptEnvironment; then
    print_status "Unit tests passed"
else
    print_error "Unit tests failed - fix logic errors first"
    exit 1
fi

# 3. Lint Check (30 seconds)
echo ""
echo "3️⃣  Running lint check..."
if command -v swiftlint &> /dev/null; then
    if swiftlint --quiet; then
        print_status "Lint check passed"
    else
        print_warning "Lint issues found - fix if critical"
    fi
else
    print_warning "SwiftLint not installed - skipping"
fi

echo ""
print_status "🎉 Quick test completed successfully!"
echo ""
echo "💡 Next steps:"
echo "   • Push your changes: git push"
echo "   • CI will run additional tests"
echo "   • Ship when CI passes"
echo ""
echo "⚡ For even faster feedback:"
echo "   • Build only: xcodebuild build -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet"
echo "   • Unit tests only: xcodebuild test -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Unit -quiet"

