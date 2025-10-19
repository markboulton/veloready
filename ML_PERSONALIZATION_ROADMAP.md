# VeloReady ML Personalization: Your Training, Your Algorithm

## App Store Marketing Copy

**Every Athlete is Different. Why Should Your Recovery Score Be Generic?**

Most fitness apps use one-size-fits-all algorithms—what works for a 25-year-old cyclist doesn't work for a 45-year-old runner. VeloReady's machine learning adapts to YOUR body over time. After just 30 days, the app learns your unique recovery patterns: Are you HRV-driven or sleep-dominant? Do you recover faster on weekends? Does your baseline shift with your training cycle? The algorithm becomes yours, trained entirely on-device with your data, continuously improving as you train. No guesswork, no generic advice—just personalized insights that get smarter every week.

**Your Data Never Leaves Your Phone. Period.**

Unlike cloud-based fitness platforms, VeloReady's machine learning models train entirely on your device using Apple's CoreML framework. Your heart rate variability, sleep patterns, and training history stay private—encrypted on your iPhone and synced via your personal iCloud account. We don't collect, aggregate, or train centralized models. There's no "VeloReady database" with your health data. The algorithm learning your recovery patterns is unique to you, running locally, improving silently in the background. This is privacy-first personalization: all the benefits of AI without sacrificing your data.

**Built for Amateur Athletes Who Take Training Seriously**

Professional athletes have coaches and sports scientists analyzing their data. You don't. VeloReady brings that same level of personalization to amateur cyclists, runners, and strength athletes through adaptive machine learning. The app learns when you're pushing too hard before you feel it, predicts recovery based on your actual patterns (not textbook averages), and adjusts training recommendations as your fitness evolves. Whether you're training for a century ride, building strength, or maintaining fitness around a busy life, VeloReady's ML engine becomes your personal performance analyst—learning, adapting, and guiding you toward your goals without burnout.

---

## Integration with Existing Architecture

### ML + Current VeloReady Infrastructure

#### AI Brief Service Enhancement
**Current:** OpenAI GPT-4o-mini generates coaching based on rule-based recovery scores  
**Enhanced:** ML predictions create more nuanced, personalized coaching

```
iOS App (On-Device ML)
  ↓
ML Recovery Engine → Personalized score (68, confidence 85%)
  ↓
AIBriefService.buildRequest() → Includes ML metadata
  ↓
Netlify ai-brief.ts → GPT-4o-mini with context:
  "Your sleep was short but HRV is stable for you,
   suggesting your body adapted well to yesterday's load..."
```

**Enhanced API Request Schema:**
```typescript
interface AIBriefRequest {
  recovery: number;              // ML-predicted
  // ... existing fields ...
  mlEnhanced: boolean;           // NEW
  mlConfidence: number;          // NEW: 0-100
  mlVersion: string;             // NEW: "v1.2-adaptive"
  keyFactors: string[];          // NEW: ["sleep_deficit", "hrv_stable"]
  personalizedWeights: {         // NEW: user's learned weights
    hrv: number;
    rhr: number;
    sleep: number;
    load: number;
  } | null;
}
```

#### iCloud Sync Integration
**New Core Data Entity:**
```swift
@objc(MLTrainingData)
public class MLTrainingData: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var featureVector: Data
    @NSManaged public var modelVersion: String
    @NSManaged public var predictionAccuracy: Double?
}
```
- Training data syncs across devices via CloudKit
- Model files stored locally (each device trains independently)
- Ensures consistency across iPhone/iPad/Watch

#### Enhanced Caching Strategy
```
IntervalsCache (activities)
  ↓
MLFeatureCache (processed features, 90 days)
  ↓ weekly retrain
MLModelCache (trained models + metadata)
  ↓ daily
MLPredictionCache (today's predictions)
  ↓
AIBriefCache (coaching briefs, ML-aware)
```

**Cache Invalidation:**
- New workout logged → Invalidate feature + prediction caches
- Weekly model retrain → Invalidate model + prediction caches
- Historical data added → Flag for model retrain

---

## 4-Phase Implementation Plan

### Phase 1: Foundation & Data Pipeline (Weeks 1-2)
**Goal:** Build ML infrastructure without disrupting existing algorithms

**Key Components:**
1. **HistoricalDataAggregator** - Pulls 90 days from Core Data, HealthKit, Intervals.icu
2. **FeatureEngineer** - Transforms raw data into ML-ready features (rolling averages, deltas, lag features)
3. **MLTrainingData Entity** - Core Data storage for processed training data
4. **MLModelRegistry** - Version management, deployment, rollback system

**Deliverables:**
- ✅ New Core Data entity (syncs via iCloud)
- ✅ Automated data aggregation (runs daily in background)
- ✅ Feature extraction pipeline
- ✅ Model registry with fallback system
- ✅ Zero user-facing changes (infrastructure only)

---

### Phase 2: Personalized Baselines (Weeks 3-4)
**Goal:** Replace static 30-day averages with context-aware baselines

**Four Baseline Models:**

1. **HRV Baseline Model**
   - Inputs: Day of week, recent CTL/ATL, sleep quality, days since hard workout
   - Output: Expected HRV today (accounting for Monday dips, training cycles)

2. **RHR Baseline Model**
   - Inputs: Day of week, recovery state, sleep duration, alcohol/illness markers
   - Output: Expected RHR today

3. **Sleep Baseline Model**
   - Inputs: Training load today, accumulated sleep debt, day of week
   - Output: Expected sleep need tonight

4. **Recovery Baseline Model**
   - Inputs: Today's workout load, current recovery, planned sleep
   - Output: Expected recovery tomorrow

**Training:** CreateML Tabular Regressor (on-device, weekly retraining)

**Integration:**
```swift
// Enhanced BaselineCalculator
func calculateHRVBaseline() async -> Double? {
    if let mlBaseline = await mlPredictor.predict(), confidence > 0.7 {
        // Blend 80% ML, 20% rule-based for safety
        return (mlBaseline * 0.8) + (ruleBasedBaseline * 0.2)
    }
    return ruleBasedBaseline  // Fallback
}
```

**User Experience:**
- Before: "HRV 45ms (baseline: 52ms) ⚠️"
- After: "HRV 45ms (your Monday baseline: 47ms) ✅ Normal for you"

**Deliverables:**
- ✅ Four baseline models trained per user
- ✅ ML-enhanced BaselineCalculator
- ✅ Context-aware UI messages
- ✅ ~15-20% improvement in baseline accuracy

---

### Phase 3: Adaptive Weight Learning (Weeks 5-8)
**Goal:** Learn individual response patterns (HRV-driven vs sleep-driven vs load-sensitive)

**Outcome Inference System:**
- Proxy 1: Recovery prediction accuracy (predicted vs actual)
- Proxy 2: Training adherence (readiness high → trained well = good outcome)
- Proxy 3: Load management (smooth CTL growth = good training)
- Proxy 4: Physiological coherence (HRV/RHR/sleep all agree = high confidence)

**Weight Optimization:**
```
Current (fixed):  recovery = (HRV×0.4) + (RHR×0.3) + (Sleep×0.2) + (Load×0.1)

ML-learned examples:
User A (HRV-responsive): HRV×0.6, RHR×0.2, Sleep×0.1, Load×0.1
User B (Sleep-dominant):  HRV×0.2, RHR×0.2, Sleep×0.5, Load×0.1
User C (Load-sensitive):  HRV×0.3, RHR×0.2, Sleep×0.2, Load×0.3
```

**Multi-Model Architecture:**
- Recovery Predictor (tomorrow's recovery)
- Readiness Predictor (today's training readiness)
- Optimal TSS Predictor (ideal training load)
- Risk Predictor (injury/illness early warning)

**Confidence Scoring:**
- High (>80%): Use ML fully
- Medium (50-80%): Blend ML + rule-based
- Low (<50%): Fall back to rules

**Deliverables:**
- ✅ Personalized weight optimization per user
- ✅ Four prediction models (recovery, readiness, TSS, risk)
- ✅ Confidence scoring system
- ✅ ~25-30% improvement in individual prediction accuracy

---

### Phase 4: Predictive Model + Continuous Learning (Weeks 9-12)
**Goal:** Proactive recommendations, anomaly detection, continuous improvement

**LSTM Time-Series Predictor:**
- Input: 7-day rolling window of all metrics
- Output: 3-day recovery forecast
- Architecture: 2-layer LSTM (64 hidden units)
- Deployment: CoreML (trained externally, runs on-device)

**Anomaly Detection:**
```swift
1. Illness Detection
   → HRV drop + RHR spike + temp variation
   → Alert: "Possible illness, recommend rest"

2. Overtraining Detection
   → CTL rising + recovery declining 2+ weeks
   → Alert: "Plan deload week, reduce volume 40-50%"

3. Alcohol Impact
   → Overnight HRV suppression pattern
   → Alert: "Recovery compromised, keep intensity low"

4. Sleep Debt
   → Accumulated deficit >5 hours
   → Alert: "Prioritize sleep this week"
```

**Smart Recommendations:**
- Current: "Recommended TSS: 60-90"
- ML-powered: "Your optimal TSS today is 73 (±8) based on your fitness trajectory and recovery pattern"

**Continuous Learning Loop:**
- Weekly retraining (Sunday night, device charging)
- Performance tracking (monitor prediction accuracy)
- Automatic model updates (deploy if accuracy improves >10%)
- Data quality checks (flag missing/corrupted data)

**Explainability:**
```
"Your recovery is 68 today because:"
  ✅ HRV recovered to normal (+5 points)
  ⚠️ Sleep was 30min short (-8 points)
  ✅ Training load manageable (+3 points)
```

**Deliverables:**
- ✅ LSTM forecasting model
- ✅ Anomaly detection (4 types)
- ✅ ML-optimized TSS recommendations
- ✅ Weekly retraining pipeline
- ✅ Explainability layer in UI
- ✅ 35-40% improvement in prediction accuracy

---

## Success Metrics

### Phase 2 (Baselines)
- Baseline prediction MAE < 5% for HRV, < 2 BPM for RHR
- 100% of users with 30+ days data have models trained
- Zero crashes from ML code

### Phase 3 (Adaptive Weights)
- Recovery prediction MAE < 8 points (0-100 scale)
- 60%+ users have weights differing >20% from defaults
- No negative impact on user retention

### Phase 4 (Full Predictive)
- 3-day forecast MAE < 10 points
- Anomaly detection catches 80%+ of illness events
- Model retraining completes in <30 seconds
- User engagement increases (more daily app opens)

---

## Technical Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Model Training | CreateML (on-device) | Privacy-first, no backend needed |
| Model Type (Phase 2-3) | Tabular Regressor | Fast, interpretable, structured data |
| Model Type (Phase 4) | LSTM (CoreML) | Sequential pattern recognition |
| Feature Store | Core Data + iCloud | Already integrated |
| Inference | CoreML framework | Native iOS, <50ms latency |
| Monitoring | Logger + Analytics | Track accuracy, no PII |
| Fallback | Rule-based algorithms | Always available |

---

## Privacy Architecture

```
┌─────────────────────────────────────┐
│ User's iPhone (All ML processing)   │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ CoreML Models (personalized)    │ │
│ │ - Trained on YOUR data only     │ │
│ │ - Never leaves device           │ │
│ │ - Updated weekly in background  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ iCloud Sync (training data)     │ │
│ │ - Encrypted end-to-end          │ │
│ │ - YOUR iCloud account only      │ │
│ │ - No VeloReady servers          │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

No central model. No data collection. Pure privacy.
```

---

## User Journey Timeline

**Week 1 (New User):** Rule-based algorithms, data collection starts  
**Week 4 (30 Days):** First ML models train, personalized baselines active  
**Week 8 (60 Days):** Adaptive weights learned, predictions more accurate  
**Week 12+ (90+ Days):** Full predictive model, proactive recommendations

---

## Performance Impact

**ML Training:** Background only (2-3 AM, device charging)  
**ML Inference:** +25ms per prediction (<100ms total)  
**Battery Impact:** Negligible (<1% per day)  
**Storage:** ~50MB per year of training data

---

## Next Steps

1. Phase 1 detailed technical spec (Core Data schema, feature engineering)
2. CreateML model architecture (hyperparameters, validation strategy)
3. Testing plan (accuracy benchmarks, A/B testing)
4. UI updates (explainability views, confidence indicators)

**Ready to start Phase 1?**
