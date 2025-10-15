# Sport Selection Revert - Product Decision

## Date: October 15, 2025

## Decision
**VeloReady is a cycling-specific app.** The sport selection feature and multi-sport AI personas have been removed to maintain product focus.

---

## What Was Removed

### iOS App Changes

**Onboarding Flow:**
- ❌ Removed Step 3: "Choose Your Sports" (sport ranking screen)
- ✅ Updated flow from 7 steps to 6 steps
- ✅ Default cycling preference set on completion
- ✅ Deleted `SportRankingStepView.swift`

**OnboardingManager:**
- ❌ Removed `selectedSports` array
- ❌ Removed `sportRankings` dictionary
- ❌ Removed `setSportRanking()` method
- ❌ Removed `saveSportPreferences()` method
- ❌ Removed `primarySport` computed property
- ✅ Added `setDefaultCyclingPreference()` method
- ✅ Updated step enum (removed `.sportRanking` case)

**AI Integration:**
- ❌ Removed `primarySport` field from `AIBriefRequest`
- ❌ Removed sport from debug logging
- ❌ Removed `userSettings` dependency from `AIBriefService`
- ✅ Requests no longer send sport parameter to backend

**Data Sources:**
- ✅ `DataSourcesStepView` always shows cycling integrations (Strava, Intervals, Wahoo)
- ✅ No longer conditional based on sport selection

### Backend Changes

**AI Brief Function:**
- ❌ Removed `PrimarySport` type definition
- ❌ Removed `STRENGTH_PROMPT` persona
- ❌ Removed `GENERAL_PROMPT` persona
- ❌ Removed `getSystemPrompt()` function
- ❌ Removed sport from cache key
- ✅ Restored single `SYSTEM_PROMPT` (cycling-focused)
- ✅ Updated prompt version to `coach-v5-cycling`
- ✅ Simplified `callOpenAI()` signature

---

## New Onboarding Flow (6 Steps)

1. **Value Prop** - Introduce VeloReady benefits
2. **What VeloReady Does** - Explain features (cycling-focused)
3. **Apple Health** - Request HealthKit permissions
4. **Connect Data Sources** - Strava, Intervals.icu, Wahoo
5. **Profile Setup** - Units preference
6. **Unlock Pro Features** - Subscription offer

---

## AI Coaching Behavior

**All users now receive:**
- 🚴 Cycling-focused coaching language
- 📊 Zone-based training recommendations (Z1-Z5)
- 💪 TSS and CTL/ATL guidance
- ⚡ FTP and power-based intervals
- 🍴 Cycling-specific fueling advice (g/h carbs)
- 😴 Recovery and sleep optimization for riders

**No longer provided:**
- ❌ Strength training advice (RPE, sets/reps)
- ❌ General wellness coaching (step counts)
- ❌ Multi-sport weighting

---

## Technical Details

### Cache Key Format Change

**Before:**
```
{userId}:{date}:{version}:{sport}:{data-status}
Example: abc123:2025-10-15:coach-v4-sport:cycling:full
```

**After:**
```
{userId}:{date}:{version}:{data-status}
Example: abc123:2025-10-15:coach-v5-cycling:full
```

**Impact:**
- ✅ Existing caches from `coach-v4-sport` will expire naturally
- ✅ New requests use simpler cache key
- ✅ No sport-specific cache pollution

### Request Payload Change

**Before:**
```json
{
  "recovery": 70,
  "sleepDelta": 0.5,
  "hrvDelta": 0.03,
  "rhrDelta": -0.01,
  "tsb": 4,
  "tssLow": 60,
  "tssHigh": 90,
  "plan": "Tempo",
  "primarySport": "cycling"
}
```

**After:**
```json
{
  "recovery": 70,
  "sleepDelta": 0.5,
  "hrvDelta": 0.03,
  "rhrDelta": -0.01,
  "tsb": 4,
  "tssLow": 60,
  "tssHigh": 90,
  "plan": "Tempo"
}
```

**Impact:**
- ✅ Simpler request structure
- ✅ Backend ignores unknown fields (forwards compatible)
- ✅ No breaking changes for existing clients

---

## Rationale

**Product Focus:**
- VeloReady is built for cyclists
- Cycling-specific integrations (Strava, Intervals.icu, Wahoo)
- Cycling-specific metrics (FTP, TSS, power zones)
- Cycling-specific coaching language

**Simplicity:**
- One clear target audience
- One AI persona to refine and improve
- Simpler onboarding flow (6 steps vs 7)
- Less code to maintain

**User Experience:**
- No confusion about app purpose
- Immediate clarity on value proposition
- All features optimized for cycling
- Consistent coaching voice

---

## What Remains

**Sport Preferences Infrastructure:**
- ✅ `SportPreferences` model still exists in codebase
- ✅ Always defaults to `cycling` with rank 1
- ✅ Can be used for future multi-sport expansion if needed
- ✅ Syncs via iCloud

**Why keep it?**
- Minimal code
- No user-facing complexity
- Future-proofs architecture
- Clean default behavior

---

## Git History

### iOS (VeloReady):
**1abedb4** - revert: Remove sport selection - VeloReady is cycling-specific

**Deletions:**
- `SportRankingStepView.swift` (224 lines)
- Sport-related methods in `OnboardingManager`
- `primarySport` from request model

**Changes:**
- 6 files modified
- 19 insertions, 224 deletions

### Backend (veloready-website):
**7cc5efd0** - revert: Remove sport personas - VeloReady is cycling-only

**Deletions:**
- Strength and general AI personas
- Sport type definitions
- Sport-aware prompt selection

**Changes:**
- 1 file modified
- 8 insertions, 55 deletions

---

## Testing Verification

### Onboarding Flow:
- [x] 6 steps complete successfully
- [x] No sport selection screen
- [x] Cycling preference set by default
- [x] Data sources show cycling integrations
- [x] Profile setup works
- [x] Subscription screen shows

### AI Coaching:
- [x] Daily Brief returns cycling-focused advice
- [x] No strength/general language
- [x] Zones, TSS, FTP mentioned
- [x] Cache key format correct
- [x] Prompt version updated

### Build Status:
- [x] iOS app builds successfully
- [x] Backend function deploys successfully
- [x] No compilation errors
- [x] All tests pass

---

## Future Considerations

**If Multi-Sport Returns:**

The infrastructure is in place to re-enable multi-sport support:

1. Re-add sport ranking screen to onboarding
2. Restore sport personas in backend
3. Add `primarySport` back to request model
4. Update cache key to include sport
5. Test each persona thoroughly

**Current State = Clean Rollback:**
- Code is clean and focused
- Easy to re-introduce if needed
- No technical debt created
- Product focus maintained

---

## Status: COMPLETE ✅

VeloReady is now a focused cycling app with:
- ✅ Streamlined 6-step onboarding
- ✅ Cycling-only AI coaching
- ✅ Clear product positioning
- ✅ Simplified codebase
- ✅ Better user experience

**Product decision validated through code.**
