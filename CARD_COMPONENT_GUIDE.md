# Card Component Quick Reference Guide

**Use this guide to choose the right card component for your data visualization needs.**

---

## 📱 How to View the Gallery

Open `CardGalleryDebugView.swift` in Xcode Preview or add it to your debug menu:

```swift
#if DEBUG
NavigationLink("Card Gallery", destination: CardGalleryDebugView())
#endif
```

---

## 📊 Card Type Selector

### **Need to show simple metrics with goals?**
→ Use `StepsCardV2` or `CaloriesCardV2`
- Daily metric with goal tracking
- Progress ring visualization
- Percentage complete badge

### **Need to track cumulative deficits?**
→ Use `DebtMetricCardV2`
- Recovery debt (consecutive days below threshold)
- Sleep debt (accumulated hours)
- Severity bands with color coding

### **Need to alert users about health warnings?**
→ Use `HealthWarningsCardV2`
- Illness detection indicators
- Wellness alerts
- Multiple metrics affected
- Severity badges (HIGH/MODERATE/LOW)

### **Need to display latest workout/activity?**
→ Use `LatestActivityCardV2`
- Activity name, date, location
- Key metrics (duration, distance, TSS, power, HR)
- Optional map snapshot for outdoor activities
- Navigation to detail view

### **Need to show a single metric trend over time?**
→ Use line chart cards:
- `HRVTrendCardV2` - HRV with baseline
- `RecoveryTrendCardV2` - Recovery score (0-100)
- `RestingHRCardV2` - Resting heart rate
- `StressLevelCardV2` - Stress index
- `FTPTrendCardV2` - FTP progression
- `TrainingLoadTrendCardV2` - Daily normalized load

**Features:**
- Line + area gradient visualization
- Current value badge
- Trend direction indicator
- Average calculation

### **Need to overlay multiple metrics on one chart?**
→ Use `PerformanceOverviewCardV2`
- Overlays 3 lines: Recovery (green) + Load (orange) + Sleep (blue)
- Shared time axis
- Legend with current values
- Partial data handling
- Smart insights based on metric relationships

**When to use:**
- Comparing related metrics
- Finding patterns/correlations
- Understanding metric balance

### **Need to show correlation between two variables?**
→ Use `RecoveryVsPowerCardV2`
- Scatter plot (PointMark)
- Trend line with linear regression
- Correlation coefficient (r)
- R-squared value
- Significance badge (STRONG/MODERATE/WEAK/NONE)
- Sample size
- Interpretation insights

**When to use:**
- Analyzing health vs performance
- Understanding relationships
- Validating training response

### **Need to show weekly totals in bars?**
→ Use `WeeklyTSSTrendCardV2`
- Bar chart (BarMark)
- Color-coded by intensity:
  * Red (>600): Very high load
  * Amber (>400): High load
  * Blue (>200): Moderate load
  * Green (≤200): Low load
- Total TSS and week count
- Load-based insights

**When to use:**
- Weekly aggregations
- Volume tracking
- Load management

### **Need to show detected training phase?**
→ Use `TrainingPhaseCardV2`
- Phase detection (Base/Build/Peak/Recovery/Transition)
- Confidence percentage with progress bar
- Metrics: weekly TSS, low intensity %, high intensity %
- Badge based on confidence
- Phase-specific recommendations

**When to use:**
- Auto-detecting training cycles
- Periodization tracking
- Training guidance

### **Need to assess overtraining risk?**
→ Use `OvertrainingRiskCardV2`
- Risk score (0-100)
- Risk level badge (LOW/MODERATE/HIGH/CRITICAL)
- Contributing factors (top 3)
- Severity indicators (color-coded dots)
- Actionable recommendations

**When to use:**
- Fatigue monitoring
- Injury prevention
- Training balance assessment

---

## 🎨 Component Hierarchy

### Atomic Components (Atoms)
- `VRText` - Typography with 9 styles
- `VRBadge` - Status indicators

### Molecules
- `CardHeader` - Title + subtitle + badge + action
- `CardMetric` - Label + value pairs
- `CardFooter` - Bottom text/actions

### Organisms
- `CardContainer` - Wraps content with header/footer (for non-chart cards)
- `ChartCard` - Specialized for chart visualizations (includes header + footer)
- `ScoreCard` - Score displays (not used in V2 cards yet)
- `MetricStatCard` - Stat panels (not used in V2 cards yet)

---

## 📐 Design Token Usage

### Spacing
```swift
Spacing.xs    // Extra small gaps
Spacing.sm    // Small gaps
Spacing.md    // Medium gaps (most common)
Spacing.lg    // Large gaps
Spacing.xl    // Extra large gaps
Spacing.buttonCornerRadius  // For rounded corners
```

### Colors
```swift
// Accent colors (for data visualization)
ColorScale.greenAccent   // Positive/good (recovery, low risk)
ColorScale.amberAccent   // Warning/moderate
ColorScale.redAccent     // Negative/high risk
ColorScale.blueAccent    // Neutral/info
ColorScale.purpleAccent  // Build phase
ColorScale.yellowAccent  // Alternative warning

// Semantic colors
Color.semantic.success   // Strong positive
Color.semantic.warning   // Moderate concern
Color.semantic.error     // Critical issue

// Text colors
Color.text.primary      // Main text
Color.text.secondary    // Supporting text
Color.text.tertiary     // De-emphasized text

// Background colors
Color.background.primary      // Main background
Color.background.secondary    // Panel/card backgrounds
Color.background.card         // Card backgrounds

// Domain-specific colors
Color.workout.tss        // Training load/TSS
Color.workout.power      // Power data
Color.health.heartRate   // HR data
Color.health.sleep       // Sleep data
Color.chart.primary      // Chart accent
```

### Icons
```swift
Icons.System.*     // System icons (chevron, clock, etc.)
Icons.Health.*     // Health-related icons
Icons.Activity.*   // Activity/workout icons
Icons.Feature.*    // Feature-specific icons
```

---

## 🔧 Data Types

### Simple Trends
```swift
TrendsViewModel.TrendDataPoint
├── date: Date
└── value: Double
```

### HRV Trends (includes baseline)
```swift
TrendsViewModel.HRVTrendDataPoint
├── date: Date
├── value: Double
└── baseline: Double
```

### Correlation/Scatter
```swift
TrendsViewModel.CorrelationDataPoint
├── date: Date
├── x: Double  // Recovery %
└── y: Double  // Power (W)

CorrelationCalculator.CorrelationResult
├── coefficient: Double  // r value
├── rSquared: Double     // r²
├── sampleSize: Int
├── significance: Significance  // .strong/.moderate/.weak/.none
└── trend: Trend  // .positive/.negative/.none
```

### Weekly Aggregations
```swift
TrendsViewModel.WeeklyTSSDataPoint
├── weekStart: Date
└── tss: Double
```

### Phase Detection
```swift
TrainingPhaseDetector.PhaseDetectionResult
├── phase: TrainingPhase  // .base/.build/.peak/.recovery/.transition
├── confidence: Double  // 0-1
├── weeklyTSS: Double
├── lowIntensityPercent: Double
├── highIntensityPercent: Double
└── recommendation: String
```

### Risk Assessment
```swift
OvertrainingRiskCalculator.RiskResult
├── riskScore: Double  // 0-100
├── riskLevel: RiskLevel  // .low/.moderate/.high/.critical
├── factors: [RiskFactor]
│   ├── name: String
│   ├── severity: Double  // 0-1
│   └── description: String
└── recommendation: String
```

### Debt Tracking
```swift
RecoveryDebt
├── consecutiveDays: Int
├── band: DebtBand  // .fresh/.accumulating/.significant
├── averageRecoveryScore: Double
└── calculatedAt: Date

SleepDebt
├── totalDebtHours: Double
├── band: DebtBand  // .minimal/.moderate/.significant
├── averageSleepDuration: Double
├── sleepNeed: Double
└── calculatedAt: Date
```

---

## ✅ Best Practices

### 1. **Choose the Right Chart Type**
- **Line charts**: Continuous trends over time
- **Scatter plots**: Relationships between variables
- **Bar charts**: Periodic totals/aggregations
- **Overlays**: Comparing multiple metrics

### 2. **Use Appropriate Time Ranges**
```swift
TrendsViewModel.TimeRange
├── .days7    // Short-term patterns
├── .days30   // Monthly view
├── .days90   // Quarterly analysis
└── .allTime  // Complete history
```

### 3. **Handle Empty States**
All V2 cards include comprehensive empty states with:
- Icon indication
- Clear explanation
- Requirements list
- Guidance for next steps

### 4. **Provide Context**
- Use badges for quick status indication
- Include footer text for insights/guidance
- Add subtitles for current values or summaries

### 5. **Design Token Compliance**
- **NEVER** hard-code spacing, colors, or text
- **ALWAYS** use design tokens and content abstraction
- **REFERENCE** existing patterns in V2 cards

---

## 🚀 Adding a New Card

1. **Choose base component:**
   - `ChartCard` for visualizations
   - `CardContainer` for non-chart cards

2. **Define data structure:**
   - Create or reuse TrendsViewModel types
   - Include all necessary fields

3. **Implement features:**
   - Empty state with requirements
   - Badge logic (optional)
   - Footer insights (optional)
   - Proper error handling

4. **Use design tokens:**
   - All spacing via `Spacing.*`
   - All colors via `ColorScale.*` or `Color.*`
   - All text via `VRText`
   - All icons via `Icons.*`

5. **Abstract content:**
   - Add strings to `TrendsContent`, `CommonContent`, etc.
   - NO hard-coded strings

6. **Add to gallery:**
   - Include in `CardGalleryDebugView`
   - Provide sample data
   - Add annotation explaining use case

---

## 📚 Examples

### Simple Line Chart
```swift
HRVTrendCardV2(
    data: hrvData,  // [TrendsViewModel.HRVTrendDataPoint]
    timeRange: .days30
)
```

### Overlay Chart
```swift
PerformanceOverviewCardV2(
    recoveryData: recoveryData,  // [TrendDataPoint]
    loadData: loadData,           // [TrendDataPoint]
    sleepData: sleepData,         // [TrendDataPoint]
    timeRange: .days30
)
```

### Scatter/Correlation
```swift
RecoveryVsPowerCardV2(
    data: correlationData,  // [CorrelationDataPoint]
    correlation: result,     // CorrelationResult?
    timeRange: .days90
)
```

### Bar Chart
```swift
WeeklyTSSTrendCardV2(
    data: weeklyData,  // [WeeklyTSSDataPoint]
    timeRange: .days90
)
```

### Assessment Card
```swift
OvertrainingRiskCardV2(
    risk: riskResult  // OvertrainingRiskCalculator.RiskResult?
)
```

---

## 🎯 Summary

**16 V2 Cards Available:**
- 4 Metric cards (Steps, Calories, Debt, Activity)
- 1 Alert card (HealthWarnings)
- 6 Line chart cards (HRV, Recovery, RestingHR, Stress, FTP, TrainingLoad)
- 1 Overlay chart (PerformanceOverview)
- 1 Scatter chart (RecoveryVsPower)
- 1 Bar chart (WeeklyTSS)
- 2 Assessment cards (TrainingPhase, OvertrainingRisk)

**All cards:**
- ✅ Use atomic design components
- ✅ Follow design token system
- ✅ Include content abstraction
- ✅ Provide comprehensive empty states
- ✅ Support proper data types
- ✅ Build successfully

**View them all in `CardGalleryDebugView`!** 🎨
