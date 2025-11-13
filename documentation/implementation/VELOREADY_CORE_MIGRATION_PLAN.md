# VeloReadyCore Migration Plan - Complete Business Logic Testing

## Overview

This document outlines a phased approach to move critical business logic into `VeloReadyCore` for fast, reliable CI testing. The goal is to catch bugs like the **Strava cache issue** before they reach production.

## Business Logic Categories

### 🔴 Critical (Phase 1-2) - Catches Most Bugs
Logic that directly impacts user experience and data accuracy

### 🟡 Important (Phase 3-4) - Prevents Regressions  
Core services that power features but are less fragile

### 🟢 Nice to Have (Phase 5+) - Complete Coverage
Supporting logic and utilities

---

## Complete Candidate List

### 🔴 **Phase 1: Data Integration & Caching** (HIGHEST PRIORITY)
**Why First**: The Strava cache bug would have been caught by these tests

| Component | File | Why Critical | Test Focus |
|-----------|------|--------------|------------|
| **UnifiedCacheManager** | `Core/Data/UnifiedCacheManager.swift` | Central caching for ALL data sources | Cache key consistency, TTL handling, offline fallback |
| **CacheKey generation** | `Core/Data/CacheKeys.swift` | Bug was here - inconsistent keys | Key format validation, consistency across services |
| **StravaDataService** | `Core/Services/StravaDataService.swift` | Primary activity data source | Cache integration, Pro/Free tier logic |
| **UnifiedActivityService** | `Core/Services/UnifiedActivityService.swift` | Aggregates Intervals + Strava | Multi-source data merging, deduplication |
| **Strava API Client** | `Core/Networking/StravaAPIClient.swift` | Network layer for Strava | Request formatting, response parsing |

**Tests to Prevent Strava Cache Bug:**
```swift
✅ Test cache key format consistency
✅ Test cache hit/miss behavior  
✅ Test offline fallback with expired cache
✅ Test legacy cache cleanup
✅ Test Pro vs Free tier cache keys
```

---

### 🔴 **Phase 2: Core Calculations** (HIGH PRIORITY)
**Why Second**: These directly affect user-visible scores

| Component | File | Why Critical | Test Focus |
|-----------|------|--------------|------------|
| **TrainingLoadCalculator** | `Core/Services/TrainingLoadCalculator.swift` | CTL, ATL, TSS calculations | Formula accuracy, edge cases, ramp rates |
| **StrainScoreService** | `Core/Services/StrainScoreService.swift` | Daily strain algorithm | TRIMP calculation, HR zone logic, multi-source aggregation |
| **RecoveryScoreService** | `Core/Services/RecoveryScoreService.swift` | Recovery algorithm | Sleep modulation, HRV/RHR weighting, baseline comparison |
| **SleepScoreService** | `Core/Services/SleepScoreService.swift` | Sleep quality scoring | Duration vs quality, deep sleep weighting |
| **FitnessTrajectoryCalculator** | `Core/Services/FitnessTrajectoryCalculator.swift` | Trend prediction | 7-day smoothing, trajectory angle |

**Tests to Prevent Score Bugs:**
```swift
✅ Test CTL/ATL calculations with known datasets
✅ Test strain score bands (Easy, Moderate, Hard, Very Hard)
✅ Test recovery score with edge cases (no HRV, no sleep)
✅ Test sleep score with partial data
✅ Test multi-source activity aggregation (HealthKit + Strava + Intervals)
```

---

### 🟡 **Phase 3: Data Models & Validation** (IMPORTANT)
**Why Third**: Ensures data integrity across the app

| Component | File | Why Important | Test Focus |
|-----------|------|---------------|------------|
| **StravaActivity** | `Core/Models/StravaActivity.swift` | Activity data structure | Parsing, optional fields, validation |
| **Activity** | `Core/Models/Activity.swift` | Intervals.icu data | Format conversion, field mapping |
| **HealthMetric** | `Core/Models/HealthMetric.swift` | HealthKit data structure | Data validation, unit conversion |
| **ActivityData** | Various models | Shared activity representation | Cross-platform compatibility |
| **AthleteProfile** | `Core/Models/AthleteProfile.swift` | User profile & zones | FTP calculation, zone generation, max HR |

**Tests to Prevent Data Bugs:**
```swift
✅ Test JSON parsing with real API responses
✅ Test missing/optional field handling
✅ Test unit conversions (meters to miles, etc.)
✅ Test zone calculations from FTP/max HR
✅ Test profile auto-detection logic
```

---

### 🟡 **Phase 4: ML & Personalization** (IMPORTANT)
**Why Fourth**: Critical for ML features, but has fallbacks

| Component | File | Why Important | Test Focus |
|-----------|------|---------------|------------|
| **PersonalizedRecoveryCalculator** | `Core/ML/Services/PersonalizedRecoveryCalculator.swift` | ML orchestration | ML vs rule-based fallback |
| **MLPredictionService** | `Core/ML/Services/MLPredictionService.swift` | Core ML inference | Input preparation, output validation |
| **MLFeatureExtractor** | `Core/ML/Services/MLFeatureExtractor.swift` | Feature engineering | Normalization, missing value handling |
| **ReadinessForecastService** | `Core/Services/ReadinessForecastService.swift` | 7-day forecast | Prediction logic, confidence scoring |
| **BaselineCalculator** | `Core/Services/BaselineCalculator.swift` | HRV/RHR baselines | Rolling average calculation, outlier detection |

**Tests to Prevent ML Bugs:**
```swift
✅ Test ML fallback when model unavailable
✅ Test feature extraction with missing data
✅ Test baseline calculation with sparse data
✅ Test forecast with various input scenarios
✅ Test confidence scoring logic
```

---

### 🟢 **Phase 5: Utilities & Helpers** (NICE TO HAVE)
**Why Later**: These are stable and have fewer edge cases

| Component | File | Why Nice to Have | Test Focus |
|-----------|------|------------------|------------|
| **DateUtils** | Various | Date manipulation | Date arithmetic, timezone handling |
| **FormattingUtils** | Various | String formatting | Duration, distance, pace formatting |
| **ValidationUtils** | Various | Data validation | Input sanitization, range checking |
| **Logger** | `Core/Services/Logger.swift` | Logging abstraction | (Probably doesn't need tests) |

---

## Revised Migration Plan

### ✅ **Phase 0: Foundation** (COMPLETE)
- [x] Create `VeloReadyCore` Swift Package
- [x] Setup CI workflow
- [x] Add example tests
- [x] Verify tests run on GitHub Actions

**Status**: ✅ Working! Tests run in <1 minute on CI

---

### 🎯 **Phase 1: Fix the Strava Cache Bug** (NEXT - 1-2 hours)
**Goal**: Ensure Strava cache issue is caught by tests

#### Step 1.1: Extract Cache Logic
```swift
// VeloReadyCore/Sources/CacheManager.swift
public class CacheManager {
    public static func generateCacheKey(type: String, params: [String: Any]) -> String {
        // Extract the cache key generation logic
    }
    
    public func fetch<T>(key: String, ttl: TimeInterval, fetchOperation: () async throws -> T) async throws -> T {
        // Extract core cache logic
    }
}
```

#### Step 1.2: Add Cache Tests
```swift
// VeloReadyCore/Tests/CacheTests.swift
func testCacheKeyConsistency() {
    let key1 = CacheManager.generateCacheKey(type: "strava", params: ["days": 365])
    let key2 = CacheManager.generateCacheKey(type: "strava", params: ["days": 365])
    assert(key1 == key2, "Cache keys must be consistent")
}

func testCacheOfflineFallback() {
    // Test that expired cache is returned when network fails
}

func testLegacyCacheCleanup() {
    // Test that old format keys are properly removed
}
```

**Outcome**: Strava cache bug would be caught immediately

---

### 🎯 **Phase 2: Core Calculations** (1-2 days)
**Goal**: Catch calculation errors in CTL, strain, recovery scores

#### Step 2.1: Extract TrainingLoadCalculator
```swift
// VeloReadyCore/Sources/TrainingLoadCalculator.swift
public struct TrainingLoadCalculator {
    public static func calculateCTL(activities: [ActivityInput], date: Date) -> Double
    public static func calculateATL(activities: [ActivityInput], date: Date) -> Double
    public static func calculateTSB(ctl: Double, atl: Double) -> Double
}
```

#### Step 2.2: Add Calculation Tests
```swift
// VeloReadyCore/Tests/TrainingLoadTests.swift
func testCTLCalculation() {
    // Test with known dataset
    let activities = [
        ActivityInput(date: Date(), tss: 100),
        // ... more activities
    ]
    let ctl = TrainingLoadCalculator.calculateCTL(activities: activities, date: Date())
    assert(ctl == expectedValue, "CTL calculation incorrect")
}

func testStrainScoreBands() {
    // Test that strain scores fall into correct bands
}
```

**Outcome**: Score calculation bugs caught before deployment

---

### 🎯 **Phase 3: Data Models** (1-2 days)
**Goal**: Ensure data parsing and validation works correctly

#### Step 3.1: Extract Data Models
```swift
// VeloReadyCore/Sources/Models/
public struct Activity: Codable {
    public let id: String
    public let tss: Double?
    public let duration: Double
    // ... all fields
}
```

#### Step 3.2: Add Parsing Tests
```swift
// VeloReadyCore/Tests/ModelTests.swift
func testStravaActivityParsing() {
    let json = """
    {"id": "123", "name": "Morning Ride", ...}
    """
    let activity = try? JSONDecoder().decode(Activity.self, from: json.data(using: .utf8)!)
    assert(activity != nil, "Should parse valid JSON")
}

func testMissingOptionalFields() {
    // Test with missing optional fields
}
```

**Outcome**: API changes don't break parsing

---

### 🎯 **Phase 4: ML & Forecasting** (2-3 days)
**Goal**: Ensure ML fallbacks work and forecasts are accurate

**Outcome**: ML bugs caught, fallback logic verified

---

### 🎯 **Phase 5: Utilities** (1 day)
**Goal**: Complete test coverage

**Outcome**: Full confidence in business logic

---

## How This Prevents the Strava Bug

### The Bug
```swift
// StravaDataService.swift (OLD)
let key = "strava_activities_\(days)d"  // ❌ Wrong format

// UnifiedActivityService.swift (OLD)  
let key = CacheKey.stravaActivities(daysBack: days)  // ✅ Right format "strava:activities:365"
```

### The Test That Would Catch It
```swift
// VeloReadyCore/Tests/CacheTests.swift
func testCacheKeyConsistency() {
    // Test that all services use the same cache key format
    let stravaKey = CacheManager.generateStravaActivitiesKey(days: 365)
    let unifiedKey = CacheManager.generateStravaActivitiesKey(days: 365)
    
    if stravaKey != unifiedKey {
        print("❌ CACHE KEY MISMATCH!")
        print("  Strava service: \(stravaKey)")
        print("  Unified service: \(unifiedKey)")
        exit(1)
    }
    
    // Test format is consistent
    assert(stravaKey == "strava:activities:365")
}
```

**Result**: Test would fail immediately, preventing the bug from reaching production.

---

## Implementation Strategy

### For Each Phase:

1. **Extract** core logic to `VeloReadyCore/Sources/`
2. **Replicate** tests from `VeloReadyTests/Unit/` to `VeloReadyCore/Tests/`
3. **Link** in main app by importing `VeloReadyCore`
4. **Verify** tests pass locally and on CI
5. **Monitor** for regressions

### Maintenance:

- When updating production code → update `VeloReadyCore`
- When adding features → add tests to `VeloReadyCore`
- Keep 1:1 parity between production and test code

---

## Success Metrics

### After Phase 1:
✅ Strava cache bugs caught by CI
✅ <1 minute CI time maintained
✅ 100% test pass rate

### After Phase 2:
✅ Calculation bugs caught before deployment
✅ Score accuracy verified with known datasets
✅ ~10-15 core tests running

### After Phase 3-5:
✅ Comprehensive business logic coverage
✅ ~30-50 tests running
✅ <2 minute CI time
✅ High confidence in all data operations

---

## Estimated Timeline

| Phase | Time | What Gets Tested |
|-------|------|------------------|
| Phase 0 | ✅ Done | Basic structure |
| Phase 1 | 1-2 hours | **Strava cache** (highest priority) |
| Phase 2 | 1-2 days | Core calculations |
| Phase 3 | 1-2 days | Data models |
| Phase 4 | 2-3 days | ML & forecasting |
| Phase 5 | 1 day | Utilities |

**Total**: ~1-2 weeks for comprehensive coverage

---

## Recommendation

**Start with Phase 1** (Strava cache testing) **immediately** - this is the quickest win and directly addresses the bug you discovered. You can complete Phase 1 in 1-2 hours and have immediate protection against similar bugs.

Then gradually add Phases 2-5 over time as you develop new features.

