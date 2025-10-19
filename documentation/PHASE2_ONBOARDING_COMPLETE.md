# Phase 2: Onboarding Flow Redesign - COMPLETE ✅

## Date: October 15, 2025

## Overview
Successfully redesigned the onboarding flow with 7 new screens, including the critical Sport Ranking step that enables AI personalization based on user's primary sport.

---

## What Was Built

### 1. Updated OnboardingManager
**File:** `VeloReady/Features/Onboarding/OnboardingManager.swift`

**New Flow Steps:**
1. **valueProp** - Welcome and key benefits
2. **whatVeloReady** - Core functionality explanation
3. **sportRanking** - Sport preference selection (CRITICAL)
4. **healthKit** - Apple Health integration
5. **dataSources** - Platform connections (conditional)
6. **profile** - Units, name, avatar
7. **subscription** - Pro features

**New Functionality:**
- `selectedSports` - Array tracking user's sport selections
- `sportRankings` - Dictionary mapping sports to ranks (1-3)
- `setSportRanking()` - Update sport ranking
- `saveSportPreferences()` - Persist to UserSettings
- `primarySport` - Quick access to rank 1 sport

### 2. New Onboarding Screens

#### Screen 1: ValuePropStepView
**File:** `VeloReady/Features/Onboarding/Views/ValuePropStepView.swift`

- Welcome screen with 5 key benefits
- Icon-based benefit cards
- Simple, clean design
- Benefits highlighted:
  - Track Your Progress
  - AI-Powered Insights
  - Multi-Sport Support
  - Smart Recovery
  - Training Load Balance

#### Screen 2: WhatVeloReadyStepView
**File:** `VeloReady/Features/Onboarding/Views/WhatVeloReadyStepView.swift`

- Explains 4 core areas
- Color-coded feature cards:
  - 🚴 **Riding First** (Blue)
  - 🧠 **Intelligence Layer** (Purple)
  - ❤️ **General Health** (Red)
  - 🛏️ **Recovery Focus** (Green)

#### Screen 3: SportRankingStepView ⭐ CRITICAL
**File:** `VeloReady/Features/Onboarding/Views/SportRankingStepView.swift`

**This is the KEY screen for AI personalization**

- Interactive sport selection
- Three sports available:
  - 🚴 Cycling
  - 💪 Strength Training
  - 🚶 General Activity
- Visual ranking badges (1, 2, 3)
- Selected cards highlight in blue
- Must select at least one sport
- Saves to `UserSettings.sportPreferences`

**How It Works:**
1. User taps sport card to select
2. Card shows rank badge in selection order
3. Rankings automatically update
4. Saved to UserSettings on continue
5. Used by AI to personalize coaching

#### Screen 4: HealthKitStepView
**File:** `VeloReady/Features/Onboarding/Views/HealthKitStepView.swift`

- Existing view (no changes)
- Requests Apple Health permissions

#### Screen 5: DataSourcesStepView (Updated)
**File:** `VeloReady/Features/Onboarding/Views/DataSourcesStepView.swift`

**Sport-Aware Behavior:**

If **Cycling** is primary sport:
- Shows 3 integration options:
  1. Strava (top)
  2. Intervals.icu (middle)
  3. Wahoo (bottom) - Coming soon
- All optional

If **Strength** or **General** is primary:
- Shows success message
- Explains Apple Health will be used
- No cycling integrations shown

#### Screen 6: ProfileSetupStepView
**File:** `VeloReady/Features/Onboarding/Views/ProfileSetupStepView.swift`

- Unit selection (Metric/Imperial)
- Optional name input
- Avatar picker (6 options)
- Saves to UserDefaults and UserSettings

#### Screen 7: SubscriptionStepView
**File:** `VeloReady/Features/Onboarding/Views/SubscriptionStepView.swift`

- Existing view (no changes)
- Pro features upsell

### 3. Updated OnboardingFlowView
**File:** `VeloReady/Features/Onboarding/Views/OnboardingFlowView.swift`

- Updated switch statement for new flow
- All 7 screens wired up
- Maintains existing transitions

---

## Data Flow

```
User selects sports (Screen 3)
        ↓
OnboardingManager.sportRankings
        ↓
OnboardingManager.saveSportPreferences()
        ↓
UserSettings.shared.sportPreferences
        ↓
SportPreferences struct (from Phase 1)
        ↓
UserDefaults + iCloud sync
```

---

## Sport Ranking Impact

The sport ranking affects:

### Immediate Effects:
- **Screen 5 (DataSources)**: Shows cycling integrations only if cycling is primary

### Future Effects (Phase 3):
- **AI Daily Brief**: Coaching language adapts to primary sport
- **AI Ride Summary**: Metrics emphasis changes by sport
- **Recovery Recommendations**: Sport-specific guidance

---

## Testing Instructions

### Option 1: Reset Onboarding
1. Open app
2. Go to **Settings → Debug Settings**
3. Scroll to bottom
4. Tap **Reset Onboarding**
5. Restart app
6. Go through new 7-step flow

### Option 2: Test Individual Screens
All screens available as standalone views in Xcode previews

### Test Cases:
1. **Test Cycling Primary**: 
   - Select Cycling as #1
   - Verify Screen 5 shows Strava/Intervals/Wahoo
   
2. **Test Strength Primary**:
   - Select Strength as #1
   - Verify Screen 5 shows "You're all set" message
   
3. **Test General Primary**:
   - Select General Activity as #1
   - Verify Screen 5 shows Apple Health message
   
4. **Test Multiple Sports**:
   - Select all 3 sports
   - Verify ranks update correctly
   - Verify primary sport detection works

---

## Design Decisions

### Why This Flow?

**Screen Order Rationale:**
1. **Welcome** - Set expectations
2. **What We Do** - Build understanding
3. **Sport Ranking** - **Critical data capture for AI**
4. **Apple Health** - Essential permissions
5. **Platform Integration** - Optional, sport-aware
6. **Profile** - Personalization
7. **Pro Features** - Monetization

**Sport Ranking First:**
- Must know sport preference before showing integrations
- Early capture ensures AI has data from day one
- Users understand app adapts to their needs

**Conditional Data Sources:**
- Reduces cognitive load for non-cyclists
- Shows only relevant integrations
- Improves completion rate

### Design Patterns Used:
- Card-based layouts for scanability
- Color-coded categories for distinction
- Visual feedback (badges, highlights)
- Progressive disclosure
- Optional steps clearly marked

---

## Verification Checklist

- [x] OnboardingManager updated with new flow
- [x] Sport ranking tracking implemented
- [x] Screen 1: ValuePropStepView created
- [x] Screen 2: WhatVeloReadyStepView created
- [x] Screen 3: SportRankingStepView created (CRITICAL)
- [x] Screen 4: HealthKitStepView (no changes needed)
- [x] Screen 5: DataSourcesStepView made sport-aware
- [x] Screen 6: ProfileSetupStepView created
- [x] Screen 7: SubscriptionStepView (no changes needed)
- [x] OnboardingFlowView wired up
- [x] Build succeeds
- [x] Changes committed to git
- [x] Sport data saves to UserSettings
- [x] iCloud sync compatible

---

## Git Commits

1. **2737034** - feat: Update OnboardingManager for new 7-step flow
2. **c15c094** - feat: Create ValuePropStepView - Screen 1
3. **9230eea** - feat: Create WhatVeloReadyStepView - Screen 2
4. **96e0f56** - feat: Create SportRankingStepView - Screen 3 (CRITICAL)
5. **e3d6c89** - feat: Create ProfileSetupStepView - Screen 6
6. **a7be543** - feat: Make DataSourcesStepView sport-aware - Screen 5
7. **0c701a8** - feat: Update OnboardingFlowView to use new step views

---

## Next Steps (Phase 3)

1. Update AI Brief function in `veloready-website/netlify/functions/ai-brief.ts`
2. Update AI Ride Summary function in `veloready-website/netlify/functions/ai-ride-summary.ts`
3. Update `AIBriefService.swift` to send sport data
4. Update `AIBriefClient.swift` request models
5. Test all 3 sport profiles for AI responses

---

## API Ready for Phase 3

The onboarding now captures and saves:
```swift
// Access from anywhere in app
let primarySport = UserSettings.shared.primarySport
// .cycling, .strength, or .general

// Full rankings
let rankings = UserSettings.shared.sportPreferences.rankings
// [.cycling: 1, .strength: 2, .general: 3]
```

This data will be sent to backend AI functions in Phase 3.

---

## Status: READY FOR PHASE 3 ✅

All Phase 2 objectives completed. New onboarding flow is live and capturing sport preferences. Ready to implement AI personalization.
