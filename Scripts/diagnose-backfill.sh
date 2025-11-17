#!/bin/bash

echo "🔍 VeloReady Backfill Diagnostic Tool"
echo "======================================"
echo ""
echo "This script will:"
echo "  1. Trigger a backfill with force refresh"
echo "  2. Capture detailed logs"
echo "  3. Analyze the results"
echo ""
echo "⚠️  NOTE: You must run the app first, then check the logs"
echo ""
echo "Press Enter to see instructions..."
read

cat <<'INSTRUCTIONS'

📋 MANUAL TEST PROCEDURE:
=========================

1. Open VeloReady app on your device

2. Go to: Settings → Debug → Force Backfill

3. Watch the console output in Xcode (Cmd+Shift+Y)

4. Look for these key markers:

   ✅ SUCCESS MARKERS:
   - "📊 [PHYSIO BACKFILL] ✅ COMPLETE - Saved X days"
   - "✅ [RECOVERY BACKFILL] Updated X days, skipped Y"
   - "✅ [SLEEP BACKFILL] Updated X days, skipped Y"

   📊 DATA TO COLLECT:
   - HRV range (look for "HRV range: X - Y ms")
   - RHR range (look for "RHR range: X - Y bpm")
   - Recovery score distribution (count how many in 40-60 vs 70-80 range)

   ⚠️  PROBLEMS TO WATCH FOR:
   - "❌ NO DATA FETCHED" - means HealthKit has no data
   - "⏭️ THROTTLED" - means backfill was skipped (use force refresh)
   - Recovery scores all in 40-60 range - calculation problem
   - "Skipping (recovery=X > 80)" - old scores not being recalculated

5. After backfill completes:
   - Navigate to Trends tab
   - Check if charts show new data
   - Look for notification: "📢 [TrendsViewModel] Received BackfillComplete notification"

6. Report findings:
   - How many days got backfilled?
   - What's the recovery score range?
   - Did the UI update?

INSTRUCTIONS

echo ""
echo "✅ Instructions displayed above"
echo ""
