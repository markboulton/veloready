# ML Phase 2 Implementation Plan

## Executive Summary

**Objective:** Implement personalized ML-based recovery predictions using on-device training and inference.

**Timeline:** 4 weeks (while collecting remaining data)

**Scope:**
- Enhanced feature engineering (4 new features)
- Privacy-focused telemetry infrastructure
- On-device model training pipeline
- Personalized recovery predictions
- Apple Watch data integration
- Production-ready deployment

**Current Status:** Phase 1 complete - collecting data (12/30 days)

---

## Phase 2 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     VeloReady ML Pipeline                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  HealthKit Data → Feature Engineering → Core Data Storage   │
│                          ↓                                    │
│                   Training Dataset                            │
│                          ↓                                    │
│                  Model Training (30+ days)                   │
│                          ↓                                    │
│                  Personalized Predictions                     │
│                          ↓                                    │
│              Enhanced Recovery Score (UI)                     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Week 1: Enhanced Feature Engineering + Telemetry

### Objectives
- Add 4 critical features that improve model accuracy
- Implement privacy-focused telemetry infrastructure
- Validate features with unit tests
- Start collecting enhanced data

### New Features

#### 1. Training Monotony & Strain
**Purpose:** Detect lack of training variation (overtraining risk indicator)

**Formula:**
```swift
trainingMonotony = average(tss_last_7_days) / standardDeviation(tss_last_7_days)
trainingStrain = sum(tss_last_7_days) * trainingMonotony
```

**Interpretation:**
- Monotony > 2.0: High risk (training too similar)
- Monotony 1.5-2.0: Moderate risk
- Monotony < 1.5: Good variation

**Research Basis:** Foster (1998) - Monitoring training in athletes with reference to overtraining syndrome

#### 2. Acute Sleep Debt
**Purpose:** Cumulative sleep deficit is better predictor than single-night duration

**Formula:**
```swift
sleepDebt = sum(max(0, sleepTarget - actualSleep)) for last 7 days
```

**Interpretation:**
- 0-2 hours: Minimal debt
- 2-5 hours: Moderate debt (recovery impaired)
- 5+ hours: Severe debt (high fatigue risk)

**Research Basis:** Van Dongen et al. (2003) - Cumulative dose-response effects of chronic sleep restriction

#### 3. Days Since Last Hard Effort
**Purpose:** Recent hard training has more impact on current recovery than distant efforts

**Formula:**
```swift
daysSinceHardEffort = today - max(date where tss > 100 OR rpe > 7)
```

**Interpretation:**
- 0-1 days: Acute fatigue likely
- 2-3 days: Partial recovery
- 4+ days: Full recovery window

**Research Basis:** Training load decay models (exponential recovery curves)

#### 4. HRV Coefficient of Variation (CV)
**Purpose:** HRV stability indicates adaptation quality

**Formula:**
```swift
hrvCV = (standardDeviation(hrv_last_7_days) / mean(hrv_last_7_days)) * 100
```

**Interpretation:**
- CV < 5%: Very stable (good adaptation)
- CV 5-10%: Normal variation
- CV > 10%: High instability (stress/illness/poor adaptation)

**Research Basis:** Plews et al. (2013) - HRV variability in endurance athletes

### Telemetry Infrastructure

#### Events to Track
```swift
// Model Performance
"ml_prediction_made" → { mae, inference_time_ms, model_version }
"ml_training_completed" → { training_time_s, sample_count, validation_mae }
"ml_feature_importance" → { top_3_features, model_version }

// Data Quality
"ml_data_collection_milestone" → { days_collected, valid_days }
"ml_feature_missing" → { feature_name, frequency }

// User Behavior
"ml_personalization_enabled" → { days_until_enabled }
"ml_personalization_disabled" → { reason }
"ml_info_sheet_viewed" → { source }
```

#### Privacy Rules
- ✅ Aggregate metrics only (no individual values)
- ✅ Round all numbers to nearest 5
- ✅ No PII, no health data values
- ✅ User can disable telemetry
- ✅ On-device processing only

#### Implementation
- Use **TelemetryDeck** (privacy-focused, GDPR-compliant)
- Fallback to OSLog if telemetry disabled
- Batch events (send max 1x per hour)

### Files to Create/Modify

**New Files:**
- `VeloReady/Core/ML/Services/MLTelemetryService.swift`
- `VeloReady/Core/ML/Models/MLFeatureVector+Enhanced.swift`
- `VeloReadyTests/ML/FeatureEngineerEnhancedTests.swift`

**Modified Files:**
- `VeloReady/Core/ML/Services/FeatureEngineer.swift`
- `VeloReady/Core/ML/Models/MLFeatureVector.swift`

### Testing Checklist
- [ ] Unit tests for each new feature calculation
- [ ] Validate with edge cases (no data, partial data, outliers)
- [ ] Verify telemetry events fire correctly
- [ ] Confirm no PII in telemetry payloads
- [ ] Performance test: Feature extraction < 100ms

### Success Criteria
- ✅ All 4 features calculate correctly
- ✅ Telemetry integration complete
- ✅ Unit test coverage > 80%
- ✅ Build succeeds
- ✅ No performance regression

---

## Week 2: Model Training Pipeline

### Objectives
- Build infrastructure to train Create ML regression model
- Convert Core Data → Create ML format
- Implement train/validation split
- Train initial model on collected data
- Evaluate model performance

### Model Architecture

**Type:** Tabular Regression (Create ML)

**Inputs:** 38 features from `MLFeatureVector`
- Demographics: 2 features
- Recovery metrics: 6 features
- Training load: 8 features
- Sleep metrics: 6 features
- Temporal features: 4 features
- **NEW** Enhanced features: 4 features
- Derived features: 8 features

**Output:** Predicted recovery score (0-100)

**Algorithm:** Boosted Tree Regressor
- Handles non-linear relationships
- Feature importance built-in
- Fast inference (< 50ms)
- Small model size (< 1MB)

### Dataset Preparation

**Format:** Create ML Table
```swift
struct TrainingRow {
    // Features (38 columns)
    let age: Int
    let weight: Double
    let hrv: Double
    let rhr: Double
    // ... all 38 features
    
    // Target
    let recoveryScore: Double
}
```

**Data Split:**
- Training: 80% (oldest data)
- Validation: 20% (most recent data)
- Minimum samples: 30 days

**Data Quality Rules:**
- Only include days with quality score ≥ 0.6
- Remove outliers (recovery score > 3σ from mean)
- Handle missing features (impute with median)

### Training Pipeline

```swift
class MLModelTrainer {
    func prepareDataset() -> MLDataTable
    func trainModel(dataset: MLDataTable) -> MLModel
    func validateModel(model: MLModel, testData: MLDataTable) -> ValidationMetrics
    func exportModel(model: MLModel, to path: URL)
}
```

**Training Parameters:**
- Max iterations: 100
- Validation fraction: 0.2
- Max depth: 6
- Min loss reduction: 0.01

**Validation Metrics:**
- MAE (Mean Absolute Error) - target < 8 points
- RMSE (Root Mean Squared Error) - target < 10 points
- R² (Coefficient of Determination) - target > 0.7

### Files to Create

**New Files:**
- `VeloReady/Core/ML/Training/MLModelTrainer.swift`
- `VeloReady/Core/ML/Training/MLDatasetBuilder.swift`
- `VeloReady/Core/ML/Training/MLValidationMetrics.swift`
- `VeloReady/Core/ML/Models/PersonalizedRecovery.mlmodel` (generated)
- `VeloReadyTests/ML/MLModelTrainerTests.swift`

### Testing Checklist
- [ ] Dataset builder handles missing data correctly
- [ ] Train/test split is deterministic
- [ ] Model trains successfully with 30 samples
- [ ] Validation MAE < 10 points (initial target)
- [ ] Model file size < 1MB
- [ ] Inference time < 50ms

### Success Criteria
- ✅ Model trains successfully
- ✅ Validation MAE < 10 points
- ✅ R² > 0.6 (initial model)
- ✅ No crashes during training
- ✅ Model exports correctly

---

## Week 3: Prediction Service & Integration

### Objectives
- Create inference service for predictions
- Integrate with existing RecoveryScoreService
- Implement fallback to rule-based scoring
- Add A/B testing mode for validation
- Update UI to show personalization

### Prediction Architecture

```
RecoveryScoreService
    ↓
    ├─ ML Available? → PersonalizedRecoveryCalculator (ML)
    │                      ↓
    │                  MLPredictionService
    │                      ↓
    │                  PersonalizedRecovery.mlmodel
    │
    └─ ML Not Available → RuleBasedRecoveryCalculator
                              ↓
                          Current Algorithm
```

**Decision Logic:**
```swift
func calculateRecoveryScore() -> RecoveryScore {
    if mlService.isModelAvailable && mlService.hasSufficientData {
        return personalizedCalculator.predict()
    } else {
        return ruleBasedCalculator.calculate()
    }
}
```

### Prediction Service

```swift
class MLPredictionService {
    func predict(features: MLFeatureVector) -> PredictionResult
    func getPredictionConfidence() -> Double
    func getFeatureImportance() -> [String: Double]
}

struct PredictionResult {
    let score: Double
    let confidence: Double
    let method: PredictionMethod // .personalized or .ruleBased
    let timestamp: Date
}
```

### Enhanced Recovery Score

**New Properties:**
```swift
struct RecoveryScore {
    // Existing
    let score: Int
    let inputs: RecoveryInputs
    
    // NEW
    let isPersonalized: Bool
    let confidence: Double?
    let predictionMethod: PredictionMethod
}
```

### UI Updates

**Recovery Score Badge:**
```swift
// Show "Personalized" badge when ML is active
if recoveryScore.isPersonalized {
    HStack {
        Text("\(recoveryScore.score)")
        Image(systemName: "sparkles")
            .foregroundColor(.blue)
    }
}
```

**Debug Mode (A/B Testing):**
```swift
// Show both scores side-by-side
VStack {
    Text("ML Prediction: \(mlScore)")
    Text("Rule-Based: \(ruleScore)")
    Text("Difference: \(abs(mlScore - ruleScore))")
}
```

### Settings Integration

**New Settings:**
- Toggle: "Use Personalized Insights" (default: ON)
- Info: "When disabled, uses rule-based scoring"
- Button: "Retrain Model" (clears and retrains)

### Files to Create/Modify

**New Files:**
- `VeloReady/Core/ML/Services/MLPredictionService.swift`
- `VeloReady/Core/ML/Services/PersonalizedRecoveryCalculator.swift`
- `VeloReady/Core/ML/Models/PredictionResult.swift`
- `VeloReady/Features/Settings/Views/MLPersonalizationSettings.swift`

**Modified Files:**
- `VeloReady/Core/Services/RecoveryScoreService.swift`
- `VeloReady/Core/Models/RecoveryScore.swift`
- `VeloReady/Features/Today/Views/RecoveryMetricsSection.swift`

### Testing Checklist
- [ ] Prediction service returns valid scores (0-100)
- [ ] Fallback works when model unavailable
- [ ] Confidence scores are reasonable (0.0-1.0)
- [ ] UI shows personalization indicator
- [ ] Settings toggle works correctly
- [ ] A/B test mode shows both scores

### Success Criteria
- ✅ Predictions match validation accuracy (MAE < 10)
- ✅ Fallback to rule-based works seamlessly
- ✅ UI clearly indicates personalization status
- ✅ No performance regression
- ✅ Settings integration complete

---

## Week 4: Apple Watch Integration & Polish

### Objectives
- Sync HRV/RHR data from Apple Watch
- Prefer Watch data over iPhone data
- Create Watch complication showing recovery score
- Final testing and validation
- Production deployment

### Watch Data Priority

**Data Source Preference:**
1. **Apple Watch** (if worn overnight)
2. **iPhone** (fallback)
3. **Manual entry** (last resort)

**Implementation:**
```swift
func getBestHRVSample(for date: Date) -> HKQuantitySample? {
    let watchSamples = hrvSamples.filter { $0.device?.isAppleWatch == true }
    let phoneSamples = hrvSamples.filter { $0.device?.isAppleWatch == false }
    
    // Prefer Watch, fallback to iPhone
    return watchSamples.first ?? phoneSamples.first
}
```

### Watch Complication

**Complication Family:** Circular

**Display:**
```
┌─────────┐
│   85    │ ← Recovery Score
│ ━━━━━━  │ ← Score bar (color-coded)
└─────────┘
```

**Update Schedule:**
- Background: Every 30 minutes
- On wrist raise: Immediate
- After workout: Immediate

**Complications Supported:**
- `.circularSmall`
- `.modularSmall`
- `.graphicCircular`
- `.graphicCorner`

### Watch Connectivity

```swift
class WatchConnectivityManager {
    func syncRecoveryScore()
    func syncTodaysMetrics()
    func requestDataUpdate()
}

// Messages
"recovery_score_update" → { score, timestamp, isPersonalized }
"request_full_sync" → triggers complete data refresh
```

### Final Polish

**Performance Optimization:**
- [ ] Cache predictions (invalidate daily)
- [ ] Batch Core Data fetches
- [ ] Lazy load historical data
- [ ] Profile memory usage

**Edge Case Handling:**
- [ ] First-time users (no model yet)
- [ ] Data gaps (travel, device change)
- [ ] Model retraining (weekly background task)
- [ ] Low confidence predictions (show warning)

**Documentation:**
- [ ] Update user-facing help content
- [ ] Code documentation (DocC)
- [ ] API documentation
- [ ] Deployment checklist

### Files to Create

**New Files:**
- `VeloReady/Core/Services/WatchConnectivityManager.swift`
- `VeloReadyWidget/VeloReadyComplication.swift`
- `VeloReadyWidget/ComplicationController.swift`
- `VeloReady/Core/ML/Services/ModelRetrainingService.swift`

### Testing Checklist
- [ ] Watch data syncs correctly
- [ ] Complication updates on schedule
- [ ] Complication shows correct score
- [ ] Background updates work
- [ ] Battery impact < 5% daily
- [ ] Memory usage < 50MB

### Success Criteria
- ✅ Watch integration complete
- ✅ Complication displays correctly
- ✅ All edge cases handled
- ✅ Performance optimized
- ✅ Ready for production

---

## Privacy & Security Considerations

### On-Device Processing
- ✅ All ML training happens on iPhone
- ✅ Model never leaves device (except via iCloud sync)
- ✅ No cloud-based inference
- ✅ No data sent to servers

### Data Minimization
- ✅ Only collect necessary features
- ✅ Delete old training data (keep last 90 days)
- ✅ User can delete all ML data
- ✅ Clear data on app uninstall

### Transparency
- ✅ Explain ML in user-facing content
- ✅ Show when personalization is active
- ✅ Allow disabling personalization
- ✅ Show data usage in Settings

### iCloud Sync
- ✅ Model syncs via CloudKit (encrypted)
- ✅ Training data syncs (encrypted)
- ✅ User controls sync settings
- ✅ Works offline (local model only)

---

## Testing Strategy

### Unit Tests
- Feature engineering calculations
- Model training pipeline
- Prediction service logic
- Data quality scoring

### Integration Tests
- HealthKit → Features → Core Data
- Core Data → Training → Model
- Model → Predictions → UI

### Performance Tests
- Feature extraction: < 100ms
- Model inference: < 50ms
- Training time: < 10s
- Memory usage: < 50MB

### User Acceptance Tests
- First-time user flow
- Model activation (day 30)
- Personalization toggle
- Watch sync
- Data deletion

---

## Deployment Checklist

### Pre-Launch
- [ ] All tests passing (unit + integration)
- [ ] Performance benchmarks met
- [ ] Privacy review complete
- [ ] Documentation updated
- [ ] Telemetry integration tested
- [ ] Beta testing with 5+ users

### Launch Day
- [ ] Feature flag: "ml_personalization_enabled" = true
- [ ] Monitor telemetry for errors
- [ ] Watch crash reports
- [ ] Monitor prediction accuracy
- [ ] User feedback collection

### Post-Launch (Week 1)
- [ ] Review telemetry data
- [ ] Analyze prediction accuracy across users
- [ ] Collect user feedback
- [ ] Fix any critical bugs
- [ ] Plan Phase 3 improvements

---

## Success Metrics

### Phase 2 Goals
- **Prediction Accuracy:** MAE < 8 points (vs. rule-based)
- **User Adoption:** 60%+ keep personalization enabled
- **Performance:** No user-reported lag or crashes
- **Data Quality:** 80%+ users reach 30 days within 45 days

### Phase 3 Targets (Future)
- **Advanced Predictions:** MAE < 5 points
- **Forecasting:** Predict recovery 1-3 days ahead
- **Adaptive Weights:** Per-user feature importance
- **LSTM Models:** Time-series predictions

---

## Next Steps After Phase 2

### Immediate (Phase 2.1)
- Model retraining schedule (weekly background)
- Prediction confidence UI improvements
- Feature importance visualization
- User education in-app tutorial

### Short-term (Phase 3)
- Adaptive feature weighting per user
- Multi-day recovery forecasting
- Training load recommendations
- Illness/injury detection

### Long-term (Phase 4+)
- LSTM time-series models
- Workout recommendation engine
- Peak performance prediction
- Social benchmarking (privacy-preserved)

---

## Risk Mitigation

### Technical Risks
| Risk | Mitigation |
|------|-----------|
| Model overfits to small dataset | Use cross-validation, regularization |
| Prediction accuracy poor | Fallback to rule-based, iterate on features |
| Performance issues | Profile early, optimize hot paths |
| Memory leaks | Comprehensive testing, instruments profiling |

### Product Risks
| Risk | Mitigation |
|------|-----------|
| Users don't trust ML | Transparency, show both scores in debug |
| Users disable personalization | Make opt-in default, show benefits |
| Privacy concerns | Clear communication, on-device only |
| Poor user experience | Extensive beta testing, gradual rollout |

---

## Resources & References

### Research Papers
- Foster (1998) - Training monotony and strain
- Van Dongen et al. (2003) - Sleep debt effects
- Plews et al. (2013) - HRV in endurance athletes
- Buchheit (2014) - Monitoring training status with HRV

### Apple Documentation
- Create ML Framework
- Core ML Integration
- HealthKit Best Practices
- Watch Complications

### Tools
- TelemetryDeck (privacy-focused analytics)
- Create ML (model training)
- Instruments (performance profiling)
- XCTest (unit testing)

---

## Timeline Summary

```
Week 1: Feature Engineering + Telemetry
├─ Day 1-2: Add 4 new features
├─ Day 3-4: Implement telemetry
└─ Day 5: Testing & validation

Week 2: Model Training Pipeline
├─ Day 1-2: Dataset builder
├─ Day 3-4: Training pipeline
└─ Day 5: Initial model training

Week 3: Prediction Service
├─ Day 1-2: Inference service
├─ Day 3-4: Integration with RecoveryScoreService
└─ Day 5: UI updates & testing

Week 4: Watch Integration & Polish
├─ Day 1-2: Watch data sync
├─ Day 3-4: Complication
└─ Day 5: Final testing & deployment
```

**Total Duration:** 4 weeks (parallel with data collection)

**Estimated Effort:** ~60-80 hours

**Completion Target:** 18 days from now (when 30 days of data collected)

---

## Document Version
- **Version:** 1.0
- **Created:** October 19, 2025
- **Author:** ML Phase 2 Implementation Team
- **Status:** READY TO IMPLEMENT
