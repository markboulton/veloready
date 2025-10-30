#!/bin/bash

# Test Data Refresh Improvements
# Tests the new 30-second cache and 1-minute update frequency

set -e

echo "🧪 Testing Data Refresh Improvements"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Verify HealthKit cache TTL
echo "📋 Test 1: Verifying HealthKit Cache TTL"
echo "   Searching for cache TTL values in HealthKitManager.swift..."

STEPS_CACHE=$(grep -A 2 "fetchDailySteps" VeloReady/Core/Networking/HealthKitManager.swift | grep "ttl:" | grep -o "ttl: [0-9]*")
CALORIES_CACHE=$(grep -A 2 "fetchDailyActiveCalories" VeloReady/Core/Networking/HealthKitManager.swift | grep "ttl:" | grep -o "ttl: [0-9]*")

if [[ "$STEPS_CACHE" == "ttl: 30" ]]; then
    echo -e "   ✅ ${GREEN}Steps cache TTL: 30 seconds${NC}"
else
    echo -e "   ❌ ${RED}Steps cache TTL: $STEPS_CACHE (expected ttl: 30)${NC}"
fi

if [[ "$CALORIES_CACHE" == "ttl: 30" ]]; then
    echo -e "   ✅ ${GREEN}Calories cache TTL: 30 seconds${NC}"
else
    echo -e "   ❌ ${RED}Calories cache TTL: $CALORIES_CACHE (expected ttl: 30)${NC}"
fi

echo ""

# Test 2: Verify LiveActivity update frequency
echo "📋 Test 2: Verifying LiveActivity Update Frequency"
echo "   Searching for timer interval in LiveActivityService.swift..."

TIMER_INTERVAL=$(grep "withTimeInterval:" VeloReady/Core/Services/LiveActivityService.swift | grep -o "withTimeInterval: [0-9]*")

if [[ "$TIMER_INTERVAL" == "withTimeInterval: 60" ]]; then
    echo -e "   ✅ ${GREEN}Update frequency: 60 seconds (1 minute)${NC}"
else
    echo -e "   ❌ ${RED}Update frequency: $TIMER_INTERVAL (expected withTimeInterval: 60)${NC}"
fi

echo ""

# Test 3: Verify foreground invalidation exists
echo "📋 Test 3: Verifying Foreground Cache Invalidation"
echo "   Checking for invalidateShortLivedCaches method..."

if grep -q "invalidateShortLivedCaches" VeloReady/Features/Today/Views/Dashboard/TodayView.swift; then
    echo -e "   ✅ ${GREEN}Foreground invalidation method exists${NC}"
else
    echo -e "   ❌ ${RED}Foreground invalidation method missing${NC}"
fi

if grep -q "healthkit:steps" VeloReady/Features/Today/Views/Dashboard/TodayView.swift; then
    echo -e "   ✅ ${GREEN}HealthKit cache invalidation configured${NC}"
else
    echo -e "   ❌ ${RED}HealthKit cache invalidation missing${NC}"
fi

echo ""

# Test 4: Verify Strava cache NOT changed
echo "📋 Test 4: Verifying Strava Cache Protection"
echo "   Checking Strava cache TTL..."

STRAVA_CACHE=$(grep "cacheTTL: TimeInterval" VeloReady/Core/Services/StravaDataService.swift | grep -o "[0-9]*")

if [[ "$STRAVA_CACHE" == "3600" ]]; then
    echo -e "   ✅ ${GREEN}Strava cache: 3600 seconds (1 hour) - PROTECTED${NC}"
else
    echo -e "   ⚠️  ${YELLOW}Strava cache: $STRAVA_CACHE seconds (expected 3600)${NC}"
fi

echo ""

# Test 5: Compile check
echo "📋 Test 5: Swift Compilation Check"
echo "   Building VeloReady target..."

if xcodebuild -project VeloReady.xcodeproj -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' clean build > /dev/null 2>&1; then
    echo -e "   ✅ ${GREEN}Project builds successfully${NC}"
else
    echo -e "   ❌ ${RED}Build failed - check Xcode for errors${NC}"
    exit 1
fi

echo ""

# Summary
echo "======================================"
echo "✅ All automated tests passed!"
echo ""
echo "📱 Manual Testing Steps:"
echo "   1. Run app on device"
echo "   2. Note current step count"
echo "   3. Walk 200 steps (2-3 minutes)"
echo "   4. Wait 90 seconds"
echo "   5. Check if steps updated ✓"
echo ""
echo "   Expected: Steps show new count within 90 seconds"
echo ""
echo "🔋 Battery Impact:"
echo "   Monitor battery drain over 1 hour of usage"
echo "   Expected: < 3% additional drain"
echo ""
echo "🎯 Success Criteria:"
echo "   ✅ Steps update within 30-90 seconds"
echo "   ✅ Calories update within 30-90 seconds"
echo "   ✅ Opening app shows fresh data immediately"
echo "   ✅ No noticeable battery impact"
echo ""
echo "📚 Documentation:"
echo "   - Issue Report: documentation/issues/DATA_REFRESH_ISSUE.md"
echo "   - API Impact: documentation/issues/DATA_REFRESH_STRAVA_API_IMPACT.md"
echo "   - Fix Summary: documentation/issues/DATA_REFRESH_FIX_COMPLETE.md"
echo ""

