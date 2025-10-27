# Training Load & Strain Features

## 1. Training Stress Score (TSS) & Load Management

### Marketing Summary
Not all workouts are created equal. VeloReady calculates Training Stress Score (TSS) for every ride, quantifying exactly how hard you worked. Track your acute and chronic training load to find the sweet spot between fitness gains and overtraining. Our adaptive algorithm learns from your power and heart rate data to give you personalized load targets.

### Scientific Detail
Training Stress Score (TSS) is the gold standard for quantifying training load in cycling, developed by Dr. Andrew Coggan. It combines intensity and duration into a single metric that predicts physiological stress.

**TSS Calculation:**
```
TSS = (duration_seconds × NP × IF) / (FTP × 3600) × 100
```

Where:
- **NP (Normalized Power)**: Weighted average power accounting for variability
- **IF (Intensity Factor)**: NP / FTP (functional threshold power)
- **FTP**: Power at lactate threshold (sustainable for ~60 minutes)

**For Heart Rate-Based Workouts (no power meter):**
We use TRIMP (Training Impulse) and convert to TSS equivalent:
```
TRIMP = duration_minutes × avg_HR_reserve × 0.64 × e^(1.92 × HR_reserve)
TSS_equivalent = TRIMP × scaling_factor
```

**Load Metrics:**

1. **CTL (Chronic Training Load)**: 42-day exponentially weighted moving average
   - Represents fitness/endurance capacity
   - Higher CTL = more fitness, but requires maintenance
   - Typical range: 40-120 TSS/day for amateurs

2. **ATL (Acute Training Load)**: 7-day exponentially weighted moving average
   - Represents recent fatigue
   - Spikes after hard training blocks
   - Should be managed relative to CTL

3. **TSB (Training Stress Balance)**: CTL - ATL
   - Positive TSB: Fresh, ready for hard efforts
   - Negative TSB: Fatigued, need recovery
   - Optimal range: -10 to +10 for most training

**Periodization Guidance:**
- Base building: Gradually increase CTL (+3-5 TSS/week)
- Build phase: Maintain CTL, vary ATL with intervals
- Taper: Reduce ATL while maintaining CTL (TSB +15 to +25)
- Recovery: Allow ATL to drop, slight CTL decay acceptable

**References:**
- Coggan, A. R., & Allen, H. (2010). *Training and Racing with a Power Meter*. VeloPress.
- Banister, E. W. (1991). Modeling elite athletic performance. *Physiological Testing of Elite Athletes*.
- Busso, T. (2003). Variable dose-response relationship between exercise training and performance. *Medicine & Science in Sports & Exercise*.

### Technical Implementation
**Architecture:**
- `StrainScoreService.swift`: Main service for load calculations
- `StrainScore.swift`: Model with CTL/ATL/TSB logic
- `VeloReadyAPIClient.swift`: Fetches activities from backend
- `IntervalsAPIClient.swift`: Fetches wellness data
- `DailyLoad` Core Data entity: Persistence layer

**Data Flow:**
1. `TodayViewModel` triggers `strainScoreService.calculateStrainScore()`
2. Service fetches recent activities from Strava via backend API
3. For each activity:
   - If power data available: Calculate TSS from NP and IF
   - If only HR data: Calculate TRIMP and convert to TSS
   - If neither: Estimate from duration and perceived exertion
4. Load historical TSS from Core Data (42 days for CTL)
5. Calculate CTL using exponential weighted moving average
6. Calculate ATL using exponential weighted moving average
7. Calculate TSB (CTL - ATL)
8. Determine training phase (Base, Build, Peak, Recovery)
9. Save to Core Data with CloudKit sync
10. Publish to `@Published var currentStrainScore`

**Code Example:**
```swift
func calculateStrainScore() async {
    // Fetch recent activities (42 days for CTL)
    let activities = await fetchActivities(days: 42)
    
    // Calculate TSS for each activity
    var dailyTSS: [Date: Double] = [:]
    for activity in activities {
        let tss = calculateTSS(activity: activity)
        let date = Calendar.current.startOfDay(for: activity.date)
        dailyTSS[date, default: 0] += tss
    }
    
    // Calculate CTL (42-day EWMA)
    var ctl: Double = 0
    let ctlDecay = 1.0 - (1.0 / 42.0)
    
    for day in -42...0 {
        let date = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let tss = dailyTSS[date] ?? 0
        ctl = (ctl * ctlDecay) + tss
    }
    
    // Calculate ATL (7-day EWMA)
    var atl: Double = 0
    let atlDecay = 1.0 - (1.0 / 7.0)
    
    for day in -7...0 {
        let date = Calendar.current.date(byAdding: .day, value: day, to: Date())!
        let tss = dailyTSS[date] ?? 0
        atl = (atl * atlDecay) + tss
    }
    
    // Calculate TSB
    let tsb = ctl - atl
    
    // Determine training phase
    let phase = determinePhase(ctl: ctl, atl: atl, tsb: tsb)
    
    // Save to Core Data
    saveToCoreData(ctl: ctl, atl: atl, tsb: tsb, phase: phase)
    
    // Publish
    currentCTL = ctl
    currentATL = atl
    currentTSB = tsb
    currentPhase = phase
}

func calculateTSS(activity: Activity) -> Double {
    if let power = activity.averagePower, let np = activity.normalizedPower {
        // Power-based TSS
        let ftp = getFTP()  // From adaptive FTP detection
        let if = np / ftp
        let duration = activity.duration
        return (duration * np * if) / (ftp * 3600) * 100
    } else if let avgHR = activity.averageHeartRate {
        // HR-based TRIMP → TSS
        let maxHR = getMaxHR()  // From adaptive max HR detection
        let restingHR = getRestingHR()
        let hrReserve = (avgHR - restingHR) / (maxHR - restingHR)
        let trimp = (activity.duration / 60) * hrReserve * 0.64 * exp(1.92 * hrReserve)
        return trimp * 1.5  // Scaling factor to match power-based TSS
    } else {
        // Fallback: estimate from duration and type
        let durationHours = activity.duration / 3600
        let estimatedIF = activity.type == .race ? 0.85 : 0.65
        return durationHours * 100 * estimatedIF
    }
}
```

**Caching Strategy:**
- Daily TSS cached in `DailyLoad` Core Data entity
- CTL/ATL recalculated daily from cached TSS values
- CloudKit sync for cross-device consistency
- Backfill algorithm for historical data gaps

---

## 2. Adaptive FTP Detection

### Marketing Summary
Forget manual FTP tests. VeloReady automatically detects your Functional Threshold Power from your regular rides, updating your zones as you get fitter. Our algorithm analyzes your power curve to find your true threshold, no 20-minute test required.

### Scientific Detail
Functional Threshold Power (FTP) is the maximum power you can sustain for approximately 60 minutes. Traditional testing requires a painful 20-minute all-out effort, which many cyclists avoid.

**Adaptive Detection Algorithm:**
We use power curve analysis to estimate FTP from regular training rides:

1. **Power Curve Construction**: For each activity, we calculate the maximum average power for durations from 1 second to 60 minutes
2. **Critical Power Model**: Fit a hyperbolic curve to the power-duration relationship
3. **FTP Estimation**: FTP ≈ 95% of 20-minute power OR 100% of critical power
4. **Confidence Weighting**: Recent efforts weighted more heavily, require multiple data points

**Validation:**
- Compare against manual FTP tests (±3% accuracy)
- Require 3+ rides with 15+ minute efforts for initial estimate
- Update monthly or when significant fitness change detected

**References:**
- Coggan, A. R. (2003). Training and racing using a power meter. *USA Cycling*.
- Monod, H., & Scherrer, J. (1965). The work capacity of a synergic muscular group. *Ergonomics*.

### Technical Implementation
**Architecture:**
- `AdaptiveZonesService.swift`: FTP detection logic
- `VeloReadyAPIClient.swift`: Fetches power stream data
- `PowerCurve.swift`: Model for power-duration analysis

**Detection Algorithm:**
```swift
func detectFTP() async -> Double? {
    // Fetch recent activities with power data (30 days)
    let activities = await fetchActivitiesWithPower(days: 30)
    
    guard activities.count >= 3 else {
        Logger.debug("⚡ Insufficient data for FTP detection (need 3+ rides)")
        return nil
    }
    
    // Build power curve for each activity
    var powerCurves: [PowerCurve] = []
    for activity in activities {
        let streams = await fetchPowerStream(activityId: activity.id)
        let curve = buildPowerCurve(streams: streams)
        powerCurves.append(curve)
    }
    
    // Find best 20-minute power across all activities
    let best20min = powerCurves.map { $0.power(duration: 1200) }.max() ?? 0
    
    // Estimate FTP (95% of 20-min power)
    let estimatedFTP = best20min * 0.95
    
    // Validate against previous FTP (reject if >10% change without confirmation)
    if let previousFTP = currentFTP {
        let change = abs(estimatedFTP - previousFTP) / previousFTP
        if change > 0.10 {
            Logger.debug("⚡ Large FTP change detected (\(change * 100)%) - requires confirmation")
            return nil  // Require manual confirmation for large changes
        }
    }
    
    Logger.debug("⚡ Detected FTP: \(estimatedFTP)W (from 20-min power: \(best20min)W)")
    return estimatedFTP
}

func buildPowerCurve(streams: PowerStream) -> PowerCurve {
    var curve: [Int: Double] = [:]  // duration → max avg power
    
    // Calculate max avg power for each duration (1s to 3600s)
    for duration in [1, 5, 10, 30, 60, 120, 300, 600, 1200, 1800, 3600] {
        var maxAvg: Double = 0
        
        // Sliding window to find max average
        for i in 0..<(streams.data.count - duration) {
            let window = streams.data[i..<(i + duration)]
            let avg = window.reduce(0, +) / Double(duration)
            maxAvg = max(maxAvg, avg)
        }
        
        curve[duration] = maxAvg
    }
    
    return PowerCurve(data: curve)
}
```

**UI Integration:**
- Show detected FTP in Settings > Zones
- Allow manual override if athlete prefers lab-tested value
- Show confidence indicator (Low/Medium/High based on data quality)
- Notify when FTP changes significantly

---

## 3. Adaptive Heart Rate Zones

### Marketing Summary
Your max heart rate isn't 220 minus your age—it's unique to you. VeloReady learns your true max HR from your hardest efforts and adjusts your training zones accordingly. Get personalized zones that actually match your physiology, not a generic formula.

### Scientific Detail
Traditional max HR formulas (220 - age) have a standard deviation of ±10-12 bpm, making them unreliable for individual athletes (Robergs & Landwehr, 2002). Actual max HR can vary by 20-30 bpm between individuals of the same age.

**Adaptive Detection:**
We analyze heart rate data from high-intensity efforts to detect true max HR:

1. **Peak Detection**: Find maximum HR from all activities
2. **Validation**: Require sustained near-max effort (>95% for 30+ seconds)
3. **Confidence**: Weight recent efforts more heavily
4. **Outlier Rejection**: Reject spikes from sensor errors

**Zone Calculation:**
Once max HR is known, we calculate 5 training zones based on lactate threshold:

- **Zone 1 (Active Recovery)**: <68% max HR
- **Zone 2 (Endurance)**: 68-83% max HR
- **Zone 3 (Tempo)**: 84-94% max HR
- **Zone 4 (Lactate Threshold)**: 95-105% LTHR
- **Zone 5 (VO2max)**: >105% LTHR

Where LTHR (Lactate Threshold HR) ≈ 90% max HR for trained cyclists.

**References:**
- Robergs, R. A., & Landwehr, R. (2002). The surprising history of the "HRmax=220-age" equation. *Journal of Exercise Physiology*.
- Seiler, S., & Kjerland, G. Ø. (2006). Quantifying training intensity distribution in elite endurance athletes. *Journal of Sports Sciences*.

### Technical Implementation
**Architecture:**
- `AdaptiveZonesService.swift`: Max HR detection and zone calculation
- `HealthKitManager.swift`: Fetches HR data from workouts
- `UserDefaults`: Stores detected max HR and zones

**Detection Algorithm:**
```swift
func detectMaxHR() async -> Double? {
    // Fetch recent high-intensity activities (90 days)
    let activities = await fetchHighIntensityActivities(days: 90)
    
    var maxHRCandidates: [(hr: Double, confidence: Double)] = []
    
    for activity in activities {
        let hrStream = await fetchHRStream(activityId: activity.id)
        
        // Find peak HR
        let peakHR = hrStream.data.max() ?? 0
        
        // Validate: require sustained near-max (>95% for 30+ seconds)
        let sustainedNearMax = hrStream.data.filter { $0 > peakHR * 0.95 }.count
        guard sustainedNearMax >= 30 else { continue }
        
        // Calculate confidence based on recency and effort type
        let daysAgo = Date().timeIntervalSince(activity.date) / 86400
        let recencyFactor = exp(-daysAgo / 30)  // Decay over 30 days
        let effortFactor = activity.type == .race ? 1.2 : 1.0
        let confidence = recencyFactor * effortFactor
        
        maxHRCandidates.append((hr: peakHR, confidence: confidence))
    }
    
    guard !maxHRCandidates.isEmpty else { return nil }
    
    // Weighted average of top 3 candidates
    let topCandidates = maxHRCandidates.sorted { $0.confidence > $1.confidence }.prefix(3)
    let weightedSum = topCandidates.reduce(0.0) { $0 + ($1.hr * $1.confidence) }
    let weightSum = topCandidates.reduce(0.0) { $0 + $1.confidence }
    let detectedMaxHR = weightedSum / weightSum
    
    Logger.debug("❤️ Detected Max HR: \(Int(detectedMaxHR)) bpm")
    return detectedMaxHR
}

func calculateHRZones(maxHR: Double) -> [HRZone] {
    let lthr = maxHR * 0.90  // Lactate threshold ≈ 90% max
    
    return [
        HRZone(number: 1, name: "Active Recovery", min: 0, max: maxHR * 0.68),
        HRZone(number: 2, name: "Endurance", min: maxHR * 0.68, max: maxHR * 0.83),
        HRZone(number: 3, name: "Tempo", min: maxHR * 0.84, max: maxHR * 0.94),
        HRZone(number: 4, name: "Threshold", min: lthr * 0.95, max: lthr * 1.05),
        HRZone(number: 5, name: "VO2max", min: lthr * 1.05, max: maxHR)
    ]
}
```

**UI Integration:**
- Show detected max HR in Settings > Zones
- Display zones with color-coded bands
- Allow manual override
- Show confidence indicator
