#!/bin/bash

# Local Development Testing Script
# Run this before pushing to get fast feedback

set -e

echo "🚀 VeloReady Local Testing Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
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

echo "📋 Running Tier 1 Tests (Fast Feedback)..."
echo ""

# Tier 1: Lint (if available)
echo "1️⃣  Running SwiftLint..."
if command -v swiftlint &> /dev/null; then
    if swiftlint; then
        print_status "SwiftLint passed"
    else
        print_error "SwiftLint failed"
        exit 1
    fi
else
    print_warning "SwiftLint not installed, skipping..."
fi

# Tier 1: Unit Tests
echo ""
echo "2️⃣  Running Unit Tests..."
if xcodebuild test \
    -project VeloReady.xcodeproj \
    -scheme VeloReady \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:VeloReadyTests/Unit \
    -quiet; then
    print_status "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

echo ""
print_status "🎉 Tier 1 tests completed successfully!"
echo ""
echo "💡 Next steps:"
echo "   • Push your changes: git push"
echo "   • Open a PR to trigger Tier 2 tests (Integration + E2E Smoke)"
echo "   • Full E2E tests will run after merging to main"
echo ""
echo "⚡ For even faster feedback, run specific test suites:"
echo "   • Unit only: xcodebuild test -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Unit"
echo "   • Integration only: xcodebuild test -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Integration"
echo ""
echo "📱 iOS 26 Development Notes:"
echo "   • Using Xcode 26 for iOS 26 development"
echo "   • CI uses Xcode 16.0 with iOS 18.0/19.0 simulators"
echo "   • Local development should use latest iOS simulators"