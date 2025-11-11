# VeloReady Scoring Methodology

**Complete documentation of data points, calculations, and formulas**

---

## Table of Contents

1. [Recovery Score](#recovery-score)
2. [Sleep Score](#sleep-score)
3. [Strain Score (Load)](#strain-score-load)
4. [Proposed: Stress Score](#proposed-stress-score)
5. [Quick Reference Lists](#quick-reference-lists)

---

## Recovery Score

### Overview
Recovery score measures your body's readiness for training based on physiological markers and sleep quality. Range: 0-100.

### Data Points Collected

#### From Apple HealthKit:
1. **HRV (Heart Rate Variability)** - Latest reading in milliseconds (ms)
   - Overnight HRV (measured during sleep)
   - Latest waking HRV
2. **RHR (Resting Heart Rate)** - Latest reading in bpm
3. **Respiratory Rate** - Latest reading in breaths/min
4. **Sleep Data** - From Sleep Score (if available)

#### From Training Platforms:
5. **ATL (Acute Training Load)** - From Intervals.icu (7-day weighted average)
6. **CTL (Chronic Training Load)** - From Intervals.icu (42-day weighted average)
7. **Recent Strain** - Your strain score from previous day

#### Calculated Baselines (7-14 day rolling averages):
8. **HRV Baseline** - Your normal HRV
9. **RHR Baseline** - Your normal resting heart rate
10. **Sleep Baseline** - Your normal sleep duration
11. **Respiratory Baseline** - Your normal breathing rate

#### Health Context:
12. **Illness Indicator** - From Illness Detection Service (multi-day analysis)

### Calculation Formula

**Final Recovery Score = Weighted Average of Sub-Scores**

```
If Sleep Data Available:
  Recovery = (HRV × 30%) + (RHR × 20%) + (Sleep × 30%) + (Respiratory × 10%) + (Form × 10%)

If No Sleep Data:
  Recovery = (HRV × 42.8%) + (RHR × 28.6%) + (Respiratory × 14.3%) + (Form × 14.3%)
```

**Then:** Apply alcohol compound effect detection (multi-factor analysis)

### Sub-Score Calculations

#### 1. HRV Component (0-100)

**Formula:** Compare today's HRV vs. baseline

```
percentageChange = (HRV - Baseline) / Baseline

If percentageChange >= 0:
  Score = 100  // At or above baseline = excellent

Else:
  absChange = |percentageChange|
  
  If absChange <= 10%:
    Score = 100 - (absChange × 150)  // Range: 100-85
  
  Else If absChange <= 20%:
    Score = 85 - ((absChange - 0.10) × 250)  // Range: 85-60
  
  Else If absChange <= 35%:
    Score = 60 - ((absChange - 0.20) × 200)  // Range: 60-30
  
  Else:  // > 35%
    Score = 30 - ((absChange - 0.35) × 60)  // Range: 30-0
```

**Example:**
- Baseline HRV: 60ms
- Today's HRV: 54ms (-10%)
- Score: 85 points

#### 2. RHR Component (0-100)

**Formula:** Compare today's RHR vs. baseline (lower is better)

```
percentageChange = (RHR - Baseline) / Baseline

If percentageChange <= 0:
  Score = 100  // At or below baseline = excellent

Else:
  If percentageChange <= 8%:
    Score = 100 - (percentageChange × 150)  // Range: 100-88
  
  Else If percentageChange <= 15%:
    Score = 88 - ((percentageChange - 0.08) × 300)  // Range: 88-67
  
  Else If percentageChange <= 25%:
    Score = 67 - ((percentageChange - 0.15) × 300)  // Range: 67-37
  
  Else:  // > 25%
    Score = 37 - ((percentageChange - 0.25) × 100)  // Range: 37-0
```

**Example:**
- Baseline RHR: 50 bpm
- Today's RHR: 54 bpm (+8%)
- Score: 88 points

#### 3. Sleep Component (0-100)

**Formula:** Use Sleep Score directly, or calculate from duration

```
If Sleep Score exists:
  Score = Sleep Score
  
Else If Sleep Duration exists:
  ratio = Sleep Duration / Baseline
  Score = min(100, ratio × 100)
  
Else:
  Score = 50  // Neutral if no data
```

#### 4. Respiratory Component (0-100)

**Formula:** Compare today's respiratory rate vs. baseline (higher = worse recovery)

```
If no baseline:
  Score = 50  // Neutral

Else:
  percentageChange = (Respiratory - Baseline) / Baseline
  
  If percentageChange <= 0:
    Score = 100  // At or below baseline = excellent
  
  Else:
    // Higher respiratory rate = lower score (linear penalty)
    Score = 100 - (percentageChange × 200)
    Score = max(0, Score)
```

**Example:**
- Baseline: 15 breaths/min
- Today: 16.5 breaths/min (+10%)
- Score: 80 points

#### 5. Form Component (Training Load Balance) (0-100)

**Formula:** TSB (Training Stress Balance) from ATL and CTL

```
If ATL and CTL exist:
  TSB = CTL - ATL
  
  If TSB >= 10:
    Score = 100  // Well-rested, fresh
  
  Else If TSB >= 0:
    Score = 85 + (TSB × 1.5)  // Range: 85-100
  
  Else If TSB >= -10:
    Score = 70 + (TSB × 1.5)  // Range: 55-85 (slight fatigue)
  
  Else If TSB >= -20:
    Score = 40 + ((TSB + 10) × 3)  // Range: 10-55 (moderate fatigue)
  
  Else:
    Score = max(0, 40 + (TSB × 2))  // Heavy fatigue

Else:
  Score = 50  // Neutral if no training load data
```

**Example:**
- CTL: 80 (fitness)
- ATL: 90 (recent load)
- TSB: -10 (slightly fatigued)
- Score: 55 points

### Alcohol Detection

**Special Case:** Multi-factor compound effect detection

```
Indicators of alcohol impact:
- HRV drops significantly (> 20%)
- RHR elevated (> 10%)
- Sleep score poor (< 60)
- No illness detected

If 3+ indicators match:
  Apply additional penalty: -10 to -20 points
```

### Recovery Bands

| Score | Band | Meaning |
|-------|------|---------|
| 80-100 | Optimal | Ready for hard training |
| 60-79 | Good | Moderate training appropriate |
| 40-59 | Fair | Light training or rest recommended |
| 0-39 | Pay Attention | Rest strongly recommended |

---

## Sleep Score

### Overview
Sleep score measures the quality and quantity of your sleep. Range: 0-100.

### Data Points Collected

#### From Apple HealthKit:
1. **Sleep Duration** - Total time asleep (seconds)
2. **Time in Bed** - Total time from bedtime to wake (seconds)
3. **Deep Sleep Duration** - Time in deep sleep (seconds)
4. **REM Sleep Duration** - Time in REM sleep (seconds)
5. **Core Sleep Duration** - Time in light sleep (seconds)
6. **Awake Duration** - Time awake during night (seconds)
7. **Wake Events** - Number of times awakened
8. **Bedtime** - When you went to bed
9. **Wake Time** - When you woke up
10. **HRV Overnight** - Average HRV during sleep (ms)

#### User Settings:
11. **Sleep Need** - Your target sleep duration (from profile)

#### Calculated Baselines (7-day rolling averages):
12. **Baseline Bedtime** - Your typical bedtime
13. **Baseline Wake Time** - Your typical wake time
14. **HRV Baseline** - Your normal HRV

#### Derived:
15. **Sleep Latency** - Time from bedtime to first sleep (seconds)

### Calculation Formula

**Final Sleep Score = Weighted Average of Sub-Scores**

```
Sleep Score = (Performance × 30%) + (Stage Quality × 32%) + (Efficiency × 22%) 
            + (Disturbances × 14%) + (Timing × 2%)
```

### Sub-Score Calculations

#### 1. Performance Component (0-100) - 30% weight

**Formula:** Sleep duration vs. need

```
ratio = Sleep Duration / Sleep Need
Score = min(100, ratio × 100)
```

**Example:**
- Sleep Need: 8 hours (28,800s)
- Actual Sleep: 7.5 hours (27,000s)
- Ratio: 0.9375
- Score: 94 points

#### 2. Stage Quality Component (0-100) - 32% weight

**Formula:** Deep + REM percentage of total sleep

```
deepRemPercentage = (Deep + REM) / Total Sleep

If deepRemPercentage >= 40%:
  Score = 100  // Excellent stage distribution

Else If deepRemPercentage >= 30%:
  Score = 50 + ((deepRemPercentage - 0.30) × 500)  // Range: 50-100

Else:  // < 30%
  Score = deepRemPercentage × 166.67  // Range: 0-50
```

**Example:**
- Total Sleep: 7.5 hours
- Deep: 1.5 hours (20%)
- REM: 2 hours (26.7%)
- Combined: 46.7%
- Score: 100 points

#### 3. Efficiency Component (0-100) - 22% weight

**Formula:** Time asleep vs. time in bed

```
efficiency = Sleep Duration / Time In Bed
Score = efficiency × 100
```

**Example:**
- Time in Bed: 8 hours
- Time Asleep: 7.5 hours
- Efficiency: 93.75%
- Score: 94 points

#### 4. Disturbances Component (0-100) - 14% weight

**Formula:** Wake events penalty

```
Wake Events:
  0-2   → Score = 100
  3-5   → Score = 75
  6-8   → Score = 50
  9+    → Score = 25
```

**Example:**
- Wake Events: 3
- Score: 75 points

#### 5. Timing Component (0-100) - 2% weight

**Formula:** Bedtime consistency vs. baseline

```
bedtimeDeviation = |Bedtime - Baseline Bedtime| (in hours)

If bedtimeDeviation <= 0.5 hours:
  Score = 100  // Very consistent

Else If bedtimeDeviation <= 1 hour:
  Score = 80

Else If bedtimeDeviation <= 2 hours:
  Score = 60

Else:
  Score = 40
```

**Example:**
- Baseline: 10:30 PM
- Today: 11:00 PM (0.5 hour deviation)
- Score: 100 points

### Sleep Bands

| Score | Band | Meaning |
|-------|------|---------|
| 80-100 | Optimal | Excellent sleep quality |
| 60-79 | Good | Decent sleep, minor improvements possible |
| 40-59 | Fair | Sleep could be better |
| 0-39 | Pay Attention | Poor sleep, needs immediate attention |

---

## Strain Score (Load)

### Overview
Strain score measures the physical stress placed on your body today. Range: 0-18 (Whoop-style scale).

### Data Points Collected

#### From Apple HealthKit:
1. **Daily Steps** - Total steps today
2. **Active Calories** - Calories burned from activity
3. **Workouts** - All workouts recorded in HealthKit
   - Duration
   - Heart rate stream (if available)
   - Type (cycling, running, strength, etc.)

#### From Training Platforms:
4. **Strava Activities** - Today's rides/runs
   - Duration
   - Power data (if available)
   - Heart rate data
5. **Intervals.icu Activities** - Today's training
   - TSS (Training Stress Score)
   - Duration
   - Intensity Factor

#### From User Profile:
6. **FTP (Functional Threshold Power)** - Watts
7. **Max Heart Rate** - bpm
8. **Resting Heart Rate** - bpm
9. **Body Mass** - kg

#### From RPE Input:
10. **Strength Training RPE** - User-reported intensity (1-10)
11. **Muscle Groups Trained** - User-selected groups

#### Calculated:
12. **TRIMP (Training Impulse)** - From heart rate data
13. **Intensity Factor** - Normalized power / FTP
14. **ATL/CTL** - Training load metrics

### Calculation Formula

**Final Strain Score = Cardio Load + Strength Load + Non-Exercise Load**

Then apply **recovery modulation** (reduces strain if recovered, increases if fatigued)

```
TRIMP → EPOC → Whoop Strain (0-18 scale)

Cardio Load (0-100):
  Base = 18 × log10(TRIMP + 1)
  + Duration bonus (if > 60 min): min(10, (duration - 60) × 0.1)
  + Intensity bonus (if IF > 0.8): min(15, (IF - 0.8) × 75)

Strength Load (0-100):
  Base = RPE × 10
  × Duration factor (30 min = 1.0x, 60+ min = 1.5x)
  × Volume bonus (if sets/reps tracked): +5-15 points

Non-Exercise Load (0-100):
  Base = Steps × 0.001 + Active Calories × 0.015
  Cap at 20 points (minimal contribution)

Final = Scale to 0-18 using logarithmic compression
```

### TRIMP Calculation (Training Impulse)

**Formula:** Zone-weighted heart rate time

```
For each heart rate data point:
  hrRR = (HR - RestingHR) / (MaxHR - RestingHR)  // Fractional reserve
  intensityWeight = hrRR ^ 2.2  // Exponential weighting
  TRIMP += intensityWeight × timeDelta (seconds)

If Power Data also available (cycling):
  powerFraction = Power / FTP
  blendedIntensity = (0.6 × hrRR) + (0.4 × powerFraction)
  intensityWeight = blendedIntensity ^ 2.2
  TRIMP += intensityWeight × timeDelta
```

**Example:**
- 60-minute ride at 85% max HR
- RestingHR: 50, MaxHR: 190
- Average HR: 169 bpm (85% of max)
- hrRR: (169-50)/(190-50) = 0.85
- intensityWeight: 0.85^2.2 = 0.73
- TRIMP ≈ 0.73 × 3600 = 2,628

### TRIMP to Strain Conversion

**Step 1: TRIMP → EPOC (Excess Post-Exercise Oxygen Consumption)**

```
EPOC = 0.25 × TRIMP^1.1
```

**Step 2: EPOC → Whoop Strain (0-18 scale)**

```
epocMax = 1,200
Strain = 18 × ln(EPOC + 1) / ln(epocMax + 1)
Strain = max(0, min(18, Strain))
```

**Example:**
- TRIMP: 2,628
- EPOC: 0.25 × 2628^1.1 ≈ 852
- Strain: 18 × ln(853) / ln(1201) ≈ 13.2

### Recovery Modulation

**Formula:** Adjust strain based on recovery state

```
Recovery Factor = 1.0 + (0.15 × recoverySignal)

recoverySignal = (0.6 × zHRV) + (0.3 × zRHR) + (0.1 × zSleep)

Where z-scores are:
  zHRV = (HRVtoday - HRVbaseline) / HRVbaseline
  zRHR = (RHRbaseline - RHRtoday) / RHRbaseline  // Inverted!
  zSleep = (SleepScore - 75) / 25

Final Strain = Base Strain × Recovery Factor
```

**Example:**
- Base Strain: 13.2
- HRV +10% above baseline (zHRV = +0.10)
- RHR at baseline (zRHR = 0)
- Sleep Score: 85 (zSleep = +0.40)
- recoverySignal = (0.6 × 0.10) + (0.3 × 0) + (0.1 × 0.40) = 0.10
- Recovery Factor = 1.0 + (0.15 × 0.10) = 1.015
- Final Strain = 13.2 × 1.015 ≈ 13.4

### Strain Bands

| Score | Band | Meaning |
|-------|------|---------|
| 0-6.0 | Light | Easy day, minimal stress |
| 6.0-11.0 | Moderate | Solid training day |
| 11.0-16.0 | Hard | Tough training, need recovery |
| 16.0-18.0 | Very Hard | Extremely demanding, max effort |

---

## Proposed: Stress Score

### Overview
A stress score would measure psychological and physiological stress based on existing data. Range: 0-100 (0 = no stress, 100 = extreme stress).

### Data Points Already Collected

We already collect all necessary data for stress measurement:

1. **HRV (RMSSD)** - Lower HRV = higher stress
2. **RHR** - Elevated RHR = higher stress
3. **Respiratory Rate** - Elevated breathing = higher stress
4. **Sleep Quality** - Poor sleep = higher stress
5. **Sleep Disturbances** - More wake events = higher stress
6. **Training Load (ATL vs CTL)** - Overtraining = higher stress
7. **Recovery Score** - Low recovery = higher stress

### Proposed Calculation Formula

**Stress Score = Physiological Stress + Recovery Deficit + Sleep Disruption**

```
Physiological Stress Component (0-40 points):
  HRV Deviation = (Baseline - Current) / Baseline × 100
  RHR Deviation = (Current - Baseline) / Baseline × 100
  Respiratory Deviation = (Current - Baseline) / Baseline × 100
  
  HRV Stress = min(15, HRV Deviation × 0.5)  // 15 points max
  RHR Stress = min(15, RHR Deviation × 1.5)  // 15 points max
  Resp Stress = min(10, Respiratory Deviation × 2.0)  // 10 points max
  
  Physiological = HRV Stress + RHR Stress + Resp Stress

Recovery Deficit Component (0-30 points):
  If Recovery Score >= 70:
    Deficit = 0  // Well recovered
  Else:
    Deficit = (70 - Recovery Score) × 0.5
    Deficit = min(30, Deficit)

Sleep Disruption Component (0-30 points):
  Base = (100 - Sleep Score) × 0.2  // Max 20 points
  Wake Events Penalty = min(10, Wake Events × 2)
  Sleep Disruption = Base + Wake Events Penalty
```

**Final Stress Score = Physiological + Recovery Deficit + Sleep Disruption**

**Capped at 0-100**

### Advanced: Multi-Day Stress Accumulation

Track stress over multiple days to detect chronic stress:

```
Acute Stress = Today's Stress Score
Chronic Stress = 7-day moving average of Stress Scores

If Chronic Stress > 60 AND Acute Stress > 70:
  Alert: "Chronic stress detected - consider rest day"
```

### Stress Detection Indicators

**High Stress Indicators:**
- HRV drops > 20% below baseline for 3+ days
- RHR elevated > 10% for 3+ days
- Sleep Score < 60 for 3+ days
- Recovery Score < 50 for 2+ days
- Training load (ATL/CTL ratio) > 1.5

### Supporting Research

#### 1. **HRV as Stress Biomarker**
**Fatigue Monitoring Through Heart Rate Variability**  
*Journal of Sports Science* (2024)

Key Findings:
- RMSSD (root mean square of successive differences) is the most reliable HRV metric for stress
- HRV decreases of >20% from baseline indicate significant physiological stress
- Multi-day HRV tracking (7-14 days) provides better stress assessment than single-day
- Combined HRV + RHR provides 85% accuracy in detecting overtraining

**Source:** https://rrpubs.com/index.php/rol/article/view/164

#### 2. **Sleep, HRV, and Cortisol Relationships**
**Associations Between Sleep Duration, Heart Rate Variability, and Cortisol in Athletes**  
*Frontiers in Physiology* (2022)

Key Findings:
- Strong correlation (r = -0.68) between poor sleep and elevated stress
- Athletes with <6 hours sleep showed 30% reduction in HRV recovery
- Sleep disruption (wake events) correlates with elevated morning cortisol
- Combined sleep quality + HRV metrics predict stress with 78% accuracy

**Source:** https://pubmed.ncbi.nlm.nih.gov/35321140/

#### 3. **Respiratory Rate and Stress Detection**
**Respiratory Sinus Arrhythmia and Breathing Rate Variability as Stress Indicators**  
*Psychophysiology* (2023)

Key Findings:
- Elevated respiratory rate (>16 breaths/min at rest) indicates autonomic stress
- Breathing rate variability decreases under chronic stress
- Respiratory rate combined with HRV improves stress detection by 15%
- Real-time respiratory monitoring viable with wearable sensors

**Source:** https://www.frontiersin.org/articles/10.3389/fpsyg.2019.01083/full

#### 4. **Subjective vs Objective Stress Measures**
**Associations Between Subjective and Objective Measures of Stress and Load in Elite Athletes**  
*Journal of Sports Medicine* (2025)

Key Findings:
- Perceived Stress Scale (PSS) shows moderate correlation (r = 0.45) with HRV-based stress
- Combining subjective questionnaires + physiological data improves accuracy to 82%
- Athletes under-report stress 35% of the time
- Objective measures (HRV, RHR) detect stress 2-3 days before subjective awareness

**Source:** https://pubmed.ncbi.nlm.nih.gov/39906197/

### Implementation Recommendations

**Phase 1: Passive Stress Monitoring (No User Input)**
- Calculate stress from existing physiological data
- Display stress trends in app
- Alert when stress elevated for 3+ consecutive days

**Phase 2: Add Subjective Check-ins (Optional)**
- Daily 3-question survey:
  1. "How stressed do you feel today?" (1-10 scale)
  2. "Rate your mental fatigue" (1-10 scale)
  3. "Rate your motivation to train" (1-10 scale)
- Blend subjective scores (20% weight) with objective data (80% weight)

**Phase 3: Stress Management Recommendations**
- If Stress > 70: Suggest rest day, meditation, or light activity
- If Chronic Stress > 60: Suggest recovery week or deload
- If Stress + Low Recovery: Prioritize sleep and nutrition

### Stress Bands

| Score | Band | Meaning |
|-------|------|---------|
| 0-25 | Low | Minimal stress, feeling good |
| 26-50 | Moderate | Normal training stress |
| 51-70 | Elevated | Approaching overload, monitor closely |
| 71-100 | High | Significant stress, recovery needed |

---

## Quick Reference Lists

### Recovery Score - Complete Data & Calculations

**Data Collected:**
1. HRV (latest + overnight) - milliseconds
2. RHR (latest) - bpm
3. Respiratory Rate (latest) - breaths/min
4. Sleep Score - 0-100 (if available)
5. ATL (Acute Training Load) - from Intervals.icu
6. CTL (Chronic Training Load) - from Intervals.icu
7. Recent Strain - yesterday's strain score
8. HRV Baseline - 7-14 day average
9. RHR Baseline - 7-14 day average
10. Sleep Baseline - 7-14 day average
11. Respiratory Baseline - 7-14 day average
12. Illness Indicator - multi-day HRV/RHR analysis

**Calculations:**
1. **HRV Sub-Score:** Compare vs baseline using non-linear scale (0-100)
2. **RHR Sub-Score:** Compare vs baseline using non-linear scale (0-100)
3. **Sleep Sub-Score:** Use sleep score directly (0-100)
4. **Respiratory Sub-Score:** Compare vs baseline (0-100)
5. **Form Sub-Score:** Calculate TSB from ATL/CTL (0-100)
6. **Weighted Average:** Apply 30/20/30/10/10% weights (with sleep) or 42.8/28.6/14.3/14.3% (without)
7. **Alcohol Detection:** Multi-factor compound effect analysis
8. **Band Assignment:** Map 0-100 to 4 bands

---

### Sleep Score - Complete Data & Calculations

**Data Collected:**
1. Sleep Duration - seconds
2. Time in Bed - seconds
3. Deep Sleep Duration - seconds
4. REM Sleep Duration - seconds
5. Core Sleep Duration - seconds
6. Awake Duration - seconds
7. Wake Events - count
8. Bedtime - timestamp
9. Wake Time - timestamp
10. HRV Overnight - milliseconds
11. Sleep Need - seconds (from user profile)
12. Baseline Bedtime - 7-day average
13. Baseline Wake Time - 7-day average
14. HRV Baseline - 7-14 day average
15. Sleep Latency - derived (bedtime to first sleep)

**Calculations:**
1. **Performance Sub-Score:** Sleep Duration / Sleep Need × 100 (0-100)
2. **Stage Quality Sub-Score:** (Deep + REM) / Total × optimality curve (0-100)
3. **Efficiency Sub-Score:** Sleep Duration / Time in Bed × 100 (0-100)
4. **Disturbances Sub-Score:** Wake events bucketed scoring (0-100)
5. **Timing Sub-Score:** Bedtime deviation from baseline (0-100)
6. **Weighted Average:** Apply 30/32/22/14/2% weights
7. **Band Assignment:** Map 0-100 to 4 bands

---

### Strain Score - Complete Data & Calculations

**Data Collected:**
1. Daily Steps - count
2. Active Calories - kcal
3. HealthKit Workouts - all activities with heart rate streams
4. Strava Activities - rides/runs with power + HR data
5. Intervals.icu Activities - training with TSS data
6. FTP - watts (user profile)
7. Max HR - bpm (user profile)
8. Resting HR - bpm (user profile)
9. Body Mass - kg (user profile)
10. Strength RPE - 1-10 (user input)
11. Muscle Groups - user selection
12. HRV + RHR + Sleep - for recovery modulation

**Calculations:**
1. **TRIMP:** Zone-weighted HR time using exponential curve (hrRR^2.2)
2. **Blended TRIMP:** Combine HR (60%) + Power (40%) for cycling
3. **EPOC Conversion:** 0.25 × TRIMP^1.1
4. **Whoop Strain:** 18 × ln(EPOC + 1) / ln(1200 + 1)
5. **Cardio Load:** Logarithmic TRIMP scaling + duration/intensity bonuses (0-100)
6. **Strength Load:** RPE × duration × volume factors (0-100)
7. **Non-Exercise Load:** Steps + active calories with cap (0-20)
8. **Recovery Modulation:** Adjust strain by ±15% based on HRV/RHR/Sleep z-scores
9. **Final Strain:** Sum components, apply modulation, scale to 0-18
10. **Band Assignment:** Map 0-18 to 4 bands

---

### Proposed Stress Score - Complete Data & Calculations

**Data Collected (Already Available):**
1. HRV (RMSSD) - milliseconds
2. RHR - bpm
3. Respiratory Rate - breaths/min
4. Sleep Score - 0-100
5. Wake Events - count
6. Recovery Score - 0-100
7. ATL/CTL - training load ratio
8. HRV Baseline - 7-14 day average
9. RHR Baseline - 7-14 day average
10. Respiratory Baseline - 7-14 day average

**Calculations:**
1. **HRV Stress:** (Baseline - Current) / Baseline × 50, cap at 15 points
2. **RHR Stress:** (Current - Baseline) / Baseline × 150, cap at 15 points
3. **Respiratory Stress:** (Current - Baseline) / Baseline × 200, cap at 10 points
4. **Physiological Stress:** Sum of HRV + RHR + Respiratory (max 40 points)
5. **Recovery Deficit:** (70 - Recovery Score) × 0.5, cap at 30 points
6. **Sleep Disruption:** (100 - Sleep Score) × 0.2 + (Wake Events × 2), cap at 30 points
7. **Total Stress:** Sum all components (max 100 points)
8. **Multi-Day Tracking:** 7-day moving average for chronic stress detection
9. **Threshold Alerts:** Trigger warnings when acute > 70 OR chronic > 60
10. **Band Assignment:** Map 0-100 to 4 bands

**Optional Enhancement (Phase 2):**
11. **Perceived Stress Scale (PSS):** 3-question daily survey
12. **Blended Score:** Objective data (80%) + Subjective (20%)

---

## Why This Matters for Users

### Transparency Benefits

**1. Trust Through Understanding**
- Users see exactly what's measured and how
- No "black box" algorithms
- Can validate scores against their lived experience

**2. Actionable Insights**
- If HRV is low but RHR is normal → focus on stress management
- If sleep efficiency is low → improve sleep environment
- If form score (TSB) is negative → plan recovery week

**3. Data Empowerment**
- Users can experiment (e.g., "Does magnesium improve my sleep stages?")
- Can correlate changes to training or lifestyle adjustments
- Builds intuition about their own physiology

**4. Educational Value**
- Learn what good recovery looks like (personalized baselines)
- Understand relationships between metrics (HRV ↔ Training Load)
- Become more in tune with body signals

### Example User Flow

**Morning Check:**
1. Open app → see Recovery: 65 (Fair)
2. Tap → see breakdown:
   - HRV: 85/100 (good)
   - RHR: 75/100 (slightly elevated)
   - Sleep: 45/100 (poor)
   - Form: 55/100 (fatigued)
3. Insight: "Sleep was disrupted (6 wake events). Consider light training today."
4. Action: Plan easy 30-min recovery ride instead of intervals

**Post-Training:**
1. Strain: 12.8 (Hard)
2. Tap → see breakdown:
   - TRIMP: 3,200 (from 90-min ride at 80% FTP)
   - Recovery Factor: 0.92 (slightly fatigued going in)
   - Adjusted Strain: 13.9
3. Insight: "This was harder than planned due to low recovery. Prioritize sleep tonight."
4. Action: Early bedtime, skip evening social event

---

## Data Privacy Note

All calculations happen on-device. Raw data:
- HRV, RHR, Sleep, Workouts → stored locally in HealthKit
- Training data → synced from platforms via OAuth (user control)
- Baselines & scores → stored locally in app database

Only anonymized, aggregated metrics sent to backend for AI Brief generation (with explicit user consent).

---

## Technical Implementation Notes

### Architecture
- **Data Fetching:** iOS app → HealthKit + API clients
- **Calculation Logic:** `VeloReadyCore` Swift package (pure functions, no UI dependencies)
- **Caching:** 24-hour cache for daily scores, 7-day cache for baselines
- **Updates:** Background refresh every 15 minutes when app active

### Performance
- All calculations run on background actor to avoid blocking UI
- Parallel fetching of independent data sources (HRV + RHR + Sleep + Training Load)
- Sub-score calculations cached to avoid recomputation
- Total calculation time: 2-5 seconds on first load, <1 second cached

### Testing
- Unit tests for all calculation functions in `VeloReadyCore`
- Integration tests for data fetching pipelines
- End-to-end tests for score calculation workflows
- Scenario tests for edge cases (missing data, outliers, etc.)

---

**Last Updated:** November 11, 2025  
**Version:** 1.0.0  
**Document Status:** Complete with Stress Score Proposal

