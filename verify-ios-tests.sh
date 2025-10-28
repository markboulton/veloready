#!/bin/bash

echo "🧪 Verifying VeloReady iOS Test Setup..."
echo "========================================"

# Check if we're in the right directory
if [ ! -f "VeloReady.xcodeproj/project.pbxproj" ]; then
    echo "❌ Not in VeloReady project directory"
    exit 1
fi

echo "✅ In VeloReady project directory"

# Check if test files exist
echo ""
echo "📁 Checking test files:"

test_files=(
    "VeloReadyTests/Integration/VeloReadyAPIClientTests.swift"
    "VeloReadyTests/Unit/TrainingLoadCalculatorTests.swift"
    "VeloReadyTests/Helpers/TestHelpers.swift"
)

for file in "${test_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

# Check if Xcode is available
echo ""
echo "🔧 Checking Xcode:"
if command -v xcodebuild &> /dev/null; then
    echo "✅ xcodebuild is available"
    xcodebuild -version | head -1
else
    echo "❌ xcodebuild not found"
fi

# Check if we can list schemes
echo ""
echo "📋 Checking Xcode schemes:"
if xcodebuild -list &> /dev/null; then
    echo "✅ Can list Xcode schemes"
    echo "Available schemes:"
    xcodebuild -list | grep -A 10 "Schemes:"
else
    echo "❌ Cannot list Xcode schemes"
fi

# Check if test target exists
echo ""
echo "🎯 Checking test targets:"
if xcodebuild -list | grep -q "VeloReadyTests"; then
    echo "✅ VeloReadyTests target exists"
else
    echo "❌ VeloReadyTests target missing"
fi

echo ""
echo "🎯 iOS test setup verification complete!"
echo ""
echo "Next steps:"
echo "1. Open VeloReady.xcodeproj in Xcode"
echo "2. Select VeloReadyTests target"
echo "3. Run tests (Cmd+U)"
echo "4. Check for any compilation errors"
