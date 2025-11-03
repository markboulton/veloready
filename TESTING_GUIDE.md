# VeloReady Subscription Sync - Testing Guide

## Quick Reference

**What was built:** iOS app now syncs subscription status to Supabase backend via `/subscription/sync` endpoint.

**Architecture:**
- iOS sends JWT token + subscription data to backend
- Backend validates JWT, extracts user_id, upserts to `user_subscriptions` table
- Proper user isolation via RLS policies

**Two ways to test:**
1. **Quick Test** - Use debug button (no purchase needed)
2. **Full Flow** - Test real subscription purchase with StoreKit

---

## Option 1: Quick Test (5 minutes)

**Best for:** Initial verification, debugging

### Steps:

1. **Build and run** (⌘R)

2. **Navigate to test button:**
   ```
   Settings → Debug & Testing → Debug Settings → Testing Features section
   ```

3. **Test FREE tier:**
   - Tap "Test Subscription Sync"
   - See: "Synced to Supabase!" ✅
   - Logs: `✅ [Subscription] Synced to backend: free`

4. **Test PRO tier:**
   - Toggle ON "Enable Pro Features (Testing)"
   - Tap "Test Subscription Sync"
   - See: "Synced to Supabase!" ✅
   - Logs: `✅ [Subscription] Synced to backend: pro`

5. **Verify in Supabase:**
   - Dashboard → user_subscriptions table
   - Check tier matches what you tested

---

## Option 2: Full Purchase Flow (15 minutes)

**Best for:** End-to-end testing, pre-release validation

### Setup (one-time):

1. **Add StoreKit config to Xcode:**
   - File exists: `/Users/markboulton/Dev/veloready/VeloReady/Configuration.storekit`
   - Xcode: Right-click VeloReady folder → Add Files
   - Select `Configuration.storekit` → Add
   
2. **Enable in scheme:**
   - Product → Scheme → Edit Scheme
   - Run → Options tab
   - StoreKit Configuration → "Configuration.storekit"
   - Close

### Test Flow:

1. **Trigger paywall:**
   
   **Via Pro Feature:**
   - Trends tab → Tap "Weekly Recovery Trend" (Pro badge)
   - PaywallView appears
   
   **Via Activities:**
   - Activities tab → Tap filter/export
   - PaywallView appears

2. **Purchase subscription:**
   - Select plan: Monthly ($9.99) or Yearly ($71.88)
   - Tap "Start Free Trial"
   - Purchase completes instantly (no payment)
   - Paywall auto-dismisses

3. **Verify sync:**
   - Xcode logs show:
     ```
     💳 [Subscription] Syncing to backend...
     ✅ [Subscription] Synced to backend: pro
     ```
   
4. **Check Supabase:**
   - Table: `user_subscriptions`
   - Fields populated:
     * `subscription_tier` = "pro"
     * `transaction_id` = Apple transaction ID
     * `product_id` = "com.veloready.pro.monthly" or yearly
     * `expires_at` = future date
     * `purchase_date` = today

5. **Test features:**
   - Pro features now unlocked
   - No paywalls shown
   - Settings → Debug Settings shows "PRO" badge

---

## Where Paywall Appears

**PaywallView is triggered from:**

1. **ProFeatureGate** - Inline upgrade cards
   - Used in: RecoveryDetailView, SleepDetailView, StrainDetailView
   
2. **ProNavigationLink** - Navigation with paywall
   - Used in: TrendsView (Weekly Recovery Trend)
   
3. **ProUpgradeCard** - Standalone upgrade prompts
   - Used in: Activities filters, AI Brief, various Pro features

4. **Onboarding** - SubscriptionStepView (first launch)

---

## Verification Checklist

### After Quick Test:
- [ ] Xcode logs show sync success
- [ ] Supabase table has row for your user
- [ ] `subscription_tier` = "free" or "pro"
- [ ] `athlete_id` matches Strava ID
- [ ] Timestamps are recent

### After Full Purchase:
- [ ] All above, plus:
- [ ] `transaction_id` populated
- [ ] `product_id` correct
- [ ] `expires_at` has future date
- [ ] `purchase_date` is today
- [ ] Pro features unlocked in app
- [ ] Debug Settings shows "PRO" badge

---

## Troubleshooting

### "Cannot sync: No user ID or athlete ID"
**Fix:** Make sure you're signed in to Strava
- Settings → Data Sources → Connect Strava
- Check SupabaseClient has valid session

### "Sync failed with HTTP error"
**Check:**
- Supabase URL is correct (hardcoded in SubscriptionManager)
- JWT token is valid (not expired)
- RLS policies allow INSERT/UPDATE
- Migration `003_subscriptions.sql` ran successfully

### Purchase doesn't trigger sync
**Check:**
- StoreKit configuration enabled in scheme
- Products loaded: Check logs for product IDs
- Transaction verified: Check logs for verification

### Supabase table empty
**Check:**
- Migration ran: `npx supabase db push`
- Table exists: Check Supabase dashboard
- RLS policies: Check you can insert as authenticated user

---

## Next Steps

After testing Day 2:

✅ **Day 2 Complete** - iOS syncs to Supabase  
🔜 **Day 3 Next** - Backend reads subscription tier and enforces limits

**To continue:**
Say "I'm ready for Day 3" to implement backend authentication enhancement.
