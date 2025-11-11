# Stress Score: UI/UX Strategy & North Star Analysis

**Date:** November 11, 2025  
**Question:** Should stress be a primary metric (4th ring) or supporting/contextual metric?

---

## TL;DR: Recommendation

**Stress should be a CONTEXTUAL/SUPPORTING metric, NOT a 4th equal ring** 🎯

**Why:**
1. Recovery already captures stress signals (HRV, RHR, sleep)
2. Athletes care about "Can I train?" (Recovery) and "How hard did I train?" (Strain) - stress is a diagnostic tool
3. 4 equal rings creates visual overload
4. Stress is slow-moving (better as trend/detail view)

**Proposed UI:** Integrated stress indicator + detail view, not a 4th primary circle

---

## North Star Metric Analysis

### What Makes a Good North Star Metric?

A north star metric should be:
1. ✅ **Actionable** - User can do something about it today
2. ✅ **Immediate** - Answers "what should I do right now?"
3. ✅ **Universal** - Every user checks it every day
4. ✅ **Predictive** - Leads to desired outcome (performance, health)
5. ✅ **Simple** - Single number, easy to interpret

### Evaluating Our Metrics

| Metric | Actionable? | Immediate? | Universal? | Predictive? | Simple? | **North Star?** |
|--------|-------------|------------|------------|-------------|---------|-----------------|
| **Recovery** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | **✅ PRIMARY** |
| **Sleep** | ⚠️ Retrospective | ❌ No (last night) | ✅ Yes | ✅ Yes | ✅ Yes | **✅ PRIMARY** |
| **Strain** | ⚠️ Retrospective | ❌ No (today's effort) | ✅ Yes | ✅ Yes | ✅ Yes | **✅ PRIMARY** |
| **Stress (Acute)** | ⚠️ Overlaps Recovery | ⚠️ Duplicates Recovery | ⚠️ Not all athletes | ⚠️ Yes | ✅ Yes | **❌ SUPPORTING** |
| **Stress (Chronic)** | ⚠️ Long-term only | ❌ No (weekly) | ⚠️ Advanced users | ✅ Yes | ⚠️ Complex | **❌ SUPPORTING** |

### Analysis: Why Stress is NOT a North Star

**1. Redundancy with Recovery**
```
Recovery Score already includes:
- HRV (stress signal)
- RHR (stress signal)
- Sleep quality (stress signal)
- Respiratory rate (stress signal)

Acute Stress Score includes:
- HRV deviation (same)
- RHR deviation (same)
- Sleep quality (same)
- Respiratory deviation (same)

Overlap: ~70-80%
```

**2. User Mental Model**

Athletes ask themselves:
- 🟢 "Am I recovered?" → **Recovery Score**
- 🟢 "Did I sleep well?" → **Sleep Score**
- 🟢 "How hard did I train?" → **Strain Score**
- 🟡 "Am I stressed?" → **Diagnostic question, not daily decision**

Stress is a *why* question, not a *what* question:
- "Why is my recovery low?" → Check stress
- "Why can't I sleep?" → Check stress
- "Why does this feel so hard?" → Check stress

**3. Actionability Gap**

| Scenario | Primary Metrics | Stress Adds Value? |
|----------|----------------|-------------------|
| Morning: "Should I train hard today?" | Recovery: 45 (Fair) | ❌ No - Recovery already tells you to go easy |
| Evening: "Did I overtrain today?" | Strain: 16.5 (Very Hard) | ❌ No - Strain already tells you it was hard |
| Weekly: "Am I overreaching?" | Recovery trending down 3 days | ✅ YES - Chronic stress shows WHY |

**Conclusion:** Stress is a diagnostic/explanatory tool, not a decision-making metric.

---

## UI/UX Design Options

### Current State: 3 Equal Rings

```
┌──────────────────────────────────────┐
│                                      │
│   ◯         ◯         ◯              │
│  Recovery   Sleep    Strain          │
│   72         85        12.8          │
│  (Fair)    (Good)    (Hard)          │
│                                      │
└──────────────────────────────────────┘
```

**Pros:**
- ✅ Visually balanced
- ✅ Clear hierarchy (3 equal = 3 important)
- ✅ Familiar pattern (Whoop has 3: Recovery, Sleep, Strain)
- ✅ Fits well on phone screen

**Cons:**
- ❌ No room for 4th ring without redesign
- ❌ 4 rings = visual clutter

---

## Option 1: 4th Equal Ring (NOT RECOMMENDED ❌)

### Layout: 2x2 Grid

```
┌──────────────────────────────────────┐
│                                      │
│     ◯            ◯                   │
│   Recovery      Sleep                │
│     72           85                  │
│                                      │
│     ◯            ◯                   │
│   Strain       Stress                │
│    12.8          68                  │
│                                      │
└──────────────────────────────────────┘
```

**Problems:**
1. ❌ Breaks horizontal visual flow
2. ❌ Takes 2x vertical space
3. ❌ No natural grouping (which goes with which?)
4. ❌ Stress looks as important as Recovery (it's not)

### Layout: 4 in a Row

```
┌──────────────────────────────────────────────┐
│                                              │
│   ◯      ◯       ◯       ◯                  │
│  Recov  Sleep  Strain  Stress               │
│   72     85     12.8     68                  │
│                                              │
└──────────────────────────────────────────────┘
```

**Problems:**
1. ❌ Cramped on phone (rings too small)
2. ❌ Requires horizontal scrolling on small phones
3. ❌ All metrics look equally important (they're not)
4. ❌ "Flat" information hierarchy

**Verdict:** Don't add a 4th equal ring. It breaks the UI and gives stress too much prominence.

---

## Option 2: Integrated Stress Indicator (RECOMMENDED ✅)

### Design: Stress as Context, Not Primary Metric

**Concept:** Show stress *when it matters*, not always.

#### 2A: Conditional Stress Banner

Show stress indicator ONLY when it's elevated:

```
┌──────────────────────────────────────┐
│                                      │
│  ⚠️  Elevated Stress Detected        │
│  Your chronic stress has been high   │
│  for 2 weeks. Consider recovery week.│
│                            [Details →]│
│                                      │
│   ◯         ◯         ◯              │
│  Recovery   Sleep    Strain          │
│   72         85        12.8          │
│  (Fair)    (Good)    (Hard)          │
│                                      │
└──────────────────────────────────────┘
```

**When to show:**
- Chronic Stress > 60 for 2+ weeks
- Acute Stress > 70 for 3+ days
- Stress increasing trend (↗) for 5+ days

**Pros:**
- ✅ Only shows when actionable
- ✅ Doesn't clutter UI when stress is normal
- ✅ Clear call-to-action
- ✅ Preserves 3-ring visual balance

**Cons:**
- ⚠️ Hidden metric (not always visible)
- ⚠️ Users might miss it

#### 2B: Subtle Stress Indicator on Recovery Ring

Embed stress signal directly into Recovery ring:

```
┌──────────────────────────────────────┐
│                                      │
│   ◯ 📊        ◯         ◯            │
│  Recovery    Sleep    Strain         │
│   72          85        12.8         │
│  (Fair)     (Good)    (Hard)         │
│  ⚠️ Stress                           │
│                                      │
└──────────────────────────────────────┘
```

Small indicator on Recovery ring when stress is elevated:
- 📊 = Stress trend icon (only shows when relevant)
- Tapping Recovery → shows full breakdown including stress

**Pros:**
- ✅ Stress logically belongs with Recovery
- ✅ Doesn't disrupt visual layout
- ✅ Discoverable but not intrusive
- ✅ Educates users (stress = part of recovery)

**Cons:**
- ⚠️ Requires user to explore
- ⚠️ Might be overlooked

#### 2C: Stress as 4th Section (Below Rings)

Keep 3 rings, add stress as separate card below:

```
┌──────────────────────────────────────┐
│                                      │
│   ◯         ◯         ◯              │
│  Recovery   Sleep    Strain          │
│   72         85        12.8          │
│  (Fair)    (Good)    (Hard)          │
│                                      │
├──────────────────────────────────────┤
│  📊 STRESS OVERVIEW                  │
│                                      │
│  Acute:    68 🟠  (Elevated)         │
│  Chronic:  72 🟠  (Elevated, ↗)      │
│                                      │
│  Main Contributor: Training Load     │
│                         [See More →] │
└──────────────────────────────────────┘
```

**Pros:**
- ✅ Clear hierarchy (rings = primary, stress = secondary)
- ✅ Dedicated space for stress details
- ✅ Can show both acute + chronic
- ✅ Doesn't disrupt 3-ring layout

**Cons:**
- ⚠️ Adds vertical scroll (longer page)
- ⚠️ Might get buried below fold

---

## Option 3: Stress Detail View Only (LEAN APPROACH ✅)

### Design: No Primary UI, Deep-Dive Only

**Today View:**
```
┌──────────────────────────────────────┐
│                                      │
│   ◯         ◯         ◯              │
│  Recovery   Sleep    Strain          │
│   72         85        12.8          │
│  (Fair)    (Good)    (Hard)          │
│  ⚠️ Why is my recovery low? →        │
│                                      │
└──────────────────────────────────────┘
```

Tapping "Why is my recovery low?" opens **Recovery Detail View** which includes stress analysis:

**Recovery Detail View:**
```
┌──────────────────────────────────────┐
│  ← Recovery Details                  │
├──────────────────────────────────────┤
│  Today's Score: 72 (Fair)            │
│                                      │
│  BREAKDOWN                           │
│  • HRV:         85/100  ✅           │
│  • RHR:         75/100  ⚠️           │
│  • Sleep:       85/100  ✅           │
│  • Form:        55/100  ⚠️           │
│  • Respiratory: 80/100  ✅           │
│                                      │
│  STRESS ANALYSIS                     │
│  • Acute Stress:   68 (Elevated) 🟠  │
│  • Chronic Stress: 72 (Elevated) 🟠  │
│                                      │
│  📊 7-Day Trend                      │
│  █ █ ██ ██ ███ ███ ███              │
│                                      │
│  WHY YOUR RECOVERY IS LOW            │
│  Your elevated RHR (+12%) and low    │
│  form score suggest accumulated      │
│  training stress. Your chronic stress│
│  has been elevated for 2 weeks.      │
│                                      │
│  RECOMMENDATION                      │
│  Schedule a recovery week with 50%   │
│  volume reduction.                   │
│                         [Learn More] │
└──────────────────────────────────────┘
```

**Pros:**
- ✅ Preserves clean 3-ring layout
- ✅ Stress is contextual (explains low recovery)
- ✅ Educates users (stress → recovery connection)
- ✅ No UI redesign needed

**Cons:**
- ⚠️ Hidden by default
- ⚠️ Power users might miss it

---

## Recommended Solution: Hybrid Approach

Combine **Option 2A** (conditional banner) + **Option 3** (detail view)

### Implementation

**Default State (Stress Normal):**
```
┌──────────────────────────────────────┐
│  TODAY                               │
│                                      │
│   ◯         ◯         ◯              │
│  Recovery   Sleep    Strain          │
│   85         92        8.5           │
│  (Good)   (Optimal)  (Moderate)      │
│                                      │
│  [Latest Activity Card]              │
│  [Sleep Card]                        │
│  [AI Brief]                          │
│                                      │
└──────────────────────────────────────┘
```

**Elevated Stress State:**
```
┌──────────────────────────────────────┐
│  TODAY                               │
│                                      │
│  ⚠️  High Training Stress            │
│  Your body is showing signs of       │
│  accumulated stress. Recovery week   │
│  recommended.          [Details →]   │
│                                      │
│   ◯         ◯         ◯              │
│  Recovery   Sleep    Strain          │
│   65         78        15.2          │
│  (Fair)    (Good)   (Very Hard)      │
│                                      │
└──────────────────────────────────────┘
```

**Tapping "Details" or Recovery Ring:**
```
┌──────────────────────────────────────┐
│  ← Stress Analysis                   │
├──────────────────────────────────────┤
│  CURRENT STATE                       │
│                                      │
│  Acute Stress:    72 🟠              │
│  Chronic Stress:  78 🟠              │
│  Trend: ↗ Increasing                 │
│                                      │
│  📊 30-DAY TREND                     │
│  ████████████████████████████        │
│  Low        Moderate        High     │
│                      ↑ You are here  │
│                                      │
│  CONTRIBUTORS                        │
│  • Training Load:    High (28 pts)   │
│    ATL/CTL = 1.3 (overreaching)      │
│                                      │
│  • Sleep Quality:    Fair (15 pts)   │
│    4 wake events, 6.5h sleep         │
│                                      │
│  • HRV:              Low (12 pts)    │
│    18% below baseline                │
│                                      │
│  • Temperature:      Elevated (8 pts)│
│    0.6°C above baseline              │
│                                      │
│  WHAT THIS MEANS                     │
│  You've completed a 3-week build     │
│  phase with high training volume.    │
│  Your body is showing normal signs   │
│  of accumulated training stress.     │
│                                      │
│  RECOMMENDATION                      │
│  ✅ Implement recovery week NOW      │
│  • Reduce volume by 50%              │
│  • Keep intensity at Z2 only         │
│  • Prioritize 8+ hours sleep         │
│  • Monitor HRV for recovery signs    │
│                                      │
│  Expected Recovery: 7-10 days        │
│                         [Got it]     │
└──────────────────────────────────────┘
```

---

## Information Architecture

### Primary Navigation: Today View

```
TODAY VIEW
├── Status Banner (conditional)
│   └── Stress Alert (only if chronic > 60 OR acute > 70)
├── 3 Primary Rings (ALWAYS)
│   ├── Recovery → Detail View → Includes stress analysis
│   ├── Sleep → Detail View
│   └── Strain → Detail View
├── Latest Activity Card
├── Sleep Card
├── Health Warnings (wellness/illness)
└── AI Brief
```

### Secondary Navigation: Trends View

```
TRENDS VIEW (NEW SECTION)
├── Recovery Trends (existing)
├── Sleep Trends (existing)
├── Strain Trends (existing)
└── Stress Trends (NEW)
    ├── 7-day acute stress chart
    ├── 30-day chronic stress chart
    ├── Stress heatmap calendar
    └── Correlation analysis
        ├── Stress vs Training Load
        ├── Stress vs Sleep Quality
        └── Stress vs Performance
```

---

## Visual Design Mockup

### Stress Alert Banner (Elevated State)

```
┌──────────────────────────────────────────────────────────┐
│  ⚠️  Training Stress Elevated                            │
│  ────────────────────────────────────────────────────    │
│                                                          │
│  Your chronic stress has been high for 2 weeks.         │
│  Consider scheduling a recovery week.                    │
│                                                          │
│  Acute: 72 🟠    Chronic: 78 🟠    Trend: ↗             │
│                                                          │
│                                      [Learn More →]      │
└──────────────────────────────────────────────────────────┘
```

**Color Coding:**
- 🟢 0-35: Green background (low stress)
- 🟡 36-60: Yellow background (moderate stress)
- 🟠 61-80: Orange background (elevated stress)
- 🔴 81-100: Red background (high stress)

**Dismissible:** Yes, but reappears daily while stress elevated

---

## Development Roadmap (Revised for UI)

### Phase 1: MVP - Detail View Only (2 weeks)

**Week 1: Backend**
- [ ] Implement acute stress calculation
- [ ] Implement chronic stress calculation  
- [ ] Add temperature baseline tracking
- [ ] Unit tests

**Week 2: UI**
- [ ] Add stress section to Recovery Detail View
- [ ] Add 7-day stress trend chart
- [ ] Add stress breakdown (contributors)
- [ ] Add stress-based recommendations

**Deliverable:** Stress analysis available in Recovery Detail View

---

### Phase 2: Proactive Alerts (2 weeks)

**Week 3: Alert Logic**
- [ ] Implement stress threshold detection
- [ ] Create conditional banner component
- [ ] Add banner dismissal logic
- [ ] Add banner reappearance logic

**Week 4: UI Polish**
- [ ] Design stress alert banner
- [ ] Add color-coded severity
- [ ] Add inline trend sparkline
- [ ] Add deep link to detail view

**Deliverable:** Proactive stress alerts on Today View

---

### Phase 3: Trends View (1 week)

**Week 5: Trends UI**
- [ ] Add "Stress" tab to Trends View
- [ ] 30-day stress chart (line + heatmap)
- [ ] Correlation analysis charts
- [ ] Export stress data (CSV)

**Deliverable:** Complete stress monitoring system

---

## User Education Strategy

### Onboarding: "What is Stress Score?"

Show on first app launch (after existing onboarding):

```
┌──────────────────────────────────────┐
│  📊 New: Stress Monitoring           │
├──────────────────────────────────────┤
│                                      │
│  VeloReady now tracks your stress    │
│  levels using data you're already    │
│  providing:                          │
│                                      │
│  • Heart rate variability (HRV)      │
│  • Resting heart rate (RHR)          │
│  • Sleep quality                     │
│  • Training load (ATL/CTL)           │
│  • Body temperature                  │
│                                      │
│  We'll alert you when your stress    │
│  is elevated and recommend specific  │
│  actions to prevent overtraining.    │
│                                      │
│  You'll find stress analysis in:     │
│  Recovery Details → Stress Analysis  │
│                                      │
│                        [Got it]      │
└──────────────────────────────────────┘
```

### In-App Tooltips

**Recovery Ring:**
```
ⓘ Tap for detailed breakdown including stress analysis
```

**Stress Alert Banner:**
```
ⓘ Chronic stress has been elevated for 2 weeks. 
  This is normal after a training block. 
  Schedule a recovery week to allow adaptation.
```

---

## A/B Testing Plan

Test 3 UI variations with users:

### Variant A: No Stress UI (Control)
- Current 3-ring layout
- No stress tracking visible

### Variant B: Conditional Banner
- 3-ring layout
- Stress banner when elevated (Option 2A)

### Variant C: Always-Visible Stress Card
- 3-ring layout  
- Stress card always below rings (Option 2C)

**Metrics to Track:**
1. User engagement (daily active users)
2. Detail view opens (% users exploring stress)
3. Training plan adjustments (% users acting on stress alerts)
4. User feedback (surveys)

**Hypothesis:** Variant B (conditional banner) will have highest engagement without overwhelming users.

**Duration:** 4 weeks per variant (12 weeks total)

---

## Competitive Positioning

### vs Whoop

**Whoop:**
- 3 primary metrics (Recovery, Sleep, Strain)
- No explicit stress metric
- Recovery Score includes stress signals implicitly

**VeloReady:**
- Same 3 primary metrics
- Stress as diagnostic tool (explains WHY recovery is low)
- More transparent ("Here's why you feel this way")

**Positioning:** "We don't just tell you you're not recovered—we tell you WHY and WHAT TO DO."

### vs Oura

**Oura:**
- 4 equal metrics (Readiness, Sleep, Activity, **Stress**)
- Stress as primary north star
- Weekly updates only

**VeloReady:**
- 3 primary metrics + contextual stress
- Stress when it matters (not always)
- Daily updates with training context

**Positioning:** "Stress tracking built for athletes, not general wellness."

---

## Conclusion: The Answer

### Should Stress Be a 4th Primary Ring? **NO** ❌

**Reasons:**
1. Redundant with Recovery (70-80% overlap)
2. Not a daily decision metric ("Should I train?" = Recovery answers this)
3. Visual clutter (4 rings breaks balanced layout)
4. Stress is diagnostic, not actionable alone

### What Should We Do Instead? **CONTEXTUAL INTEGRATION** ✅

**Implementation:**
1. **Phase 1:** Add stress analysis to Recovery Detail View
2. **Phase 2:** Show conditional alert banner when stress elevated
3. **Phase 3:** Add Trends view with full stress history

**Benefits:**
- ✅ Preserves clean 3-ring UI
- ✅ Stress visible when actionable
- ✅ Educates users (stress → recovery connection)
- ✅ No redesign needed
- ✅ Competitive advantage vs Whoop
- ✅ Differentiated from Oura (athlete-specific)

### The North Star Hierarchy

```
PRIMARY (North Star):
1. Recovery ← "Can I train hard today?"
2. Sleep    ← "Did I recover overnight?"
3. Strain   ← "How hard did I train?"

SECONDARY (Diagnostic):
4. Stress   ← "WHY am I not recovered?"
5. Form     ← "Am I building fitness?"
6. Fatigue  ← "Am I overreaching?"
```

**Final Answer:** Stress is a powerful tool, but it's a *supporting actor*, not the *lead role*.

---

**Last Updated:** November 11, 2025  
**Status:** Recommendation - Ready for Design Review  
**Next Step:** Create mockups for conditional banner + detail view

