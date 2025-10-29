# Repository Revert Summary

## Date: October 27, 2025

Both repositories have been successfully reverted to their state from before the October 27th changes.

## Reverted Commits

### veloready (iOS App)
**Reverted TO:** `a143a84` - "strain scroe tweaks" (Oct 26, 18:48 GMT)

**Commits removed:**
- `b21f0b9` - Fix: Identified fitness trajectory chart issue - missing backend authentication
- `3b16059` - Investigation: Fitness trajectory chart not showing values
- `56b1b0b` - Merge branch 'main'
- `8551c5f` - build fix
- `2c4cf41` - features
- `b3a8058` - strain score tweaks (Oct 27)

**Changes reverted:**
- Investigation documentation for fitness trajectory chart
- Authentication fix documentation
- BUILD_FIXES_SUMMARY.md updates
- Feature documentation (BROWN_BAG_PRESENTATION_OUTLINE, FEATURES_*.md files)

### veloready-website (Backend)
**Reverted TO:** `5fef5f6` - "tweaks to ai brief" (Oct 27, 09:09 GMT)

**Commits removed:**
- `eb45ece` - Documentation: Activity caching investigation and testing procedures
- `2a43c2f` - lets try and fix this bug
- `c3d11f7` - docs
- `bd77a67` - Fix: Use text type for blob store get to prevent JSON parse errors
- `dc05dd9` - Add cache hit/miss logging for debugging
- `a6a43d2` - Fix: Add 1-hour caching to listActivitiesSince (THE CACHING CHANGE)
- `dfc84b5` - strava stats fix

**Changes reverted:**
- Activity list caching implementation (`netlify/lib/strava.ts`)
- Cache hit/miss logging
- Text type for blob store
- Testing and debugging documentation
- Audit log timestamp fixes

## Why Revert?

The caching changes introduced in commit `a6a43d2` on the backend were causing the fitness trajectory chart to show 0 values. However, the investigation revealed the actual issue was **authentication**, not the caching itself. 

By reverting, we're going back to a known working state before these changes were made.

## Next Steps

1. **Test the app** - Check if the fitness trajectory chart now shows values
2. **Review authentication** - The real issue is missing Supabase session for backend API calls
3. **If chart still shows 0** - The problem is authentication, not caching
4. **If chart works** - Can carefully re-apply caching with proper testing

## Current State

Both repositories are now reverted:
- **veloready**: `a143a84` - Oct 26, 18:48 GMT (strain scroe tweaks)
- **veloready-website**: `5fef5f6` - Oct 27, 09:09 GMT (tweaks to ai brief - BEFORE caching changes)

## To Deploy Backend Changes

```bash
cd /Users/mark.boulton/Documents/dev/veloready-website
git push origin main --force
```

⚠️ **Warning:** This force push will overwrite the remote repository history. Make sure this is what you want before proceeding.

## To Re-apply Changes Later

If you want to bring back any of the reverted commits:

```bash
# For selective commits:
git cherry-pick <commit-hash>

# To see what was reverted:
git reflog
```

The commits aren't deleted, just removed from the main branch. They can be recovered from the reflog if needed.

