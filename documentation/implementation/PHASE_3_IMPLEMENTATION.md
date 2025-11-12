# Phase 3: Data Models & Validation - Implementation Plan

**Date**: October 29, 2025  
**Status**: Starting  
**Goal**: Extract core data models to VeloReadyCore for platform independence and testability

---

## 🎯 Overview

Phase 3 focuses on extracting data models from the iOS app into `VeloReadyCore`. This ensures:

1. **Platform Independence**: Models can be reused in iOS, watchOS, or backend
2. **Validation Logic**: Data integrity is tested independently
3. **Type Safety**: Compile-time guarantees for data structures
4. **Testability**: Parse real API responses and test edge cases

---

## 📊 Current State Analysis

### What We Have (Phase 1 & 2)

✅ **Calculation Functions** with result structs:
- `TrainingLoadCalculations` - Returns raw `Double` values (CTL, ATL, TSB)
- `StrainCalculations.StrainResult` - Returns `(score: Double, band: StrainBand)`
- `RecoveryCalculations.RecoveryScore` - Returns struct with breakdown
- `SleepCalculations.SleepScore` - Returns struct with breakdown

✅ **Enums** already in VeloReadyCore:
- `StrainBand`
- `RecoveryBand`
- `SleepBand`

### What Phase 3 Needs

The iOS app has several data models with platform dependencies (UIKit, SwiftUI, HealthKit) that need to be made platform-agnostic:

1. **Activity Models** - `UnifiedActivity`, `Activity`, `StravaActivity`
2. **Score Models** - `RecoveryScore`, `SleepScore`, `StrainScore`, `ReadinessScore`
3. **Profile Models** - `AthleteProfile`, `UserSettings`
4. **Health Models** - `HealthMetric`, `SleepData`

---

## 🚧 Phase 3 Strategy: Incremental Approach

Rather than extracting all models at once, let's use a **pragmatic, test-driven approach**:

### Option A: Extract Only What's Needed for Testing
**Focus**: Extract models needed to test data validation and parsing
- Smaller scope
- Faster to implement
- Test real-world data (API responses, HealthKit data)

### Option B: Full Model Extraction
**Focus**: Move all data models to VeloReadyCore
- Larger scope
- More refactoring required
- Full platform independence

---

## 🎯 Recommended Approach: Option A (Pragmatic)

Let's focus on **data validation and parsing tests** for the most critical data sources:

### Phase 3.1: Activity Data Validation (1-2 hours)

**Goal**: Ensure activity data from Intervals.icu and Strava is parsed correctly

#### Files to Extract:
1. `ActivityData.swift` - Platform-agnostic activity representation
2. `ActivityParser.swift` - Parsing logic for API responses

#### Tests to Add:
```swift
// VeloReadyCore/Tests/ActivityDataTests.swift

func testActivityParsing() {
    // Test parsing real Intervals.icu JSON
    let json = """
    {
        "id": "12345",
        "start_date_local": "2025-10-29T08:00:00",
        "type": "Ride",
        "moving_time": 3600,
        "distance": 30000,
        "average_heartrate": 145,
        "average_watts": 200,
        "icu_training_load": 85.5
    }
    """
    
    let activity = try ActivityParser.parseIntervals(json)
    assert(activity.tss == 85.5)
    assert(activity.duration == 3600)
}

func testMissingOptionalFields() {
    // Test that missing power/HR doesn't crash
}

func testInvalidData() {
    // Test that malformed JSON is handled gracefully
}
```

---

### Phase 3.2: Athlete Profile Validation (1 hour)

**Goal**: Ensure FTP, zones, and profile data is validated correctly

#### Files to Extract:
1. `AthleteProfile.swift` - Athlete zones and metrics
2. `ZoneCalculations.swift` - Power/HR zone calculations

#### Tests to Add:
```swift
// VeloReadyCore/Tests/AthleteProfileTests.swift

func testPowerZoneCalculation() {
    let ftp = 250.0
    let zones = ZoneCalculations.calculatePowerZones(ftp: ftp)
    
    // Coggan zones:
    // Z1: < 55% FTP = <137.5W
    // Z2: 56-75% FTP = 140-187.5W
    // Z3: 76-90% FTP = 190-225W
    // Z4: 91-105% FTP = 227.5-262.5W
    // Z5: 106-120% FTP = 265-300W
    // Z6: >121% FTP = >302.5W
    
    assert(zones[0] == 137.5, "Z1 threshold")
    assert(zones[1] == 187.5, "Z2 threshold")
    assert(zones[2] == 225.0, "Z3 threshold")
}

func testHeartRateZoneCalculation() {
    let maxHR = 190.0
    let zones = ZoneCalculations.calculateHRZones(maxHR: maxHR)
    // Test zone boundaries
}

func testInvalidFTP() {
    // Test that negative/zero FTP is handled
}
```

---

### Phase 3.3: Health Data Validation (1 hour)

**Goal**: Ensure HealthKit data is processed correctly

#### Files to Extract:
1. `HealthMetric.swift` - Platform-agnostic health data
2. `HealthDataValidator.swift` - Validation logic

#### Tests to Add:
```swift
// VeloReadyCore/Tests/HealthDataTests.swift

func testHRVValidation() {
    // Test that HRV values are in valid range (20-100ms)
    assert(HealthDataValidator.isValidHRV(50.0) == true)
    assert(HealthDataValidator.isValidHRV(-10.0) == false)
    assert(HealthDataValidator.isValidHRV(200.0) == false)
}

func testRHRValidation() {
    // Test that RHR values are in valid range (30-120 bpm)
}

func testSleepDurationValidation() {
    // Test that sleep duration is reasonable (0-16 hours)
}

func testOutlierDetection() {
    // Test that extreme outliers are flagged
    let hrv = [50, 52, 48, 51, 10] // 10 is an outlier
    assert(HealthDataValidator.hasOutlier(hrv) == true)
}
```

---

## 📈 Success Metrics

### Test Coverage Goals:
- **Activity Parsing**: 6 tests (valid, missing fields, invalid, edge cases)
- **Profile Validation**: 6 tests (zones, FTP, HR, invalid data)
- **Health Data**: 6 tests (HRV, RHR, sleep, outliers)
- **Total**: ~18 new tests

### Performance:
- Test execution: **<1 second** (pure data validation, no I/O)
- Total VeloReadyCore tests: **31 + 18 = 49 tests**
- Total time: **~8-9 seconds** (still <10s!)

### Impact:
- ✅ Catch data parsing bugs before they reach production
- ✅ Validate API responses match expectations
- ✅ Ensure health data is within reasonable ranges
- ✅ Test zone calculations are correct

---

## 🛠 Implementation Steps

### Step 1: Create Platform-Agnostic Activity Model (30 min)

```swift
// VeloReadyCore/Sources/Models/ActivityData.swift

public struct ActivityData {
    public let id: String
    public let startDate: Date
    public let type: String
    public let duration: TimeInterval
    public let distance: Double? // meters
    public let tss: Double?
    public let averagePower: Double?
    public let normalizedPower: Double?
    public let averageHeartRate: Double?
    public let maxHeartRate: Double?
    public let intensityFactor: Double?
    public let calories: Int?
    
    public init(
        id: String,
        startDate: Date,
        type: String,
        duration: TimeInterval,
        distance: Double? = nil,
        tss: Double? = nil,
        averagePower: Double? = nil,
        normalizedPower: Double? = nil,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        intensityFactor: Double? = nil,
        calories: Int? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.type = type
        self.duration = duration
        self.distance = distance
        self.tss = tss
        self.averagePower = averagePower
        self.normalizedPower = normalizedPower
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.intensityFactor = intensityFactor
        self.calories = calories
    }
}
```

### Step 2: Create Activity Parser (30 min)

```swift
// VeloReadyCore/Sources/Parsing/ActivityParser.swift

import Foundation

public struct ActivityParser {
    
    public enum ParsingError: Error {
        case invalidJSON
        case missingRequiredField(String)
        case invalidDateFormat
    }
    
    /// Parse Intervals.icu activity JSON
    public static func parseActivity(_ json: String) throws -> ActivityData {
        guard let data = json.data(using: .utf8) else {
            throw ParsingError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(IntervalsResponse.self, from: data)
        
        return ActivityData(
            id: response.id,
            startDate: response.start_date_local,
            type: response.type,
            duration: TimeInterval(response.moving_time),
            distance: response.distance,
            tss: response.icu_training_load,
            averagePower: response.average_watts,
            normalizedPower: response.weighted_average_watts,
            averageHeartRate: response.average_heartrate,
            maxHeartRate: response.max_heartrate
        )
    }
    
    private struct IntervalsResponse: Codable {
        let id: String
        let start_date_local: Date
        let type: String
        let moving_time: Int
        let distance: Double?
        let icu_training_load: Double?
        let average_watts: Double?
        let weighted_average_watts: Double?
        let average_heartrate: Double?
        let max_heartrate: Double?
    }
}
```

### Step 3: Add Tests (30 min)

```swift
// VeloReadyCore/Tests/ActivityParsingTests.swift

import Foundation

extension VeloReadyCoreTests {
    
    static func testActivityParsing() async -> Bool {
        print("\n🧪 Test 32: Intervals.icu Activity Parsing")
        print("   Testing JSON parsing for Intervals activities...")
        
        let json = """
        {
            "id": "12345",
            "start_date_local": "2025-10-29T08:00:00Z",
            "type": "Ride",
            "moving_time": 3600,
            "distance": 30000.0,
            "average_heartrate": 145.0,
            "average_watts": 200.0,
            "weighted_average_watts": 210.0,
            "icu_training_load": 85.5
        }
        """
        
        do {
            let activity = try ActivityParser.parseActivity(json)
            
            guard activity.id == "12345" else {
                print("   ❌ FAIL: ID mismatch")
                return false
            }
            
            guard activity.tss == 85.5 else {
                print("   ❌ FAIL: TSS mismatch")
                return false
            }
            
            guard activity.duration == 3600 else {
                print("   ❌ FAIL: Duration mismatch")
                return false
            }
            
            guard activity.averagePower == 200.0 else {
                print("   ❌ FAIL: Power mismatch")
                return false
            }
            
            print("   ✅ PASS: Intervals activity parsed correctly")
            return true
        } catch {
            print("   ❌ FAIL: Parsing error: \(error)")
            return false
        }
    }
    
    // More tests...
}
```

### Step 4: Add Zone Calculations (30 min)

```swift
// VeloReadyCore/Sources/Calculations/ZoneCalculations.swift

public struct ZoneCalculations {
    
    /// Calculate Coggan power zones from FTP
    /// Returns zone boundaries: [Z1/Z2, Z2/Z3, Z3/Z4, Z4/Z5, Z5/Z6]
    public static func calculatePowerZones(ftp: Double) -> [Double] {
        return [
            ftp * 0.55,  // Z1 upper bound (Active Recovery)
            ftp * 0.75,  // Z2 upper bound (Endurance)
            ftp * 0.90,  // Z3 upper bound (Tempo)
            ftp * 1.05,  // Z4 upper bound (Threshold)
            ftp * 1.20   // Z5 upper bound (VO2max)
            // Z6 (Anaerobic) is > 1.20 * FTP
        ]
    }
    
    /// Calculate heart rate zones from max HR
    public static func calculateHRZones(maxHR: Double) -> [Double] {
        return [
            maxHR * 0.60,  // Z1 upper bound
            maxHR * 0.70,  // Z2 upper bound
            maxHR * 0.80,  // Z3 upper bound
            maxHR * 0.90,  // Z4 upper bound
            maxHR * 0.95   // Z5 upper bound
        ]
    }
    
    /// Validate FTP is within reasonable range
    public static func isValidFTP(_ ftp: Double) -> Bool {
        return ftp > 0 && ftp < 500 // Reasonable range for cyclists
    }
}
```

---

## 🎯 Estimated Timeline

| Task | Time | Tests Added |
|------|------|-------------|
| Activity model + parser | 1 hour | 6 tests |
| Zone calculations | 30 min | 4 tests |
| Health data validation | 1 hour | 6 tests |
| Integration & verification | 30 min | - |
| **Total** | **3 hours** | **16 tests** |

---

## 🔍 What This Phase DOESN'T Do

To keep Phase 3 focused and fast, we're **NOT**:

❌ Moving SwiftUI-specific models (`@Observable`, `@Published`)  
❌ Moving CoreData entities  
❌ Moving HealthKit-specific types (`HKWorkout`, `HKQuantity`)  
❌ Refactoring the entire iOS app to use VeloReadyCore models  

**Why**: These are platform-specific and tightly coupled to iOS. Moving them would require significant refactoring without adding test value.

---

## ✅ Phase 3 Success Criteria

At the end of Phase 3, we should have:

1. ✅ **Activity parsing tests** - Catch API response changes
2. ✅ **Zone calculation tests** - Ensure FTP/HR zones are correct
3. ✅ **Health data validation** - Flag invalid/outlier data
4. ✅ **~47-49 total tests** - Comprehensive coverage
5. ✅ **<10 second test time** - Still fast feedback loop

---

## 🚀 Next Steps

After completing Phase 3:

### Phase 4: ML & Forecasting (Optional)
- Extract ML model inference logic
- Test personalization algorithms
- Verify fallback behavior

### Phase 5: Utilities (Optional)
- Date/time utilities
- Math/statistics utilities
- Formatting utilities

---

## 📝 Notes

**Key Insight**: Phase 3 is about **data integrity**, not architectural purity. We're adding tests to catch real-world bugs (API changes, invalid data, parsing errors), not creating a perfect abstraction layer.

**Pragmatic Approach**: Extract only what provides test value. The iOS app can continue using its existing models; VeloReadyCore just needs enough structure to validate data.

---

*Next: Start with Step 1 - Create ActivityData model*
