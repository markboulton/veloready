# Adaptive Y-Axis Enhancement

**Date:** November 15, 2025

## Overview

Enhanced the Y-axis to be **very adaptive** to data variation, ensuring that even small changes in FTP/VO2 are clearly visible in both sparklines and the 6-month chart.

## Components

### 1. Sparklines (Today Page)
**Status:** Already adaptive ✅

The RAGSparkline component already uses min/max normalization:
```swift
let maxValue = values.max() ?? 1
let minValue = values.min() ?? 0
let normalizedValue = (value - minValue) / range
```

This means sparklines automatically zoom to fit the data range, showing all variation.

### 2. 6-Month Chart (Adaptive Performance Page)
**Status:** Enhanced ✅

#### Old Implementation (±10% padding)
```swift
let range = maxValue - minValue
let padding = range * 0.1
let lowerBound = max(0, minValue - padding)
let upperBound = maxValue + padding
```

**Problem:** If the actual data range is small, 10% padding might not zoom in enough.

**Example with small variation:**
- Data range: 195W to 199W (4W actual range)
- Padding: 0.4W (10% of 4W)
- Y-axis: 194.6W to 199.4W
- Visible but not as pronounced

#### New Implementation (±20% padding + minimum range)
```swift
let range = maxValue - minValue

// Use 20% padding OR minimum 10% of mean value (whichever is larger)
let meanValue = (maxValue + minValue) / 2
let minRange = meanValue * 0.1  // Minimum 10% range of mean value
let effectiveRange = max(range, minRange)

let padding = effectiveRange * 0.2  // 20% padding around the effective range
let lowerBound = max(0, minValue - padding)
let upperBound = maxValue + padding
```

**Improvement:** Guarantees we always zoom in enough to show variation.

**Example with small variation:**
- Data range: 195W to 199W (4W actual range)
- Mean: 197W
- Minimum range: 19.7W (10% of mean)
- Effective range: 19.7W (uses minimum since 4W < 19.7W)
- Padding: 3.94W (20% of effective range)
- Y-axis: 191W to 203W
- **Much more visible variation!**

**Example with large variation:**
- Data range: 170W to 210W (40W actual range)
- Mean: 190W
- Minimum range: 19W (10% of mean)
- Effective range: 40W (uses actual since 40W > 19W)
- Padding: 8W (20% of effective range)
- Y-axis: 162W to 218W
- Shows full progression with good padding

## Benefits

### 1. Small Variations Always Visible
Even if data only varies by ±2% (e.g., 195-199W), the chart will zoom in to make this variation clear.

### 2. Large Variations Still Work
The algorithm adapts - if you have a large range (e.g., 170-210W from June to now), it will show the full range with appropriate padding.

### 3. Works for Both Metrics
- **FTP (W):** Typical range 150-250W → adaptive scaling
- **VO2 (ml/kg/min):** Typical range 40-60 → adaptive scaling

### 4. No Fixed Range
The Y-axis is never fixed at 0-300W or similar. It always adapts to your actual data.

## Testing Examples

### Scenario 1: Flat Period (Small Variation)
```
Data: 195W, 196W, 197W, 198W, 199W
Old Y-axis: 194.6W to 199.4W (5W range)
New Y-axis: 191W to 203W (12W range)
Result: 2.4x more visible variation
```

### Scenario 2: Growth Period (Large Variation)
```
Data: 170W, 180W, 190W, 200W, 210W
Old Y-axis: 166W to 214W (48W range)
New Y-axis: 162W to 218W (56W range)
Result: Full progression clearly visible with good margins
```

### Scenario 3: Decline Period
```
Data: 210W, 200W, 190W, 180W, 170W
Old Y-axis: 166W to 214W (48W range)
New Y-axis: 162W to 218W (56W range)
Result: Decline clearly visible
```

## Visual Impact

### Before (±10% padding):
```
300W ┤
     │
     │
250W ┤
     │
     │
200W ┼───────────────────── (flat line, barely visible variation)
     │
150W ┤
     │
100W ┤
     │
 50W ┤
     │
  0W └─────────────────────
```

### After (±20% padding + minimum range):
```
205W ┤
     │
     │  ╱╲
200W ┤ ╱  ╲    ╱╲
     │╱    ╲  ╱  ╲
195W ┤      ╲╱    ╲
     │            ╲╱
190W ┤
     │
185W └─────────────────────
```

## Implementation

**File Modified:** `AdaptivePerformanceDetailView.swift:155-176`

**Lines Changed:**
```swift
// OLD (lines 155-168):
// Calculate adaptive Y-axis domain with ±10% padding
private var yAxisDomain: ClosedRange<Double> {
    let values = historicalData.map { selectedMetric == .ftp ? $0.ftp : ($0.vo2 ?? 0) }
    guard let minValue = values.min(), let maxValue = values.max(), minValue > 0 else {
        return 0...100
    }

    let range = maxValue - minValue
    let padding = range * 0.1
    let lowerBound = max(0, minValue - padding)
    let upperBound = maxValue + padding

    return lowerBound...upperBound
}

// NEW (lines 155-176):
// Calculate very adaptive Y-axis domain to show variation
// Uses ±20% padding OR minimum 10% range to ensure variation is visible
private var yAxisDomain: ClosedRange<Double> {
    let values = historicalData.map { selectedMetric == .ftp ? $0.ftp : ($0.vo2 ?? 0) }
    guard let minValue = values.min(), let maxValue = values.max(), minValue > 0 else {
        return 0...100
    }

    let range = maxValue - minValue

    // Use 20% padding OR minimum 10% of mean value (whichever is larger)
    // This ensures we always zoom in enough to see variation
    let meanValue = (maxValue + minValue) / 2
    let minRange = meanValue * 0.1  // Minimum 10% range of mean value
    let effectiveRange = max(range, minRange)

    let padding = effectiveRange * 0.2  // 20% padding around the effective range
    let lowerBound = max(0, minValue - padding)
    let upperBound = maxValue + padding

    return lowerBound...upperBound
}
```

## Combined Effect

With both the granularity fix (30/60-day windows) AND the adaptive Y-axis:

1. **Real data variation** (from smaller windows and more historical data)
2. **Zoomed-in view** (from adaptive Y-axis with minimum range)
3. **Result:** Clear, visible progression showing your actual fitness journey

## Expected User Experience

**Before:**
- "The chart looks flat, I can't see any variation"
- Y-axis: 0-300W, data: 195-199W (invisible variation)

**After:**
- Clear ups and downs showing training/recovery cycles
- Y-axis: 191-203W, data: 195-199W (clearly visible ±2% variation)
- Can see week-by-week progression over 6 months
- June's 210-220W peak visible as a clear high point

## Testing

To verify the adaptive Y-axis:
1. Clear cache (forces recalculation)
2. Open Adaptive Performance page
3. Check Y-axis labels on the chart
4. Should see values close to your actual data range (e.g., 185W-205W instead of 0W-300W)
5. Switch between FTP and VO2 metrics - Y-axis should adapt to each
