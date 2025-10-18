# Design System Migration Progress

## ✅ **Completed (Phases 1-2)**

### **Phase 1: Core Color System & Components**

**Files Updated:**
1. `ColorScale.swift` - Added refined metric colors
2. `ColorPalette.swift` - Added semantic mappings
3. `ChartStyleModifiers.swift` - Created (NEW)
4. `RecoveryRingView.swift` - Updated
5. `CompactRingView.swift` - Updated
6. `TrendChart.swift` - Updated

**Key Changes:**
- ✅ Recovery gradient: #FF4444 → #FFB800 → #00D9A3
- ✅ Metric signature colors (soft blue, mint, coral, amber)
- ✅ Chart grid lines at 6% opacity (barely visible)
- ✅ Axis labels: 10pt medium, muted grey (#6B6B6B)
- ✅ Soft white text (#E8E8E8, not #FFFFFF)
- ✅ Huge metrics (32-48pt), tiny labels (10-11pt)
- ✅ UPPERCASE labels
- ✅ No rounded corners
- ✅ No shadows

### **Phase 2: Weekly Report Charts**

**Files Updated:**
1. `FitnessTrajectoryChart.swift` - Updated

**Key Changes:**
- ✅ CTL/ATL lines with refined colors
- ✅ Very subtle TSB area fill (8% opacity)
- ✅ Thin strokes (2px)
- ✅ Smooth curves (.catmullRom)
- ✅ Refined grid lines and axes

---

## 🔄 **Remaining Work**

### **Phase 3: Remaining Charts** (Estimated: 2-3 hours)

**Files to Update:**
1. `SleepHypnogramChart.swift`
2. `RadarChart.swift`
3. `CircadianClockChart.swift`
4. `StackedAreaChart.swift`
5. `WeeklyTrendChart.swift`
6. `WorkoutDetailCharts.swift`
7. `IntensityChart.swift`
8. `IntensityChartNew.swift`
9. `TrainingLoadChart.swift`
10. `ZonePieChartSection.swift`

**Changes Needed:**
- Update grid lines to `ColorPalette.chartGridLine`
- Update axis labels to 10pt medium, `ColorPalette.chartAxisLabel`
- Update metric colors to use `ColorPalette.*Metric`
- Add `.interpolationMethod(.catmullRom)` to all lines
- Reduce area fill opacity to 8-15%
- Update typography (huge metrics, tiny labels)

### **Phase 4: Metric Displays** (Estimated: 1-2 hours)

**Files to Update:**
1. All metric card components
2. Detail view headers
3. Dashboard metric displays

**Changes Needed:**
- Update to 48pt bold metrics
- Update to 11pt UPPERCASE labels
- Use `ColorPalette.recoveryColor(for:)` for dynamic colors
- Use `ColorPalette.*Metric` for specific metrics

### **Phase 5: AI Brief** (Estimated: 30min)

**Files to Update:**
1. `AIBriefView.swift`

**Changes Needed:**
- Keep rainbow gradient (it's AI-specific, not data viz)
- Update any metric displays inside
- Update typography if needed

---

## 🎨 **Design Principles Applied**

### **Color Usage:**
- ✅ Minimal, purposeful color (only for data)
- ✅ Muted, desaturated tones
- ✅ Single metric color per chart
- ✅ Recovery gradient: coral → amber → mint
- ✅ Metric signatures: blue (strain/sleep), mint (HRV), coral (HR), amber (TSS)

### **Typography:**
- ✅ Huge metrics: 32-48pt bold
- ✅ Tiny labels: 10-11pt medium
- ✅ UPPERCASE labels
- ✅ Soft white text (#E8E8E8)
- ✅ Muted grey labels (#6B6B6B)

### **Charts:**
- ✅ Very subtle grid lines (6% opacity)
- ✅ Thin strokes (2px)
- ✅ Smooth curves (.catmullRom)
- ✅ Subtle area fills (8-15% opacity)
- ✅ No symbols on lines (cleaner)
- ✅ Minimal axes

### **Layout:**
- ✅ True black backgrounds
- ✅ No rounded corners on cards
- ✅ No shadows
- ✅ Flat design
- ✅ Full-width separators

---

## 📊 **Color Reference**

### **Recovery Scale:**
```swift
Poor:      #FF4444  // Coral red
Low:       #FF8844  // Soft orange
Medium:    #FFB800  // Warm amber
Good:      #B8D946  // Yellow-green
Excellent: #00D9A3  // Mint green

// Usage:
ColorPalette.recoveryColor(for: score)
```

### **Metric Signatures:**
```swift
Strain:      ColorPalette.strainMetric      // #6B9FFF Soft blue
Sleep:       ColorPalette.sleepMetric       // #6B9FFF Soft blue
HRV:         ColorPalette.hrvMetric         // #00D9A3 Mint
Heart Rate:  ColorPalette.heartRateMetric   // #FF6B6B Coral
Power/FTP:   ColorPalette.powerMetric       // #4D9FFF Electric blue
TSS:         ColorPalette.tssMetric         // #FFB800 Amber
Respiratory: ColorPalette.respiratoryMetric // #9B7FFF Soft purple
```

### **Chart Styling:**
```swift
Grid lines:  ColorPalette.chartGridLine   // white at 6% opacity
Axis labels: ColorPalette.chartAxisLabel  // #6B6B6B
Text:        ColorPalette.textPrimarySoft // #E8E8E8
```

---

## 🔧 **How to Continue**

### **For Each Chart File:**

1. **Update grid lines:**
```swift
// Before:
.foregroundStyle(Color.text.tertiary.opacity(0.3))

// After:
.foregroundStyle(ColorPalette.chartGridLine)
```

2. **Update axis labels:**
```swift
// Before:
.font(.system(size: TypeScale.xxs))
.foregroundStyle(Color.text.secondary)

// After:
.font(.system(size: 10, weight: .medium))
.foregroundStyle(ColorPalette.chartAxisLabel)
```

3. **Update line marks:**
```swift
// Before:
LineMark(...)
    .foregroundStyle(Color.blue)

// After:
LineMark(...)
    .foregroundStyle(ColorPalette.hrvMetric)
    .lineStyle(RefinedChartMarks.lineStyle())
    .interpolationMethod(.catmullRom)
```

4. **Update area marks:**
```swift
// Before:
AreaMark(...)
    .foregroundStyle(Color.green.opacity(0.3))

// After:
AreaMark(...)
    .foregroundStyle(RefinedChartMarks.areaGradient(metricColor: ColorPalette.hrvMetric))
    .interpolationMethod(.catmullRom)
```

### **For Each Metric Display:**

1. **Update metric value:**
```swift
// Before:
Text("\(value)")
    .font(.title)
    .foregroundColor(.primary)

// After:
Text("\(value)")
    .font(.system(size: 48, weight: .bold))
    .foregroundColor(ColorPalette.hrvMetric)
```

2. **Update label:**
```swift
// Before:
Text("HRV")
    .font(.caption)
    .foregroundColor(.secondary)

// After:
Text("HRV")
    .font(.system(size: 11, weight: .medium))
    .foregroundColor(ColorPalette.labelSecondary)
    .textCase(.uppercase)
```

---

## ✅ **Testing Checklist**

- [ ] Recovery ring shows gradient colors
- [ ] Compact rings use refined colors
- [ ] Trend charts have subtle grid lines
- [ ] Fitness trajectory chart looks clean
- [ ] All metrics use UPPERCASE labels
- [ ] All charts use smooth curves
- [ ] Grid lines are barely visible
- [ ] No rounded corners anywhere
- [ ] No shadows anywhere
- [ ] Text is soft white, not pure white

---

## 🔄 **Rollback Instructions**

To rollback to previous design:
```bash
git checkout main
```

To see what changed:
```bash
git diff main design-system-migration
```

To merge when ready:
```bash
git checkout main
git merge design-system-migration
git push origin main
```

---

## 📈 **Progress: 20% Complete**

- ✅ Phase 1: Core system (100%)
- ✅ Phase 2: Weekly Report charts (20%)
- ⏳ Phase 3: Remaining charts (0%)
- ⏳ Phase 4: Metric displays (0%)
- ⏳ Phase 5: Final polish (0%)

**Estimated Time Remaining:** 3-5 hours

---

## 🎯 **Next Steps**

1. Test current changes in simulator
2. Continue with Phase 3 (remaining charts)
3. Update metric displays (Phase 4)
4. Final polish and testing (Phase 5)
5. Merge to main when satisfied

**Branch:** `design-system-migration`
**Commits:** 2
**Files Changed:** 7
**Lines Added:** ~350
**Lines Removed:** ~50
