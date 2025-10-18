# Trends & Settings Comprehensive Audit

## 1. Weekly Report Analysis

### Current Status
- **Caching:** ✅ YES - Cached for **1 week** (604,800 seconds)
- **Cache Key:** `{userId}:weekly-report:{mondayDate}:{promptVersion}`
- **Auto-refresh:** Every Monday (new week = new cache key)
- **Model:** `gpt-4o-mini`
- **Max tokens:** 1200
- **Temperature:** 0.4

### Cost Analysis (Scaling)

#### Current Prompt Size:
- **System prompt:** ~1,400 chars (~350 tokens)
- **Few-shot examples:** 5 examples × ~400 chars = ~2,000 chars (~500 tokens)
- **User content:** ~500 chars (~125 tokens)
- **Total input:** ~975 tokens
- **Output:** ~400 tokens (1500-2000 chars target)

#### Cost per Request (gpt-4o-mini):
- **Input:** $0.150 / 1M tokens = 975 tokens × $0.00000015 = **$0.00015**
- **Output:** $0.600 / 1M tokens = 400 tokens × $0.0000006 = **$0.00024**
- **Total per generation:** **~$0.00039** (less than half a cent)

#### Scaling Projections:

**With 1-week caching:**
| Users | Requests/Week | Cost/Week | Cost/Month | Cost/Year |
|-------|---------------|-----------|------------|-----------|
| 100   | 100           | $0.04     | $0.16      | $1.92     |
| 1,000 | 1,000         | $0.39     | $1.56      | $18.72    |
| 10,000| 10,000        | $3.90     | $15.60     | $187.20   |
| 50,000| 50,000        | $19.50    | $78.00     | $936.00   |

**Cache hit rate impact:**
- Current: 1 generation per user per week
- If users check multiple times: Cache serves subsequent requests (FREE)
- Estimated cache hit rate: 80-90% (users check 2-3× per week)

### Recommendation: Reduce by 20%

**Current target:** 1500-2000 chars (250-300 words, ~400 tokens)
**New target:** 1200-1600 chars (200-240 words, ~320 tokens)

**Changes needed:**
1. Reduce max_tokens from 1200 → 960
2. Update system prompt constraint to "1200-1600 chars total"
3. Tighten paragraph structure (4 paragraphs instead of 5)

**New structure:**
- Para 1: Week overview + key pattern
- Para 2: Training load + fitness trajectory
- Para 3: Wellness foundation + limiting factors
- Para 4: Strategic guidance for next week

**Cost savings:** ~20% reduction in output tokens = ~$0.00005 per request
**At scale (50k users):** $936/year → $750/year = **$186 saved**

---

## 2. Fitness Trajectory - NO DATA

**Issue:** Section shows "No data available"

**Investigation needed:**
- Check if CTL/ATL/TSB data is being calculated
- Verify data is being passed to the view
- Check date range for historical data

---

## 3. Wellness Foundation - NEEDS MORE

**Current:** Likely minimal or missing data

**Investigation needed:**
- Check what's currently displayed
- Add more wellness metrics (HRV trend, RHR trend, sleep consistency)
- Enhance visualization

---

## 4. Metric Label Styling Pattern

**New standard:** CAPS + GREY for all metric labels

**Examples:**
- "Total TSS" → "TOTAL TSS" (grey)
- "Training Time" → "TRAINING TIME" (grey)
- "Average Power" → "AVERAGE POWER" (grey)

**Implementation:**
```swift
Text("TOTAL TSS")
    .font(.caption)
    .foregroundColor(.text.secondary)
    .textCase(.uppercase)
```

**Apply to:**
- Training load summary chart
- Ride metadata (top of ride detail)
- All metric labels app-wide

---

## 5. Compact Ring Caps on Today

**Issue:** Caps don't work well
**Fix:** Revert to lowercase + white, increase size

**Current (broken):**
```swift
Text("OPTIMAL")
    .font(.caption2)
    .textCase(.uppercase)
```

**New (fixed):**
```swift
Text("optimal")
    .font(.caption)  // Increased from caption2
    .foregroundColor(.white)
    .textCase(.lowercase)
```

---

## 6. Ride Metadata Labels

**Apply caps + grey pattern:**
```swift
// Label
Text("AVERAGE POWER")
    .font(.caption)
    .foregroundColor(.text.secondary)
    .textCase(.uppercase)

// Value
Text("245 W")
    .font(.body)
    .fontWeight(.semibold)
    .foregroundColor(.text.primary)
```

---

## 7. AI Ride Summary Loading State

**Issue:** Different from daily brief/weekly report
**Fix:** Match the spinner + text pattern

**Current:** Just spinner
**New:** Spinner + "Analyzing your ride..."

---

## 8. Settings Audit

### 8a. Sleep Target Impact
**Question:** Does changing sleep target affect scoring?
**Investigation:** Check `SleepScoreService` for sleep target usage

### 8b. Data Sources
- **Remove:** Garmin (not implemented)
- **Ordering:** Clarify what it does and impact
- **User communication:** Explain priority/fallback behavior

### 8c. Adaptive Zones
- **Remove:** "PRO" badge (confusing)

### 8d. Display Preferences
**Check:**
- Do unit changes work?
- Do they trigger recalculations?
- Or just display formatting?

### 8e. Notifications
**Verify:** Does notification toggle actually work?
**Check:** Permission requests, notification scheduling

### 8f. iCloud Sync
**Verify:** Is it working correctly?

### 8g. Send Feedback
**Issue:** Doesn't attach logs
**Fix:** Attach logs as file (can be large)

### 8h. Profile Loading
**Issue:** Spinner for user info
**Fix:** 
- Debug loading delay
- Add user editing capability
- Add avatar from photo library

### 8i. Sign Out
**Clarify:** What account? Intervals.icu?
**Add:** Clear explanation in UI

---

## Priority Order

### High Priority (Do First):
1. ✅ Weekly report reduction (20%)
2. ✅ Metric label caps+grey pattern (app-wide)
3. ✅ Compact ring caps fix (Today)
4. ✅ AI ride summary loading state
5. ✅ Send feedback logs attachment

### Medium Priority:
6. Fitness trajectory data fix
7. Wellness foundation enhancement
8. Remove Garmin from data sources
9. Remove PRO badge from adaptive zones
10. Profile loading debug

### Low Priority (Investigate):
11. Sleep target impact verification
12. Data source ordering clarification
13. Display preferences verification
14. Notifications verification
15. iCloud sync verification
16. Sign out clarification

---

## Implementation Notes

### Caps + Grey Pattern
Create a reusable modifier:
```swift
extension View {
    func metricLabel() -> some View {
        self
            .font(.caption)
            .foregroundColor(.text.secondary)
            .textCase(.uppercase)
    }
}

// Usage:
Text("TOTAL TSS").metricLabel()
```

### Cost Monitoring
- Set up alerts at $10/month, $50/month, $100/month
- Monitor cache hit rates
- Consider adding rate limiting per user

### Caching Strategy
- Weekly report: 1 week (current) ✅
- Daily brief: 24 hours
- Ride summary: Permanent (per ride ID)
