# VeloReady ML: Clear Next Steps

**Date:** October 30, 2025  
**Current Status:** 21 days collected, 9 days to go  
**Next Milestone:** November 8, 2025 (30 days)

---

## TL;DR

**What you asked:** "What is the plan for ML? Debug shows no model is being used."

**Answer:** 
- You have 21/30 days of data collected ✅
- Training infrastructure is built and ready ✅
- No model trained yet because you need 30 days minimum ⏳
- Debug correctly shows "None" - this is expected ✅

**What to do next:** Wait 9 days, then train model on Mac (1-2 hours)

---

## Today: Understanding (✅ YOU ARE HERE)

### What You Have
✅ **Data Collection:** 21 days automatically collected  
✅ **Infrastructure:** Complete ML pipeline built  
✅ **Features:** 38 features captured daily  
✅ **Training Code:** Ready to execute when you have 30 days

### What You Don't Have
❌ **Trained Model:** None (need 30 days minimum)  
❌ **Predictions:** Can't predict without model  
❌ **UI Updates:** Prediction service not implemented yet

### Why Debug Shows "No Model"
This is **correct and expected**. The app is:
- Collecting data daily ✅
- Storing to Core Data ✅
- Waiting for 30 days threshold ⏳
- Ready to train when you hit 30 days ✅

**Status:** Everything is working as designed.

---

## Next 9 Days: Passive Data Collection (Oct 31 - Nov 7)

### Your Action Items
- [ ] Continue using app normally
- [ ] Wear Apple Watch overnight (for HRV/RHR)
- [ ] Sync Intervals.icu daily (for TSS)
- [ ] No code changes needed

### What's Happening Automatically
The app collects data every day:
```
Daily App Launch:
1. Check: Is it a new day? ✓
2. Aggregate last 90 days from HealthKit/Strava/Intervals
3. Engineer 38 features per day
4. Store to Core Data
5. Update count: 22, 23, 24... → 30 days
```

### Optional: Monitor Progress
```
Settings → Debug → ML Infrastructure
Check: "Training Data: XX days"
```

**Expected:** Count increases by 1 each day

---

## November 8, 2025: Train First Model (1-2 hours)

### Prerequisites
- [x] 30+ days of data (will have by Nov 8)
- [ ] Mac with Xcode installed
- [ ] 1-2 hours of time

### Option 1: Train via Debug UI (Easiest)

**Step-by-step:**
1. Open VeloReady app on **macOS**
2. Navigate to: `Settings → Debug → ML Infrastructure`
3. Verify: "Training Data: 30+ days"
4. Tap button: **"Test Training Pipeline"**
5. Wait ~60 seconds (watch logs)
6. Success message: "✅ Pipeline test PASSED"
7. Verify: "Current Model: 1.0" (should appear)

**Expected Output:**
```
✅ Pipeline test PASSED
   Samples: 24 train, 6 test
   MAE: 8.2
   Training time: 45.3s
   Exported to: TestModel.mlmodel
```

**Success Criteria:**
- MAE < 10 (Mean Absolute Error)
- RMSE < 12 (Root Mean Squared Error)
- R² > 0.6 (explains 60%+ of variance)
- File size < 1MB

### Option 2: Train via Code

Create a debug button or script:

```swift
// In MLDebugView or separate script
Task {
    let trainer = MLModelTrainer()
    
    // Train model
    let result = try await trainer.trainModel()
    
    // Export model
    let modelURL = try trainer.exportModel(result.model)
    
    // Register in registry
    let metadata = MLModelMetadata(
        version: "1.0",
        phase: .baseline,
        createdAt: Date(),
        trainingSampleCount: result.trainingSamples,
        validationAccuracy: result.metrics.rSquared,
        modelType: .tabularRegressor,
        isValid: result.metrics.isGoodQuality
    )
    
    MLModelRegistry.shared.registerModel(metadata: metadata)
    try MLModelRegistry.shared.deployModel(version: "1.0")
    
    print("Model trained and deployed!")
    print("MAE: \(result.metrics.mae)")
    print("Model at: \(modelURL.path)")
}
```

### Troubleshooting

**Problem:** "Insufficient training data"  
**Solution:** Wait for 30 days, currently at 21

**Problem:** "Create ML not available"  
**Solution:** Must run on macOS (not iOS)

**Problem:** "MAE > 10 (poor accuracy)"  
**Solution:** Normal for first model, will improve with more data

**Problem:** "Training crashes"  
**Solution:** Check logs, may need to adjust training config

---

## Week of November 11: Implement Predictions (Week 3)

### Status
**Code to write:** ~2-3 days of work  
**Complexity:** Medium  
**Priority:** High (to actually use the model)

### Tasks

#### Day 1-2: Prediction Service
1. Create `MLPredictionService.swift`
   - Load PersonalizedRecovery.mlmodel
   - Predict with today's features
   - Return confidence score

2. Create `PersonalizedRecoveryCalculator.swift`
   - Wrapper around MLPredictionService
   - Feature vector preparation
   - Result interpretation

3. Update `RecoveryScoreService.swift`
   - Check: Model available?
   - If yes → Use ML prediction
   - If no → Fallback to rule-based

#### Day 3: UI Integration
1. Update `RecoveryScore` model
   ```swift
   struct RecoveryScore {
       let score: Int
       let isPersonalized: Bool  // NEW
       let confidence: Double?   // NEW
       let method: PredictionMethod // NEW
   }
   ```

2. Update Today view
   - Show "✨ Personalized" badge when ML active
   - Add info button explaining personalization
   - Show confidence if available

#### Day 4: Settings
1. Add ML Personalization settings section
   - Toggle: "Use Personalized Insights"
   - Info: Explain what it does
   - Show: Data status, model version

2. Add debug A/B test mode
   - Show both ML and rule-based scores
   - Show difference
   - Useful for validation

### Files to Create
```
VeloReady/Core/ML/Services/
├── MLPredictionService.swift        [NEW]
└── PersonalizedRecoveryCalculator.swift [NEW]

VeloReady/Core/Models/
└── PredictionResult.swift           [NEW]

VeloReady/Features/Settings/Views/
└── MLPersonalizationSettingsView.swift [NEW]

VeloReady/Features/Today/Views/
└── [Update RecoveryMetricsSection.swift]
```

### Testing Checklist
- [ ] Predictions return valid scores (0-100)
- [ ] Confidence scores reasonable (0.0-1.0)
- [ ] Fallback works when model unavailable
- [ ] UI shows personalization indicator
- [ ] Settings toggle works
- [ ] A/B test mode helpful

---

## Week of November 18: Polish & Deploy (Week 4)

### Status
**Code to write:** ~2 days of work  
**Complexity:** Low-Medium  
**Priority:** Medium (nice-to-have improvements)

### Tasks

#### Day 1: Watch Integration
1. Improve HRV/RHR data source priority
   ```swift
   // Prefer Watch → iPhone → Manual
   func getBestHRVSample(for date: Date) -> HKQuantitySample? {
       let watchSamples = hrvSamples.filter { $0.device?.isAppleWatch == true }
       return watchSamples.first ?? phoneSamples.first
   }
   ```

2. Sync recovery score to Watch
   - Use WatchConnectivityManager
   - Send: score, timestamp, isPersonalized

#### Day 2: Watch Complication
1. Create recovery score complication
   - Circular: Score + bar
   - Modular: Score + label
   - Update every 30 minutes

#### Day 3: Optimization
1. Performance
   - [ ] Cache predictions (invalidate daily)
   - [ ] Profile memory usage
   - [ ] Batch Core Data fetches

2. Edge cases
   - [ ] First-time users (no model yet)
   - [ ] Data gaps (travel, device change)
   - [ ] Low confidence predictions (show warning)

#### Day 4: Final Testing
1. Manual testing
   - [ ] End-to-end prediction flow
   - [ ] Settings integration
   - [ ] Watch sync
   - [ ] Edge cases

2. Performance validation
   - [ ] Inference < 50ms
   - [ ] Memory < 50MB
   - [ ] Battery impact < 5% daily

#### Day 5: Documentation & Deploy
1. Documentation
   - [ ] Update user-facing help content
   - [ ] Code documentation (DocC)
   - [ ] Deployment checklist

2. Deploy
   - [ ] Enable ML feature flag
   - [ ] Monitor telemetry
   - [ ] Collect user feedback

---

## Timeline Summary

```
TODAY (Oct 30)
├─ Read this document ✅
└─ Understand current state ✅

NEXT 9 DAYS (Oct 31 - Nov 7)
├─ Normal app usage (data collects automatically)
├─ Wear Watch overnight
└─ Sync Intervals.icu

NOV 8 (Day 30)
├─ Open app on Mac
├─ Debug → Test Training Pipeline
├─ Wait 60 seconds
└─ Verify model trained ✅

WEEK OF NOV 11 (Week 3)
├─ Day 1-2: Prediction service
├─ Day 3: UI updates
└─ Day 4: Settings integration

WEEK OF NOV 18 (Week 4)
├─ Day 1-2: Watch integration
├─ Day 3: Optimization
└─ Day 4-5: Testing & deploy

RESULT: Personalized ML predictions live! 🎉
```

---

## Quick Reference: Key Files

### To Check Status
```
VeloReady/Features/Debug/Views/MLDebugView.swift
- Shows: Training data count, model version, data quality
```

### To Train Model (Week 2)
```
VeloReady/Core/ML/Training/MLModelTrainer.swift
- Method: trainModel() -> TrainingResult
- Export: exportModel() -> URL
```

### To Implement Predictions (Week 3)
```
VeloReady/Core/Services/RecoveryScoreService.swift
- Update: Add ML prediction path
- Fallback: Keep rule-based for safety
```

### Data Storage
```
Core Data Entity: MLTrainingData
- Location: VeloReady.xcdatamodeld
- Count: 21 days currently
```

---

## Expected Outcomes

### After 30 Days (Nov 8)
✅ Trained ML model  
✅ Model validated (MAE < 10)  
✅ Model deployed to registry  
✅ Debug shows "Current Model: 1.0"

### After Week 3 (Nov 15)
✅ Predictions working  
✅ UI shows personalization  
✅ Settings integration complete  
✅ Fallback to rule-based working

### After Week 4 (Nov 22)
✅ Watch integration improved  
✅ Complication showing score  
✅ Performance optimized  
✅ Production ready  
🎉 **ML personalization LIVE**

---

## Key Metrics to Track

### Data Quality
- **Days collected:** 21 → 30 → 40+
- **Valid days:** Should match total days
- **Completeness:** Target > 80%

### Model Performance
- **MAE (Mean Absolute Error):** Target < 8 points
- **RMSE (Root Mean Squared Error):** Target < 10 points
- **R² (Variance explained):** Target > 0.7

### User Impact
- **Prediction accuracy:** Better than rule-based
- **Inference time:** < 50ms
- **Battery impact:** < 5% daily
- **Adoption rate:** Target 60%+ keep enabled

---

## Questions?

### "Can I train with 21 days?"
**Yes, but not recommended.** Accuracy will be lower (MAE ~12-15 vs target 8-10). Wait for 30.

### "Why macOS only?"
Create ML framework is macOS-only. Alternatives: TensorFlow → Core ML, but more complex.

### "Will it auto-retrain?"
Not yet. Week 4 adds weekly background retraining. Manual for now.

### "What if predictions are bad?"
Automatic fallback to rule-based. User can disable ML in Settings.

### "How do I know it's working?"
Debug view shows model version + predictions will say "Personalized" with ✨ indicator.

---

## Support Resources

### Documentation
- [Full State Document](./ML_CURRENT_STATE_AND_PLAN.md) - Comprehensive overview
- [Phase 2 Progress](./implementation/ML_PHASE_2_PROGRESS.md) - Weekly updates
- [Implementation Plan](./implementation/ML_PHASE_2_IMPLEMENTATION_PLAN.md) - Technical details

### Code Files
- Training: `VeloReady/Core/ML/Training/`
- Services: `VeloReady/Core/ML/Services/`
- Debug: `VeloReady/Features/Debug/Views/MLDebugView.swift`

### Logs
Look for:
- `🚀 [ML]` - Data processing
- `🎓 [MLModelTrainer]` - Training
- `✅ [ML]` - Success messages
- `⚠️ [ML]` - Warnings

---

## Action Items Checklist

### This Week (Oct 30 - Nov 7)
- [ ] Read this document
- [ ] Check Debug UI (verify 21 days)
- [ ] Continue normal app usage
- [ ] Wear Watch overnight
- [ ] Sync Intervals.icu daily

### November 8, 2025
- [ ] Open app on Mac
- [ ] Run "Test Training Pipeline"
- [ ] Verify model trained successfully
- [ ] Check: "Current Model: 1.0"

### Week of November 11
- [ ] Implement MLPredictionService
- [ ] Integrate with RecoveryScoreService
- [ ] Update UI with personalization indicator
- [ ] Add Settings toggle
- [ ] Test predictions

### Week of November 18
- [ ] Improve Watch integration
- [ ] Create Watch complication
- [ ] Optimize performance
- [ ] Final testing
- [ ] Deploy to production

---

**Status:** You're on track. 9 more days of data collection, then 1-2 hours to train, then 1 week to implement predictions. Everything is working as designed. 🎯

