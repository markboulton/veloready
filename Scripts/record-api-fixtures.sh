#!/bin/bash
#
# Record API Fixtures for Contract Testing
# 
# This script records REAL API responses from Strava and Intervals.icu
# for use in contract testing. It makes 3-5 API calls total.
#
# Usage:
#   export STRAVA_TOKEN="your_access_token"
#   export INTERVALS_TOKEN="your_api_key"
#   ./Scripts/record-api-fixtures.sh
#
# API Cost: 3-5 requests (one-time)
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🎬 Recording API Fixtures for Contract Testing"
echo "================================================"
echo ""

# Check for required tokens
if [ -z "$STRAVA_TOKEN" ]; then
    echo -e "${RED}❌ Error: STRAVA_TOKEN not set${NC}"
    echo ""
    echo "Please set your Strava access token:"
    echo "  export STRAVA_TOKEN=\"your_access_token\""
    echo ""
    echo "Get your token from: https://www.strava.com/settings/api"
    exit 1
fi

if [ -z "$INTERVALS_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  Warning: INTERVALS_TOKEN not set${NC}"
    echo "Skipping Intervals.icu fixtures"
    echo ""
fi

# Create fixtures directory if it doesn't exist
mkdir -p Tests/Fixtures

# Track API calls
API_CALLS=0

echo -e "${YELLOW}⚠️  This will make 3-5 Strava API requests${NC}"
echo "Current quota: 1000 requests/day"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Recording Strava API responses..."
echo ""

# 1. Fetch recent activities
echo "1/5 📊 Fetching recent activities..."
curl -s -H "Authorization: Bearer $STRAVA_TOKEN" \
  "https://www.strava.com/api/v3/athlete/activities?per_page=10&page=1" \
  > Tests/Fixtures/strava_activities_response.json

if [ $? -eq 0 ]; then
    ACTIVITY_COUNT=$(cat Tests/Fixtures/strava_activities_response.json | grep -o '"id"' | wc -l | tr -d ' ')
    echo -e "   ${GREEN}✓${NC} Recorded $ACTIVITY_COUNT activities"
    API_CALLS=$((API_CALLS + 1))
else
    echo -e "   ${RED}✗ Failed to fetch activities${NC}"
    exit 1
fi

# 2. Fetch single activity detail
echo "2/5 📋 Fetching activity detail..."
ACTIVITY_ID=$(cat Tests/Fixtures/strava_activities_response.json | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$ACTIVITY_ID" ]; then
    echo -e "   ${RED}✗ No activity ID found${NC}"
    exit 1
fi

curl -s -H "Authorization: Bearer $STRAVA_TOKEN" \
  "https://www.strava.com/api/v3/activities/$ACTIVITY_ID" \
  > Tests/Fixtures/strava_activity_detail_response.json

if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✓${NC} Recorded activity $ACTIVITY_ID"
    API_CALLS=$((API_CALLS + 1))
else
    echo -e "   ${RED}✗ Failed to fetch activity detail${NC}"
    exit 1
fi

# 3. Fetch athlete profile
echo "3/5 👤 Fetching athlete profile..."
curl -s -H "Authorization: Bearer $STRAVA_TOKEN" \
  "https://www.strava.com/api/v3/athlete" \
  > Tests/Fixtures/strava_athlete_response.json

if [ $? -eq 0 ]; then
    ATHLETE_NAME=$(cat Tests/Fixtures/strava_athlete_response.json | grep -o '"firstname":"[^"]*' | cut -d'"' -f4)
    echo -e "   ${GREEN}✓${NC} Recorded athlete profile"
    API_CALLS=$((API_CALLS + 1))
else
    echo -e "   ${RED}✗ Failed to fetch athlete profile${NC}"
    exit 1
fi

# 4. Fetch Intervals.icu activities (if token provided)
if [ -n "$INTERVALS_TOKEN" ]; then
    echo "4/5 📈 Fetching Intervals.icu activities..."
    
    # Get athlete ID first
    ATHLETE_ID=$(curl -s -u "API_KEY:$INTERVALS_TOKEN" \
      "https://intervals.icu/api/v1/athlete" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$ATHLETE_ID" ]; then
        echo -e "   ${YELLOW}⚠️  Failed to get Intervals.icu athlete ID${NC}"
    else
        curl -s -u "API_KEY:$INTERVALS_TOKEN" \
          "https://intervals.icu/api/v1/athlete/$ATHLETE_ID/activities?oldest=2025-10-01&newest=2025-10-29" \
          > Tests/Fixtures/intervals_activities_response.json
        
        if [ $? -eq 0 ]; then
            INTERVALS_COUNT=$(cat Tests/Fixtures/intervals_activities_response.json | grep -o '"id":"[^"]*' | wc -l | tr -d ' ')
            echo -e "   ${GREEN}✓${NC} Recorded $INTERVALS_COUNT activities"
            API_CALLS=$((API_CALLS + 2))  # Athlete + activities
        else
            echo -e "   ${YELLOW}⚠️  Failed to fetch Intervals.icu activities${NC}"
        fi
    fi
else
    echo "4/5 ⏭️  Skipping Intervals.icu (no token)"
fi

echo ""
echo "================================================"
echo -e "${GREEN}✅ Done!${NC}"
echo ""
echo "📊 Summary:"
echo "   API calls made: $API_CALLS"
echo "   Remaining quota: $((1000 - API_CALLS)) requests today"
echo "   Fixtures saved to: Tests/Fixtures/"
echo ""
echo "📁 Files created:"
ls -lh Tests/Fixtures/*.json | awk '{print "   " $9 " (" $5 ")"}'
echo ""
echo "🧪 Next steps:"
echo "   1. Review fixtures for sensitive data"
echo "   2. Run tests: swift run VeloReadyCoreTests"
echo "   3. Commit fixtures if tests pass"
echo ""

