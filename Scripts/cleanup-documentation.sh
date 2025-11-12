#!/bin/bash

# Documentation Cleanup Script
# Reorganizes root markdown files into documentation/ folder
# Date: November 11, 2025

set -e  # Exit on error

REPO_ROOT="/Users/mark.boulton/Documents/dev/veloready"
cd "$REPO_ROOT"

echo "🧹 Starting Documentation Cleanup..."
echo ""

# Step 1: Create new folder structure
echo "📁 Step 1: Creating new folders..."
mkdir -p documentation/architecture
mkdir -p documentation/features
mkdir -p documentation/fixes/critical
mkdir -p documentation/archive/bugs
mkdir -p documentation/archive/healthkit
mkdir -p documentation/archive/cache
mkdir -p documentation/archive/loading-states
mkdir -p documentation/archive/refactoring
mkdir -p documentation/archive/phases
mkdir -p documentation/archive/performance
mkdir -p documentation/archive/testing
mkdir -p documentation/archive/ui
mkdir -p documentation/archive/strava
mkdir -p documentation/archive/misc

echo "✅ Folders created"
echo ""

# Step 2: Move current/relevant architecture docs
echo "📦 Step 2: Moving current architecture docs..."
mv ARCHITECTURE_FIX_HEALTHKIT_INIT.md documentation/architecture/ 2>/dev/null || true
mv RESILIENCE_ANALYSIS.md documentation/architecture/ 2>/dev/null || true
mv TECHNICAL_DEBT_ANALYSIS.md documentation/architecture/ 2>/dev/null || true
mv TODAY_CODE_HEALTH_SUMMARY.md documentation/architecture/ 2>/dev/null || true
mv SUPABASE_AUTH_ROBUSTNESS_ANALYSIS.md documentation/architecture/ 2>/dev/null || true
mv SUPABASE_AUTH_ROBUSTNESS_COMPLETE.md documentation/architecture/ 2>/dev/null || true

echo "✅ Architecture docs moved (6 files)"
echo ""

# Step 3: Move feature documentation
echo "📦 Step 3: Moving feature documentation..."
mv SCORING_METHODOLOGY.md documentation/features/ 2>/dev/null || true
mv STRESS_COMPARISON_OURA.md documentation/features/ 2>/dev/null || true
mv STRESS_UI_STRATEGY.md documentation/features/ 2>/dev/null || true
mv CLOUDKIT_BACKUP_RESTORE.md documentation/features/ 2>/dev/null || true
mv TIER_LIMIT_ERROR_HANDLING.md documentation/features/ 2>/dev/null || true
mv CIRCUIT_BREAKER.md documentation/features/ 2>/dev/null || true
mv CLIENT_SIDE_THROTTLING.md documentation/features/ 2>/dev/null || true
mv EXPONENTIAL_BACKOFF_RETRY.md documentation/features/ 2>/dev/null || true

echo "✅ Feature docs moved (8 files)"
echo ""

# Step 4: Move recent critical fixes
echo "📦 Step 4: Moving recent critical fixes..."
mv BUG_FIX_HEALTHKIT_RACE_CONDITION.md documentation/fixes/critical/ 2>/dev/null || true
mv BUG_FIX_SCORE_CALCULATION_NEVER_STARTS.md documentation/fixes/critical/ 2>/dev/null || true
mv SCORE_TIMEOUT_FIX.md documentation/fixes/critical/ 2>/dev/null || true

echo "✅ Critical fixes moved (3 files)"
echo ""

# Step 5: Archive historical bug fixes
echo "📦 Step 5: Archiving historical bug fixes..."
mv BUG_FIXES_2025-11-06.md documentation/archive/bugs/ 2>/dev/null || true
mv BUG_FIXES_2025-11-07.md documentation/archive/bugs/ 2>/dev/null || true
mv BUG_FIXES_2025-11-09.md documentation/archive/bugs/ 2>/dev/null || true
mv BUG_FIXES_NOV9_EVENING.md documentation/archive/bugs/ 2>/dev/null || true
mv BUG_FIXES_SUMMARY_2025-11-09.md documentation/archive/bugs/ 2>/dev/null || true
mv BUG_REPORT_20251110.md documentation/archive/bugs/ 2>/dev/null || true
mv BUGFIX_HEALTHKIT_FLASH_V2.md documentation/archive/bugs/ 2>/dev/null || true
mv BUGFIX_PHASE3_FOLLOWUP.md documentation/archive/bugs/ 2>/dev/null || true
mv BUGFIX_THREE_CRITICAL_ISSUES.md documentation/archive/bugs/ 2>/dev/null || true
mv BUGFIX_TIMING_RACE_CONDITIONS.md documentation/archive/bugs/ 2>/dev/null || true
mv BUGS_FIXED_SUMMARY.md documentation/archive/bugs/ 2>/dev/null || true
mv CRITICAL_BUGS_ANALYSIS.md documentation/archive/bugs/ 2>/dev/null || true
mv CRITICAL_DATA_LOSS_FIX.md documentation/archive/bugs/ 2>/dev/null || true
mv CRITICAL_FIXES_ROUND4.md documentation/archive/bugs/ 2>/dev/null || true
mv CRITICAL_FIXES_SUMMARY.md documentation/archive/bugs/ 2>/dev/null || true
mv EMERGENCY_FIX.md documentation/archive/bugs/ 2>/dev/null || true
mv FIX_SUMMARY.md documentation/archive/bugs/ 2>/dev/null || true
mv FIXES_APPLIED_SUMMARY.md documentation/archive/bugs/ 2>/dev/null || true

echo "✅ Bug fixes archived (18 files)"
echo ""

# Step 6: Archive HealthKit evolution
echo "📦 Step 6: Archiving HealthKit evolution..."
mv HEALTHKIT_AUTHORIZATION_DEEP_ANALYSIS.md documentation/archive/healthkit/ 2>/dev/null || true
mv HEALTHKIT_AUTHORIZATION_FIX_SUMMARY.md documentation/archive/healthkit/ 2>/dev/null || true
mv HEALTHKIT_FIX_COMPLETE_SUMMARY.md documentation/archive/healthkit/ 2>/dev/null || true
mv HEALTHKIT_PHASE2_COMPLETE.md documentation/archive/healthkit/ 2>/dev/null || true
mv HEALTHKIT_PHASE3_COMPLETE.md documentation/archive/healthkit/ 2>/dev/null || true
mv IOS26_PERMISSION_FIX.md documentation/archive/healthkit/ 2>/dev/null || true

echo "✅ HealthKit docs archived (6 files)"
echo ""

# Step 7: Archive cache system evolution
echo "📦 Step 7: Archiving cache system evolution..."
mv BULLETPROOF_CACHE_SYSTEM_COMPLETE.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_ARCHITECTURE_ANALYSIS.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_CORRUPTION_FIX_NOV9.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_FIX_COMPLETE.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_FIX_VERIFICATION.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_FIXES_IMPLEMENTATION.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_IMPLEMENTATION_COMPLETE.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_LOADING_STATE_FIX.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_PERSISTENCE_SUCCESS.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_RESILIENCE_IMPLEMENTED.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_RESILIENCE_STRATEGY.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_UNIT_TESTS.md documentation/archive/cache/ 2>/dev/null || true
mv CACHE_VERSION_SYSTEM.md documentation/archive/cache/ 2>/dev/null || true
mv CORE_DATA_CACHE_SETUP.md documentation/archive/cache/ 2>/dev/null || true

echo "✅ Cache docs archived (14 files)"
echo ""

# Step 8: Archive loading states evolution
echo "📦 Step 8: Archiving loading states evolution..."
mv COMPACT_RINGS_LOADING_BEHAVIOR_FIX.md documentation/archive/loading-states/ 2>/dev/null || true
mv COMPACT_RINGS_LOADING_FIX.md documentation/archive/loading-states/ 2>/dev/null || true
mv COMPACT_RINGS_TESTING_CHECKLIST.md documentation/archive/loading-states/ 2>/dev/null || true
mv CONTEXTUAL_LOADING_STATES.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATE_FINAL_STATUS.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATE_FIXES_ROUND2.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATE_FIXES_ROUND3.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATE_IMPROVEMENTS.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATE_TEST_REPORT.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATE_VISUAL_GUIDE.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATES_GAP_FIX.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATUS_ALIGNMENT_FIX.md documentation/archive/loading-states/ 2>/dev/null || true
mv LOADING_STATUS_IMPROVEMENTS.md documentation/archive/loading-states/ 2>/dev/null || true

echo "✅ Loading state docs archived (13 files)"
echo ""

# Step 9: Archive refactoring plans
echo "📦 Step 9: Archiving refactoring plans..."
mv ACTION_PLAN_MAKE_ROBUST.md documentation/archive/refactoring/ 2>/dev/null || true
mv ARCHITECTURAL_AUDIT_NOV9.md documentation/archive/refactoring/ 2>/dev/null || true
mv COMPREHENSIVE_FIX_PLAN.md documentation/archive/refactoring/ 2>/dev/null || true
mv LARGE_SCALE_REFACTOR_PLAN.md documentation/archive/refactoring/ 2>/dev/null || true
mv REFACTOR_DOCS.md documentation/archive/refactoring/ 2>/dev/null || true
mv REFACTOR_EXECUTION_PLAN.md documentation/archive/refactoring/ 2>/dev/null || true
mv REFACTOR_PLAN_FINAL.md documentation/archive/refactoring/ 2>/dev/null || true
mv REFACTOR_PLAN_REVISED.md documentation/archive/refactoring/ 2>/dev/null || true

echo "✅ Refactoring docs archived (8 files)"
echo ""

# Step 10: Archive phase completion docs
echo "📦 Step 10: Archiving phase completion docs..."
mv DAY_2_COMPLETE.md documentation/archive/phases/ 2>/dev/null || true
mv DAY_2_FIXED.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE1_3_4_COMPLETION_STATUS.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE1_4_STRAIN_EXTRACTION_PLAN.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE1_COMPLETE_SUMMARY.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE1_COMPLETE_SUMMARY.txt documentation/archive/phases/ 2>/dev/null || true
mv PHASE1_FINAL_COMPLETE.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE1_SLEEP_STRAIN_EXECUTION_SUMMARY.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE2_CRITICAL_FIX.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE2_FIX_APPLIED.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE2_ISSUE_RESOLVED.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE2_OPTIMIZATION.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE3_COMPLETE.md documentation/archive/phases/ 2>/dev/null || true
mv PHASE3_VERIFICATION.md documentation/archive/phases/ 2>/dev/null || true
mv WEEK1_COMPLETE.md documentation/archive/phases/ 2>/dev/null || true
mv WEEK2_INTEGRATION_COMPLETE.md documentation/archive/phases/ 2>/dev/null || true

echo "✅ Phase docs archived (16 files)"
echo ""

# Step 11: Archive performance work
echo "📦 Step 11: Archiving performance work..."
mv ACTIVITY_FETCH_FIXES_IMPLEMENTED.md documentation/archive/performance/ 2>/dev/null || true
mv ACTIVITY_FETCH_OPTIMIZATION.md documentation/archive/performance/ 2>/dev/null || true
mv PERFORMANCE_ANALYSIS_REPORT.md documentation/archive/performance/ 2>/dev/null || true
mv PERFORMANCE_FIXES_IMPLEMENTED.md documentation/archive/performance/ 2>/dev/null || true
mv PERFORMANCE_OPTIMIZATION_COMPLETE.md documentation/archive/performance/ 2>/dev/null || true
mv PERFORMANCE_SUMMARY.md documentation/archive/performance/ 2>/dev/null || true
mv REFRESH_PERFORMANCE_FIX.md documentation/archive/performance/ 2>/dev/null || true
mv STARTUP_ISSUES_FIXED.md documentation/archive/performance/ 2>/dev/null || true
mv STARTUP_PERFORMANCE_FIXES.md documentation/archive/performance/ 2>/dev/null || true

echo "✅ Performance docs archived (9 files)"
echo ""

# Step 12: Archive testing history
echo "📦 Step 12: Archiving testing history..."
mv BUILD_VERIFICATION.md documentation/archive/testing/ 2>/dev/null || true
mv TEST_FIX_SUMMARY.md documentation/archive/testing/ 2>/dev/null || true
mv TEST_PHASE2_FIX.md documentation/archive/testing/ 2>/dev/null || true

echo "✅ Testing docs archived (3 files)"
echo ""

# Step 13: Archive UI evolution
echo "📦 Step 13: Archiving UI evolution..."
mv DESIGN_SYSTEM_100_COMPLETE.md documentation/archive/ui/ 2>/dev/null || true
mv FINAL_POLISH_FIXES.md documentation/archive/ui/ 2>/dev/null || true
mv LATEST_RIDE_CARD_FIX.md documentation/archive/ui/ 2>/dev/null || true
mv LAYOUT_FIXES_QUICK_REF.md documentation/archive/ui/ 2>/dev/null || true
mv RAINBOW_GRADIENT_UPDATE.md documentation/archive/ui/ 2>/dev/null || true
mv RECOVERY_DETAIL_FIX_PROMPT.md documentation/archive/ui/ 2>/dev/null || true
mv RECOVERY_SUBSCORES_FIX.md documentation/archive/ui/ 2>/dev/null || true
mv TODAY_PAGE_COMPLETE_SUMMARY.md documentation/archive/ui/ 2>/dev/null || true

echo "✅ UI docs archived (8 files)"
echo ""

# Step 14: Archive Strava history
echo "📦 Step 14: Archiving Strava history..."
mv STRAVA_AUTH_ISSUE_FIXED.md documentation/archive/strava/ 2>/dev/null || true
mv STRAVA_AUTH_ISSUE.md documentation/archive/strava/ 2>/dev/null || true
mv STRAVA_INTEGRATION_STATUS.md documentation/archive/strava/ 2>/dev/null || true

echo "✅ Strava docs archived (3 files)"
echo ""

# Step 15: Archive miscellaneous docs
echo "📦 Step 15: Archiving miscellaneous docs..."
mv DEBUG_LOGGING_ADDED.md documentation/archive/misc/ 2>/dev/null || true
mv DEBUG_SCORE_DISAPPEARANCE.md documentation/archive/misc/ 2>/dev/null || true
mv HOOK_TEST.md documentation/archive/misc/ 2>/dev/null || true
mv MANUAL_STEPS_REQUIRED.md documentation/archive/misc/ 2>/dev/null || true
mv PRE_COMMIT_HOOK_UPDATE.md documentation/archive/misc/ 2>/dev/null || true
mv PRODUCTION_READINESS_PLAN.md documentation/archive/misc/ 2>/dev/null || true
mv PRODUCTION_READINESS_PROMPTS.md documentation/archive/misc/ 2>/dev/null || true
mv RACE_CONDITION_FIXES_COMPLETE.md documentation/archive/misc/ 2>/dev/null || true
mv REVERT_SUMMARY.md documentation/archive/misc/ 2>/dev/null || true
mv SCORE_ACCURACY_ANALYSIS.md documentation/archive/misc/ 2>/dev/null || true
mv TODO_CLEANUP_COMPLETE.md documentation/archive/misc/ 2>/dev/null || true
mv TODO_CLEANUP_PLAN.md documentation/archive/misc/ 2>/dev/null || true

echo "✅ Misc docs archived (12 files)"
echo ""

# Step 16: Delete obsolete files
echo "🗑️  Step 16: Deleting obsolete files..."
rm -f BUILD_DEPLOYMENT_NOTES.md 2>/dev/null || true
rm -f CI_TEST.md 2>/dev/null || true
rm -f CI_UPDATE_SUMMARY.md 2>/dev/null || true
rm -f COMMIT_MESSAGE_AUTH_FIX.txt 2>/dev/null || true
rm -f COMMIT_MESSAGE_DATA_REFRESH.txt 2>/dev/null || true
rm -f PROPOSED_SIMPLE_HEALTHKIT_MANAGER.swift 2>/dev/null || true
rm -f PROPOSED_UNIFIED_CACHE.swift 2>/dev/null || true
rm -f TESTING_DEPLOYMENT_SUMMARY.md 2>/dev/null || true
rm -f TESTING_GUIDE.md 2>/dev/null || true
rm -f TESTING_IMPLEMENTATION_SUMMARY.md 2>/dev/null || true
rm -f TESTING_IMPROVEMENT_PLAN.md 2>/dev/null || true
rm -f TESTING_IMPROVEMENTS_2025-11-06.md 2>/dev/null || true
rm -f TESTING_QUICK_START.md 2>/dev/null || true
rm -f TESTING_SPEED_TIERS.md 2>/dev/null || true

echo "✅ Obsolete files deleted (14 files)"
echo ""

echo "✅ Documentation cleanup complete!"
echo ""
echo "📊 Summary:"
echo "  - Architecture docs: 6 files → documentation/architecture/"
echo "  - Feature docs: 8 files → documentation/features/"
echo "  - Critical fixes: 3 files → documentation/fixes/critical/"
echo "  - Archived: ~100 files → documentation/archive/*/"
echo "  - Deleted: 14 obsolete files"
echo ""
echo "🎯 Root directory is now clean!"
echo "   Remaining: README.md, LICENSE.md, QUICK_START.md"
echo ""
echo "Next steps:"
echo "  1. Review changes with: git status"
echo "  2. Update README.md with new structure"
echo "  3. Create INDEX files in new folders"
echo "  4. Commit changes"



