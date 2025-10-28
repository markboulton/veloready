#!/bin/bash

# Pre-push Git Hook
# Runs Tier 1 tests before allowing push

echo "🔍 Running pre-push checks..."
echo "=============================="

# Run the local test script
if ./scripts/local-test.sh; then
    echo ""
    echo "✅ Pre-push checks passed! Pushing to remote..."
    exit 0
else
    echo ""
    echo "❌ Pre-push checks failed! Please fix the issues before pushing."
    echo ""
    echo "💡 To skip this check (not recommended):"
    echo "   git push --no-verify"
    exit 1
fi
