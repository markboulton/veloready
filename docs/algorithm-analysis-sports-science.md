# VeloReady Algorithm Analysis vs Modern Sports Science

**Date:** November 2025
**Author:** Algorithm Review

## Executive Summary

Your algorithms are **fundamentally sound** and align with industry standards (TrainingPeaks, Whoop, Intervals.icu). However, there are several evidence-based improvements that could enhance reliability, accuracy, and provide competitive differentiation.

---

## 1. RECOVERY SCORING (`RecoveryCalculations.swift`)

### Current Approach
- Weighted composite: HRV 30%, RHR 20%, Sleep 30%, Respiratory 10%, Form 10%
- Percentage-based deviations from rolling baselines
- Alcohol compound detection using multi-signal confidence scoring

### Sports Science Assessment

**What You're Doing Right:**
- Using HRV as primary recovery marker aligns with research (Plews et al., 2013)
- Multi-signal approach (HRV + RHR + Sleep) matches Whoop methodology
- Baseline-relative scoring is the gold standard

**Research-Backed Concerns:**

1. **Single-day HRV vs Rolling Average**
   > "A 7-day running average of LnRMSSD instead of daily measures" is recommended (Plews et al., 2013; *Frontiers in Physiology*)

   Your algorithm uses single-day HRV readings. Research shows daily HRV has high noise; the **7-day rolling average** and **coefficient of variation (CV)** are more predictive of readiness.

2. **Missing CV Metric**
   > "Athletes with the smallest CV at baseline subsequently handle overload very well... Conversely, athletes with the highest CV respond least favorably" (HRVtraining.com research)

   **Day-to-day HRV fluctuation** (CV) is a better predictor of overreaching than absolute HRV values.

3. **Linear vs Non-Linear HRV Scoring**
   Your `calculateHRVComponent` uses linear scaling. Research suggests:
   > "Non-linear dynamic analysis of HRV data... is a reasonable numerical indicator" for fatigue monitoring (*ScienceDirect*, 2024)

### Recommendations

| Priority | Improvement | Impact |
|----------|-------------|--------|
| High | Add 7-day rolling LnRMSSD average | Better noise filtering |
| High | Add HRV CV (coefficient of variation) as readiness signal | Early overreaching detection |
| Medium | Weight recent 3 days more heavily in baseline | Faster adaptation to trends |
| Low | Consider LnRMSSD/RR ratio for identifying vagal saturation | Catch parasympathetic ceiling |

---

## 2. SLEEP SCORING (`SleepCalculations.swift`)

### Current Approach
- 5 sub-scores: Performance 30%, Stage Quality 32%, Efficiency 22%, Disturbances 14%, Timing 2%
- Fixed thresholds (40% deep+REM = excellent)
- HRV-based quality adjustment (recently added)

### Sports Science Assessment

**What You're Doing Right:**
- Weighting stage quality highly aligns with recovery research
- Sleep efficiency metric is validated
- HRV adjustment catches "false good sleep" scenarios

**Research-Backed Concerns:**

1. **Fixed Deep/REM Thresholds**
   Research shows significant individual variation:
   > "Mean deep sleep percentage of 25.56 ± 4.88%, and mean REM sleep percentage of 18.99 ± 2.81%" (*PMC Sleep Architecture Study*)

   Athletes in different sports show 2-fold differences in deep sleep (61-139 minutes). Your **personalized** function exists but isn't the default.

2. **Missing Post-Exercise Sleep Architecture Changes**
   > "Match days incurred... altered sleep architecture (deep: +9.8%; REM: -6.9%)" (*Taylor & Francis*, 2025)

   Hard training days legitimately alter sleep architecture. Your algorithm may penalize this as "poor" sleep.

3. **Sleep Stage Accuracy from Wearables**
   > "Oura ring measured sleep with... agreement of 65%, 51%, and 61% in measuring light, deep, and REM sleep" (*PMC Polysomnography Study*)

   Consumer wearables have 50-65% accuracy on sleep stages. Building complex formulas on unreliable data is risky.

### Recommendations

| Priority | Improvement | Impact |
|----------|-------------|--------|
| High | Use `calculatePersonalizedStageQualityScore` by default | Individual accuracy |
| High | Reduce stage quality weight to 20-25% given wearable accuracy | Reliability |
| Medium | Add "recovery day" context (high TSS yesterday → expect more deep) | Context awareness |
| Medium | Weight total sleep time more heavily (most reliable metric) | Use best data |

---

## 3. TRAINING LOAD (`TrainingLoadCalculations.swift`)

### Current Approach
- Standard CTL/ATL with 42/7 day time constants
- Linear exponential weighted moving average
- TSB = CTL - ATL

### Sports Science Assessment

**What You're Doing Right:**
- Formula matches TrainingPeaks/Intervals.icu standard
- 42/7 day constants are widely accepted defaults

**Critical Research-Backed Concerns:**

1. **Fixed Time Constants Are Wrong for Individuals**
   > "The main flaw with the Banister and Busso models is that the values for the constants used are specific to each individual, and possibly to the particular training regime" (*PMC Banister Model Study*)

   > "The use of general constants should be avoided since they do not account for interindividual differences" (*Sports Medicine Open*, 2022)

   Research suggests fitness decay time constant ranges from 30-60 days depending on athlete.

2. **TSB Model Fundamental Limitation**
   > "The main limitation of the TSB model can be seen in that training reduces performance and never improves it. The TSB model only indicates improved performance when training is reduced." (*Fellrnr.com analysis*)

   The **Banister impulse-response model** is more experimentally validated but mathematically complex.

3. **Missing Training Type Differentiation**
   Different training modalities have different adaptation curves. Your calculation treats all TSS equally.

### Recommendations

| Priority | Improvement | Impact |
|----------|-------------|--------|
| High | Add adaptive time constants based on user history | Personalization |
| High | Consider separate fitness/fatigue tracking (Banister model) | Accuracy |
| Medium | Add half-life display (14.5 days for CTL, 2.4 for ATL) | User understanding |
| Low | Consider training-type-specific time constants | Precision |

---

## 4. STRAIN SCORING (`StrainCalculations.swift`)

### Current Approach
- TRIMP calculation with 2.2 zone weight exponent
- Whoop-like logarithmic strain formula: `18 × ln(EPOC + 1) / ln(EPOC_max + 1)`
- Blended HR + Power option

### Sports Science Assessment

**What You're Doing Right:**
- TRIMP is validated (Morton et al., 1990; Banister's original work)
- Logarithmic scaling matches Whoop approach
- Blending HR + power covers limitations of each

**Research-Backed Concerns:**

1. **TRIMP Validation Studies Show Variation**
   > "The strongest relationships with changes in aerobic fitness variables were observed for iTRIMP (r = .81) and TSS (r = .75-.79)" (*PubMed Cycling Validation Study*)

   **Individualized TRIMP (iTRIMP)** outperforms standard Banister TRIMP. iTRIMP uses individual HR-lactate relationships.

2. **Your Zone Exponent (2.2) Is Arbitrary**
   Banister's original used gender-specific factors (1.67 for women, 1.92 for men). Your 2.2 may over-weight high intensity.

3. **Whoop's Algorithm Is A Black Box**
   > "It is important to point out that these metrics are black boxes. We have no idea what algorithms wearable companies use" (*CTS Expert Critique*)

   > "One expert noted: 'I tend not to dedicate much of my time to made up-scores... Eventually, it is just calories'" (*Two Percent Analysis*)

### Recommendations

| Priority | Improvement | Impact |
|----------|-------------|--------|
| High | Consider iTRIMP if lactate threshold data available | +6% accuracy over standard TRIMP |
| Medium | Make zone exponent configurable (1.67-2.2 range) | Personalization |
| Medium | Add sRPE (session RPE) as validation/fallback | Cross-validation |
| Low | Validate EPOC conversion factor against real EPOC data | Calibration |

---

## 5. BASELINE CALCULATIONS (`BaselineCalculations.swift`)

### Current Approach
- 30-day window with 3-sigma outlier removal
- Median instead of mean (robust)
- Historical alcohol day detection and exclusion

### Sports Science Assessment

**What You're Doing Right:**
- 30-day window matches research recommendations
- Outlier removal is essential for HRV data
- Alcohol exclusion is innovative and valuable

**Research-Backed Concerns:**

1. **Static Window vs Adaptive**
   > "Some alternatives motivated by relevant physiological assumptions make the features' parameters varying over time" (*Sports Medicine Open*, 2022)

   Fitness changes over seasons; 30-day baseline may lag behind rapid improvement or decline.

2. **Missing Trend Detection**
   > "An increasing HRV trend throughout training is not always a good thing—several studies have reported increasing HRV trends in overtrained athletes" (*SimpliFaster Research*)

   Your baseline doesn't track **direction of change** (improving vs declining trend).

### Recommendations

| Priority | Improvement | Impact |
|----------|-------------|--------|
| High | Add trend detection (7-day vs 30-day comparison) | Early warning system |
| Medium | Consider exponentially-weighted baseline (recent days weighted more) | Faster adaptation |
| Medium | Add seasonal/phase adjustment capability | Periodization awareness |

---

## 6. COMPETITIVE EDGE OPPORTUNITIES

Based on the research, here are differentiators that would set VeloReady apart:

### Tier 1: High Impact, Research-Validated

1. **HRV-Guided Training Recommendations**
   > "HRV-guided training significantly improved VO2max (MD = 2.84, p < 0.0001)" and "fewer non-responders" (*PMC Meta-Analysis*)

   **Opportunity**: Provide daily "train hard / train easy / rest" recommendations based on HRV trend + CV. No major competitor does this well on iOS.

2. **Coefficient of Variation (CV) Dashboard**
   Show users their HRV stability over time. Higher CV = need more recovery. This is cutting-edge sports science that Whoop doesn't surface.

3. **Transparent Algorithm Explanations**
   > Whoop criticized: "black boxes... We have no idea what algorithms [they] use"

   **Opportunity**: Be the "open science" alternative. Show users exactly why their score is what it is.

### Tier 2: Medium Impact, Differentiating

4. **Individualized Time Constants**
   Learn user's personal fitness/fatigue decay rates over 3-6 months. Display as "Your recovery profile."

5. **Training Type Classification**
   Different adaptations for endurance vs intensity vs strength. Show users their current training distribution.

6. **Sleep Architecture Context**
   "Your deep sleep was elevated (+12%) - normal after yesterday's hard workout" instead of penalizing.

### Tier 3: Innovative/Experimental

7. **Machine Learning Fatigue Classification**
   > "24 HRV features were calculated and then a feature selection method was proposed. After feature selection, the best 11 features were used" (*ScienceDirect*, 2024)

   Train a model on user's historical data to predict fatigue states.

8. **Multi-Day Recovery Projection**
   Given current state + planned training, project recovery over next 3-7 days.

---

## Key Scientific References

1. **Plews et al. (2013)** - LnRMSSD as preferred HRV metric, 7-day rolling average
2. **Morton et al. (1990)** - Banister TRIMP validation for endurance performance
3. **Murray et al. (2017)** - EWMA for training load vs injury/illness risk
4. **Saw et al. (2016)** - Athlete monitoring best practices
5. **PMC 8507742** - HRV-guided training meta-analysis
6. **Sports Medicine Open (2022)** - Fitness-fatigue model limitations
7. **German Journal of Sports Medicine (2024)** - HRV methods review

---

## Summary Priority Matrix

| Category | Quick Wins (1-2 weeks) | Medium-term (1-2 months) | Long-term (3+ months) |
|----------|------------------------|--------------------------|----------------------|
| **Reliability** | Increase sleep duration weight | Add HRV rolling average | Adaptive baselines |
| **Accuracy** | Use personalized sleep stages | Add CV metric | Individualized time constants |
| **Competitive Edge** | Transparent algorithm explanations | HRV-guided recommendations | ML fatigue prediction |

---

## Bottom Line

Your algorithms are **solid and industry-standard**. The biggest opportunities for improvement are:

1. **HRV**: Switch from single-day to 7-day rolling average + add CV metric (most impactful reliability fix)
2. **Sleep**: Use personalized baselines by default, reduce stage quality weighting given wearable accuracy
3. **Training Load**: Consider adaptive time constants (hardest to implement, biggest accuracy gain)
4. **Competitive Edge**: HRV-guided daily training recommendations + transparent "why" explanations

The alcohol detection work is actually ahead of the curve - most apps don't attempt this at all. The compound signal detection (HRV + RHR together) is research-aligned.
