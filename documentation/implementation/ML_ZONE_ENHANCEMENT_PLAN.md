# ML-Enhanced Adaptive Zones - Implementation Plan

**Status:** Ready for Phase 3 (after Phase 2 ML infrastructure complete)  
**Timeline:** 2-3 weeks  
**Priority:** High - Unique differentiator vs. competitors

---

## Executive Summary

Enhance adaptive training zones with ML personalization to create context-aware, individualized zone boundaries that adapt to current fitness and fatigue state.

**Key Innovation:** No other cycling app adjusts zones based on real-time recovery and fatigue. This is a **major competitive advantage**.

---

## Current State (After Strava-First Implementation)

✅ **Completed Today:**
- Strava activities are PRIMARY data source
- Intelligent activity merging (Strava + Intervals.icu)
- Pro: 365 days, Free: 90 days
- Cached for performance (1 hour TTL)
- Critical Power model for FTP computation
- HR lactate threshold detection

**Current Algorithm (Sports Science-Based):**
```swift
// Critical Power model (Burnley & Jones 2018)
- Analyzes power distribution across activities
- Computes FTP from 20-minute best power × 0.95
- Detects lactate threshold from HR/power relationship
- Generates 7-zone power/HR boundaries (Coggan model)
```

**Limitations:**
- ❌ Doesn't account for current fitness changes
- ❌ Doesn't adjust for fatigue/recovery state
- ❌ Uses generic zone boundaries (not personalized)
- ❌ Static zones (don't adapt intra-week)

---

## ML Enhancement Opportunities

### A. **FTP/LTHR Trend Prediction** (Phase 3, Week 1-2)

**Problem:** Zones are only updated when you manually trigger recomputation. By the time zones update, you've already been training at wrong intensities for days/weeks.

**ML Solution:** Predict FTP/LTHR trends BEFORE they happen.

**How It Works:**
```swift
class FTPTrendPredictor {
    func predictFTPChange(
        currentFTP: Double,
        recentActivities: [Activity],  // Last 30 days
        recoveryScores: [Double],      // Daily recovery
        trainingLoad: TrainingLoad     // CTL/ATL/TSB
    ) async -> FTPPrediction {
        // ML model inputs:
        // - Current FTP
        // - Recent power curve trends (5s, 1min, 5min, 20min)
        // - Average recovery score (last 7 days)
        // - Training load (CTL rising/falling?)
        // - Days since last hard effort
        
        let prediction = await mlModel.predict(features)
        
        return FTPPrediction(
            predictedFTP: prediction.ftp,
            confidence: prediction.confidence,
            changeDirection: prediction.direction,  // .improving, .declining, .stable
            daysUntilChange: prediction.daysUntil
        )
    }
}

struct FTPPrediction {
    let predictedFTP: Double
    let confidence: Double          // 0.0-1.0
    let changeDirection: Direction  // .improving, .declining, .stable
    let daysUntilChange: Int       // How soon
}
```

**Example:**
```
Current FTP: 250W
Recent trends:
- 20min power: +5W over last 2 weeks
- Recovery score: Avg 85 (good)
- CTL: Rising (+3 points/week)

ML Prediction:
  FTP will increase to 255W in 3-5 days
  Confidence: 82%
  Recommendation: Update zones proactively
```

**Benefits:**
- ✅ Always training at correct intensity
- ✅ Proactive zone updates (not reactive)
- ✅ Catches declining fitness early

**Training Data:**
- Input: Activity history (30d), recovery, training load
- Target: Actual FTP change measured 7 days later
- Collect data: 60 days (enough for patterns)

---

### B. **Personalized Zone Boundaries** (Phase 3, Week 2-3)

**Problem:** Everyone uses same zone percentages (Coggan model). But physiology varies:
- Some athletes have higher anaerobic capacity
- Some have better lactate clearance
- Some recover faster between intervals

**ML Solution:** Learn YOUR personal zone boundaries.

**How It Works:**
```swift
class PersonalizedZoneCalculator {
    func personalizeZones(
        baseFTP: Double,
        activities: [Activity],
        userProfile: UserPhysiology
    ) async -> PersonalizedZones {
        // ML learns:
        // - Your lactate threshold (not generic 95% max HR)
        // - Your anaerobic capacity (W' varies person to person)
        // - Your VO2max power (not generic 120% FTP)
        // - Your recovery between intervals
        
        let personalizedBoundaries = await mlModel.learnBoundaries(
            ftp: baseFTP,
            powerCurve: activities.powerCurve,
            hrResponse: activities.hrResponse,
            recoveryRate: activities.recoveryRate
        )
        
        return PersonalizedZones(
            recovery: 0...personalizedBoundaries.endurance,
            endurance: personalizedBoundaries.endurance...personalizedBoundaries.tempo,
            tempo: personalizedBoundaries.tempo...personalizedBoundaries.threshold,
            threshold: personalizedBoundaries.threshold...personalizedBoundaries.vo2max,
            vo2max: personalizedBoundaries.vo2max...personalizedBoundaries.anaerobic,
            anaerobic: personalizedBoundaries.anaerobic...personalizedBoundaries.neuromuscular,
            neuromuscular: personalizedBoundaries.neuromuscular...999
        )
    }
}
```

**Example:**
```
Generic Coggan Zones (FTP 250W):
Z1: 0-138W    (< 55%)
Z2: 138-188W  (56-75%)
Z3: 188-213W  (76-90%)
Z4: 213-250W  (91-105%)
Z5: 250-300W  (106-120%)
Z6: 300-375W  (121-150%)
Z7: 375W+     (> 150%)

YOUR Personalized Zones (ML-learned):
Z1: 0-145W    (< 58%)  ← Higher endurance capacity
Z2: 145-195W  (58-78%)
Z3: 195-220W  (78-88%)  ← Narrower tempo zone
Z4: 220-255W  (88-102%) ← Higher threshold tolerance
Z5: 255-315W  (102-126%) ← Better VO2max
Z6: 315-380W  (126-152%)
Z7: 380W+     (> 152%)
```

**Benefits:**
- ✅ Zones match YOUR physiology
- ✅ More accurate training prescription
- ✅ Better interval pacing

**Training Data:**
- Input: Power curve, HR response, recovery patterns
- Target: Observed performance at each intensity
- Collect data: 90 days (need varied intensities)

---

### C. **Context-Aware Zone Adjustments** (Phase 4, Week 1-2)

**Problem:** Your zones should change based on current state:
- Fatigued? Reduce zones
- Fresh? Increase zones
- Illness? Significantly reduce zones

**ML Solution:** Real-time zone adjustment based on recovery score.

**How It Works:**
```swift
class ContextAwareZoneService {
    func getAdjustedZones(
        baseZones: PowerZones,
        recoveryScore: Double,
        recentTrainingLoad: TrainingLoad
    ) -> AdjustedZones {
        // Calculate adjustment factor based on recovery
        let adjustment = calculateAdjustment(
            recoveryScore: recoveryScore,
            atl: recentTrainingLoad.atl,
            tsb: recentTrainingLoad.tsb
        )
        
        // Apply to all zones
        return AdjustedZones(
            zones: baseZones.map { $0 * adjustment },
            adjustmentFactor: adjustment,
            reason: getAdjustmentReason(adjustment)
        )
    }
    
    private func calculateAdjustment(
        recoveryScore: Double,
        atl: Double,
        tsb: Double
    ) -> Double {
        switch recoveryScore {
        case 0..<40:   return 0.80  // Fatigued: -20%
        case 40..<60:  return 0.90  // Low: -10%
        case 60..<80:  return 1.00  // Normal: 0%
        case 80..<95:  return 1.05  // Good: +5%
        case 95...100: return 1.08  // Excellent: +8%
        default:       return 1.00
        }
    }
}
```

**Example:**
```
Tuesday (Recovery Score: 45 - Fatigued)
Base FTP: 250W
Adjusted FTP: 225W (-10%)
Z4 Threshold: 202-225W (instead of 225-250W)
→ App shows: "Adjusted for recovery state"

Sunday (Recovery Score: 92 - Fresh)
Base FTP: 250W
Adjusted FTP: 262W (+5%)
Z4 Threshold: 235-262W (instead of 225-250W)
→ App shows: "Fresh - zones increased"
```

**Benefits:**
- ✅ Always training at appropriate intensity
- ✅ Prevents overtraining
- ✅ Optimizes hard days when fresh

---

## Implementation Plan

### **Phase 3: ML Zone Enhancements** (Weeks 5-7 after Phase 2)

#### Week 5: FTP Trend Prediction

**Day 1-2: Model Development**
- [ ] Create `FTPTrendPredictor.swift`
- [ ] Define features for FTP prediction
- [ ] Create training dataset from existing data
- [ ] Train regression model (Core ML)

**Day 3-4: Integration**
- [ ] Integrate with `AthleteProfileManager`
- [ ] Add predictive FTP to profile
- [ ] Create UI indicator for predicted changes
- [ ] Test accuracy against actual FTP changes

**Day 5: Testing & Validation**
- [ ] Validate predictions on test data
- [ ] Add telemetry for prediction accuracy
- [ ] Test proactive zone updates

**Success Criteria:**
- ✅ Prediction MAE < 5 watts
- ✅ Confidence score > 0.7 for most predictions
- ✅ Zones update proactively

#### Week 6: Personalized Zone Boundaries

**Day 1-2: Boundary Learning**
- [ ] Create `PersonalizedZoneCalculator.swift`
- [ ] Analyze power curve patterns
- [ ] Detect personal lactate threshold
- [ ] Learn VO2max and anaerobic capacity

**Day 3-4: Zone Generation**
- [ ] Generate personalized zone boundaries
- [ ] Compare to Coggan model (show delta)
- [ ] Update zone display in UI
- [ ] Add "Personalized" badge to zones

**Day 5: Testing & Validation**
- [ ] Validate zones against workout data
- [ ] Test edge cases (new users, limited data)
- [ ] Add telemetry for zone accuracy

**Success Criteria:**
- ✅ Zones match observed performance
- ✅ Users can see personalized vs. standard
- ✅ Smooth fallback for new users

#### Week 7: Context-Aware Adjustments

**Day 1-2: Adjustment Logic**
- [ ] Create `ContextAwareZoneService.swift`
- [ ] Implement recovery-based adjustment
- [ ] Add training load consideration
- [ ] Test adjustment calculations

**Day 3-4: UI Integration**
- [ ] Show adjusted zones in workout views
- [ ] Add explanation ("Adjusted for recovery")
- [ ] Display adjustment factor (+5%, -10%)
- [ ] Update zone legends

**Day 5: Testing & Polish**
- [ ] Test all adjustment scenarios
- [ ] Validate against user feedback
- [ ] Performance testing
- [ ] Documentation

**Success Criteria:**
- ✅ Zones adjust correctly based on recovery
- ✅ Clear UI explanation
- ✅ Users understand adjustments

---

## Technical Architecture

### New Services

```
VeloReady/Core/ML/Services/Zones/
├── FTPTrendPredictor.swift          # Predict FTP changes
├── PersonalizedZoneCalculator.swift # Learn personal boundaries
├── ContextAwareZoneService.swift    # Real-time adjustments
└── ZonePredictionModel.mlmodel      # Trained ML model
```

### Models

```swift
// FTP Prediction Result
struct FTPPrediction {
    let currentFTP: Double
    let predictedFTP: Double
    let confidence: Double
    let changeDirection: Direction
    let daysUntilChange: Int
    let factors: [String: Double]  // Feature importance
}

// Personalized Zones
struct PersonalizedZones {
    let baseZones: [Double]        // Standard Coggan
    let personalizedZones: [Double] // ML-learned
    let adjustmentReasons: [String] // Why different
    let confidenceScore: Double
}

// Adjusted Zones (context-aware)
struct AdjustedZones {
    let zones: [Double]
    let adjustmentFactor: Double
    let reason: String
    let isTemporary: Bool
}
```

### Integration with Existing Systems

**AthleteProfile:**
```swift
struct AthleteProfile {
    // Existing
    var ftp: Double?
    var powerZones: [Double]?
    
    // NEW
    var predictedFTP: FTPPrediction?
    var personalizedZones: PersonalizedZones?
    var currentAdjustment: ZoneAdjustment?
}
```

**UI Updates:**
```swift
// Zone display shows:
"Adaptive Power Zones (Personalized)"
"FTP: 250W (predicted: 255W in 3 days)"
"Today's zones adjusted for recovery (-10%)"
```

---

## Data Requirements

### For FTP Trend Prediction:
- **Minimum:** 30 days of activity data
- **Optimal:** 90 days for accurate trends
- **Features:** Power curve, recovery scores, training load

### For Personalized Boundaries:
- **Minimum:** 60 days with varied intensities
- **Optimal:** 180 days (covers periodization)
- **Features:** Performance at each zone, HR response, recovery rate

### For Context-Aware Adjustments:
- **Minimum:** Current recovery score
- **Optimal:** 7 days recovery trend
- **Features:** Recovery score, training load, sleep

---

## Success Metrics

### Phase 3 Targets:

**FTP Prediction:**
- MAE < 5 watts (within 2%)
- Confidence > 70% for predictions
- Update zones 3-5 days before manual recomputation

**Personalized Zones:**
- Zones differ from Coggan by 5-15% (expected)
- Match actual performance within 3%
- User satisfaction > 80%

**Context-Aware Adjustments:**
- Adjustment applied when recovery < 60 or > 85
- Users complete workouts at adjusted zones
- Reduced overtraining markers

### User Impact:

**Before ML Zones:**
```
User training at FTP 250W
Recovery: 45 (fatigued)
Workout: 4x8min @ 240W (96% FTP)
Result: Couldn't complete, stopped at 3rd interval
```

**After ML Zones:**
```
User training at FTP 250W
Recovery: 45 (fatigued)
ML Adjustment: -10% (225W adjusted FTP)
Workout: 4x8min @ 216W (96% of adjusted)
Result: Completed all intervals successfully
```

---

## Competitive Advantage

**No other cycling app does this:**

| Feature | TrainerRoad | Zwift | Wahoo | VeloReady (Phase 3) |
|---------|-------------|-------|-------|---------------------|
| Adaptive FTP | ❌ Manual ramp test | ❌ Manual | ❌ Manual | ✅ ML-predicted |
| Personalized Zones | ❌ Generic Coggan | ❌ Generic | ❌ Generic | ✅ ML-learned |
| Context-Aware | ❌ Static | ❌ Static | ❌ Static | ✅ Recovery-adjusted |
| Real-time Updates | ❌ No | ❌ No | ❌ No | ✅ Daily adjustments |

**Market Positioning:**
> "VeloReady is the only app that adjusts your training zones based on how you feel today, not just what you did last month."

---

## Risk Mitigation

### Technical Risks:

| Risk | Mitigation |
|------|-----------|
| ML predictions inaccurate | Require 70% confidence, fallback to standard |
| Users confused by adjustments | Clear UI explanations, show why |
| Zones change too frequently | Rate limit: max 1x per day |
| Not enough training data | Require minimum 30/60 days |

### Product Risks:

| Risk | Mitigation |
|------|-----------|
| Users don't trust ML zones | Show both standard and personalized |
| Users prefer manual control | Allow disable, override |
| Pro feature gatekeeping | Phase 3A free, 3B/C Pro |
| Poor user adoption | Extensive education, benefits |

---

## Timeline Summary

```
Phase 3: ML Zone Enhancements
├─ Week 5: FTP Trend Prediction (5 days)
├─ Week 6: Personalized Boundaries (5 days)
└─ Week 7: Context-Aware Adjustments (5 days)

Total: 15 days (3 weeks)
Prerequisites: Phase 2 ML infrastructure complete
```

---

## Next Steps

### Immediate (Now):
1. ✅ Strava-first implementation (DONE)
2. ✅ Activity caching (DONE)
3. ⏸️ Wait for Phase 2 completion

### Week 5 Start:
1. Create FTPTrendPredictor skeleton
2. Define feature set for prediction
3. Start collecting training data
4. Build first prediction model

### Documentation:
- ✅ This plan document
- ⏸️ API documentation (Week 5)
- ⏸️ User education content (Week 7)

---

## Questions & Decisions

### Open Questions:

1. **Pro Gating:** Should all ML zone features be Pro, or some free?
   - **Recommendation:** FTP Prediction = Free, Personalized + Context = Pro

2. **UI Complexity:** How much detail to show users?
   - **Recommendation:** Simple by default, detail on tap

3. **Update Frequency:** How often to recalculate zones?
   - **Recommendation:** FTP daily, Personalized weekly, Context real-time

### Decisions Made:

- ✅ Strava is primary data source
- ✅ Use Core ML (on-device)
- ✅ Privacy-first (no cloud ML)
- ✅ Fallback to standard zones always available

---

## Conclusion

ML-enhanced adaptive zones represent a **major competitive differentiator** for VeloReady. By combining:
- Strava-first data strategy (done today)
- ML personalization (Phase 3)
- Context-aware adjustments (Phase 4)

We create training zones that are:
- ✅ More accurate (personalized to YOU)
- ✅ More timely (predict changes early)
- ✅ More adaptive (adjust to current state)

**No other app offers this level of sophistication.**

---

**For questions or planning:** Refer to this document and `ML_PHASE_2_IMPLEMENTATION_PLAN.md`

**Status:** Ready to implement after Phase 2 complete
