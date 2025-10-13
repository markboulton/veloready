# Activity History Limits - Tier Recommendations

## Summary

**FREE Tier**: 30 days, 100 activities  
**PRO Tier**: 90 days, 300 activities

---

## Detailed Analysis

### FREE Tier: 30 Days

**Limits:**
- Days: 30
- Max activities: 100
- Typical activities: 30-60 (1-2 per day)

**Rationale:**
1. **ATL Calculation** ✅
   - Needs: 7 days
   - Have: 30 days
   - Result: Full accuracy

2. **CTL Calculation** ⚠️
   - Needs: 42 days (ideal)
   - Have: 30 days
   - Result: Reduced accuracy but acceptable
   - Impact: ~70% accuracy vs ideal

3. **TSB Calculation** ✅
   - Needs: CTL + ATL
   - Result: Works, slightly less accurate

4. **API Load** ✅
   - Intervals.icu: 100 activities
   - Strava: 100 activities
   - Result: Minimal load, fast

5. **Storage** ✅
   - ~30-60 activities
   - ~500KB-1MB
   - Result: Negligible

6. **User Value** ✅
   - Recent trends visible
   - Current form/readiness accurate
   - Last month's training visible

### PRO Tier: 90 Days

**Limits:**
- Days: 90
- Max activities: 300
- Typical activities: 90-180 (1-2 per day)

**Rationale:**
1. **CTL Calculation** ✅
   - Needs: 42 days
   - Have: 90 days
   - Result: Full accuracy + buffer for gaps

2. **ATL Calculation** ✅
   - Needs: 7 days
   - Have: 90 days
   - Result: Full accuracy

3. **TSB Calculation** ✅
   - Needs: CTL + ATL
   - Result: Maximum accuracy

4. **Seasonal Trends** ✅
   - 3-month view
   - Training block comparison
   - Fitness progression visible

5. **API Load** ✅
   - Intervals.icu: 300 activities
   - Strava: 300 activities
   - Result: Manageable, cached

6. **Storage** ✅
   - ~90-180 activities
   - ~1.5MB-3MB
   - Result: Still small

7. **User Value** ✅✅
   - Full training history
   - Accurate predictions
   - Historical comparisons
   - Worth the PRO upgrade

---

## Implementation

### Centralized Configuration

```swift
// In ProFeatureConfig.swift
var activityHistoryDays: Int {
    return hasProAccess ? 90 : 30
}

var activityFetchLimit: Int {
    return hasProAccess ? 300 : 100
}
```

### Usage

```swift
let config = ProFeatureConfig.shared
let activities = try await apiClient.fetchRecentActivities(
    limit: config.activityFetchLimit,
    daysBack: config.activityHistoryDays
)
```

---

## Alternative Considerations

### Why Not 60 Days for FREE?
- ❌ Only marginal CTL improvement
- ❌ 2x API load
- ❌ Less incentive for PRO upgrade
- ✅ 30 days is sufficient for basic needs

### Why Not 120 Days for PRO?
- ❌ Diminishing returns (CTL only needs 42)
- ❌ Increased API load
- ❌ More storage
- ✅ 90 days is optimal balance

### Why Not Unlimited for PRO?
- ❌ API rate limits
- ❌ Storage concerns
- ❌ Performance impact
- ❌ Most users don't need >90 days
- ✅ 90 days covers all use cases

---

## Competitive Analysis

| App | FREE | PRO |
|-----|------|-----|
| **VeloReady** | 30 days | 90 days |
| Strava | 30 days | Unlimited* |
| TrainingPeaks | 7 days | Unlimited |
| Intervals.icu | 30 days | Unlimited |
| Whoop | 30 days | Unlimited |

*Strava's "unlimited" is actually limited by API pagination

**Conclusion**: Our limits are competitive and appropriate.

---

## User Communication

### FREE Tier Message
> "Access your last 30 days of activities. Upgrade to PRO for 90-day history and advanced analytics."

### PRO Upgrade CTA
> "Unlock 90 days of activity history for more accurate fitness tracking and seasonal trend analysis."

### In-App Display
- Show "Last 30 days" badge on FREE
- Show "Last 90 days" badge on PRO
- Dim/disable activities beyond limit
- CTA to upgrade when scrolling past limit

---

## Monitoring & Optimization

### Metrics to Track
1. Average activities per user (FREE vs PRO)
2. API call frequency
3. Cache hit rates
4. User complaints about limits
5. Upgrade conversion from activity limits

### Future Adjustments
- If FREE users average <15 activities/month → Consider 45 days
- If PRO users rarely use >60 days → Consider 60 days
- If API costs spike → Reduce limits
- If storage becomes issue → Add compression

---

## Recommendation: APPROVED ✅

**FREE: 30 days, 100 activities**
**PRO: 90 days, 300 activities**

This provides:
- ✅ Sufficient data for core features (FREE)
- ✅ Excellent data for advanced features (PRO)
- ✅ Clear value proposition for PRO
- ✅ Manageable API and storage costs
- ✅ Competitive with market
- ✅ Room for future optimization
