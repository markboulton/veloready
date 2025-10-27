# Recovery System Features

## 1. Recovery Score

### Marketing Summary
VeloReady's Recovery Score gives you a single, actionable number (0-100) that tells you how ready your body is to train. Unlike generic fitness trackers, our algorithm is specifically tuned for cyclists, weighing the metrics that matter most for endurance performance. Wake up, check your score, and know instantly whether today is the day to push hard or dial it back.

### Scientific Detail
The Recovery Score is a multi-factor algorithm that synthesizes five key physiological markers into a single 0-100 score with categorical bands (Optimal 90-100, Good 75-89, Fair 60-74, Poor 40-59, Limited Data <40).

**Weighting Formula:**
- **HRV (30%)**: Heart Rate Variability is the gold standard for autonomic nervous system recovery. We compare your overnight HRV (RMSSD) against a 7-day rolling baseline. A positive delta indicates parasympathetic dominance (recovered), while negative indicates sympathetic stress (fatigued). Research shows HRV is the strongest predictor of readiness to train (Plews et al., 2013).

- **Sleep Quality (30%)**: Sleep is when adaptation happens. Our 5-factor sleep algorithm (duration, quality, efficiency, disturbances, timing) captures both quantity and quality. Deep sleep drives physical recovery, REM sleep consolidates motor learning, and total duration determines glycogen replenishment (Walker, 2017).

- **Resting Heart Rate (20%)**: RHR is a simple but powerful marker of cardiovascular stress. An elevated RHR (>3% above baseline) indicates incomplete recovery, dehydration, or illness. We use overnight RHR from HealthKit, comparing against a 7-day rolling average.

- **Respiratory Rate (10%)**: Elevated respiratory rate during sleep can indicate stress, illness, or overtraining. While less studied than HRV, emerging research shows it's a valuable secondary marker (Schäfer & Vagedes, 2013).

- **Training Load (10%)**: We factor in your Training Stress Balance (TSB = CTL - ATL). A deeply negative TSB indicates accumulated fatigue that requires recovery time, even if other metrics look good.

**Special Modifiers:**
- **Alcohol Detection**: Overnight HRV analysis detects alcohol consumption (HRV drops 15-30% after drinking). We apply a proportional penalty to the recovery score.
- **Illness Override**: When our 7-signal illness detection system identifies body stress, we cap the recovery score at 60 regardless of other metrics.

**References:**
- Plews, D. J., et al. (2013). Training adaptation and heart rate variability in elite endurance athletes. *International Journal of Sports Physiology and Performance*.
- Walker, M. (2017). *Why We Sleep*. Scribner.
- Schäfer, A., & Vagedes, J. (2013). How accurate is pulse rate variability as an estimate of heart rate variability? *International Journal of Cardiology*.

### Technical Implementation
**Architecture:**
- `RecoveryScoreService.swift`: Main service class with `calculateRecoveryScore()` method
- `RecoveryScore.swift`: Model with calculation logic and band determination
- `HealthKitManager.swift`: Data source for HRV, RHR, respiratory rate
- `SleepScoreService.swift`: Dependency for sleep quality component
- `StrainScoreService.swift`: Dependency for training load component

**Data Flow:**
1. `TodayViewModel` triggers `recoveryScoreService.calculateRecoveryScore()`
2. Service checks if calculation already done today (daily limit like Whoop)
3. Fetches overnight HRV (RMSSD) from HealthKit `HKQuantityTypeIdentifierHeartRateVariabilitySDNN`
4. Fetches overnight RHR from HealthKit `HKQuantityTypeIdentifierRestingHeartRate`
5. Fetches respiratory rate from HealthKit `HKQuantityTypeIdentifierRespiratoryRate`
6. Calculates 7-day rolling baselines for each metric
7. Calls `sleepScoreService.currentSleepScore` (waits if calculation in progress)
8. Calls `strainScoreService.currentStrainScore` for TSB
9. Applies weighting formula: `(HRV * 0.3) + (Sleep * 0.3) + (RHR * 0.2) + (Resp * 0.1) + (Load * 0.1)`
10. Checks for alcohol via `applyAlcoholCompoundEffect()` (skipped if illness detected)
11. Checks for illness via `IllnessDetectionService` (caps score at 60 if detected)
12. Determines band (Optimal, Good, Fair, Poor, Limited Data)
13. Saves to Core Data (`DailyScores` entity) with CloudKit sync
14. Publishes to `@Published var currentRecoveryScore`

**Caching Strategy:**
- One calculation per day (like Whoop)
- Cached in Core Data with `date` as key
- CloudKit sync for cross-device consistency
- Re-calculation triggered only if data changes significantly

**Code Example:**
```swift
func calculateRecoveryScore() async {
    // Check if already calculated today
    guard !hasCalculatedToday() else { return }
    
    // Fetch overnight HRV
    let hrv = await healthKitManager.getOvernightHRV()
    let hrvBaseline = calculateHRVBaseline(days: 7)
    let hrvScore = calculateHRVScore(current: hrv, baseline: hrvBaseline)
    
    // Fetch overnight RHR
    let rhr = await healthKitManager.getOvernightRHR()
    let rhrBaseline = calculateRHRBaseline(days: 7)
    let rhrScore = calculateRHRScore(current: rhr, baseline: rhrBaseline)
    
    // Get sleep score (wait if in progress)
    let sleepScore = await getSleepScoreWithWait()
    
    // Get respiratory rate
    let respRate = await healthKitManager.getRespiratoryRate()
    let respScore = calculateRespScore(current: respRate)
    
    // Get training load
    let tsb = strainScoreService.currentTSB ?? 0
    let loadScore = calculateLoadScore(tsb: tsb)
    
    // Calculate base score
    var baseScore = (hrvScore * 0.3) + (sleepScore * 0.3) + 
                    (rhrScore * 0.2) + (respScore * 0.1) + (loadScore * 0.1)
    
    // Check for illness (skip alcohol if detected)
    let illness = illnessDetectionService.detectIllness()
    if illness != nil {
        baseScore = min(baseScore, 60)
    } else {
        // Apply alcohol penalty if detected
        baseScore = applyAlcoholCompoundEffect(baseScore, hrv: hrv, baseline: hrvBaseline)
    }
    
    // Determine band
    let band = determineBand(score: baseScore)
    
    // Save to Core Data
    saveToCoreData(score: baseScore, band: band)
    
    // Publish
    currentRecoveryScore = baseScore
    currentRecoveryBand = band
}
```

---

## 2. Illness Detection

### Marketing Summary
VeloReady doesn't just track your metrics—it watches for warning signs that you're getting sick. Our 7-signal detection system catches illness early, even when traditional apps miss it. Whether it's a subtle HRV spike from inflammation or disrupted sleep from congestion, VeloReady alerts you to rest before a cold becomes a lost training week.

### Scientific Detail
Traditional fitness trackers only detect HRV drops, missing a critical pattern: **HRV spikes during illness**. When your body fights infection, the parasympathetic nervous system can overdrive, causing HRV to spike 100-300% above baseline (Buchheit, 2014). This is often accompanied by elevated RHR and poor sleep quality.

**7-Signal Detection System:**

1. **HRV Drop (>10% below baseline)**: Classic overtraining or illness marker
2. **HRV Spike (>100% above baseline)**: Parasympathetic overdrive from inflammation
3. **Elevated RHR (>3% above baseline)**: Cardiovascular stress response
4. **Sleep Disruption**: Score 60-84 with negative deviation OR >15% drop (wake events, congestion)
5. **Respiratory Rate Change**: Elevated or depressed breathing rate
6. **Activity Drop**: Sudden decrease in training volume (fatigue, motivation loss)
7. **Body Temperature** (planned): Direct fever detection

**Confidence Scoring:**
Each signal contributes to a 0-100% confidence score. We require 50% minimum confidence to show an alert. Severity levels:
- **Low (50-65%)**: Single weak signal, monitor closely
- **Moderate (66-80%)**: Multiple signals, consider rest day
- **High (>80%)**: Strong signals, prescribe rest

**Real-World Example:**
- User: Oct 21, 2025 (sick with sore throat)
- HRV: 141ms (baseline 44ms) = +220% spike
- Sleep: 6 wake events, score 78 (fair but disrupted)
- RHR: Elevated 5% above baseline
- **Detection: HIGH severity, 51% confidence**
- **Prescription: Rest day, AI brief overrides all other metrics**

**References:**
- Buchheit, M. (2014). Monitoring training status with HR measures. *Sports Medicine*.
- Plews, D. J., et al. (2014). Heart rate variability and training intensity distribution. *Frontiers in Physiology*.

### Technical Implementation
**Architecture:**
- `IllnessDetectionService.swift`: Main detection service
- `IllnessIndicator.swift`: Model with signal types and severity
- `RecoveryScoreService.swift`: Consumes illness indicator to cap score
- `AIBriefService.swift`: Passes illness indicator to AI for prescription
- `IllnessAlertBanner.swift`: UI component for warnings

**Detection Algorithm:**
```swift
func detectIllness() -> IllnessIndicator? {
    var signals: [IllnessSignal] = []
    var confidence: Double = 0.0
    
    // Signal 1: HRV Spike
    if let hrv = currentHRV, let baseline = hrvBaseline {
        let delta = ((hrv - baseline) / baseline) * 100
        if delta > 100 {
            signals.append(.hrvSpike)
            confidence += 20  // Strong signal
        }
    }
    
    // Signal 2: HRV Drop
    if let hrv = currentHRV, let baseline = hrvBaseline {
        let delta = ((hrv - baseline) / baseline) * 100
        if delta < -10 {
            signals.append(.hrvDrop)
            confidence += 15
        }
    }
    
    // Signal 3: Elevated RHR
    if let rhr = currentRHR, let baseline = rhrBaseline {
        let delta = ((rhr - baseline) / baseline) * 100
        if delta > 3 {
            signals.append(.elevatedRHR)
            confidence += 15
        }
    }
    
    // Signal 4: Sleep Disruption
    if let sleep = sleepScore, let baseline = sleepBaseline {
        let delta = sleep - baseline
        if (sleep >= 60 && sleep <= 84 && delta < 0) || delta < -15 {
            signals.append(.sleepDisruption)
            confidence += 20  // Strong signal
        }
    }
    
    // Signal 5: Respiratory Rate Change
    if let resp = respiratoryRate, let baseline = respBaseline {
        let delta = abs(resp - baseline)
        if delta > 2 {
            signals.append(.respiratoryRateChange)
            confidence += 10
        }
    }
    
    // Signal 6: Activity Drop
    if let tss = recentTSS, let baseline = tssBaseline {
        let delta = ((tss - baseline) / baseline) * 100
        if delta < -30 {
            signals.append(.activityDrop)
            confidence += 10
        }
    }
    
    // Require 50% confidence minimum
    guard confidence >= 50 else { return nil }
    
    // Determine severity
    let severity: IllnessSeverity
    if confidence >= 80 {
        severity = .high
    } else if confidence >= 66 {
        severity = .moderate
    } else {
        severity = .low
    }
    
    return IllnessIndicator(
        signals: signals,
        confidence: confidence,
        severity: severity,
        detectedAt: Date()
    )
}
```

**Integration Points:**
1. **Recovery Score**: Caps score at 60 when illness detected, skips alcohol detection
2. **AI Brief**: Passes illness indicator to backend, AI prescribes rest regardless of other metrics
3. **UI Alerts**: Shows `IllnessAlertBanner` on Recovery, Sleep, and Trends pages
4. **Logging**: Detailed logs for debugging false positives/negatives

**Data Sources:**
- HRV: HealthKit `HKQuantityTypeIdentifierHeartRateVariabilitySDNN`
- RHR: HealthKit `HKQuantityTypeIdentifierRestingHeartRate`
- Sleep: `SleepScoreService.currentSleepScore`
- Respiratory Rate: HealthKit `HKQuantityTypeIdentifierRespiratoryRate`
- Activity: `StrainScoreService` TSS history

---

## 3. Alcohol Detection

### Marketing Summary
Had a few drinks last night? VeloReady knows. Our overnight HRV analysis automatically detects alcohol consumption and adjusts your recovery score accordingly. No manual logging required—the app sees the physiological impact and helps you make smarter training decisions the morning after.

### Scientific Detail
Alcohol has a profound, measurable impact on autonomic nervous system recovery. Studies show HRV drops 15-30% after alcohol consumption, with the effect lasting 12-48 hours depending on quantity (Spaak et al., 2008). The mechanism is multi-factorial:

1. **Acetaldehyde toxicity**: Alcohol metabolite disrupts autonomic regulation
2. **Dehydration**: Reduces blood volume, elevates RHR
3. **Sleep disruption**: Suppresses REM sleep, increases wake events
4. **Inflammation**: Triggers immune response, elevates cortisol

**Detection Algorithm:**
We analyze overnight HRV patterns to detect the characteristic "alcohol signature":
- HRV drop of 15-30% below baseline
- Elevated RHR (3-8% above baseline)
- Sleep disruption (reduced REM, increased wake events)
- Respiratory rate changes

**Penalty Calculation:**
The recovery score penalty is proportional to the severity of the HRV drop:
- Mild (15-20% drop): -5 to -10 points
- Moderate (20-25% drop): -10 to -20 points
- Severe (>25% drop): -20 to -30 points

**Important:** We skip alcohol detection if illness is detected, as the physiological signals are identical.

**References:**
- Spaak, J., et al. (2008). Dose-related effects of red wine and alcohol on heart rate variability. *American Journal of Physiology*.
- Sagawa, Y., et al. (2011). Alcohol has a dose-related effect on parasympathetic nerve activity during sleep. *Alcoholism: Clinical and Experimental Research*.

### Technical Implementation
**Architecture:**
- `RecoveryScore.swift`: Contains `applyAlcoholCompoundEffect()` method
- `RecoveryScoreService.swift`: Calls alcohol detection after base score calculation
- `IllnessDetectionService.swift`: Checked first to avoid false positives during illness

**Detection Logic:**
```swift
func applyAlcoholCompoundEffect(_ baseScore: Double, hrv: Double, baseline: Double) -> Double {
    // Skip if illness detected (same signals as alcohol)
    if let illness = illnessIndicator {
        Logger.debug("🍷 Skipping alcohol detection - illness detected")
        return baseScore
    }
    
    // Calculate HRV delta
    let hrvDelta = ((hrv - baseline) / baseline) * 100
    
    // Detect alcohol signature (HRV drop 15-30%)
    guard hrvDelta < -15 else { return baseScore }
    
    // Calculate penalty proportional to drop
    let penalty: Double
    if hrvDelta < -25 {
        penalty = 30  // Severe
    } else if hrvDelta < -20 {
        penalty = 20  // Moderate
    } else {
        penalty = 10  // Mild
    }
    
    Logger.debug("🍷 Alcohol detected (HRV drop: \(hrvDelta)%) - applying penalty: -\(penalty)")
    
    return max(baseScore - penalty, 0)
}
```

**Why This Works:**
- **Passive detection**: No manual logging required
- **Accurate**: HRV is a direct measure of alcohol's physiological impact
- **Illness-aware**: Skips detection when illness signals present
- **Proportional**: Penalty matches severity of impact

**Limitations:**
- Cannot distinguish between alcohol and other causes of HRV drop (stress, poor sleep)
- Assumes HRV drop is alcohol if no illness detected
- May miss very light drinking (<2 drinks)

**Future Enhancements:**
- Machine learning to improve accuracy
- Integration with manual logging for validation
- Personalized thresholds based on individual response
