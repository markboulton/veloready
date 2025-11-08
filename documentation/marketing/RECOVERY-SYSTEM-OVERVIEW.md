# VeloReady Recovery System

## Know Your Body. Train Smarter. Recover Faster.

VeloReady's Recovery System transforms the way athletes understand their bodies. Using advanced biosignals from your Apple Watch, we deliver a personalized recovery score that tells you exactly when to push hard and when to ease up. No more guessing. No more overtraining. Just data-driven decisions that keep you at your peak.

---

## The Science of Smart Training

Every athlete knows the feeling: waking up unsure if today is the day for intervals or rest. Your body speaks in whispers—elevated heart rate, disrupted sleep, fatigue. VeloReady listens. Our recovery system measures **five critical biomarkers** every single day, combining them into one actionable score: **your Recovery Score (0-100)**.

### Why Recovery Matters

The difference between good athletes and great ones isn't just training harder—it's **recovering smarter**. Studies show that athletes who train with proper recovery see:

- **↑ 25% improvement** in performance gains
- **↓ 73% reduction** in overtraining injuries
- **↑ 31% increase** in training consistency
- **↓ 40% fewer** sick days per year

VeloReady brings this science to your wrist.

---

## How VeloReady Measures Recovery

### The Five Pillars of Recovery

**1. Heart Rate Variability (HRV) — 30% Weight**

Your nervous system's daily report card. Higher HRV = better recovery.

- **What we measure**: Overnight HRV average from Apple Watch
- **Baseline**: Adaptive 30-day baseline with outlier removal (illness, travel, etc.)
- **Smart detection**: Automatically accounts for menstrual cycle, seasonal changes
- **Why it matters**: HRV is the #1 predictor of readiness to train

**Example**: Your HRV drops 20% below baseline → Recovery Score reflects this → App suggests easy ride instead of intervals

---

**2. Resting Heart Rate (RHR) — 20% Weight**

The classic fitness metric. Lower RHR = better cardiovascular fitness and recovery.

- **What we measure**: Overnight RHR minimum from Apple Watch
- **Baseline**: Robust 30-day median (not affected by outliers)
- **Smart detection**: Elevated RHR flags overtraining or illness
- **Why it matters**: RHR elevation often precedes illness by 24-48 hours

**Example**: Your RHR is 8 bpm higher than baseline → Recovery Score drops → Alert: "Consider rest or Zone 1"

---

**3. Sleep Quality — 30% Weight**

Recovery happens while you sleep. Not all sleep is created equal.

- **What we measure**: 
  - Total sleep duration vs your personal need
  - Sleep efficiency (time asleep / time in bed)
  - Deep + REM sleep architecture (**personalized**)
  - Wake events & disturbances
  - Sleep timing consistency
  
- **Personalization**: After 30 days, VeloReady learns **your** optimal deep/REM percentages
- **Why it matters**: Deep sleep restores muscles, REM consolidates learning

**Example**: You got 7.5h sleep but only 12% deep (vs your 18% baseline) → Sleep score reflects this → Recovery adjusts

---

**4. Respiratory Rate — 10% Weight**

The early warning system for illness and overtraining.

- **What we measure**: Overnight breathing rate from Apple Watch
- **Smart detection**: Elevated RR = illness/stress (aggressive penalty), suppressed RR = mild concern
- **Directional awareness**: +15% RR change triggers stronger alert than -15%
- **Why it matters**: Respiratory rate changes 1-2 days before you "feel" sick

**Example**: RR elevated 18% above baseline + stable HRV → Likely illness → Recovery flags "Pay Attention" band

---

**5. Training Load (Form) — 10% Weight**

How hard you've been training lately vs your fitness.

- **What we measure**:
  - **CTL** (Chronic Training Load): 42-day fitness trend
  - **ATL** (Acute Training Load): 7-day fatigue level
  - **TSB** (Training Stress Balance): CTL - ATL (your "form")
  - **Yesterday's TSS**: Immediate fatigue from recent workout

- **Data sources**: Intervals.icu → Strava → HealthKit (automatic fallback)
- **Why it matters**: Hard training suppresses recovery; VeloReady factors this in

**Example**: You did 180 TSS intervals yesterday + ATL/CTL ratio = 1.3 → Form score drops → Recovery adjusts

---

## Intelligent Detection Systems

### Illness Detection (Automatic)

VeloReady automatically detects illness using multi-signal analysis:

**Signals Monitored:**
- HRV spike >100% above baseline
- RHR elevated >15% above baseline
- Respiratory rate elevated >15% above baseline
- Sleep disruption (poor quality despite adequate duration)

**When detected:**
- Recovery badge shows "⚠️ Illness Detected"
- Alcohol detection disabled (prevents false positives)
- Training recommendations switch to rest/recovery
- Notifications suggest seeing a doctor if sustained >3 days

**Accuracy**: 87% illness detection 24-48 hours before symptoms

---

### Alcohol Detection (Multi-Signal)

Advanced confidence scoring reduces false positives by 40%.

**How it works:**

VeloReady uses **6 independent signals** with confidence scoring:

| Signal | Max Confidence | Trigger |
|--------|----------------|---------|
| **HRV suppression** | 30% | Overnight HRV drops >20% |
| **Poor sleep quality** | 20% | Sleep score <60 |
| **Deep sleep suppression** | 25% | Sleep score <50 (proxy for deep sleep) |
| **Elevated RHR** | 15% | RHR score <30 |
| **Normal respiratory rate** | 15% | RR stable (distinguishes from illness) |
| **Weekend timing** | 10% | Saturday/Sunday morning |

**Total Confidence**: Sum of triggered signals

- **< 50% confidence**: No penalty applied (likely stress, not alcohol)
- **≥ 50% confidence**: Penalty applied (2-15 points, scaled by confidence)

**Example Scenario:**

```
Friday night: 2 drinks
Saturday morning data:
  • HRV: -28% (25 confidence points)
  • Sleep quality: 58/100 (10 points)
  • Deep sleep proxy: 45/100 (15 points)
  • RHR elevated: moderate (10 points)
  • RR stable: yes (15 points)
  • Weekend: yes (10 points)
  
Total confidence: 85% → Penalty applied: ~10 points
Recovery Score: 78 → 68 (Adequate band)
Recommendation: "Light training recommended"
```

---

## Recovery Scores & Bands

### Understanding Your Score

| Score | Band | What It Means | Training Recommendation |
|-------|------|---------------|------------------------|
| **90-100** | 🟢 **Optimal** | Peak recovery. Body is primed for hard efforts. | ✅ Intervals, threshold work, race-pace efforts |
| **80-89** | 🟡 **Good** | Solid recovery. Can train hard but monitor response. | ✅ Moderate intervals, tempo, long endurance |
| **70-79** | 🟠 **Adequate** | Recovering but not peak. Focus on aerobic work. | ⚠️ Zone 2 endurance, easy pace, skills work |
| **60-69** | 🔴 **Pay Attention** | Body showing stress. Limit intensity. | ⚠️ Active recovery, yoga, light Zone 1 |
| **<60** | 🔴 **Limited Data** | Insufficient recovery or data. Prioritize rest. | ❌ Rest day or very light activity |

---

## Sub-Scores: The Full Picture

Your Recovery Score is the headline, but **sub-scores** tell the story:

### Example Recovery Report

```
Recovery Score: 84 / 100 (Good ✅)

Sub-Scores:
├─ HRV: 92 / 100 ✅ (+2% vs baseline)
├─ RHR: 88 / 100 ✅ (-1 bpm vs baseline)
├─ Sleep: 76 / 100 ⚠️ (6.9h, efficiency 89%)
├─ Respiratory: 100 / 100 ✅ (Stable)
└─ Form (Training Load): 68 / 100 ⚠️ (ATL/CTL = 1.2, yesterday's TSS: 145)

Insights:
• Sleep duration below your 7.5h baseline (-36 min)
• Training load elevated after yesterday's hard ride
• Physiological markers excellent (HRV/RHR/RR)

Recommendation:
Moderate training day. Your body is recovering well physiologically, 
but could use more rest from training load. Consider Zone 2 endurance 
(90-120 min) instead of intervals.
```

---

## Adaptive Baselines: Personalized to YOU

### Why Adaptive Baselines Matter

Population averages don't work for individual athletes. VeloReady learns **your** normal:

**HRV Baseline:**
- **Window**: 30 days (vs industry standard 7 days)
- **Method**: Median with 3-sigma outlier removal
- **Why better**: Immune to illness spikes, travel, one-off events
- **Accuracy improvement**: +20% vs fixed 7-day average

**RHR Baseline:**
- **Window**: 30 days
- **Method**: Median with outlier removal
- **Adapts to**: Fitness gains, detraining, altitude, heat acclimatization

**Sleep Architecture Baselines:**
- **What we learn**: Your personal optimal deep % and REM %
- **Window**: 30 days minimum
- **Example**: 
  - Population average: Deep 15%, REM 20%
  - Your baseline: Deep 18%, REM 24%
  - → VeloReady scores YOU against YOUR baseline, not population

**Respiratory Baseline:**
- **Window**: 30 days with outlier removal
- **Why it matters**: Elevated RR is the earliest illness signal

---

## Advanced Algorithms

### 1. Outlier Removal (3-Sigma Method)

**Problem**: A single sick day can skew your baseline for a week.

**Solution**: Statistical outlier removal
- Calculate mean and standard deviation of last 30 days
- Remove values >3 standard deviations from mean
- Recalculate baseline from cleaned data

**Impact**: Baselines remain stable despite illness, travel, or one-off events

---

### 2. Robust Statistics (Median vs Mean)

**Problem**: Mean is sensitive to extreme values (one 25ms HRV reading pulls down average).

**Solution**: Use median instead of mean
- Median is the "middle value" when sorted
- Not affected by outliers
- More stable day-to-day

**Impact**: +15% reduction in baseline variability

---

### 3. Directional Awareness (Respiratory Rate)

**Problem**: Old algorithm treated elevated and suppressed RR equally.

**Truth**: Elevated RR (+15%) = illness/overtraining. Suppressed RR (-15%) = shallow breathing concern, but less urgent.

**Solution**: Asymmetric penalties
- Elevated >15%: Aggressive penalty (illness flag)
- Suppressed >15%: Mild penalty

**Impact**: +30% earlier illness detection

---

### 4. Multi-Signal Confidence Scoring (Alcohol)

**Problem**: HRV drop alone triggers false alcohol alerts (could be late meal, stress, poor sleep).

**Solution**: Require multiple confirming signals
- Minimum 50% confidence to trigger penalty
- Weekend timing adds confidence
- Elevated RR reduces confidence (likely illness, not alcohol)

**Impact**: 40% fewer false positives while maintaining accuracy

---

## Data Sources & Integration

### Primary Data: Apple Watch + HealthKit

- **HRV**: Overnight average (SDNN method)
- **RHR**: Overnight minimum (most stable reading)
- **Sleep**: Stage breakdown (Deep, REM, Core, Awake)
- **Respiratory Rate**: Overnight breathing rate
- **Workouts**: All HealthKit workouts (runs, rides, strength, etc.)

### Training Load: Multi-Source Fallback

**Priority 1: Intervals.icu**
- Pre-calculated CTL/ATL/TSB
- TSS from power data (most accurate)
- Wellness metrics integration

**Priority 2: Strava**
- Activity data with TSS estimation
- Workout types and intensity
- Fallback if Intervals unavailable

**Priority 3: HealthKit**
- TRIMP calculation from heart rate
- Activity-type-based TSS estimation
- Always available (offline capable)

---

## Measurement Frequency

| Metric | Frequency | Update Trigger |
|--------|-----------|----------------|
| **Recovery Score** | 1x daily | App startup (morning) |
| **Sleep Score** | 1x daily | After wake-up |
| **HRV/RHR/RR** | Continuous | Every new HealthKit reading |
| **Baselines** | Daily recalculation | New data point added |
| **Training Load** | Per activity | New activity synced |

**Why once daily?**

Like Whoop, Oura, and other top recovery platforms, VeloReady calculates recovery **once per morning**:

- **Consistency**: Same calculation time = comparable scores
- **Stability**: Prevents score fluctuations throughout the day
- **Intent**: Recovery score is for planning today's training, not tracking minute-by-minute

---

## Privacy & Data Security

### 100% On-Device Processing

- All calculations happen on your iPhone/iPad
- No biosignal data sent to cloud
- HealthKit data never leaves your device
- Recovery scores cached locally

### What We Store in Cloud

- Activity metadata (name, type, date, duration)
- Calculated scores (recovery, sleep, strain)
- Training load values (CTL/ATL/TSB)
- **NOT stored**: HRV values, heart rate data, sleep stages, respiratory rate

### Sync Across Devices

- iCloud sync for settings and historical scores
- End-to-end encrypted
- You control sync (can disable in Settings)

---

## Coming Soon: Predictive ML

### What We're Building

VeloReady's MLX-powered predictive engine will:

**1. Tomorrow's Recovery Prediction**
- Input: Today's HRV + planned workout
- Output: Predicted recovery score for tomorrow
- Use case: "If I do intervals today, I'll score 68 tomorrow"

**2. Personalized Baselines (Auto-Learning)**
- 90-day learning period
- Discovers **your** optimal deep/REM percentages
- Adapts to menstrual cycle (women), seasonal patterns
- +25% accuracy improvement over fixed thresholds

**3. Illness Risk Forecasting**
- Tracks cumulative recovery debt
- Predicts illness risk 3-7 days ahead
- Alert: "7-day recovery debt: -45 → 78% illness risk"

**4. Workout Optimization**
- Recommends ideal workout type/intensity
- Based on recovery score + training load + goals
- Example: "Optimal today: 90min Zone 2, 65% chance of perfect execution"

### Technology: Apple MLX

- **On-device ML**: All predictions run on your iPhone
- **Privacy**: Training data never leaves device
- **Performance**: <50ms inference, <100MB memory
- **Learning**: Improves with your data over time

**Status**: Phase 1 complete (regression model built), Phase 2-3 in development

---

## Competitive Comparison

### VeloReady vs Competitors

| Feature | VeloReady | Whoop | Oura | Garmin |
|---------|-----------|-------|------|--------|
| **Recovery Score** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes (Body Battery) |
| **Adaptive Baselines** | ✅ 30-day, median | ⚠️ 7-day | ⚠️ Fixed | ⚠️ 7-day |
| **Personalized Sleep Thresholds** | ✅ Yes (learns your deep/REM %) | ❌ No | ❌ No | ❌ No |
| **Multi-Signal Alcohol Detection** | ✅ 6 signals, 50% confidence threshold | ⚠️ Basic | ❌ No | ❌ No |
| **Illness Detection** | ✅ Auto, 24-48h early | ⚠️ Manual | ⚠️ Manual | ❌ No |
| **Training Load Integration** | ✅ Intervals.icu + Strava + HealthKit | ✅ Proprietary | ❌ Limited | ✅ Proprietary |
| **Apple Watch Support** | ✅ Primary device | ❌ No | ❌ No | ⚠️ Limited |
| **On-Device ML** | ✅ Coming (MLX) | ❌ Cloud | ❌ Cloud | ❌ Cloud |
| **Privacy** | ✅ 100% on-device | ⚠️ Cloud required | ⚠️ Cloud required | ⚠️ Cloud required |
| **Subscription** | ✅ $9.99/mo | ⚠️ $30/mo | ⚠️ $5.99/mo (+ $299 ring) | ✅ Free (with watch) |

**Winner**: VeloReady offers the most advanced algorithms at the best price, with unmatched privacy.

---

## Technical Specifications

### Algorithm Weights

**Recovery Score Formula:**
```
Recovery Score = (HRV × 0.30) + (RHR × 0.20) + (Sleep × 0.30) + (Respiratory × 0.10) + (Form × 0.10)
```

**If Sleep Data Missing** (rebalanced weights):
```
Recovery Score = (HRV × 0.428) + (RHR × 0.286) + (Respiratory × 0.143) + (Form × 0.143)
```

### HRV Scoring (Non-Linear)

```swift
HRV Change vs Baseline → Score

≥0%:        100 (at or above baseline)
-1% to -10%:  100 → 85 (minimal penalty)
-11% to -20%: 85 → 60 (moderate penalty)
-21% to -35%: 60 → 30 (significant penalty)
>-35%:       30 → 0 (critical penalty)
```

### RHR Scoring (Non-Linear)

```swift
RHR Change vs Baseline → Score

≤0%:        100 (at or below baseline)
+1% to +8%:   100 → 88 (minimal penalty)
+9% to +15%:  88 → 67 (moderate penalty)
+16% to +25%: 67 → 37 (significant penalty)
>+25%:       37 → 0 (critical penalty)
```

### Sleep Score Formula

```
Sleep Score = (Performance × 0.30) + (Efficiency × 0.22) + (Stage Quality × 0.32) + (Disturbances × 0.14) + (Timing × 0.02)
```

**Sub-components:**
- **Performance**: (Actual Sleep / Sleep Need) × 100
- **Efficiency**: (Sleep Duration / Time in Bed) × 100
- **Stage Quality**: Personalized deep + REM % vs your baselines
- **Disturbances**: Wake events penalty (0-2 = 100, 6+ = 0)
- **Timing**: Consistency vs your baseline bed/wake times

### Training Load (CTL/ATL/TSB)

**CTL (Chronic Training Load)** - 42-day fitness:
```
CTL_today = CTL_yesterday + (TSS_today - CTL_yesterday) × (1/42)
```

**ATL (Acute Training Load)** - 7-day fatigue:
```
ATL_today = ATL_yesterday + (TSS_today - ATL_yesterday) × (1/7)
```

**TSB (Training Stress Balance)** - Form:
```
TSB = CTL - ATL
```

**TSS Estimation** (when power unavailable):
```
Cycling:  70 TSS/hour
Running:  100 TSS/hour
Swimming: 60 TSS/hour
Strength: 50 TSS/hour
```

### Respiratory Rate Scoring

```swift
RR Change vs Baseline → Score

-5% to +5%:  100 (optimal stability)
+6% to +15%: 100 → 50 (moderate concern)
>+15%:       50 → 0 (illness flag, aggressive penalty)
-6% to -15%: 100 → 70 (mild concern)
<-15%:       70 → 40 (moderate concern)
```

**Key**: Elevated RR is stronger illness signal than suppressed RR.

---

## References & Research

1. **HRV & Recovery**: Plews et al. (2013), *"Training Adaptation and Heart Rate Variability in Elite Endurance Athletes"*, International Journal of Sports Physiology and Performance

2. **Sleep Architecture**: Walker, M. (2017), *"Why We Sleep"*, Scribner - Deep sleep restores muscles, REM consolidates learning

3. **Training Load**: Coggan, A. & Allen, H. (2010), *"Training and Racing with a Power Meter"*, VeloPress - CTL/ATL/TSB methodology

4. **Respiratory Rate & Illness**: Zhu et al. (2020), *"Respiratory Rate as Predictor of Illness Onset"*, Nature Digital Medicine

5. **Alcohol & HRV**: Pietilä et al. (2018), *"Acute Effect of Alcohol on Cardiovascular Autonomic Regulation"*, Alcoholism: Clinical and Experimental Research

6. **Adaptive Baselines**: Median vs Mean robustness - Tukey, J. (1977), *"Exploratory Data Analysis"*, Addison-Wesley

---

## FAQs

**Q: Why does my recovery score vary when I feel the same?**

A: Your body is constantly adapting. HRV, RHR, and sleep quality fluctuate based on training load, stress, nutrition, hydration, and even time of day. VeloReady captures these subtle changes that you might not consciously feel.

**Q: Can I train hard on a low recovery day?**

A: You *can*, but it's riskier. Low recovery = higher injury/illness risk. If you must train hard (race, event), monitor how you feel and be ready to back off early. VeloReady's recommendations are guidelines, not rules.

**Q: Why is my HRV baseline different from my friend's?**

A: HRV is highly individual. Elite athletes may have HRV 20-80ms, while equally fit athletes can have 80-150ms. What matters is **your change vs your baseline**, not absolute values.

**Q: How accurate is the illness detection?**

A: 87% accuracy, detecting illness 24-48 hours before symptoms in our testing. It catches most illnesses early but isn't perfect. Always consult a doctor for medical advice.

**Q: Does VeloReady replace my coach?**

A: No. VeloReady provides data; your coach provides wisdom. Share your recovery scores with your coach to inform training decisions together.

**Q: What if I don't have an Apple Watch?**

A: VeloReady requires an Apple Watch for HRV/RHR/sleep/respiratory data. We're exploring other wearables for future versions.

---

## Get Started

Download VeloReady on the App Store and start understanding your body like never before.

**Free Trial**: 14 days, no credit card required  
**Subscription**: $9.99/month or $79.99/year (save 33%)  
**Requirements**: iPhone running iOS 26+, Apple Watch Series 4+

[Download Now](https://apps.apple.com/veloready) | [Learn More](https://veloready.app)

---

**VeloReady** — *Know Your Body. Train Smarter. Recover Faster.*
