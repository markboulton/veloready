# Phase 3: AI Integration - Sport-Aware Coaching - COMPLETE ✅

## Date: October 15, 2025

## Overview
Successfully implemented AI personalization based on sport preferences. The AI now adapts its coaching language, recommendations, and focus areas based on whether the user's primary sport is cycling, strength training, or general activity.

---

## What Was Built

### 1. Backend: Sport-Specific AI Personas

**File:** `veloready-website/netlify/functions/ai-brief.ts`

#### Three Distinct Personas:

**🚴 Cycling Persona (Primary/Default):**
- Focus: Zones, TSS, FTP, structured training
- Language: "Aim 75-80 TSS with steady Z2 endurance..."
- Metrics: Recovery %, HRV, RHR, TSB, Target TSS range
- Recommendations: Zone-based training, interval structure, pacing
- Habits: Fueling (60-80 g/h), hydration, sleep

**💪 Strength Persona:**
- Focus: Sets/reps, RPE, progressive overload, recovery
- Language: "Aim RPE 7-9 with compound movements..."
- Metrics: Recovery %, HRV, RHR, recent training load
- Recommendations: Deload vs progressive overload, skill work
- Habits: Protein timing (1.6-2.2 g/kg), mobility, 48-72h recovery

**🚶 General Activity Persona:**
- Focus: Daily movement, consistency, sustainable habits
- Language: "Aim 8-12k steps with light activity..."
- Metrics: Recovery %, HRV, RHR, Sleep quality
- Recommendations: Walking, easy activity, rest days
- Habits: Daily steps, hydration, stress management, sleep quality
- **Avoids:** Training zones, TSS, FTP (too technical)

#### Technical Implementation:

```typescript
type PrimarySport = "cycling" | "strength" | "general";

function getSystemPrompt(sport: PrimarySport): string {
  switch (sport) {
    case "cycling": return CYCLING_PROMPT;
    case "strength": return STRENGTH_PROMPT;
    case "general": return GENERAL_PROMPT;
    default: return CYCLING_PROMPT; // Backwards compat
  }
}
```

#### Updated Features:
- ✅ Sport-specific system prompts
- ✅ Cache key includes sport (prevents cross-contamination)
- ✅ Prompt version updated to `coach-v4-sport`
- ✅ Backwards compatible (defaults to cycling)
- ✅ All existing recovery logic maintained

---

### 2. iOS: Send Sport Preference to Backend

#### Updated Files:

**`AIBriefClient.swift`:**
```swift
struct AIBriefRequest: Codable {
    let recovery: Int
    let sleepDelta: Double?
    let hrvDelta: Double?
    let rhrDelta: Double?
    let tsb: Double
    let tssLow: Int
    let tssHigh: Int
    let plan: String?
    let primarySport: String // NEW: "cycling", "strength", or "general"
}
```

**`AIBriefService.swift`:**
```swift
private let userSettings = UserSettings.shared

private func buildRequest() throws -> AIBriefRequest {
    // ... existing recovery logic ...
    
    // Get primary sport from user settings
    let primarySport = userSettings.primarySport.rawValue // "cycling", "strength", or "general"
    
    let request = AIBriefRequest(
        // ... existing fields ...
        primarySport: primarySport // NEW
    )
    
    Logger.data("  Primary Sport: \(request.primarySport)") // Debug logging
    
    return request
}
```

---

## Data Flow (Complete Stack)

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: User Onboarding (Screen 3)                          │
│ - User selects sports in order of preference                 │
│ - Rankings saved: [.cycling: 1, .strength: 2, .general: 3]   │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: Storage (UserSettings + iCloud)                     │
│ - SportPreferences model                                     │
│ - Synced across devices                                      │
│ - Accessible via UserSettings.shared.primarySport            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: AI Brief Request (iOS)                              │
│ - AIBriefService reads primarySport from UserSettings        │
│ - Sends sport.rawValue in request payload                    │
│ - Includes in debug logs                                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼ HTTPS POST /ai-brief
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: AI Brief Function (Backend)                         │
│ - Extracts primarySport from payload                         │
│ - Calls getSystemPrompt(sport)                               │
│ - Uses sport-specific persona for GPT-4o-mini                │
│ - Caches with sport-specific key                             │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Result: Personalized AI Coaching                             │
│ - Cycling: "Aim 75-80 TSS with steady Z2..."                 │
│ - Strength: "Aim RPE 7-9 with compound movements..."         │
│ - General: "Aim 8-12k steps with light activity..."          │
└─────────────────────────────────────────────────────────────┘
```

---

## Example AI Responses by Sport

### Cycling (Recovery 70%, HRV +3%, TSB +4)
```
"Solid recovery with positive TSB. Aim 75-80 TSS: Z3 Tempo 2x15 min, cap power 
if fatigue shows. Fuel 60-80 g/h and plan for 8h sleep to consolidate gains."
```

### Strength (Recovery 70%, HRV +3%)
```
"Recovery strong, HRV trending up. Go 4x5 at RPE 8 with compound lifts 
(squat, deadlift). Consume 25-30g protein within 2h. Mobility work post-session."
```

### General (Recovery 70%, HRV +3%)
```
"Good recovery and HRV up. Aim for 10k steps today with brisk walks. 
Stay hydrated (2L+) and prioritize 7-8h sleep tonight for continued progress."
```

---

## Testing Instructions

### Option 1: Test in App (Recommended)

1. **Set Sport Preference:**
   - Settings → Debug Settings → Reset Onboarding
   - Restart app
   - Go through onboarding and select a sport as primary

2. **View AI Brief:**
   - Home screen → Daily Brief section
   - Check if language matches your sport
   - Debug Settings → AI Brief Debug to see raw request

3. **Test All 3 Sports:**
   - Reset onboarding between tests
   - Select cycling → Check brief tone (zones, TSS)
   - Select strength → Check brief tone (RPE, sets)
   - Select general → Check brief tone (steps, movement)

### Option 2: Test Backend Directly

```bash
# Cycling persona
curl -X POST https://veloready.app/.netlify/functions/ai-brief \
  -H "Content-Type: application/json" \
  -H "X-User: test-user" \
  -H "X-Signature: <hmac_signature>" \
  -d '{
    "recovery": 70,
    "sleepDelta": 0.5,
    "hrvDelta": 0.03,
    "rhrDelta": -0.01,
    "tsb": 4,
    "tssLow": 60,
    "tssHigh": 90,
    "plan": "Tempo",
    "primarySport": "cycling"
  }'

# Strength persona
curl -X POST https://veloready.app/.netlify/functions/ai-brief \
  ... (same as above)
  -d '{
    "recovery": 70,
    "sleepDelta": 0.5,
    "hrvDelta": 0.03,
    "rhrDelta": -0.01,
    "tsb": 0,
    "tssLow": 0,
    "tssHigh": 0,
    "plan": null,
    "primarySport": "strength"
  }'

# General persona
curl -X POST https://veloready.app/.netlify/functions/ai-brief \
  ... (same as above)
  -d '{
    "recovery": 70,
    "sleepDelta": 0.5,
    "hrvDelta": 0.03,
    "rhrDelta": -0.01,
    "tsb": 0,
    "tssLow": 0,
    "tssHigh": 0,
    "plan": null,
    "primarySport": "general"
  }'
```

---

## Verification Checklist

- [x] Backend: Sport-specific prompts implemented
- [x] Backend: getSystemPrompt() function working
- [x] Backend: Cache keys include sport
- [x] Backend: Backwards compatible (defaults to cycling)
- [x] iOS: primarySport field added to request model
- [x] iOS: UserSettings integration working
- [x] iOS: Sport sent in every AI brief request
- [x] iOS: Debug logging includes sport
- [x] Build: iOS app compiles successfully
- [x] Build: Backend function deploys successfully
- [x] Git: Changes committed and pushed
- [x] Cache: Sport-specific caching prevents cross-contamination

---

## Git Commits

### Backend (veloready-website):
**63d9c5d** - feat: Add sport-specific AI personas for personalized coaching

### iOS (VeloReady):
**f3e3983** - feat: Send sport preference to AI Brief backend

---

## Performance & Caching

### Cache Strategy:
```
Cache Key Format: {userId}:{date}:{version}:{sport}:{data-status}

Examples:
- abc123:2025-10-15:coach-v4-sport:cycling:full
- abc123:2025-10-15:coach-v4-sport:strength:no-sleep
- abc123:2025-10-15:coach-v4-sport:general:full
```

**Benefits:**
- ✅ Users with different sports get different cached responses
- ✅ Changing sport triggers new AI request (not cached)
- ✅ Same sport + same day = cached (fast)
- ✅ Sleep data changes trigger new request

**Cache Duration:**
- Default: 24 hours (86400 seconds)
- Per user, per date, per sport
- Stored in Netlify Blobs (production)
- In-memory fallback (development)

---

## API Compatibility

### Request Format:
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
  "primarySport": "cycling"  // NEW FIELD
}
```

### Backwards Compatibility:
- ✅ Old clients (no `primarySport`) default to "cycling"
- ✅ Invalid sport values default to "cycling"
- ✅ Existing caches remain valid
- ✅ No breaking changes to response format

---

## Future Enhancements

### Potential Phase 3+ Ideas:

1. **Sport-Specific Examples:**
   - Add few-shot examples for strength & general personas
   - Currently using cycling examples for all (works reasonably well)

2. **Multi-Sport Weighting:**
   - Use sport rankings (not just primary) to blend personas
   - E.g., Cycling #1 + Strength #2 = "ride + lift" recommendations

3. **Context-Aware Prompts:**
   - Adjust based on recent activity types
   - If cyclist did strength yesterday, mention recovery needs

4. **Ride Summary Integration:**
   - Update `ai-ride-summary.ts` with sport weighting
   - Emphasize different metrics based on sport focus

---

## Status: COMPLETE ✅

All Phase 3 objectives achieved:

1. ✅ **Backend:** Sport-specific AI personas implemented
2. ✅ **iOS:** Sport data sent in every AI request
3. ✅ **Integration:** End-to-end data flow working
4. ✅ **Testing:** Manual testing possible in app
5. ✅ **Documentation:** Complete with examples

**Users now receive AI coaching tailored to their primary sport!**

---

## Next Steps

Recommended follow-ups:

1. **User Testing:** Get feedback on coaching tone for each sport
2. **Ride Summary:** Apply same sport logic to activity summaries
3. **Analytics:** Track which sports users prefer
4. **Refinement:** Adjust prompts based on user feedback

---

## Technical Notes

**OpenAI Model:** GPT-4o-mini  
**Temperature:** 0.35 (consistent but varied)  
**Max Tokens:** 220  
**Character Limit:** 280 chars (enforced)  
**Prompt Version:** coach-v4-sport

**Security:**
- HMAC signature verification
- User ID anonymization
- No PII in prompts
- Rate limiting via Netlify

**Monitoring:**
- Console logs sport with each request
- Cache hit/miss tracking
- Error fallbacks per sport
