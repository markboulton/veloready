# Today Page Enhancements - Implementation Plan

**Date:** October 30, 2025  
**Status:** In Progress

---

## Bugs to Fix

### 1. ML Progress Bar Not Auto-Updating ✅ 
**Problem:** Progress bar in AI Brief shows stale data until manual refresh in debug settings

**Root Cause:** 
- `MLTrainingDataService.trainingDataCount` is only loaded on init from UserDefaults
- When new data is processed (daily), the count updates in UserDefaults but @Published var doesn't refresh
- AIBriefView calls `mlService.refreshTrainingDataCount()` on appear, but this doesn't persist

**Fix:**
- Make `refreshTrainingDataCount()` actually refresh from CoreData
- Call it in TodayViewModel when data refreshes
- Ensure it updates the @Published variable

**Files:**
- `VeloReady/Core/ML/Services/MLTrainingDataService.swift`
- `VeloReady/Features/Today/ViewModels/TodayViewModel.swift`

---

### 2. Center Loaders on First App Open ⏳
**Problem:** Loading spinners not centered to compact rings on initial app load

**Root Cause:**
- LoadingOverlay uses fixed positioning
- Doesn't account for compact rings position

**Fix:**
- Calculate compact rings vertical position
- Center loading spinner there
- OR: Show skeleton for compact rings during load

**Files:**
- `VeloReady/Features/Today/Views/Dashboard/LoadingOverlay.swift`
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`

---

## New Features

### 3. Disabled/Hidden Card Group in Settings 🎯
**Feature:** Allow users to hide cards by moving them to a "Disabled" group

**Design:**
```
Settings > Customize Today

Active Cards (Drag to reorder)
├── VeloAI Brief
├── Latest Activity  
├── Steps
└── Calories

Hidden Cards (Drag here to hide)
├── Recent Activities
└── [Empty state: "Drag cards here to hide them"]
```

**Implementation:**
- Add `hiddenSections: [TodaySection]` to `TodaySectionOrder`
- Update card reorder UI to show two groups
- Filter out hidden sections in `TodayView.movableSection()`
- Sync to iCloud

**Files:**
- `VeloReady/Features/Today/Models/TodaySectionOrder.swift`
- `VeloReady/Features/Settings/Views/TodayCustomizationView.swift` (create)
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`

---

### 4. Loading Performance Chart 📊
**Feature:** Show app loading performance (time to interactive, phases)

**Data Source:**
- Use existing telemetry from `TodayViewModel`
- Track phase timings:
  - App launch → UI visible
  - Cached data loaded
  - Fresh data loaded
  - Complete

**Design:**
```
┌─────────────────────────────┐
│ Loading Performance         │
│                             │
│ ▓▓▓▓░░░░░░ Phase 1: 0.2s   │ (Cached data)
│ ▓▓▓▓▓▓▓▓░░ Phase 2: 2.1s   │ (Fresh data)
│ ▓▓▓▓▓▓▓▓▓▓ Complete: 5.3s  │
│                             │
│ 7-day average: 3.8s         │
│ Best: 2.1s | Worst: 8.9s    │
└─────────────────────────────┘
```

**Implementation:**
- Create `LoadingPerformanceCardV2` component
- Track timings in `TodayViewModel`
- Store last 7 days in UserDefaults
- Add to movable sections

**Files:**
- `VeloReady/Features/Today/Views/Components/LoadingPerformanceCardV2.swift` (create)
- `VeloReady/Features/Today/ViewModels/TodayViewModel.swift`
- `VeloReady/Features/Today/Models/TodaySectionOrder.swift`

---

### 5. CTL/ATL/Form Chart 📈
**Feature:** Optional fitness/fatigue/form chart (PMC style)

**Data Source:**
- Use existing Core Data: `DailyMetricsCoreData` (CTL, ATL, TSB)
- Query last 30/60/90 days

**Design:**
```
┌─────────────────────────────┐
│ Training Load               │
│ [7D] [30D] [60D]            │
│                             │
│     ┌────CTL (Fitness)      │
│    ╱                        │
│   ╱  ATL (Fatigue)──┐       │
│  ╱                   ╲      │
│ ╱     Form (TSB) ────╲─    │
│                             │
│ CTL: 45 | ATL: 28 | TSB: 17│
└─────────────────────────────┘
```

**Implementation:**
- Create `TrainingLoadChartCardV2`
- Query Core Data for CTL/ATL/TSB
- Use Swift Charts with 3 lines
- Add to movable sections (optional)
- Hidden by default (user enables in settings)

**Files:**
- `VeloReady/Features/Today/Views/Components/TrainingLoadChartCardV2.swift` (create)
- `VeloReady/Features/Today/Models/TodaySectionOrder.swift`
- `VeloReady/Features/Settings/Views/TodayCustomizationView.swift`

---

### 6. 'Customize This View' CTA 🎨
**Feature:** Floating action button at bottom to customize Today page

**Design:**
```
┌─────────────────────────────┐
│                             │
│  (scrollable content)       │
│                             │
│                             │
│  ┌───────────────────────┐  │
│  │ 🎨 Customize this view│  │ ← Tappable card
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
```

**Implementation:**
- Add as last item in Today scrollview (after all sections)
- Styled as a subtle card with icon + text
- Taps navigate to Settings > Customize Today
- Always visible (not in movable sections)

**Files:**
- `VeloReady/Features/Today/Views/Dashboard/TodayView.swift`
- `VeloReady/Features/Settings/Views/SettingsView.swift`

---

## Implementation Order

1. ✅ **Bug: ML Progress Bar** (Critical - 15 min)
2. ⏳ **Bug: Center Loaders** (Critical - 20 min)
3. 🎯 **Feature: Hidden Cards** (High - 45 min)
4. 📊 **Feature: Loading Chart** (Medium - 30 min)
5. 📈 **Feature: CTL/ATL Chart** (Medium - 40 min)
6. 🎨 **Feature: Customize CTA** (Low - 10 min)

**Total estimated time:** 2.5 hours

---

## Testing Checklist

### Bug Fixes
- [ ] ML progress bar updates automatically when data processes
- [ ] Loaders centered on compact rings on fresh launch
- [ ] No visual jumps or misalignment

### Hidden Cards
- [ ] Can drag cards to "Hidden" section
- [ ] Hidden cards don't show on Today page
- [ ] Can drag cards back to "Active" to re-enable
- [ ] State persists across app launches
- [ ] Syncs to iCloud

### Loading Performance Chart
- [ ] Shows current session timing
- [ ] Shows 7-day average
- [ ] Updates on each app launch
- [ ] Accurate phase breakdown

### CTL/ATL Chart
- [ ] Disabled by default
- [ ] Can be enabled in settings
- [ ] Shows accurate data from Core Data
- [ ] 3 lines render correctly (CTL/ATL/TSB)
- [ ] Period selector works (7/30/60 days)

### Customize CTA
- [ ] Always visible at bottom
- [ ] Taps navigate to settings
- [ ] Haptic feedback on tap
- [ ] Looks good in light/dark mode

---

## Success Criteria

1. **ML Progress Updates:** Progress bar reflects current day count without manual intervention
2. **Centered Loading:** Professional loading state aligned with content
3. **Card Control:** Users can hide unwanted cards
4. **Performance Insight:** Users can see app loading performance
5. **Training Insight:** Users can optionally view PMC-style fitness data
6. **Discoverability:** Clear path to customization settings

All features must be backwards compatible and not break existing Today page functionality.

