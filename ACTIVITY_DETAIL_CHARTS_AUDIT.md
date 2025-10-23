# Activity Detail Charts Audit: Phase 2/3 Gap Analysis

**Date:** October 23, 2025, 7:55pm UTC+01:00  
**Status:** CRITICAL - Activity detail charts NOT using atomic card wrappers

---

## 🚨 **Problem Discovered**

The activity detail views (RideDetailSheet, WalkingDetailView, WorkoutDetailView) have **chart components that are NOT using atomic card wrappers** from Phase 2/3!

### What We Found

**These charts build their own UI structure:**
- ❌ Custom VStack layouts
- ❌ Manual headers with `.font(.headline)`
- ❌ Hard-coded spacing values
- ❌ Inconsistent padding
- ❌ NOT using StandardCard or ChartCard wrappers

**They should be using:**
- ✅ ChartCard wrapper (from Phase 2/3)
- ✅ Design tokens (Spacing.md, etc.)
- ✅ VRText components
- ✅ Consistent styling

---

## 📊 Chart Components That Need Refactoring

### 1. IntensityChart.swift (239 lines)
**Current Structure:**
```swift
struct IntensityChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {  // ❌ Manual layout
            HStack(spacing: 8) {
                Text("Ride Intensity")  // ❌ Manual header
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            // Chart content...
        }
    }
}
```

**Should Be:**
```swift
struct IntensityChart: View {
    var body: some View {
        ChartCard(  // ✅ Atomic wrapper
            title: TrainingLoadContent.Metrics.rideIntensity,
            subtitle: "Intensity Factor and TSS analysis"
        ) {
            // Chart content only
        }
    }
}
```

**Estimated Refactor:** 30-50 lines reduction

---

### 2. TrainingLoadChart.swift (600 lines)
**Current Structure:**
```swift
struct TrainingLoadChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {  // ❌ Manual layout
            HStack(spacing: 8) {
                Text(TrainingLoadContent.title)  // ❌ Manual header
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            // Complex chart with CTL/ATL/TSB...
        }
    }
}
```

**Should Be:**
```swift
struct TrainingLoadChart: View {
    var body: some View {
        ChartCard(  // ✅ Atomic wrapper
            title: TrainingLoadContent.title,
            subtitle: "21-day fitness trend"
        ) {
            // Chart content only
        }
    }
}
```

**Estimated Refactor:** 50-80 lines reduction

---

### 3. ZonePieChartSection.swift (456 lines)
**Current Structure:**
```swift
struct ZonePieChartSection: View {
    var body: some View {
        VStack(spacing: 24) {  // ❌ Manual layout
            // Heart Rate Zone Chart
            VStack(alignment: .leading, spacing: 16) {  // ❌ Nested manual layout
                HStack(spacing: 8) {
                    Text("Adaptive HR Zones")  // ❌ Manual header
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                // Chart content...
            }
            .padding(.horizontal, 16)  // ❌ Hard-coded padding
            .padding(.vertical, 24)
            
            // Power Zone Chart
            // Similar manual structure...
        }
    }
}
```

**Should Be:**
```swift
struct ZonePieChartSection: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {  // ✅ Design token
            ChartCard(  // ✅ Atomic wrapper
                title: "Adaptive HR Zones",
                subtitle: "Time in each heart rate zone"
            ) {
                // HR chart content only
            }
            
            ChartCard(  // ✅ Atomic wrapper
                title: "Power Zones",
                subtitle: "Time in each power zone"
            ) {
                // Power chart content only
            }
        }
    }
}
```

**Estimated Refactor:** 80-120 lines reduction

---

### 4. WorkoutChartsSection (in WorkoutDetailView.swift)
**Current Structure:**
```swift
struct WorkoutChartsSection: View {
    var body: some View {
        VStack(spacing: 24) {  // ❌ Manual layout
            // Power chart
            if hasPowerData {
                VStack(alignment: .leading, spacing: 12) {  // ❌ Manual layout
                    Text("Power")  // ❌ Manual header
                        .font(.headline)
                    // Chart...
                }
            }
            // HR chart, Speed chart, Cadence chart...
            // All with manual layouts
        }
    }
}
```

**Should Be:**
```swift
struct WorkoutChartsSection: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {  // ✅ Design token
            if hasPowerData {
                ChartCard(title: "Power") {  // ✅ Atomic wrapper
                    // Chart content only
                }
            }
            // Similar for HR, Speed, Cadence...
        }
    }
}
```

**Estimated Refactor:** 40-60 lines reduction

---

### 5. HeartRateChart (in WalkingDetailView.swift)
**Current Structure:**
```swift
struct HeartRateChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {  // ❌ Manual layout
            Text("Heart Rate")  // ❌ Manual header
                .font(.headline)
                .fontWeight(.semibold)
            // Chart content...
        }
        .padding()  // ❌ Hard-coded padding
    }
}
```

**Should Be:**
```swift
struct HeartRateChart: View {
    var body: some View {
        ChartCard(title: "Heart Rate") {  // ✅ Atomic wrapper
            // Chart content only
        }
    }
}
```

**Estimated Refactor:** 20-30 lines reduction

---

## 📊 Summary of Charts Needing Refactoring

| Chart Component | Lines | Manual Layout? | Needs ChartCard? | Est. Reduction |
|----------------|-------|----------------|------------------|----------------|
| IntensityChart | 239 | ✅ Yes | ✅ Yes | 30-50 lines |
| TrainingLoadChart | 600 | ✅ Yes | ✅ Yes | 50-80 lines |
| ZonePieChartSection | 456 | ✅ Yes | ✅ Yes | 80-120 lines |
| WorkoutChartsSection | ~200 | ✅ Yes | ✅ Yes | 40-60 lines |
| HeartRateChart | ~100 | ✅ Yes | ✅ Yes | 20-30 lines |
| **TOTAL** | **~1,595** | **5 charts** | **5 charts** | **220-340 lines** |

---

## 🎯 Why This Matters

### Current Problems

1. **Inconsistent UI**
   - Some charts use ChartCard (Trends section)
   - Activity charts use manual layouts
   - Different padding, spacing, headers

2. **Code Duplication**
   - Every chart rebuilds header structure
   - Repeated padding/spacing values
   - Inconsistent styling

3. **Not Following Phase 2/3 Standards**
   - Phase 2/3 created atomic card wrappers
   - Activity charts weren't migrated
   - Breaking the design system

4. **Harder to Maintain**
   - Changes to card styling require updating 5+ files
   - No single source of truth
   - Inconsistent with rest of app

### What Should Happen

**All charts should use ChartCard:**
```swift
ChartCard(
    title: "Chart Title",
    subtitle: "Optional description",
    footerText: "Optional insight"
) {
    // Chart content only
}
```

**Benefits:**
- ✅ Consistent styling across app
- ✅ 220-340 lines of code reduction
- ✅ Follows Phase 2/3 design system
- ✅ Single source of truth for card styling
- ✅ Easier to maintain

---

## 🔍 Comparison: Trends vs Activity Charts

### Trends Charts (Phase 2/3 Complete) ✅

**Example: PerformanceOverviewCardV2**
```swift
struct PerformanceOverviewCardV2: View {
    var body: some View {
        ChartCard(  // ✅ Using atomic wrapper
            title: TrendsContent.Cards.performanceOverview,
            subtitle: TrendsContent.PerformanceOverview.subtitle,
            footerText: generateInsight()
        ) {
            // Chart content only
        }
    }
}
```

**Status:** ✅ Follows Phase 2/3 standards

### Activity Charts (NOT Migrated) ❌

**Example: IntensityChart**
```swift
struct IntensityChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {  // ❌ Manual layout
            HStack(spacing: 8) {
                Text(TrainingLoadContent.Metrics.rideIntensity)  // ❌ Manual header
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            // Chart content...
        }
    }
}
```

**Status:** ❌ NOT following Phase 2/3 standards

---

## 💡 Recommended Action Plan

### Option A: Refactor Activity Charts (Recommended) ⭐

**Scope:**
1. Migrate 5 chart components to use ChartCard
2. Remove manual layouts
3. Use design tokens
4. Achieve consistency with Trends section

**Estimated Time:** 1-2 hours

**Benefits:**
- ✅ Consistent UI across entire app
- ✅ 220-340 lines reduction
- ✅ Completes Phase 2/3 properly
- ✅ Easier maintenance

**Impact:**
- Activity detail views: 5 charts refactored
- Code reduction: ~15-20%
- Design system: 100% consistent

### Option B: Leave As-Is

**Pros:**
- No work needed

**Cons:**
- ❌ Inconsistent with Trends section
- ❌ Phase 2/3 incomplete
- ❌ Harder to maintain
- ❌ Code duplication

---

## 📋 Detailed Refactoring Checklist

If we proceed with Option A, here's what needs to be done:

### 1. IntensityChart.swift
- [ ] Replace VStack with ChartCard wrapper
- [ ] Remove manual header
- [ ] Use design tokens for spacing
- [ ] Test with Pro/Free users

### 2. TrainingLoadChart.swift
- [ ] Replace VStack with ChartCard wrapper
- [ ] Remove manual header
- [ ] Use design tokens for spacing
- [ ] Ensure legend still works
- [ ] Test with Pro users

### 3. ZonePieChartSection.swift
- [ ] Split into two ChartCard instances (HR + Power)
- [ ] Remove manual layouts
- [ ] Use design tokens
- [ ] Test Pro upgrade CTA placement
- [ ] Test with/without power data

### 4. WorkoutChartsSection
- [ ] Wrap each chart (Power, HR, Speed, Cadence) in ChartCard
- [ ] Remove manual headers
- [ ] Use design tokens
- [ ] Test with various data combinations

### 5. HeartRateChart (WalkingDetailView)
- [ ] Replace VStack with ChartCard wrapper
- [ ] Remove manual header
- [ ] Use design tokens
- [ ] Test with walking workouts

---

## 🎯 Expected Outcome

### Before (Current State)
```
Activity Detail Views:
├── IntensityChart (239 lines) - Manual layout ❌
├── TrainingLoadChart (600 lines) - Manual layout ❌
├── ZonePieChartSection (456 lines) - Manual layout ❌
├── WorkoutChartsSection (~200 lines) - Manual layout ❌
└── HeartRateChart (~100 lines) - Manual layout ❌

Total: ~1,595 lines with inconsistent styling
```

### After (Refactored)
```
Activity Detail Views:
├── IntensityChart (~190 lines) - ChartCard ✅
├── TrainingLoadChart (~520 lines) - ChartCard ✅
├── ZonePieChartSection (~340 lines) - ChartCard ✅
├── WorkoutChartsSection (~150 lines) - ChartCard ✅
└── HeartRateChart (~70 lines) - ChartCard ✅

Total: ~1,270 lines with consistent styling
Reduction: 325 lines (20%)
```

---

## 🚀 Integration with Phase 4

**This is separate from Phase 4 ViewModels!**

- **Phase 2/3:** UI components and card wrappers (THIS ISSUE)
- **Phase 4:** Business logic extraction into ViewModels (SEPARATE)

**The charts already have ViewModels** (RideDetailViewModel, WalkingDetailViewModel), but they're **not using atomic card wrappers** for their UI.

**Both should be done:**
1. ✅ ViewModels for business logic (DONE)
2. ❌ ChartCard wrappers for UI (NOT DONE)

---

## 💭 Your Decision

Should we:

**A)** Refactor activity charts to use ChartCard (1-2 hours, completes Phase 2/3 properly) ⭐

**B)** Leave as-is and move on (inconsistent UI, incomplete Phase 2/3)

**My recommendation:** **Option A** - Complete Phase 2/3 properly before moving to Trends ViewModels. This ensures consistent UI across the entire app.

What do you think?
