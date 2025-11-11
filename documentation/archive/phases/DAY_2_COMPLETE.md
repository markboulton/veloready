# Day 2: iOS Subscription Sync - COMPLETE ✅

**Date:** November 3, 2025

## Summary

Successfully implemented iOS to Supabase subscription sync. The app now automatically syncs subscription status to the backend whenever subscription state changes.

---

## Changes Made

### 1. SupabaseClient.swift
**Location:** `/Users/markboulton/Dev/VeloReady/VeloReady/Core/Networking/SupabaseClient.swift`

**Added:**
- `var currentUserId: String?` - Computed property to get current user ID from session
- Returns `session?.user.id`

**Lines:** 24-27

---

### 2. StravaAuthService.swift  
**Location:** `/Users/markboulton/Dev/veloready/VeloReady/Core/Services/StravaAuthService.swift`

**Added:**
- `var athleteId: Int?` - Computed property to get athlete ID
- Checks connection state first, then falls back to UserDefaults
- Returns athlete ID as Int for easy use

**Lines:** 14-24

---

### 3. Date+Extensions.swift (NEW FILE)
**Location:** `/Users/markboulton/Dev/veloready/VeloReady/Shared/Extensions/Foundation/Date+Extensions.swift`

**Created:**
- `var iso8601String: String` - Extension to convert Date to ISO8601 string
- Uses `ISO8601DateFormatter()` with fractional seconds
- Required for API date fields (expires_at, trial_ends_at, purchase_date)

---

### 4. SubscriptionManager.swift
**Location:** `/Users/markboulton/Dev/veloready/VeloReady/Core/Services/SubscriptionManager.swift`

**Added:**

#### A. `syncToBackend()` method (lines 249-335)
- Async function to sync subscription to Supabase
- Gets user ID from SupabaseClient
- Gets athlete ID from StravaAuthService
- Maps subscription status to tier/status/dates:
  - `.subscribed` → tier: "pro", status: "active"
  - `.trial` → tier: "trial", status: "active"
  - `.notSubscribed` → tier: "free", status: "active"
- Fetches latest transaction details (id, productId, purchaseDate)
- Creates upsert request to Supabase REST API
- Uses `Prefer: resolution=merge-duplicates` for upsert on conflict
- Logs success/failure

#### B. `getLatestTransaction()` helper (lines 337-345)
- Async function to get verified transaction from StoreKit
- Iterates through `Transaction.currentEntitlements`
- Returns first verified transaction
- Used to extract transaction ID, product ID, purchase date

#### C. Updated `updateProFeatureConfig()` (line 240-242)
- Now calls `syncToBackend()` after saving subscription state
- Runs in background Task (non-blocking)

---

## How It Works

### Sync Flow:
```
User purchases/trial expires
    ↓
StoreKit updates subscription status
    ↓
updateSubscriptionStatus() called
    ↓
updateProFeatureConfig() updates ProFeatureConfig
    ↓
syncToBackend() called in background Task
    ↓
POST to Supabase user_subscriptions table
    ↓
Backend database updated with current tier
```

### Data Synced:
- `user_id` - Supabase user UUID
- `athlete_id` - Strava athlete ID
- `subscription_tier` - "free", "pro", or "trial"
- `subscription_status` - "active", "expired", "cancelled"
- `expires_at` - Pro subscription expiration (ISO8601)
- `trial_ends_at` - Trial expiration (ISO8601)
- `transaction_id` - Apple transaction ID
- `product_id` - "com.veloready.pro.monthly" or "com.veloready.pro.yearly"
- `purchase_date` - When subscription was purchased (ISO8601)
- `auto_renew` - Always true for active subscriptions

---

## Testing

### **Option 1: Quick Test (Recommended)**
Use the debug button to test sync without purchasing.

1. **Build and run app** (⌘R in Xcode)

2. **Navigate to Debug Settings:**
   ```
   Settings tab → Debug & Testing → Debug Settings → Testing Features
   ```

3. **Test sync with different tiers:**
   
   **FREE tier (default):**
   - Tap **"Test Subscription Sync"** button
   - See success: "Synced to Supabase!"
   - Check logs: `✅ [Subscription] Synced to backend: free`
   
   **PRO tier:**
   - Toggle ON **"Enable Pro Features (Testing)"**
   - Tap **"Test Subscription Sync"** button
   - See success: "Synced to Supabase!"
   - Check logs: `✅ [Subscription] Synced to backend: pro`

4. **Verify in Supabase:**
   - Dashboard → Table Editor → `user_subscriptions`
   - Check `subscription_tier` = "free" or "pro"
   - Check `athlete_id` matches your Strava ID

---

### **Option 2: Full Purchase Flow (Real Testing)**
Test the complete subscription flow with StoreKit.

1. **Add StoreKit configuration to Xcode:**
   - File already created: `VeloReady/Configuration.storekit`
   - In Xcode: Right-click VeloReady folder → Add Files
   - Select `Configuration.storekit` → Add
   - Product → Scheme → Edit Scheme → Run → Options
   - StoreKit Configuration → Select "Configuration.storekit"

2. **Trigger paywall in app:**
   
   **Method A: Via Pro feature**
   - Go to any Pro-gated feature (e.g., Trends → Weekly Recovery Trend)
   - Tap the Pro badge/upgrade button
   - PaywallView appears
   
   **Method B: Via Activities**
   - Go to Activities tab
   - Tap filter/export (Pro features)
   - PaywallView appears

3. **Complete purchase:**
   - Select plan (Monthly $9.99 or Yearly $71.88)
   - Tap "Start Free Trial" button
   - Purchase completes instantly (no payment in simulator)
   - Paywall dismisses automatically

4. **Verify sync happened:**
   - Check Xcode logs:
     ```
     💳 [Subscription] Syncing to backend...
     ✅ [Subscription] Synced to backend: pro
     ```
   - Check Supabase table:
     - `subscription_tier` = "pro"
     - `transaction_id` populated
     - `product_id` = "com.veloready.pro.monthly" or "com.veloready.pro.yearly"
     - `expires_at` has future date

5. **Test subscription features:**
   - Pro features now unlocked
   - No more paywalls shown
   - Debug Settings shows "PRO" badge

### Expected Results:

✅ Logs show sync success  
✅ Supabase table has new/updated row  
✅ `subscription_tier` matches current status  
✅ `athlete_id` matches Strava ID  
✅ Transaction details populated for paid subscriptions  

### Troubleshooting:

**"Cannot sync: No user ID or athlete ID"**
- Make sure you're signed in to Strava
- Check SupabaseClient has valid session
- Check StravaAuthService is connected

**"Sync failed with HTTP error"**
- Check Supabase URL is correct
- Check JWT token is valid (not expired)
- Check RLS policies allow INSERT/UPDATE
- Check migration 003_subscriptions.sql ran successfully

**"Invalid Supabase URL"**
- Verify hardcoded URL matches your Supabase project
- Check apikey header matches your anon key

---

## Next Steps

✅ **Day 2 Complete** - iOS subscription sync implemented

🔜 **Day 3 Next** - Backend authentication enhancement
- Update `netlify/lib/auth.ts` to query subscription tier
- Add tier limits constants
- Return subscription info with auth result

---

## Files Modified Summary

| File | Lines | Changes |
|------|-------|---------|
| SupabaseClient.swift | 4 | Added currentUserId property |
| StravaAuthService.swift | 11 | Added athleteId property |
| Date+Extensions.swift | 10 | NEW FILE - ISO8601 formatting |
| SubscriptionManager.swift | 108 | Added syncToBackend() + helper |

**Total:** 133 lines added across 4 files
