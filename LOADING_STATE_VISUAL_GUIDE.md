# Loading State Visual Guide

## 📱 User Experience Flow

### Current Experience (❌ Problems)
```
[Black Screen]
      ↓
[Animated Rings - 8 seconds]
      ↓
[Spinners everywhere]
      ↓
[Scores appear suddenly]

Problems:
- User doesn't know what's happening
- Long wait with no feedback
- Spinners are distracting
- No visibility into progress
```

### New Experience (✅ Solution)
```
[Animated Rings - 2 seconds max]
      ↓
┌─────────────────────────┐
│ Today                   │
│ Calculating scores...   │ ← Small grey text
│                         │
│ ⭕ ⭕ ⭕                 │ ← Grey rings (no spinners)
│                         │
└─────────────────────────┘
      ↓
┌─────────────────────────┐
│ Today                   │
│ Contacting Strava...    │ ← State updates
│                         │
│ 🟢 ⭕ ⭕                 │ ← Recovery filled in
│ Optimal                 │ ← Label appears
└─────────────────────────┘
      ↓
┌─────────────────────────┐
│ Today                   │
│ Downloading 12 activities...│
│                         │
│ 🟢 🔵 ⭕                 │ ← Sleep filled in
│ Optimal  Good           │
└─────────────────────────┘
      ↓
┌─────────────────────────┐
│ Today                   │
│ [Status fades out]      │
│                         │
│ 🟢 🔵 🟠                 │ ← All rings ready
│ Optimal  Good  Moderate │
└─────────────────────────┘
```

---

## 🎨 Component Layout

### TodayView Header
```
┌────────────────────────────────────┐
│  Today                      [🔔]   │ ← VRText .largeTitle
│  ⚙️ Calculating scores...          │ ← LoadingStatusView (small, grey)
│                                    │
│  ┌──────────────────────────────┐ │
│  │  🟢     🔵     🟠            │ │ ← CompactRingsView
│  │  85     72     45            │ │
│  │ Optimal Good  Moderate       │ │
│  └──────────────────────────────┘ │
└────────────────────────────────────┘
```

### LoadingStatusView States

**Loading State:**
```
⚙️ Calculating scores...
   ↑ Small spinner + grey text
```

**Error State (Tappable):**
```
⚠️ Unable to connect. Tap to retry.
   ↑ Error icon + red text + tap gesture
```

**Complete State (Brief):**
```
✓ Ready
  ↑ Checkmark + grey text (fades after 0.5s)
```

---

## 🔄 State Transition Timeline

### Visual Timeline
```
0.0s  [🎬 Animated Rings Splash]
      
2.0s  ┌─────────────────────────┐
      │ Today                   │
      │ ⚙️ Calculating scores... │
      │ ⭕ ⭕ ⭕                 │ ← All grey
      └─────────────────────────┘

3.0s  ┌─────────────────────────┐
      │ Today                   │
      │ ⚙️ Contacting Strava...  │
      │ 🟢 ⭕ ⭕                 │ ← Recovery ready
      │ Optimal                 │
      └─────────────────────────┘

3.8s  ┌─────────────────────────┐
      │ Today                   │
      │ ⚙️ Downloading 12 activities...│
      │ 🟢 ⭕ ⭕                 │
      │ Optimal                 │
      └─────────────────────────┘

5.0s  ┌─────────────────────────┐
      │ Today                   │
      │ ⚙️ Processing data...    │
      │ 🟢 🔵 ⭕                 │ ← Sleep ready
      │ Optimal  Good           │
      └─────────────────────────┘

6.0s  ┌─────────────────────────┐
      │ Today                   │
      │ ⚙️ Refreshing scores...  │
      │ 🟢 🔵 ⭕                 │
      │ Optimal  Good           │
      └─────────────────────────┘

6.8s  ┌─────────────────────────┐
      │ Today                   │
      │ ✓ Ready                 │
      │ 🟢 🔵 🟠                 │ ← All ready
      │ Optimal  Good  Moderate │
      └─────────────────────────┘

7.3s  ┌─────────────────────────┐
      │ Today                   │ ← Status faded
      │                         │
      │ 🟢 🔵 🟠                 │
      │ Optimal  Good  Moderate │
      └─────────────────────────┘
```

---

## 🎭 Ring States

### Grey (Loading)
```swift
⭕  ← Grey stroke, subtle shimmer animation
   No score text
   No label
```

### Filled (Ready)
```swift
🟢  ← Color stroke (ColorScale.recoveryColor)
85 ← Score text appears
Optimal ← Label appears
```

### Shimmer Animation
```
Grey ring with subtle gradient sweep
Not a spinner - more subtle
Indicates "working on it"
```

---

## ⚠️ Error States

### Network Error
```
┌─────────────────────────────────┐
│ Today                           │
│ ⚠️ Unable to connect. Tap to retry.│ ← Red text, tappable
│                                 │
│ ⭕ ⭕ ⭕                         │ ← Rings stay grey
└─────────────────────────────────┘
```

### Strava Auth Error
```
┌─────────────────────────────────┐
│ Today                           │
│ ⚠️ Strava connection expired.   │
│    Tap to reconnect.            │ ← Red text, opens auth
│                                 │
│ 🟢 ⭕ ⭕                         │ ← Partial data shown
│ Optimal                         │
└─────────────────────────────────┘
```

---

## 📐 Spacing & Typography

### LoadingStatusView Specs
```
Padding: Spacing.md (12pt) horizontal
         Spacing.xs (4pt) vertical
         
Text: VRText .caption style
      ColorScale.textSecondary (grey)
      ColorScale.errorColor (errors)
      
Spinner: ProgressView .small
         ColorScale.textSecondary
         
Height: ~24pt (auto-sized)
```

### Compact Rings Specs
```
Ring Size: 60x60pt
Ring Stroke: 8pt
Ring Spacing: Spacing.lg (16pt)

Grey State:
- Stroke: ColorScale.textTertiary @ 0.3 opacity
- Shimmer: ColorScale.textTertiary @ 0.2-0.3 opacity

Filled State:
- Stroke: Respective color (recovery/sleep/strain)
- Background: Same color @ 0.3 opacity
```

---

## 🎯 Key UX Principles

### 1. Immediate Feedback
```
User opens app
      ↓
< 2 seconds later
      ↓
UI appears (even if not ready)
      ↓
User sees what's happening
```

### 2. Progressive Disclosure
```
Grey rings → "We're working on it"
      ↓
Status text → "Here's what we're doing"
      ↓
Rings fill in → "Here's your data"
      ↓
Status fades → "All done"
```

### 3. Graceful Degradation
```
If network fails:
- Show cached data
- Clear error message
- Tap to retry
- Don't block the UI
```

### 4. Readability
```
Each state visible for ≥0.8s
User can read and understand
Not too fast (flashing)
Not too slow (waiting)
```

---

## 🔧 Implementation Priority

### Must Have (MVP)
1. ✅ LoadingState model
2. ✅ LoadingStatusView component
3. ✅ Grey rings during loading
4. ✅ Basic state progression
5. ✅ Error states with retry

### Should Have (V1.1)
1. Activity count in "Downloading X activities..."
2. Smooth state transitions
3. Haptic feedback on errors
4. Pull-to-refresh integration

### Nice to Have (Future)
1. Progress percentages
2. Detailed error codes
3. Background sync indicator
4. Offline mode detection

---

## 🎬 Animation Specs

### Status Text Transitions
```swift
.transition(.opacity.combined(with: .move(edge: .top)))
.animation(.easeInOut(duration: 0.3), value: state)
```

### Ring Fill Animation
```swift
Circle()
    .trim(from: 0, to: progress)
    .animation(.easeInOut(duration: 0.5), value: progress)
```

### Shimmer Animation
```swift
.animation(
    .linear(duration: 1.5)
    .repeatForever(autoreverses: false),
    value: isLoading
)
```

---

## 💡 Design Decisions

### Why Small Grey Text?
- Apple Mail pattern (familiar)
- Non-intrusive
- Easy to read
- Doesn't compete with main content

### Why Grey Rings?
- Clear "not ready" state
- Better than spinners (less distracting)
- Subtle shimmer shows progress
- Smooth transition to colored rings

### Why No Spinners?
- Too distracting
- Old-fashioned
- Apple moving away from them
- Status text provides better context

### Why State Throttling?
- Prevents states flashing by
- Ensures readability
- Better than showing nothing
- Users can understand progress

---

## 🎨 Color Palette

### Loading States
```swift
textSecondary    // Status text
textTertiary     // Grey rings
errorColor       // Error states
```

### Ready States
```swift
recoveryColor    // Recovery ring
sleepColor       // Sleep ring
strainColor      // Strain ring
```

---

## ✅ Acceptance Criteria

### User Can...
- [ ] See UI within 2 seconds
- [ ] Understand what app is doing
- [ ] See progress as it happens
- [ ] Understand when loading is complete
- [ ] Retry on errors
- [ ] Use app with partial data

### Technical...
- [ ] No race conditions
- [ ] States always readable (≥0.8s)
- [ ] Smooth transitions
- [ ] Proper error handling
- [ ] Memory efficient
- [ ] Accessible

---

## 📊 Before/After Comparison

### Metrics

| Metric | Before | After |
|--------|--------|-------|
| Time to UI | 8s | 2s |
| User feedback | None | Real-time |
| Error visibility | Hidden | Clear |
| User understanding | Low | High |
| Perceived speed | Slow | Fast |

### User Perception

**Before:**
> "Why is it taking so long?"
> "Is it frozen?"
> "What's happening?"

**After:**
> "I can see what it's doing"
> "It's downloading my rides"
> "Almost ready"

---

This visual guide complements the architecture document and provides clear specifications for implementation.
