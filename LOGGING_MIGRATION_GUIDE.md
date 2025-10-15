# Logging Migration Guide
**Date:** October 15, 2025  
**Status:** 171/926 print statements migrated (18.5%)

---

## ✅ **Completed Migration**

### **Top 3 Hot-Path Files (171 prints)**

Files that run on **every app launch** have been migrated:

| File | Print Statements | Status |
|------|------------------|---------|
| **RecoveryScoreService.swift** | 69 | ✅ Migrated to Logger |
| **StrainScoreService.swift** | 43 | ✅ Migrated to Logger |
| **HealthKitManager.swift** | 59 | ✅ Migrated to Logger |
| **ActivityLocationService.swift** | 1 | ✅ Already migrated |
| **TOTAL** | **172** | **✅ Complete** |

---

## 🎛️ **How to Control Logging**

### **Debug Toggle (Settings → Debug Settings)**

```swift
// Toggle ON/OFF in the app
Settings → Debug Settings → "Enable Debug Logging"
```

**Default: OFF** (clean console, optimal performance)  
**Turn ON when:** Actively debugging specific issues

### **What Gets Logged**

#### **Always Shown (regardless of toggle):**
```swift
Logger.info("Important event")       // ✅ Always shown
Logger.warning("Something unusual")   // ⚠️ Always shown
Logger.error("Failed to...", error:)  // ❌ Always shown
```

#### **Respects Debug Toggle (OFF by default):**
```swift
Logger.debug("Detailed info")         // 🔍 Only when ON
Logger.performance("Loaded", duration:) // ⚡ Only when ON
Logger.network("API call")             // 🌐 Only when ON
Logger.data("Parsed 10 items")        // 📊 Only when ON
Logger.health("HRV: 45ms")            // 💓 Only when ON
Logger.cache("Cache hit")             // 💾 Only when ON
```

---

## 📊 **Migration Statistics**

### **Current State**
- **Migrated:** 172 print statements (18.5%)
- **Remaining:** 754 print statements (81.5%)
- **Total:** 926 print statements

### **Performance Impact**

| Scenario | Logging Output | Performance |
|----------|----------------|-------------|
| **Production Build** | Zero (always disabled) | Optimal ✅ |
| **Debug + Toggle OFF** | Errors & warnings only | Optimal ✅ |
| **Debug + Toggle ON** | Full diagnostic | Slightly slower ⚠️ |

---

## 📋 **Remaining Files to Migrate**

### **High Priority (Medium Frequency)**
These files are called less frequently but still run often:

| File | Prints | Priority | When to Migrate |
|------|--------|----------|-----------------|
| `IntervalsAPIClient.swift` | 67 | High | Next API work |
| `StravaAuthService.swift` | 63 | High | Next auth work |
| `SleepScoreService.swift` | 42 | High | Next sleep work |

### **Medium Priority (Low Frequency)**
Called occasionally or during specific features:

| File | Prints | Priority | When to Migrate |
|------|--------|----------|-----------------|
| `AthleteProfile.swift` | 109 | Medium | Next zones work |
| `RideDetailViewModel.swift` | 105 | Medium | Next ride detail work |
| `TodayViewModel.swift` | 38 | Medium | Next dashboard work |
| `IntervalsAPIDebugView.swift` | 66 | Medium | Debug view work |

### **Low Priority (Rarely Called)**
Settings, onboarding, one-time setup:

| Category | Files | Prints | Priority |
|----------|-------|--------|----------|
| Settings & Config | 15 files | ~200 | Low |
| OAuth & Auth | 5 files | ~100 | Low |
| Debug Tools | 8 files | ~150 | Low |
| Other | 15 files | ~204 | Low |

---

## 🔧 **Migration Examples**

### **Before (Old Style)**
```swift
print("📊 Loaded \(count) activities")
print("⚠️ Network timeout after 10 seconds")
print("❌ Failed to parse: \(error)")
```

### **After (Logger Style)**
```swift
Logger.data("Loaded \(count) activities")
Logger.warning("Network timeout after 10 seconds")
Logger.error("Failed to parse", error: error)
```

### **With Categories**
```swift
Logger.debug("Starting calculation", category: .health)
Logger.network("Fetching from API", category: .network)
Logger.cache("Cache miss for key", category: .cache)
```

---

## 🎯 **Migration Strategy**

### **Incremental Approach (Recommended)**

**Don't migrate everything at once!** Instead:

1. ✅ **Hot paths done** - Files called every launch
2. **Migrate during feature work** - When touching a file for features
3. **Migrate during bug fixes** - When debugging specific areas
4. **Target: <100 prints app-wide** (from 926)

### **When to Migrate**

```
Working on API changes?     → Migrate IntervalsAPIClient.swift
Fixing sleep algorithm?     → Migrate SleepScoreService.swift
Updating athlete profile?   → Migrate AthleteProfile.swift
Working on ride details?    → Migrate RideDetailViewModel.swift
```

### **Auto-Migration Script**

For bulk migration:
```bash
python3 /tmp/migrate_logger.py path/to/YourFile.swift
```

---

## 📖 **Logger API Reference**

### **Debug Methods (Respects Toggle)**

```swift
// General debug info
Logger.debug("Message", category: .performance)

// Performance measurement
Logger.performance("Operation completed", duration: 1.2)

// Convenience measurement
let result = Logger.measure("Load data") {
    return expensiveOperation()
}

// Async measurement
let result = await Logger.measureAsync("Fetch API") {
    return await apiCall()
}
```

### **Always-On Methods**

```swift
// Important information
Logger.info("User logged in", category: .data)

// Warnings
Logger.warning("Rate limit approaching", category: .network)

// Errors
Logger.error("Failed to save", error: error, category: .data)
```

### **Specialized Methods**

```swift
Logger.network("GET /api/activities")
Logger.data("Parsed 15 wellness records")
Logger.health("HRV: 45ms, RHR: 62bpm")
Logger.cache("Cache hit for key: user_settings")
```

---

## 🚀 **Benefits Achieved**

### **For Development**
- ✅ Clean console by default (toggle OFF)
- ✅ Full diagnostics when needed (toggle ON)
- ✅ Persistent toggle setting
- ✅ Easy access via Settings UI

### **For Production**
- ✅ Zero logging overhead (always disabled)
- ✅ Privacy-safe with os_log
- ✅ Efficient structured logging
- ✅ No accidental data leaks

### **For Debugging**
- ✅ Turn on/off without recompile
- ✅ Categorized logs
- ✅ Performance measurements
- ✅ Error context preserved

---

## 📈 **Progress Tracking**

```
Progress: ████████░░░░░░░░░░░░░░░░░░░░░░░░ 18.5%

Migrated:  172 / 926
Remaining: 754
Target:    <100 (90% reduction)
```

### **Milestones**

- [x] Phase 1: Create Logger utility
- [x] Phase 2: Add debug toggle UI
- [x] Phase 3: Migrate hot paths (3 files, 171 prints)
- [ ] Phase 4: Migrate during feature work (ongoing)
- [ ] Phase 5: Final cleanup (<100 prints total)

---

## 💡 **Tips & Best Practices**

### **When Writing New Code**

```swift
// ✅ DO: Use Logger from the start
Logger.debug("User tapped save button", category: .ui)

// ❌ DON'T: Use print()
print("User tapped save button")
```

### **Choosing Logger Method**

```swift
// Data operations
Logger.data("Fetched 10 records")

// Network calls
Logger.network("POST /api/workouts - 201 Created")

// Health/fitness data
Logger.health("Calculated recovery score: 75")

// Performance tracking
Logger.performance("Score calculation", duration: 0.45)

// Cache operations
Logger.cache("Loaded cached athlete profile")

// Errors
Logger.error("Failed to decode JSON", error: error, category: .network)

// Warnings
Logger.warning("API rate limit reached", category: .network)
```

### **Debug Toggle Best Practices**

**Leave OFF during:**
- Normal feature testing
- UI/UX validation
- Performance testing
- Battery life testing

**Turn ON when:**
- Debugging specific algorithms
- Investigating crashes
- Testing integrations
- Validating data flow

---

## 📝 **Summary**

**Current Status:** ✅ Hot paths migrated, debug toggle working

**To Use:**
1. Settings → Debug Settings
2. Toggle "Enable Debug Logging"
3. OFF = clean console, ON = full logs

**Next Steps:**
- Migrate files incrementally during feature work
- Keep toggle OFF for normal testing
- Turn ON only when actively debugging

**Goal:** Reduce from 926 → <100 print statements app-wide
