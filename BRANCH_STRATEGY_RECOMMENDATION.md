# Branch Strategy Recommendation - November 13, 2025

## 🎯 Your Goal

> "I want a clean Main with the Strava fixes that won't regress/conflict when I merge in Wahoo integration"

## 💡 The Problem

The Strava cache fixes (commit 191a400) **depend on** the Wahoo integration changes:

```
Wahoo Integration (0fe0cde):
- Renamed IntervalsActivity → Activity (70+ files)
- Changed ActivityConverter.stravaToIntervals() → stravaToActivity()

Strava Fixes (191a400):
- Uses Activity type (not IntervalsActivity)
- Uses stravaToActivity() (not stravaToIntervals())
```

**Therefore:** Strava fixes cannot exist without Wahoo changes.

---

## ✅ **Recommended Solution: Keep Both on Main**

### **Why This is Best:**

1. **No Conflicts** - Wahoo is already merged, Strava builds on top
2. **Actually Works** - The code compiles and runs
3. **No Duplication** - Don't need to maintain two versions of Strava fixes
4. **Forward Compatible** - Future Wahoo updates merge cleanly
5. **Faster Deployment** - No complex branching gymnastics

### **Current State (Recommended):**

```
main: dab5126 ──→ 8570d6c ──→ 0fe0cde ──→ 191a400 ──→ 45ac167
                  (Wahoo1)   (Wahoo2)   (Strava)     (merge)
                  
Status: ✅ Working, tested, ready to deploy
```

**What's on main:**
- ✅ Wahoo OAuth integration
- ✅ IntervalsActivity → Activity rename
- ✅ Strava cache fixes (5-min TTL, pull-to-refresh)
- ✅ All documentation

**Deployable?** YES - Everything works together

---

## 🔀 Alternative: Separate Branches (More Work, Same Result)

If you really want separate branches:

### **Option A: Wahoo-Integration-2 Becomes Redundant**

```
main: Has Wahoo + Strava (ready to deploy)
wahoo-integration-2: Has only Wahoo (becomes obsolete)
```

**Result:** wahoo-integration-2 serves no purpose since Wahoo is already on main.

### **Option B: Create Strava-Fixes-Only Branch**

```
main: Has Wahoo + Strava (ready to deploy)
strava-fixes-only: Has Strava adapted to IntervalsActivity type
```

**Problems:**
1. strava-fixes-only can't be deployed (needs Wahoo rename)
2. Merging wahoo-integration-2 to main creates conflicts
3. Need to maintain two versions of Strava fixes

**Complexity:** High
**Benefit:** None (main already has everything)

---

## 📊 Comparison Matrix

| Approach | Conflicts? | Deploy Ready? | Maintenance | Complexity |
|----------|------------|---------------|-------------|------------|
| **Keep Current Main** | ❌ None | ✅ Yes | 🟢 Low | 🟢 Simple |
| **Separate Branches** | ⚠️ Many | ⚠️ Partial | 🔴 High | 🔴 Complex |

---

## 🎯 My Recommendation

### **Keep main as-is with both Wahoo + Strava**

**Rationale:**
1. The Strava fixes were built on top of Wahoo's type rename
2. Separating them creates artificial dependency problems
3. Both features work well together
4. No user-facing reason to keep them separate
5. Easier to test, deploy, and maintain

### **If You Must Separate:**

Only do this if there's a **business reason** to deploy Strava without Wahoo:

1. Keep `wahoo-integration-2` with Wahoo-only changes
2. Rebase `main` to have Wahoo first, then Strava on top
3. Create feature flag to disable Wahoo UI if needed

But this adds complexity with no technical benefit.

---

## 🚀 Recommended Next Steps

### **Deploy Current Main (Wahoo + Strava)**

```bash
# 1. Test locally
git checkout main
# Open Xcode, run tests

# 2. Deploy backend
cd /Users/mark.boulton/Documents/dev/veloready-website
netlify deploy --prod

# 3. Deploy iOS (if ready)
# Build in Xcode, submit to TestFlight

# 4. Monitor
# Check Strava API rate limits
# Test pull-to-refresh
# Test Wahoo OAuth (if enabled)
```

### **Future Wahoo Development**

If you want to continue Wahoo development:

```bash
# Create new branch from main
git checkout -b wahoo-enhancements main

# Make Wahoo improvements
# ...

# Merge back when ready
git checkout main
git merge wahoo-enhancements
```

---

## 💭 Why This Feels Wrong But Isn't

### **Concern:** "I merged Wahoo branch but I'm not ready to launch Wahoo"

**Solution:** Feature flags or conditional compilation

```swift
#if WAHOO_ENABLED
// Wahoo-specific UI
#endif
```

or

```swift
if ProFeatureConfig.shared.wahooEnabled {
    // Show Wahoo option
}
```

**This way:**
- Code is in main (clean history)
- Wahoo features are hidden until enabled
- No branch management overhead
- Strava fixes deploy immediately

### **Concern:** "Wahoo changes 70+ files, seems risky"

**Reality:** Most changes are:
- Type rename: `IntervalsActivity` → `Activity` (safer, more accurate)
- Method rename: `stravaToIntervals()` → `stravaToActivity()` (clearer)

These are **improvements** that benefit the codebase regardless of Wahoo.

---

## 🎯 Final Verdict

**Keep main with Wahoo + Strava together.**

**Reasons:**
1. ✅ Technical dependency (Strava needs Wahoo's types)
2. ✅ Cleaner history (chronological, no rebasing)
3. ✅ Less maintenance (one branch to worry about)
4. ✅ Faster deployment (no conflict resolution)
5. ✅ Better testing (test everything together)

**If you want to hide Wahoo features:**
- Use feature flags
- Don't show Wahoo in UI until ready
- Keep code in main, control visibility

---

## 📝 Summary

**Your Question:**
> "I want clean Main with Strava fixes that won't conflict with Wahoo"

**Answer:**
The cleanest solution is to **keep both on main** because:
- They're technically interdependent
- Separating creates artificial problems
- Current state works perfectly
- No conflicts when Wahoo is already integrated

**Current main status:**
- ✅ Wahoo integration (type safety improvements)
- ✅ Strava cache fixes (performance improvements)
- ✅ Ready to deploy
- ✅ No conflicts (everything merged)

**Action:** Deploy current main, use feature flags if needed to control Wahoo visibility.

---

**Status:** ✅ Recommendation complete
**Decision:** Your choice - but I recommend keeping both together

