# Sleep Data Missing Banner - UI Redesign

## Overview
Redesigned the sleep data missing notification from a dismissable gray panel to a persistent, collapsible accordion-style banner.

## Changes Made

### 1. **New Collapsible Banner Design**

**Before:**
- Gray background panel with dismiss (X) button
- Always visible until dismissed
- Once dismissed, never shows again (stored in UserDefaults)

**After:**
- Clean, minimal design with no background panel
- Accordion-style collapse/expand behavior
- Persistent - always shows when sleep data is missing
- Interactive chevron arrow (points down when expanded, right when collapsed)
- Smooth animations

### 2. **Banner Position**
- Moved **above** the compact ring panel (Recovery/Sleep/Load)
- Positioned **below** the "Today" heading
- No longer in a gray panel - blends with the rest of the UI

### 3. **Visual Structure**

**Header Row (Always Visible):**
```
🌙 Sleep data missing                    ⌄
```
- Moon icon (small, 16pt)
- "Sleep data missing" text
- Chevron arrow (right-aligned, interactive)
  - Points **down** when expanded
  - Points **right** when collapsed

**Expandable Content:**
```
    Recovery is based only on waking HRV and resting HR. 
    Wear your watch tonight for complete recovery analysis.
```
- Indented to align with text (not icon)
- Only visible when expanded
- Smooth fade + slide animation

### 4. **Sleep Ring Interaction**

**When sleep data is missing:**
- **Removed** the chevron (>) from "Sleep" heading
- Ring is no longer interactive/tappable
- Shows "?" in the ring as before

### 5. **State Management**

Added new state variable:
```swift
@State private var isSleepBannerExpanded = true
```
- Defaults to **expanded** (user sees the explanation)
- User can collapse/expand at will
- State resets each session (not persisted)

### 6. **Removed Features**
- ❌ Dismiss (X) button
- ❌ Gray background panel
- ❌ Permanent dismissal via UserDefaults
- ❌ Sheet presentation for more info

## Code Changes

**File:** `Features/Today/Views/Dashboard/TodayView.swift`

1. Added `isSleepBannerExpanded` state variable
2. Moved banner above `recoveryMetricsSection`
3. Removed condition checking `!missingSleepBannerDismissed`
4. Completely rewrote `missingSleepDataBanner` view
5. Removed chevron from Sleep heading when data is missing

## User Experience

### When Sleep Data is Missing:
1. User sees banner immediately (expanded by default)
2. Can tap anywhere on header row to collapse
3. Banner persists - always visible when sleep data is missing
4. Smooth animation when expanding/collapsing
5. Sleep ring shows "?" and is not tappable

### When Sleep Data is Available:
- Banner disappears completely
- Sleep ring becomes tappable with chevron (>)
- Normal navigation to sleep details

## Design Rationale

- **Persistent**: Important information shouldn't be permanently dismissable
- **Collapsible**: Gives users control without hiding critical info
- **Clean**: No background panel - feels more integrated
- **Accessible**: Large tap target, clear visual hierarchy
- **Informative**: Explains why recovery might be limited

---

**Status:** ✅ Implemented and tested
**Build:** ✅ Successful (warnings only)
