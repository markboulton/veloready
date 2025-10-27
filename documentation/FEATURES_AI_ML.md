# AI & Machine Learning Features

## 1. AI Daily Brief

### Marketing Summary
Your personal cycling coach, powered by AI. Every morning, VeloReady's AI analyzes your recovery, sleep, training load, and planned workout to give you a personalized training recommendation. Get specific TSS targets, zone guidance, fueling advice, and the "why" behind each suggestion—all in a conversational tone that feels like texting with your coach.

### Scientific Detail
The AI Daily Brief uses OpenAI's GPT-4o-mini model with carefully engineered prompts to synthesize multiple physiological signals into actionable training guidance.

**Input Context (13 variables):**
1. Recovery Score (0-100)
2. Sleep Score (0-100)
3. HRV Delta (% change from baseline)
4. RHR Delta (% change from baseline)
5. Training Stress Balance (CTL - ATL)
6. Target TSS Range (from training plan or adaptive recommendation)
7. Planned Workout (if any)
8. Illness Indicator (severity, confidence, signals)
9. Body Stress Level (low/moderate/high)
10. Recent Training History (7-day TSS)
11. Sleep Debt (cumulative hours)
12. Time Constraints (explicit or inferred)
13. Weather Conditions (planned feature)

**Decision Rules (Hierarchical):**

1. **CRITICAL OVERRIDE - Illness Detection**
   - If Body Stress = MODERATE or HIGH → Prescribe rest or max 30 TSS Z1 gentle spin
   - Educational tone: "Your metrics suggest your body needs extra recovery today"
   - Overrides all other signals

2. **HRV Spike Override (>100%)**
   - Unusual autonomic response → Suggest rest or very light activity
   - Often indicates illness or extreme stress

3. **HRV Priority Rule**
   - If HRV Delta ≥ +15%, this indicates strong recovery even if RHR slightly elevated
   - Common after hard training—prioritize HRV over RHR in decision
   - Example: HRV +126%, RHR +9% → "Excellent recovery, ready for productive session"

4. **Recovery-Based Guidance**
   - Recovery < 50% OR (HRV ≤ -2% AND RHR ≥ +2% AND HRV < +15%) → De-load ≤ 55 TSS (Z1-Z2)
   - Recovery ≥ 66% AND TSB ≥ 0 → Metrics support productive session at top of target
   - Mixed signals → Cap around midpoint, emphasize fueling/recovery habits

5. **Sleep Score Interpretation**
   - 85-100: Excellent (strong recovery signal)
   - 70-84: Good (adequate for moderate training)
   - 60-69: Fair (consider reducing intensity)
   - <60: Poor (prioritize recovery)

6. **Time-Crunched Optimization**
   - If explicit or implied time constraint → Recommend 45-60 min format
   - Sweet Spot, Tempo, or high-cadence endurance for efficiency

**Few-Shot Examples (Teaching the Model):**
```
Example 1 (Excellent Recovery):
Input: Recovery: 96% | Sleep: 98/100 | HRV: +126% | RHR: +9% | TSB: +37 | Target: 40-52
Output: "Excellent recovery with HRV way up (+126%) — your body is well-rested despite 
slightly elevated RHR. Ready for 50-52 TSS: Z2-Z3 ride 60-75 min. Fuel 60 g/h and stay 
hydrated."

Example 2 (Illness Override):
Input: Recovery: 65% | Sleep: 78/100 | HRV: +220% | RHR: +5% | Body Stress: HIGH
Output: "Your metrics suggest your body needs extra recovery today. HRV spike (+220%) and 
disrupted sleep indicate your immune system is working hard. Take a rest day or gentle 
20-min walk. Prioritize hydration and nutrition."

Example 3 (Mixed Signals):
Input: Recovery: 72% | Sleep: 85/100 | HRV: -5% | RHR: +3% | TSB: -8 | Target: 70-90
Output: "Decent recovery but HRV slightly down and you're carrying fatigue (TSB -8). Aim 
for 75 TSS: Z2 endurance ride 90 min. Keep intensity controlled and fuel well."
```

**Output Format:**
- Concise (2-3 sentences max)
- Specific TSS target and zone recommendation
- Fueling guidance when relevant (60-90g carbs/hour for hard efforts)
- Educational "why" when appropriate
- Relatable tone (like a coach texting their rider)

**References:**
- Coggan, A. R., & Allen, H. (2010). *Training and Racing with a Power Meter*. VeloPress.
- Seiler, S. (2010). What is best practice for training intensity and duration distribution in endurance athletes? *International Journal of Sports Physiology and Performance*.

### Technical Implementation
**Architecture:**
- `AIBriefService.swift`: iOS service that builds request and handles response
- `ai-brief.ts`: Netlify Function that calls OpenAI API
- `netlify/lib/cache.ts`: Caching layer using Netlify Blobs
- `AIBriefRequest.swift`: Request model with all input variables
- `AIBriefResponse.swift`: Response model with brief text and metadata

**Request Flow:**
1. `TodayViewModel` calls `aiBriefService.fetchBrief()`
2. Service builds `AIBriefRequest` with current metrics:
   ```swift
   let request = AIBriefRequest(
       athleteId: currentAthleteId,
       recovery: recoveryScoreService.currentRecoveryScore,
       sleep: sleepScoreService.currentSleepScore,
       hrvDelta: calculateHRVDelta(),
       rhrDelta: calculateRHRDelta(),
       tsb: strainScoreService.currentTSB,
       targetTSS: getTargetTSSRange(),
       plannedWorkout: getPlannedWorkout(),
       illnessIndicator: illnessDetectionService.currentIndicator,
       sleepDebt: sleepScoreService.currentSleepDebt
   )
   ```
3. Service sends POST to `/api/ai-brief` with JWT authentication
4. Backend checks cache (key: `${userId}:${date}:${promptVersion}`)
5. If cache miss, builds OpenAI prompt and calls API
6. Caches response in Netlify Blobs (24h TTL)
7. Returns brief text to iOS app
8. App saves to Core Data for offline access
9. Publishes to `@Published var briefText`

**Backend Prompt Engineering:**
```typescript
// ai-brief.ts
const systemPrompt = `You are an expert cycling coach providing daily training guidance.
Analyze the athlete's recovery metrics and provide a concise, actionable recommendation.

${DECISION_RULES}

Keep output concise and relatable, like a coach texting their rider before a session.`;

const userPrompt = `Recovery: ${recovery}% | Sleep: ${sleep}/100 | HRV Delta: ${hrvDelta}% | 
RHR Delta: ${rhrDelta}% | TSB: ${tsb} | Target TSS: ${targetMin}-${targetMax} | 
Plan: ${plannedWorkout || 'none'}${illnessIndicator ? ` | Body Stress: ${illnessIndicator.severity}` : ''}`;

const response = await openai.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [
    { role: 'system', content: systemPrompt },
    ...fewShotExamples,
    { role: 'user', content: userPrompt }
  ],
  temperature: 0.7,
  max_tokens: 150
});
```

**Caching Strategy:**
- **Cache Key**: `${userId}:${isoDateUTC}:${promptVersion}:${cacheKeySuffix}`
  - User-specific (multi-user isolation)
  - Date-specific (new brief each day)
  - Version-specific (invalidate when prompt changes)
  - Suffix for A/B testing or custom variants
- **TTL**: 24 hours (brief valid for current day only)
- **Storage**: Netlify Blobs (serverless key-value store)
- **Hit Rate**: ~80% (most users check brief once per day)

**Security:**
- HMAC signature verification on requests
- Supabase JWT authentication
- User-specific cache isolation
- Rate limiting (10 requests/hour per user)

**Cost Optimization:**
- GPT-4o-mini: $0.00015 per request (vs $0.03 for GPT-4)
- Caching reduces API calls by 80%
- Estimated cost: $0.50/month per 100 active users

**Code Example:**
```typescript
// ai-brief.ts
export default async (req: Request) => {
  // Authenticate user
  const { userId, athleteId } = await authenticate(req);
  
  // Parse request
  const body = await req.json();
  const { recovery, sleep, hrvDelta, rhrDelta, tsb, targetTSS, illnessIndicator } = body;
  
  // Check cache
  const cacheKey = `${userId}:${isoDateUTC()}:${PROMPT_VERSION}`;
  const cached = await getFromCache(cacheKey);
  if (cached) {
    return new Response(JSON.stringify({ brief: cached, cached: true }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  // Build prompt
  const userPrompt = buildPrompt(body);
  
  // Call OpenAI
  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      ...FEW_SHOT_EXAMPLES,
      { role: 'user', content: userPrompt }
    ],
    temperature: 0.7,
    max_tokens: 150
  });
  
  const brief = response.choices[0].message.content;
  
  // Cache response
  await saveToCache(cacheKey, brief, 86400);  // 24h TTL
  
  return new Response(JSON.stringify({ brief, cached: false }), {
    headers: { 'Content-Type': 'application/json' }
  });
};
```

---

## 2. Machine Learning Roadmap

### Marketing Summary
VeloReady is building the most personalized cycling training platform, powered by on-device machine learning. Our ML models will learn your unique physiology to predict recovery, optimize zones, and prevent injuries—all while keeping your data private on your device.

### Scientific Detail
Machine learning enables personalization beyond rule-based algorithms. By training models on individual athlete data, we can:

1. **Capture Non-Linear Relationships**: Recovery isn't a simple weighted sum—it's influenced by complex interactions between HRV, sleep, training load, and individual factors
2. **Adapt to Individual Physiology**: Some athletes recover faster, some are more sensitive to sleep debt, some respond differently to training load
3. **Predict Future States**: ML can forecast tomorrow's recovery based on today's metrics and planned training
4. **Detect Patterns**: Identify early warning signs of overtraining, illness, or injury risk

**Privacy-First Approach:**
- All model training happens on-device using Core ML
- No data sent to servers for training
- Models personalized to individual athlete
- Federated learning (future): Aggregate insights without sharing raw data

### Technical Implementation
**Current State (Data Collection):**
- `MLTrainingData` Core Data entity stores daily features
- 19 days of data collected (need 90+ for initial training)
- Features: recovery, sleep, strain, HRV, RHR, CTL, ATL, TSS, sleep debt, illness indicators
- Labels: next-day recovery score, next-day HRV, next-day sleep quality

**Data Schema:**
```swift
@objc(MLTrainingData)
public class MLTrainingData: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var athleteId: String
    
    // Features (today's metrics)
    @NSManaged public var recoveryScore: Double
    @NSManaged public var sleepScore: Double
    @NSManaged public var strainScore: Double
    @NSManaged public var hrv: Double
    @NSManaged public var rhr: Double
    @NSManaged public var ctl: Double
    @NSManaged public var atl: Double
    @NSManaged public var tsb: Double
    @NSManaged public var todayTSS: Double
    @NSManaged public var sleepDebt: Double
    @NSManaged public var illnessConfidence: Double
    
    // Labels (tomorrow's outcomes)
    @NSManaged public var nextDayRecovery: Double
    @NSManaged public var nextDayHRV: Double
    @NSManaged public var nextDaySleep: Double
}
```

---

## 3. ML Phase 1: Personalized Recovery Prediction (Q1 2026)

### Marketing Summary
What if you could see tomorrow's recovery score today? VeloReady's ML model learns your unique recovery patterns to predict how you'll feel tomorrow based on today's training and metrics. Plan your week with confidence, knowing when to push and when to rest.

### Scientific Detail
Recovery prediction is a supervised learning problem: given today's metrics and planned training, predict tomorrow's recovery score.

**Model Architecture:**
- **Type**: Gradient Boosted Decision Trees (XGBoost or Core ML's built-in)
- **Input Features (12)**:
  1. Today's recovery score
  2. Today's sleep score
  3. Today's HRV (absolute and delta)
  4. Today's RHR (absolute and delta)
  5. Today's TSS (planned workout)
  6. Current CTL/ATL/TSB
  7. Sleep debt
  8. Days since last rest day
  9. Illness confidence
  10. Day of week (circadian patterns)
  11. Recent trend (3-day moving average)
  12. Alcohol detected (binary)

- **Output**: Tomorrow's recovery score (0-100)

**Training Process:**
1. Collect 90+ days of data per athlete
2. Split into train (70%), validation (15%), test (15%)
3. Train XGBoost model on-device using Create ML
4. Hyperparameter tuning via grid search
5. Validate on holdout set (target RMSE < 8 points)
6. Export to Core ML format
7. Deploy to app via over-the-air update

**Evaluation Metrics:**
- RMSE (Root Mean Squared Error): Target < 8 points
- MAE (Mean Absolute Error): Target < 6 points
- R² (Coefficient of Determination): Target > 0.7

**Personalization:**
- Each athlete gets their own model
- Model retrains weekly with new data
- Adapts to fitness changes, life stress, aging

### Technical Implementation
**Architecture:**
- `MLRecoveryPredictor.swift`: Wrapper for Core ML model
- `MLTrainingService.swift`: Handles model training and updates
- `RecoveryPredictionView.swift`: UI for showing predictions

**Prediction Flow:**
```swift
class MLRecoveryPredictor {
    private var model: RecoveryPredictionModel?
    
    func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "RecoveryPredictor", withExtension: "mlmodelc") else {
            Logger.error("ML model not found")
            return
        }
        
        do {
            model = try RecoveryPredictionModel(contentsOf: modelURL)
        } catch {
            Logger.error("Failed to load ML model: \(error)")
        }
    }
    
    func predictTomorrowRecovery(
        todayRecovery: Double,
        todaySleep: Double,
        hrv: Double,
        hrvDelta: Double,
        rhr: Double,
        rhrDelta: Double,
        plannedTSS: Double,
        ctl: Double,
        atl: Double,
        tsb: Double,
        sleepDebt: Double,
        daysSinceRest: Int,
        illnessConfidence: Double,
        dayOfWeek: Int,
        recentTrend: Double,
        alcoholDetected: Bool
    ) -> Double? {
        guard let model = model else { return nil }
        
        do {
            let input = RecoveryPredictionModelInput(
                todayRecovery: todayRecovery,
                todaySleep: todaySleep,
                hrv: hrv,
                hrvDelta: hrvDelta,
                rhr: rhr,
                rhrDelta: rhrDelta,
                plannedTSS: plannedTSS,
                ctl: ctl,
                atl: atl,
                tsb: tsb,
                sleepDebt: sleepDebt,
                daysSinceRest: Double(daysSinceRest),
                illnessConfidence: illnessConfidence,
                dayOfWeek: Double(dayOfWeek),
                recentTrend: recentTrend,
                alcoholDetected: alcoholDetected ? 1.0 : 0.0
            )
            
            let prediction = try model.prediction(input: input)
            return prediction.tomorrowRecovery
        } catch {
            Logger.error("Prediction failed: \(error)")
            return nil
        }
    }
}
```

**Training Pipeline:**
```swift
class MLTrainingService {
    func trainRecoveryModel() async throws {
        // Fetch training data from Core Data
        let data = fetchMLTrainingData(minDays: 90)
        
        guard data.count >= 90 else {
            throw MLError.insufficientData
        }
        
        // Convert to Create ML format
        let dataTable = convertToMLDataTable(data)
        
        // Split train/validation/test
        let (train, validation, test) = dataTable.randomSplit(by: [0.7, 0.15, 0.15])
        
        // Train model
        let model = try MLBoostedTreeRegressor(
            trainingData: train,
            targetColumn: "nextDayRecovery",
            featureColumns: [
                "todayRecovery", "todaySleep", "hrv", "hrvDelta",
                "rhr", "rhrDelta", "plannedTSS", "ctl", "atl", "tsb",
                "sleepDebt", "daysSinceRest", "illnessConfidence",
                "dayOfWeek", "recentTrend", "alcoholDetected"
            ],
            validationData: validation
        )
        
        // Evaluate on test set
        let metrics = model.evaluation(on: test)
        Logger.debug("ML Model Evaluation - RMSE: \(metrics.rootMeanSquaredError), R²: \(metrics.rSquared)")
        
        // Export to Core ML
        try model.write(to: getModelURL())
        
        // Notify app to reload model
        NotificationCenter.default.post(name: .mlModelUpdated, object: nil)
    }
}
```

---

## 4. ML Phase 2: Adaptive Zone Refinement (Q2 2026)

### Marketing Summary
Your training zones should evolve as you get fitter—and adjust when you're tired. VeloReady's ML-enhanced zones adapt to your current fitness and fatigue state, giving you personalized power and heart rate targets that maximize training effectiveness.

### Scientific Detail
Traditional training zones are static, based on a single FTP or max HR test. But optimal training intensity varies based on:
- Current fitness level (CTL)
- Fatigue state (TSB)
- Recovery status
- Time of day
- Recent training history

**ML-Enhanced Zones:**
1. **Fitness-Adjusted FTP**: ML model predicts current FTP based on recent power curve data, accounting for fitness trends
2. **Fatigue-Adjusted Zones**: When TSB < -10, reduce zone targets by 3-5% to account for accumulated fatigue
3. **Recovery-Adjusted Zones**: When recovery < 70%, suggest lower zones for same perceived effort
4. **Personalized Zone Boundaries**: Learn individual lactate threshold and VO2max from response to training

**Model Architecture:**
- **Type**: Neural Network (3 hidden layers)
- **Inputs**: Power curve data (1s, 5s, 10s, 30s, 1min, 5min, 20min, 60min), CTL, ATL, TSB, recovery score, recent training
- **Outputs**: Current FTP, Zone 2 ceiling, Zone 4 floor, VO2max power

### Technical Implementation
**Architecture:**
- `AdaptiveZonesML.swift`: ML-enhanced zone calculation
- `ZonePredictionModel.mlmodel`: Core ML model
- `ZonesView.swift`: UI showing current vs baseline zones

**Zone Adjustment Logic:**
```swift
func calculateAdaptiveZones() -> [PowerZone] {
    // Get baseline FTP from ML model
    let baseFTP = mlZonePredictor.predictCurrentFTP(
        powerCurve: recentPowerCurve,
        ctl: currentCTL,
        atl: currentATL
    )
    
    // Adjust for fatigue
    let fatigueAdjustment = currentTSB < -10 ? 0.95 : 1.0
    let adjustedFTP = baseFTP * fatigueAdjustment
    
    // Adjust for recovery
    let recoveryAdjustment = currentRecovery < 70 ? 0.97 : 1.0
    let finalFTP = adjustedFTP * recoveryAdjustment
    
    // Calculate zones
    return [
        PowerZone(name: "Active Recovery", min: 0, max: finalFTP * 0.55),
        PowerZone(name: "Endurance", min: finalFTP * 0.56, max: finalFTP * 0.75),
        PowerZone(name: "Tempo", min: finalFTP * 0.76, max: finalFTP * 0.90),
        PowerZone(name: "Threshold", min: finalFTP * 0.91, max: finalFTP * 1.05),
        PowerZone(name: "VO2max", min: finalFTP * 1.06, max: finalFTP * 1.20),
        PowerZone(name: "Anaerobic", min: finalFTP * 1.21, max: finalFTP * 1.50)
    ]
}
```

---

## 5. ML Phase 3: Injury Risk Prediction (Q3 2026)

### Marketing Summary
Prevent injuries before they happen. VeloReady's ML model analyzes your wellness trends, training load, and biomechanical patterns to identify early warning signs of overtraining and injury risk. Get alerts when you need to back off, keeping you healthy and on the bike.

### Scientific Detail
Overtraining and injury often follow predictable patterns:
- Rapid CTL increase (>5 TSS/day per week)
- Persistent negative TSB (<-20 for >7 days)
- Declining HRV trend (>10% drop over 7 days)
- Elevated RHR trend (>5% increase over 7 days)
- Poor sleep quality (score <70 for >3 consecutive days)
- High acute:chronic workload ratio (>1.5)

**ML Injury Risk Model:**
- **Type**: LSTM (Long Short-Term Memory) neural network for time series
- **Inputs**: 14-day history of recovery, sleep, HRV, RHR, TSS, illness indicators
- **Output**: Injury risk score (0-100) and risk category (Low/Medium/High)

**Early Warning System:**
- Risk > 70: High risk, recommend rest day
- Risk 50-70: Medium risk, reduce intensity
- Risk < 50: Low risk, train normally

### Technical Implementation
**Architecture:**
- `InjuryRiskPredictor.swift`: LSTM model wrapper
- `InjuryRiskAlert.swift`: UI alert component
- `TrendsView.swift`: Shows risk trend over time

**Prediction Flow:**
```swift
func predictInjuryRisk() -> Double {
    // Fetch 14-day history
    let history = fetch14DayHistory()
    
    // Prepare LSTM input (14 timesteps × 10 features)
    let input = prepareLSTMInput(history)
    
    // Run prediction
    let risk = lstmModel.predict(input: input)
    
    return risk
}
```
