# Training Load Chart - Unified Component

**Date:** November 14, 2025

## Summary

Unified the training load chart into a single reusable component (`TrainingLoadChartView`) used in both the Today page and activity detail views.

## Changes Implemented

### 1. ✅ Created Unified Component

**File:** `TrainingLoadChartView.swift`

A single, reusable chart component with:
- **Colored lines:** CTL (Blue), ATL (Amber), TSB (gradient)
- **Full-width tooltip:** Shows date, CTL, ATL, TSB values
- **Zone-colored Form line:** RAG gradient (red/green/grey/blue/yellow)
- **White outlined circle selector:** Draggable at bottom of chart
- **Zone legend:** 5 zones with ranges
- **Compact fonts:** 9-10pt throughout

### 2. ✅ Updated Today Page

**File:** `TrainingLoadGraphCard.swift`

- Now uses `TrainingLoadChartView` instead of `TodayTrainingLoadChart`
- Removed duplicate `TrainingLoadDataPoint` struct
- Same data loading logic (60 days + 7 day projection)

### 3. ✅ Updated Activity Detail View

**File:** `TrainingLoadChart.swift`

- Now uses `TrainingLoadChartView` instead of inline chart code
- Converts `LoadDataPoint` to `TrainingLoadDataPoint`
- Simplified from ~300 lines to ~150 lines
- Removed duplicate chart rendering code
- Removed `selectedDate` state (handled by component)

### 4. ✅ Deleted Old Component

**Deleted:** `TodayTrainingLoadChart.swift`

- No longer needed
- All functionality moved to unified component

## Component Features

### TrainingLoadChartView

**Props:**
- `data: [TrainingLoadDataPoint]` - Array of data points to display

**Features:**
1. **Colored Lines:**
   - CTL: Blue (`ColorScale.blueAccent`)
   - ATL: Amber (`ColorScale.amberAccent`)
   - TSB: Gradient based on zone

2. **Full-Width Tooltip:**
   - Appears when date selected
   - Shows date, CTL, ATL, TSB
   - TSB value color-coded to zone
   - 9-10pt fonts

3. **Zone-Colored Form Line:**
   - High Risk (<-30): Red
   - Optimal (-30 to -10): Green
   - Grey Zone (-10 to +5): Grey
   - Fresh (+5 to +20): Blue
   - Transition (>+20): Yellow

4. **Interactive Selector:**
   - White outlined circle (12pt diameter, 2pt stroke)
   - Positioned at bottom of chart
   - Draggable via `.chartAngleSelection`

5. **Zone Legend:**
   - Shows all 5 zones with ranges
   - 6pt circle indicators
   - 9pt labels

## Data Model

```swift
struct TrainingLoadDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let ctl: Double
    let atl: Double
    let tsb: Double
    let isFuture: Bool
}
```

## Usage

### Today Page
```swift
TrainingLoadChartView(data: viewModel.chartData)
```

### Activity Detail
```swift
let chartViewData = chartData.map { point in
    TrainingLoadDataPoint(
        date: point.date,
        ctl: point.ctl,
        atl: point.atl,
        tsb: point.tsb,
        isFuture: point.isFuture
    )
}

TrainingLoadChartView(data: chartViewData)
```

## Files Modified

1. **Created:** `TrainingLoadChartView.swift` - Unified chart component
2. **Updated:** `TrainingLoadGraphCard.swift` - Use unified component
3. **Updated:** `TrainingLoadChart.swift` - Use unified component
4. **Deleted:** `TodayTrainingLoadChart.swift` - No longer needed

## Benefits

- ✅ **Single source of truth** - One component, consistent behavior
- ✅ **Colored lines** - CTL (blue), ATL (amber), TSB (gradient)
- ✅ **Full-width tooltip** - Better visibility
- ✅ **Less code** - Reduced duplication by ~200 lines
- ✅ **Easier maintenance** - Changes apply to both views
- ✅ **Consistent UX** - Same interaction pattern everywhere

## Testing

1. **Clean build:**
   ```bash
   Cmd + Shift + K
   Cmd + B
   ```

2. **Today page:**
   - Open app → scroll to Training Load card
   - Should see colored lines (blue CTL, amber ATL, gradient TSB)
   - Drag across chart → white circle appears at bottom
   - Tooltip shows values

3. **Activity detail:**
   - Tap any activity with TSS
   - Scroll to Training Load Chart
   - Same colored lines and interactions
   - Current metrics shown below chart
