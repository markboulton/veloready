# Sleep System Features

## 1. Sleep Score

### Marketing Summary
Sleep is where the magic happens—your body repairs muscle, consolidates learning, and restocks energy. VeloReady's Sleep Score breaks down your night into five key factors, showing you exactly what's working and what's not. Get personalized insights on duration, quality, efficiency, and consistency, with actionable recommendations to optimize your recovery.

### Scientific Detail
The Sleep Score is a 5-factor algorithm (0-100 scale) that captures both quantity and quality of sleep, weighted by their impact on athletic recovery.

**Weighting Formula:**

1. **Performance (Duration vs Need) - 30%**
   - Compares actual sleep duration to your personalized sleep need
   - Sleep need calculated from 7-day baseline + activity-based adjustment
   - Research shows 7-9 hours optimal for athletes (Mah et al., 2011)
   - Score: 100 if duration ≥ need, proportional penalty if less

2. **Quality (Deep + REM Sleep) - 32%**
   - Deep sleep (N3): Physical recovery, growth hormone release, muscle repair
   - REM sleep: Motor learning consolidation, emotional regulation
   - Optimal: Deep 15-25%, REM 20-25% of total sleep (Walker, 2017)
   - Score based on percentage of total sleep in restorative stages

3. **Efficiency (Sleep / Time in Bed) - 22%**
   - Measures how much time in bed is actually spent sleeping
   - Optimal: >85% efficiency (Ohayon et al., 2017)
   - Low efficiency indicates sleep onset issues or frequent waking
   - Score: (actual efficiency / 85) * 100, capped at 100

4. **Disturbances (Wake Events) - 14%**
   - Counts number of wake events during the night
   - Optimal: 0-2 wake events (Ohayon et al., 2017)
   - Excessive waking disrupts sleep cycles, reduces quality
   - Score: 100 - (wake events * 10), minimum 0

5. **Timing (Consistency) - 2%**
   - Measures bedtime and wake time consistency vs 7-day average
   - Circadian rhythm optimization (Roenneberg et al., 2012)
   - Score: 100 - (deviation in minutes / 2), minimum 0

**Sleep Debt Tracking:**
- Cumulative deficit when duration < need
- Debt accumulates over multiple nights
- Shown as "X hours behind" in UI
- Cleared when duration > need (surplus applied to debt)

**Interpretation Bands:**
- 85-100: Excellent (optimal recovery)
- 70-84: Good (adequate recovery)
- 60-69: Fair (suboptimal recovery)
- <60: Poor (impaired recovery)

**References:**
- Mah, C. D., et al. (2011). The effects of sleep extension on athletic performance. *Sleep*.
- Walker, M. (2017). *Why We Sleep*. Scribner.
- Ohayon, M., et al. (2017). National Sleep Foundation's sleep quality recommendations. *Sleep Health*.
- Roenneberg, T., et al. (2012). Social jetlag and obesity. *Current Biology*.

### Technical Implementation
**Architecture:**
- `SleepScoreService.swift`: Main service with `calculateSleepScore()` method
- `SleepScore.swift`: Model with calculation logic
- `HealthKitManager.swift`: Data source for sleep analysis
- `DailyScores` Core Data entity: Persistence layer

**Data Flow:**
1. `TodayViewModel` triggers `sleepScoreService.calculateSleepScore()`
2. Service checks if already calculated today (daily limit)
3. Fetches sleep data from HealthKit `HKCategoryTypeIdentifierSleepAnalysis`
4. Parses sleep stages: Core, Deep, REM, Awake
5. Calculates total duration, time in bed, wake events
6. Fetches 7-day baseline for bedtime, wake time, duration
7. Calculates sleep need (baseline + activity adjustment)
8. Applies 5-factor weighting formula
9. Calculates sleep debt (cumulative deficit)
10. Saves to Core Data with CloudKit sync
11. Publishes to `@Published var currentSleepScore`

**HealthKit Sleep Stages:**
```swift
enum HKCategoryValueSleepAnalysis {
    case inBed          // Time in bed but not asleep
    case asleepCore     // Light sleep (N1, N2)
    case asleepDeep     // Deep sleep (N3)
    case asleepREM      // REM sleep
    case awake          // Wake events during night
}
```

**Code Example:**
```swift
func calculateSleepScore() async {
    // Check if already calculated today
    guard !hasCalculatedToday() else { return }
    
    // Fetch last night's sleep from HealthKit
    let sleepSamples = await healthKitManager.getSleepAnalysis(
        start: Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86400),
        end: Calendar.current.startOfDay(for: Date())
    )
    
    // Parse sleep stages
    var totalSleep: TimeInterval = 0
    var deepSleep: TimeInterval = 0
    var remSleep: TimeInterval = 0
    var coreSleep: TimeInterval = 0
    var wakeEvents = 0
    var timeInBed: TimeInterval = 0
    
    for sample in sleepSamples {
        let duration = sample.endDate.timeIntervalSince(sample.startDate)
        
        switch sample.value {
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            deepSleep += duration
            totalSleep += duration
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            remSleep += duration
            totalSleep += duration
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            coreSleep += duration
            totalSleep += duration
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            wakeEvents += 1
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            timeInBed += duration
        }
    }
    
    // Calculate baselines (7-day average)
    let durationBaseline = calculateDurationBaseline(days: 7)
    let bedtimeBaseline = calculateBedtimeBaseline(days: 7)
    let wakeTimeBaseline = calculateWakeTimeBaseline(days: 7)
    
    // Calculate sleep need (baseline + activity adjustment)
    let recentTSS = strainScoreService.getRecentTSS(days: 1)
    let sleepNeed = durationBaseline + (recentTSS > 100 ? 0.5 * 3600 : 0)  // +30min if hard day
    
    // Factor 1: Performance (30%)
    let performanceScore = min((totalSleep / sleepNeed) * 100, 100)
    
    // Factor 2: Quality (32%)
    let deepPercent = (deepSleep / totalSleep) * 100
    let remPercent = (remSleep / totalSleep) * 100
    let deepScore = min((deepPercent / 20) * 100, 100)  // Optimal 20%
    let remScore = min((remPercent / 22.5) * 100, 100)  // Optimal 22.5%
    let qualityScore = (deepScore + remScore) / 2
    
    // Factor 3: Efficiency (22%)
    let efficiency = (totalSleep / timeInBed) * 100
    let efficiencyScore = min((efficiency / 85) * 100, 100)  // Optimal 85%
    
    // Factor 4: Disturbances (14%)
    let disturbanceScore = max(100 - (Double(wakeEvents) * 10), 0)
    
    // Factor 5: Timing (2%)
    let bedtimeDeviation = abs(currentBedtime.timeIntervalSince(bedtimeBaseline)) / 60
    let wakeDeviation = abs(currentWakeTime.timeIntervalSince(wakeTimeBaseline)) / 60
    let timingScore = max(100 - ((bedtimeDeviation + wakeDeviation) / 2), 0)
    
    // Calculate final score
    let finalScore = (performanceScore * 0.30) +
                     (qualityScore * 0.32) +
                     (efficiencyScore * 0.22) +
                     (disturbanceScore * 0.14) +
                     (timingScore * 0.02)
    
    // Calculate sleep debt
    let deficit = max(sleepNeed - totalSleep, 0)
    let previousDebt = loadPreviousSleepDebt()
    let newDebt = previousDebt + deficit
    
    // Save to Core Data
    saveToCoreData(
        score: finalScore,
        duration: totalSleep,
        deep: deepSleep,
        rem: remSleep,
        efficiency: efficiency,
        wakeEvents: wakeEvents,
        debt: newDebt
    )
    
    // Publish
    currentSleepScore = finalScore
}
```

**Caching Strategy:**
- One calculation per day (like Whoop)
- Cached in Core Data `DailyScores` entity
- CloudKit sync for cross-device consistency
- Historical data used for baselines and trends

---

## 2. Sleep Debt Tracking

### Marketing Summary
One bad night won't ruin your training, but a week of short sleep will. VeloReady tracks your cumulative sleep debt, showing you exactly how many hours you're behind. Get clear guidance on when to prioritize an early bedtime to catch up, and watch your recovery improve as you pay down the debt.

### Scientific Detail
Sleep debt is the cumulative difference between your sleep need and actual sleep duration. Research shows:

**Accumulation:**
- Debt accumulates linearly (Van Dongen et al., 2003)
- 1 hour deficit per night = 7 hours debt after 1 week
- Cognitive and physical performance decline proportionally

**Impact on Performance:**
- 5+ hours debt: -10% VO2max, -20% time to exhaustion (Oliver et al., 2009)
- 10+ hours debt: -30% reaction time, impaired decision making
- Chronic debt linked to overtraining syndrome (Hausswirth et al., 2014)

**Recovery:**
- Debt cannot be "paid back" 1:1 (sleeping 12 hours doesn't erase 5 hours debt)
- Requires consistent surplus over multiple nights
- 2-3 nights of extended sleep can reduce debt by 50%

**References:**
- Van Dongen, H. P., et al. (2003). The cumulative cost of additional wakefulness. *Sleep*.
- Oliver, S. J., et al. (2009). One night of sleep deprivation decreases treadmill endurance performance. *European Journal of Applied Physiology*.
- Hausswirth, C., et al. (2014). Evidence of disturbed sleep and increased illness in overreached endurance athletes. *Medicine & Science in Sports & Exercise*.

### Technical Implementation
**Architecture:**
- `SleepScoreService.swift`: Calculates and tracks debt
- `DailyScores` Core Data entity: Stores daily debt values
- `SleepDetailView.swift`: Displays debt in UI

**Calculation Logic:**
```swift
func calculateSleepDebt(duration: TimeInterval, need: TimeInterval) -> TimeInterval {
    // Load previous debt from Core Data
    let previousDebt = loadPreviousSleepDebt()
    
    // Calculate today's deficit or surplus
    let todayDelta = duration - need
    
    if todayDelta < 0 {
        // Deficit: add to debt
        let newDebt = previousDebt + abs(todayDelta)
        Logger.debug("💤 Sleep deficit: \(abs(todayDelta)/3600)h - Total debt: \(newDebt/3600)h")
        return newDebt
    } else {
        // Surplus: pay down debt (50% efficiency)
        let paydown = min(todayDelta * 0.5, previousDebt)
        let newDebt = max(previousDebt - paydown, 0)
        Logger.debug("💤 Sleep surplus: \(todayDelta/3600)h - Paid down: \(paydown/3600)h - Remaining debt: \(newDebt/3600)h")
        return newDebt
    }
}
```

**UI Display:**
```swift
// SleepDetailView.swift
if let debt = sleepScoreService.currentSleepDebt, debt > 0 {
    HStack {
        Image(systemName: "moon.zzz.fill")
            .foregroundColor(.orange)
        Text("Sleep Debt: \(formatHours(debt)) behind")
            .font(.subheadline)
    }
}
```

**Persistence:**
- Stored in `DailyScores.sleepDebt` (TimeInterval)
- Synced via CloudKit
- Historical debt shown in trends chart

---

## 3. Sleep Consistency Scoring

### Marketing Summary
Your body loves routine. VeloReady tracks your bedtime and wake time consistency, helping you optimize your circadian rhythm. Even if you're getting enough sleep, irregular timing can hurt recovery. See your consistency score and get nudges to stick to a schedule that works.

### Scientific Detail
Circadian rhythm consistency is crucial for sleep quality and athletic performance. Irregular sleep timing causes "social jetlag"—the equivalent of traveling across time zones every week (Roenneberg et al., 2012).

**Impact of Inconsistency:**
- >2 hour bedtime variation: -15% sleep quality (Wittmann et al., 2006)
- Irregular timing disrupts melatonin production
- Reduces deep sleep percentage
- Impairs glucose metabolism and recovery

**Optimal Consistency:**
- Bedtime variation: <30 minutes
- Wake time variation: <30 minutes
- Weekend vs weekday: <1 hour difference

**References:**
- Roenneberg, T., et al. (2012). Social jetlag and obesity. *Current Biology*.
- Wittmann, M., et al. (2006). Social jetlag: Misalignment of biological and social time. *Chronobiology International*.

### Technical Implementation
**Architecture:**
- `SleepScoreService.swift`: Calculates consistency score
- `DailyScores` Core Data entity: Stores bedtime/wake time
- 7-day rolling baseline for comparison

**Calculation Logic:**
```swift
func calculateConsistencyScore(bedtime: Date, wakeTime: Date) -> Double {
    // Calculate 7-day baseline
    let bedtimeBaseline = calculateBedtimeBaseline(days: 7)
    let wakeTimeBaseline = calculateWakeTimeBaseline(days: 7)
    
    // Calculate deviation in minutes
    let bedtimeDeviation = abs(bedtime.timeIntervalSince(bedtimeBaseline)) / 60
    let wakeDeviation = abs(wakeTime.timeIntervalSince(wakeTimeBaseline)) / 60
    
    // Average deviation
    let avgDeviation = (bedtimeDeviation + wakeDeviation) / 2
    
    // Score: 100 - (deviation / 2), minimum 0
    // 30 min deviation = 85 score
    // 60 min deviation = 70 score
    // 120 min deviation = 40 score
    let score = max(100 - (avgDeviation / 2), 0)
    
    return score
}
```

**UI Display:**
```swift
// SleepDetailView.swift
CardMetric(
    label: "Consistency",
    value: "\(Int(consistencyScore))",
    unit: "/100",
    color: consistencyScore > 85 ? .green : .orange
)
```
