# Wellness Warning Detection Thresholds

## Overview
VeloReady uses two detection services for health/wellness warnings:
1. **Illness Detection Service** (Red Warning - Higher Sensitivity)
2. **Wellness Detection Service** (Amber Warning - Lower Sensitivity)

---

## Illness Detection Service
**File:** `Core/Services/IllnessDetectionService.swift`  
**Purpose:** Detects potential illness indicators with higher sensitivity  
**Alert Style:** Red warning banner with "Body Stress Detected"

### Detection Thresholds
| Metric | Threshold | Description |
|--------|-----------|-------------|
| **HRV Drop** | -10% | 10% drop from baseline |
| **HRV Spike** | +100% | 100% elevation (parasympathetic overdrive) |
| **RHR Elevation** | +3% | 3% elevation above baseline |
| **Sleep Quality Drop** | -15% | 15% drop from baseline |
| **Sleep Disruption** | Score 60-84 | With negative deviation |
| **Respiratory Change** | +8% | 8% change from baseline |
| **Activity Drop** | -25% | 25% drop from baseline |
| **Temperature Elevation** | +0.3°C | 0.3°C above baseline |

### Detection Rules
- **Minimum Signals Required:** 1 (only need 1 strong signal)
- **Minimum Confidence:** 0.5 (50%)
- **Analysis Window:** 7 days
- **Minimum Data Points:** 3 days
- **Analysis Interval:** 1 hour (prevents over-analysis)

### Severity Levels
- **Low:** Single weak signal
- **Moderate:** 1-2 strong signals
- **High:** 3+ signals with sustained trend

### ML-Enhanced Confidence Adjustment
- **Sustained Multi-Day Trends:** +10% confidence boost
- **Multiple Concurrent Signals:** +5% per additional signal (beyond 2)
- **Worsening Recent Trend:** Noted in pattern analysis

---

## Wellness Detection Service
**File:** `Core/Services/WellnessDetectionService.swift`  
**Purpose:** Detects sustained multi-day wellness concerns (more conservative)  
**Alert Style:** Amber/Yellow warning banner

### Detection Thresholds
| Metric | Threshold | Description |
|--------|-----------|-------------|
| **RHR Elevation** | +15% | 15% above baseline |
| **HRV Depression** | -20% | 20% below baseline |
| **Respiratory Elevation** | +20% | 20% above baseline |
| **Body Temp Elevation** | +0.5°C | 0.5°C above baseline |

### Detection Rules
- **Minimum Consecutive Days:** 2 days
- **Minimum Affected Metrics:** 3 (need 3+ metrics affected)
- **Analysis Window:** 3 days
- **Analysis Interval:** 1 hour

### Severity Levels
| Severity | Criteria |
|----------|----------|
| **Red** | 5+ metrics affected OR 4+ consecutive days |
| **Amber** | 4+ metrics affected OR 3+ consecutive days |
| **Yellow** | 3 metrics affected with shorter duration |

### Override Logic
- If Recovery Score > 75: Only show alert if 4+ metrics affected
  - Prevents false alarms when user feels good

---

## Debug/Testing Toggles
**File:** `Core/Config/ProFeatureConfig.swift`

### Available Toggles
1. **`showIllnessIndicatorForTesting`**
   - Shows mock illness indicator (Moderate severity, 78% confidence)
   - Triggers red "Body Stress Detected" banner

2. **`showWellnessWarningForTesting`**
   - Shows mock wellness alert (Red severity, multiple indicators)
   - Triggers amber wellness warning banner

### Location
Settings → Debug → Testing Features

---

## UI Display

### Illness Indicator (Red)
- **Component:** `HealthWarningsCard.swift`
- **Banner Style:** Red accent color
- **Title:** "Body Stress Detected"
- **Shows:** Severity badge, recommendation, affected signals
- **Detail Sheet:** `IllnessDetailSheet` with full metrics

### Wellness Alert (Amber/Yellow)
- **Component:** `HealthWarningsCard.swift`
- **Banner Style:** Amber/Yellow accent color
- **Title:** Varies by alert type
- **Shows:** Severity badge, affected metrics count
- **Detail Sheet:** `WellnessDetailSheet` with trends

---

## Real-World Detection Example
**Date:** October 21, 2025  
**User Status:** Sick (sore throat, fatigue)

### Metrics:
- HRV: 141ms (baseline: 44ms) = **+220% spike**
- Wake Events: 6 (high disruption)
- Sleep Score: 68 (masked as "acceptable")

### Detection Result:
- **Old System:** Missed completely (only checked HRV drops)
- **New System:** **HIGH severity** illness indicator with 51% confidence
- **AI Response:** Prescribed rest, overrode other training suggestions

---

## Caching
Both services use `UnifiedCacheManager` with appropriate TTLs:
- **Illness Detection:** `CacheTTL.wellness` (2 hours)
- **Health Metrics:** `CacheTTL.healthMetrics` (30 minutes)
- **Daily Scores:** `CacheTTL.dailyScores` (24 hours)

## Performance
- Analysis runs asynchronously to avoid blocking UI
- Parallel data fetching using `async let`
- Respects minimum analysis interval to prevent over-querying
- Cached results reduce HealthKit queries
