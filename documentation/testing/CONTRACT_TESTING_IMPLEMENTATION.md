# Contract Testing Implementation - API Quota Conscious

**Date**: October 29, 2025  
**Constraint**: Strava API limit of 1000 requests/day **per app** (not per user)  
**Goal**: Zero-cost testing that catches API changes

---

## 🚨 Critical Constraint: API Quota

### Strava API Limits (Per App, Not Per User!)
```
15-minute limit:  100 requests
Daily limit:      1,000 requests
Monthly limit:    30,000 requests
```

**Impact on Testing**:
- ❌ Cannot run tests against real Strava API in CI (would burn quota)
- ❌ Cannot run tests on every PR (10 PRs/day = 10,000 requests if each test makes 1 call)
- ❌ Cannot run tests in parallel
- ✅ Must use **recorded responses** (zero API calls)

### Your Scaling Concern
```
Current: 1 user (you)
Future:  100 users → 100,000 requests/day
Testing: 0 API calls (must not consume quota)
```

**Bottom Line**: We **CANNOT** test against real Strava API in CI/PR workflows.

---

## ✅ Solution: Contract Testing with Recorded Responses

### Approach: Zero API Calls in Tests

```
┌─────────────────────────────────────────────────┐
│  Step 1: Record Real API Responses (Once)      │
│  - Manual: Call Strava API once                │
│  - Save response to fixtures/                  │
│  - API cost: 1 request (one-time)              │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  Step 2: Test Against Recorded Responses       │
│  - Load fixture from disk                      │
│  - Parse with our parsers                      │
│  - Verify all fields work                      │
│  - API cost: 0 requests ✅                     │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  Step 3: Update Quarterly or When API Changes  │
│  - Re-record responses (manual)                │
│  - API cost: 1-2 requests (quarterly)          │
└─────────────────────────────────────────────────┘
```

**Total API Cost**: 
- Initial setup: 3-5 requests (one-time)
- Ongoing: 0 requests per test run ✅
- Quarterly updates: 3-5 requests
- **Annual total**: ~15-20 requests (0.002% of quota)

---

## 📁 Implementation Plan

### Step 1: Record Real API Responses (One-Time, Manual)

Create a script to record responses:

```bash
#!/bin/bash
# Scripts/record-api-fixtures.sh
# Run this ONCE to record real API responses
# Cost: 3 API requests total

echo "🎬 Recording API fixtures..."
echo "⚠️  This will make 3 Strava API requests"
echo ""

# 1. Fetch recent activities (most common endpoint)
echo "1/3 Fetching activities..."
curl -H "Authorization: Bearer $STRAVA_TOKEN" \
  "https://www.strava.com/api/v3/athlete/activities?per_page=10" \
  > Tests/Fixtures/strava_activities_response.json

# 2. Fetch single activity detail (for full field coverage)
echo "2/3 Fetching activity detail..."
ACTIVITY_ID=$(jq -r '.[0].id' Tests/Fixtures/strava_activities_response.json)
curl -H "Authorization: Bearer $STRAVA_TOKEN" \
  "https://www.strava.com/api/v3/activities/$ACTIVITY_ID" \
  > Tests/Fixtures/strava_activity_detail_response.json

# 3. Fetch athlete profile
echo "3/3 Fetching athlete profile..."
curl -H "Authorization: Bearer $STRAVA_TOKEN" \
  "https://www.strava.com/api/v3/athlete" \
  > Tests/Fixtures/strava_athlete_response.json

echo "✅ Done! API cost: 3 requests"
echo "📊 Remaining quota: $(expr 1000 - 3) requests today"
```

**Run this script**:
- Once during initial setup
- Quarterly to refresh (or when Strava announces API changes)
- Cost: 3 requests total

---

### Step 2: Add Contract Tests (Zero API Cost)

```swift
// VeloReadyCore/Tests/APIContractTests.swift

import Foundation

extension VeloReadyCoreTests {
    
    // MARK: - Strava Contract Tests
    
    static func testStravaActivitiesContract() async -> Bool {
        print("\n🧪 Test 39: Strava Activities API Contract")
        print("   Testing against REAL Strava API response...")
        
        // Load recorded response (zero API calls!)
        guard let fixture = loadFixture("strava_activities_response.json") else {
            print("   ❌ FAIL: Fixture not found")
            return false
        }
        
        // Parse with our parser
        do {
            let activities = try JSONDecoder().decode([StravaActivity].self, from: fixture)
            
            guard activities.count > 0 else {
                print("   ❌ FAIL: No activities in response")
                return false
            }
            
            // Verify critical fields exist in REAL API response
            for (index, activity) in activities.enumerated() {
                guard !activity.id.isEmpty else {
                    print("   ❌ FAIL: Activity[\(index)].id missing")
                    return false
                }
                
                guard activity.name != nil else {
                    print("   ❌ FAIL: Activity[\(index)].name missing")
                    return false
                }
                
                guard activity.type != nil else {
                    print("   ❌ FAIL: Activity[\(index)].type missing")
                    return false
                }
                
                guard activity.startDate != nil else {
                    print("   ❌ FAIL: Activity[\(index)].start_date missing")
                    return false
                }
                
                // Optional fields (should exist for cycling activities)
                if activity.type == "Ride" {
                    if activity.distance == nil {
                        print("   ⚠️  WARNING: Ride missing distance")
                    }
                    if activity.movingTime == nil {
                        print("   ⚠️  WARNING: Ride missing moving_time")
                    }
                }
            }
            
            print("   ✅ PASS: Strava API contract verified")
            print("      Activities: \(activities.count)")
            print("      All required fields present: ✓")
            print("      API calls made: 0 ✅")
            return true
            
        } catch {
            print("   ❌ FAIL: Failed to parse Strava response")
            print("      Error: \(error)")
            print("      This means Strava API format has CHANGED!")
            return false
        }
    }
    
    static func testStravaActivityDetailContract() async -> Bool {
        print("\n🧪 Test 40: Strava Activity Detail API Contract")
        print("   Testing against REAL Strava activity detail...")
        
        guard let fixture = loadFixture("strava_activity_detail_response.json") else {
            print("   ❌ FAIL: Fixture not found")
            return false
        }
        
        do {
            let activity = try JSONDecoder().decode(StravaActivity.self, from: fixture)
            
            // Verify detailed fields exist
            guard activity.averageSpeed != nil || activity.maxSpeed != nil else {
                print("   ❌ FAIL: Speed data missing from detail response")
                return false
            }
            
            guard activity.calories != nil else {
                print("   ⚠️  WARNING: Calories missing from detail response")
            }
            
            // Verify power data exists (if activity has power)
            if activity.deviceWatts == true {
                guard activity.averageWatts != nil else {
                    print("   ❌ FAIL: device_watts=true but average_watts missing")
                    return false
                }
            }
            
            print("   ✅ PASS: Strava activity detail contract verified")
            print("      API calls made: 0 ✅")
            return true
            
        } catch {
            print("   ❌ FAIL: Failed to parse activity detail")
            print("      Error: \(error)")
            return false
        }
    }
    
    static func testIntervalsAPIContract() async -> Bool {
        print("\n🧪 Test 41: Intervals.icu API Contract")
        print("   Testing against REAL Intervals.icu response...")
        
        guard let fixture = loadFixture("intervals_activities_response.json") else {
            print("   ❌ FAIL: Fixture not found")
            return false
        }
        
        do {
            // Parse multiple activities
            let jsonString = String(data: fixture, encoding: .utf8)!
            let jsonArray = try JSONSerialization.jsonObject(with: fixture) as! [[String: Any]]
            
            for (index, activityDict) in jsonArray.enumerated() {
                // Verify critical fields
                guard activityDict["id"] != nil else {
                    print("   ❌ FAIL: Activity[\(index)].id missing")
                    return false
                }
                
                guard activityDict["start_date_local"] != nil else {
                    print("   ❌ FAIL: Activity[\(index)].start_date_local missing")
                    return false
                }
                
                // Check for TSS field (critical for our calculations!)
                if activityDict["icu_training_load"] == nil && activityDict["training_stress_score"] == nil {
                    print("   ⚠️  WARNING: Activity[\(index)] missing TSS field")
                    print("      Checked: icu_training_load, training_stress_score")
                }
            }
            
            print("   ✅ PASS: Intervals.icu API contract verified")
            print("      Activities: \(jsonArray.count)")
            print("      API calls made: 0 ✅")
            return true
            
        } catch {
            print("   ❌ FAIL: Failed to parse Intervals.icu response")
            print("      Error: \(error)")
            return false
        }
    }
    
    // MARK: - Helper: Load Fixture
    
    static func loadFixture(_ filename: String) -> Data? {
        // Try to load from Tests/Fixtures/
        let fixturesPath = "Tests/Fixtures/\(filename)"
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: fixturesPath)) {
            return data
        }
        
        // Try relative to current directory
        if let data = try? Data(contentsOf: URL(fileURLWithPath: "../Tests/Fixtures/\(filename)")) {
            return data
        }
        
        return nil
    }
}
```

**API Cost**: 0 requests per test run ✅

---

### Step 3: Add Fixtures to Test Runner

Update the main test runner:

```swift
// VeloReadyCore/Tests/VeloReadyCoreTests.swift

@main
struct VeloReadyCoreTests {
    static func main() async {
        // ... existing tests ...
        
        // Test 39: Strava Activities Contract
        if await testStravaActivitiesContract() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 40: Strava Activity Detail Contract
        if await testStravaActivityDetailContract() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Test 41: Intervals.icu Contract
        if await testIntervalsAPIContract() {
            passed += 1
        } else {
            failed += 1
        }
        
        // Summary
        print("\n===================================================")
        print("✅ Tests passed: \(passed)")
        if failed > 0 {
            print("❌ Tests failed: \(failed)")
        }
        print("===================================================")
        print("📊 API Quota Used: 0 requests ✅")
    }
}
```

---

## 📊 API Quota Impact Analysis

### Current Approach (38 Tests)
```
API Calls per Test Run: 0
API Calls per PR: 0
API Calls per Day (10 PRs): 0
Monthly Cost: 0 requests
% of Quota: 0%
```

### With Contract Testing (41 Tests)
```
API Calls per Test Run: 0 ✅
API Calls per PR: 0 ✅
API Calls per Day (10 PRs): 0 ✅
Monthly Cost: 0 requests ✅
% of Quota: 0% ✅

One-time Setup Cost: 3-5 requests
Quarterly Updates: 3-5 requests
Annual Total: ~15-20 requests (0.002% of quota)
```

### Alternative: Real API Tests (NOT RECOMMENDED)
```
API Calls per Test Run: 10 ❌
API Calls per PR: 10 ❌
API Calls per Day (10 PRs): 100 ❌ (10% of daily quota!)
Monthly Cost: 3,000 requests ❌ (10% of monthly quota!)
```

**Verdict**: Contract testing uses **0% of quota** during normal development! ✅

---

## 🔄 Updating Fixtures

### When to Update Fixtures

1. **Quarterly** (proactive):
   ```bash
   # Run once per quarter
   ./Scripts/record-api-fixtures.sh
   # Cost: 3 requests
   ```

2. **When Strava announces API changes** (reactive):
   ```bash
   # Strava blog: "We're updating our API"
   ./Scripts/record-api-fixtures.sh
   # Cost: 3 requests
   ```

3. **When tests start failing in production** (reactive):
   ```bash
   # User reports: "Activities not syncing"
   ./Scripts/record-api-fixtures.sh
   # Cost: 3 requests
   # Update tests to match new format
   ```

### Automation (Optional)

Add a **scheduled CI job** that runs once per month:

```yaml
# .github/workflows/update-fixtures.yml
name: Update API Fixtures

on:
  schedule:
    - cron: '0 0 1 * *'  # First day of month
  workflow_dispatch:  # Manual trigger

jobs:
  update-fixtures:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Record API fixtures
        env:
          STRAVA_TOKEN: ${{ secrets.STRAVA_TEST_TOKEN }}
        run: |
          ./Scripts/record-api-fixtures.sh
      
      - name: Run tests with new fixtures
        run: swift run VeloReadyCoreTests
      
      - name: Create PR if fixtures changed
        if: ${{ hashFiles('Tests/Fixtures/**') != hashFiles('Tests/Fixtures/**@{1 day ago}') }}
        run: |
          git checkout -b update-api-fixtures
          git add Tests/Fixtures/
          git commit -m "chore: Update API fixtures (monthly refresh)"
          gh pr create --title "Update API Fixtures" --body "Automated monthly refresh"
```

**API Cost**: 3 requests per month = 36 requests per year (0.1% of quota)

---

## 🎯 What This Catches

### Example 1: Strava Renames Field

**Scenario**: Strava changes `icu_training_load` → `training_stress_score`

**Before Contract Tests:**
```
1. Change happens in Strava API
2. Our app continues using old field name
3. TSS becomes null for all new activities
4. Users report "Training load is 0"
5. We investigate, find the issue
Time to detect: Days/weeks
```

**With Contract Tests:**
```
1. Change happens in Strava API
2. We re-record fixtures (3 API calls)
3. Contract test fails: "icu_training_load field missing"
4. We update parser to check both old and new field names
5. Deploy fix proactively
Time to detect: Minutes (when we update fixtures)
```

### Example 2: Strava Adds Required Field

**Scenario**: Strava makes `athlete_id` a required field

**Before Contract Tests:**
```
1. Change happens
2. Our parsing works (nullable field)
3. But we never use athlete_id
4. No impact... until we need it later
5. Suddenly app breaks when we try to use it
```

**With Contract Tests:**
```
1. Change happens
2. We re-record fixtures
3. Test sees new `athlete_id` field
4. We document it: "New field available"
5. We can proactively use it if needed
```

---

## 📈 Scaling Considerations

### As Your User Base Grows

**10 users:**
- App usage: ~100 requests/day
- Test usage: 0 requests/day ✅
- Total: 100 requests (10% of quota)

**100 users:**
- App usage: ~1,000 requests/day
- Test usage: 0 requests/day ✅
- Total: 1,000 requests (100% of quota) ⚠️

**1,000 users:**
- App usage: ~10,000 requests/day ❌
- Test usage: 0 requests/day ✅
- **Problem**: You'll hit the quota from user traffic alone!

**Solution**: Implement aggressive caching (which we already test!)

---

## ✅ Implementation Checklist

### Phase 1: Setup (30 minutes)

- [ ] Create `Tests/Fixtures/` directory
- [ ] Create `Scripts/record-api-fixtures.sh`
- [ ] Run script once (cost: 3 API requests)
- [ ] Verify fixtures are saved

### Phase 2: Add Tests (2 hours)

- [ ] Add `testStravaActivitiesContract()`
- [ ] Add `testStravaActivityDetailContract()`
- [ ] Add `testIntervalsAPIContract()`
- [ ] Add `loadFixture()` helper
- [ ] Update test runner to include new tests

### Phase 3: Verify (15 minutes)

- [ ] Run `swift run VeloReadyCoreTests`
- [ ] Verify all 41 tests pass
- [ ] Confirm 0 API calls made

### Phase 4: Documentation (15 minutes)

- [ ] Document fixture update process
- [ ] Add README in `Tests/Fixtures/`
- [ ] Set calendar reminder for quarterly updates

**Total Time**: 3 hours  
**Total API Cost**: 3 requests (one-time)  
**Ongoing API Cost**: 0 requests per test run ✅

---

## 🎯 Recommendation

**Proceed with Contract Testing:**

**Pros:**
- ✅ **Zero API quota usage** during development
- ✅ Catches real API format changes
- ✅ Fast (no network I/O)
- ✅ Reliable (no flaky network issues)
- ✅ Easy to update (re-record quarterly)

**Cons:**
- ⚠️ Requires manual fixture updates
- ⚠️ Doesn't test authentication flow
- ⚠️ Doesn't test rate limiting

**Bottom Line**: This is the **only** viable approach given your API quota constraints. Real API integration tests would burn through your quota too quickly.

---

## 📊 Final Comparison

| Approach | API Cost/Test | API Cost/Day | Catches Format Changes | Viable? |
|----------|---------------|--------------|------------------------|---------|
| **Contract Testing** | 0 | 0 | ✅ (when fixtures updated) | ✅ YES |
| Real API Tests | 10 | 100+ | ✅ (immediately) | ❌ NO (quota) |
| Mock Server | 0 | 0 | ⚠️ (if mocks drift) | ✅ YES |
| No Integration Tests | 0 | 0 | ❌ | ❌ NO |

**Winner**: Contract Testing + Mock Server (Phase 2)

---

*Ready to implement? This will add 3 tests with ZERO API quota impact.* 🚀

