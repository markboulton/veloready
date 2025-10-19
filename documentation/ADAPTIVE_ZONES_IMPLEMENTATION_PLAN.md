# Adaptive Zones Implementation Plan

**Date:** October 16, 2025  
**Objective:** Achieve feature parity between Strava and Intervals.icu for adaptive zone computation

---

## 🔍 **Current State Analysis**

### **Issues Identified:**

1. **Settings Display Issue:**
   - `AthleteZonesSettingsView` shows FTP (211W) but zones are displayed below
   - User reports "just 211W FTP" - need to verify if zones are actually showing

2. **Data Fetch Periods:**
   - Current: 120 days for FTP computation
   - Current: 90 days for general activity fetch
   - Required: 90 days (Free), 365 days (Pro)

3. **Strava vs Intervals Parity:**
   - Intervals.icu: ✅ Zones computed from activities
   - Strava: ❓ Need to verify zone computation works

4. **Logging:**
   - Some logging exists but needs enhancement
   - Need consistent logging across all zone computation paths

---

## 📋 **Implementation Tasks**

### **Phase 1: Audit & Fix Display** ✅

- [x] Verify `AthleteZonesSettingsView` displays zones correctly
- [ ] Add logging to show when zones are displayed
- [ ] Fix any UI issues preventing zone display

### **Phase 2: Extend Data Fetch Periods**

**Current State:**
```swift
// UnifiedActivityService.swift
func fetchRecentActivities(limit: Int = 100, daysBack: Int = 90)

// Various calls:
- FTP computation: 120 days, limit 300
- Training load: 42 days, limit 200
- General: 90 days, limit 200
```

**Required Changes:**
```swift
// Free users: 90 days
// Pro users: 365 days

func fetchRecentActivities(limit: Int, daysBack: Int) async throws -> [IntervalsActivity] {
    let proConfig = await MainActor.run { ProFeatureConfig.shared }
    let maxDays = proConfig.hasProAccess ? 365 : 90
    let actualDays = min(daysBack, maxDays)
    
    Logger.data("📊 Fetching activities: \(actualDays) days (Pro: \(proConfig.hasProAccess))")
    // ... fetch logic
}
```

**Files to Update:**
1. `/Core/Services/UnifiedActivityService.swift` - Add Pro check
2. `/Core/Networking/IntervalsAPIClient.swift` - Update fetch logic
3. `/Core/Networking/StravaAPIClient.swift` - Update fetch logic
4. `/Core/Models/AthleteProfile.swift` - Update computation to use extended data

### **Phase 3: Centralize Zone Calculation**

**Current Architecture:**
- `AthleteProfileManager.computeFromActivities()` - Main computation
- `AthleteProfileManager.generatePowerZones()` - Static zone generation
- `AthleteProfileManager.generateHRZones()` - Static zone generation

**Issues:**
- Computation happens in `AthleteProfile.swift` (model)
- Should be in a dedicated service for testability

**Proposed:**
```
/Core/Services/AdaptiveZonesService.swift
- computeFTP(activities: [IntervalsActivity]) -> FTPResult
- computeHRZones(activities: [IntervalsActivity]) -> HRZonesResult
- generatePowerZones(ftp: Double) -> [Double]
- generateHRZones(maxHR: Double, lthr: Double?) -> [Double]
```

**Benefits:**
- Testable
- Reusable
- Clear separation of concerns
- Easier to maintain parity

### **Phase 4: Ensure Strava Parity**

**Verify:**
1. Strava activities fetch correctly
2. Strava activities convert to `IntervalsActivity` format
3. Zone computation works with Strava data
4. Results are identical for same performance data

**Test Cases:**
- User with only Strava: Zones computed ✅
- User with only Intervals: Zones computed ✅
- User with both: Uses Intervals (priority)
- User switches source: Zones recompute

### **Phase 5: Background Computation**

**Current:**
- Computation happens in `CacheManager.refreshTodaysData()`
- Blocks on `await computeFromActivities()`

**Required:**
```swift
// Non-blocking computation
Task.detached(priority: .background) {
    await AdaptiveZonesService.shared.computeZones()
}

// UI shows:
// - Last computed zones immediately
// - "Computing..." indicator if in progress
// - Updates when complete
```

**Files to Update:**
1. `/Core/Data/CacheManager.swift` - Make computation non-blocking
2. `/Core/Models/AthleteProfile.swift` - Add computation state
3. `/Features/Settings/Views/AthleteZonesSettingsView.swift` - Show state

### **Phase 6: Enhanced Logging**

**Add logging for:**
1. Data fetch (source, count, date range)
2. Zone computation (inputs, outputs, confidence)
3. Cache hits/misses
4. Errors and fallbacks
5. Performance metrics

**Format:**
```
🎯 [Zones] Starting computation (source: intervals, activities: 150, days: 365)
📊 [Zones] FTP Computation:
   - 60-min power: 220W
   - 20-min power: 216W
   - Weighted FTP: 212W
   - Confidence: 95%
✅ [Zones] Computed FTP: 212W (zones: 7)
💾 [Zones] Saved to cache
```

---

## 🎯 **Success Criteria**

1. ✅ Settings shows all zones (Power: 7 zones, HR: 7 zones)
2. ✅ Free users: 90 days of data
3. ✅ Pro users: 365 days of data
4. ✅ Strava and Intervals.icu have identical computation
5. ✅ Computation doesn't block UI
6. ✅ Comprehensive logging at all stages
7. ✅ Zones update automatically on new activities

---

## 📝 **Implementation Order**

1. **Fix Display** (Quick win)
   - Verify zones are showing
   - Add logging to confirm

2. **Extend Data Periods** (Core requirement)
   - Add Pro check to fetch functions
   - Update all call sites
   - Test with Free and Pro accounts

3. **Centralize Logic** (Code quality)
   - Create `AdaptiveZonesService`
   - Move computation logic
   - Update all references

4. **Ensure Parity** (Feature parity)
   - Test Strava-only scenario
   - Test Intervals-only scenario
   - Verify identical results

5. **Background Computation** (Performance)
   - Make async/non-blocking
   - Add progress indicators
   - Test UI responsiveness

6. **Enhanced Logging** (Debugging)
   - Add comprehensive logs
   - Test log output
   - Verify clarity

---

## 🧪 **Testing Plan**

### **Test Scenarios:**

1. **Free User + Intervals.icu**
   - Fetch 90 days
   - Compute zones
   - Verify display

2. **Pro User + Intervals.icu**
   - Fetch 365 days
   - Compute zones
   - Verify display

3. **Free User + Strava**
   - Fetch 90 days
   - Compute zones
   - Verify display

4. **Pro User + Strava**
   - Fetch 365 days
   - Compute zones
   - Verify display

5. **User with Both**
   - Verify Intervals takes priority
   - Verify fallback to Strava works

6. **Manual Override**
   - Set manual FTP
   - Verify zones update
   - Verify computation skipped

---

## 📊 **Current vs Target**

| Feature | Current | Target |
|---------|---------|--------|
| **Data Period (Free)** | 90-120 days | 90 days |
| **Data Period (Pro)** | 90-120 days | 365 days |
| **Strava Zones** | ❓ Unclear | ✅ Working |
| **Intervals Zones** | ✅ Working | ✅ Working |
| **UI Display** | ❓ Issue reported | ✅ Clear display |
| **Logging** | ⚠️ Partial | ✅ Comprehensive |
| **Background Compute** | ❌ Blocking | ✅ Non-blocking |
| **Centralized Logic** | ❌ Scattered | ✅ Service-based |

---

## 🚀 **Next Steps**

1. Start with Phase 1 (Fix Display)
2. Verify current state with logs
3. Proceed systematically through phases
4. Test after each phase
5. Commit working code incrementally
