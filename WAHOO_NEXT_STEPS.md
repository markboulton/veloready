# Wahoo Integration - Current State & Next Steps

**Last Updated:** November 13, 2025  
**Current Status:** ✅ Infrastructure Complete, Data Integration Pending

---

## 📍 Where You Are Now

### ✅ Completed (Phase 3: Infrastructure)

**iOS App:**
- ✅ Wahoo added to `DataSource` enum
- ✅ `WahooAuthService` - OAuth authentication flow
- ✅ `WahooAuthConfig` - Configuration and credentials
- ✅ Rate limiting configured (60 req/15min, 200/hr, 2000/day)
- ✅ Icons and branding (#338CF2 Wahoo blue)

**Backend:**
- ✅ `oauth-wahoo-start.ts` - OAuth initiation
- ✅ `oauth-wahoo-token-exchange.ts` - Token exchange & Supabase user creation
- ✅ `webhooks-wahoo.ts` - Webhook handler with signature validation
- ✅ `public/oauth/wahoo/callback.html` - OAuth callback page
- ✅ Rate limiting infrastructure

**Database:**
- ✅ Migration file created: `003_wahoo_integration.sql`
- ✅ Tables defined:
  - `wahoo_credentials` (OAuth tokens)
  - `wahoo_workouts` (activity data)
  - `wahoo_power_zones` (FTP/zones)
  - `wahoo_webhook_events` (webhook logs)
- ⚠️ **Migration NOT yet run** (needs to be applied)

**Documentation:**
- ✅ `WAHOO_INTEGRATION_SUMMARY.md` - Implementation details
- ✅ `WAHOO_DATA_INTEGRATION_ARCHITECTURE.md` - Data flow architecture
- ✅ `WAHOO_QUICK_TEST.md` - Testing guide

### ❌ Not Yet Complete (Phase 3A-E: Data Integration)

**The Problem:** Wahoo infrastructure exists, but **workouts are never fetched or displayed** in the app.

**Missing Components:**
1. **No WahooDataService** - Nothing fetches workouts from database
2. **No API endpoint** - Backend can't return workouts to iOS
3. **No ActivityConverter** - Can't convert Wahoo format to Activity
4. **No UnifiedActivityService integration** - Wahoo not merged with Strava/Intervals
5. **No UI integration** - Wahoo workouts don't appear in activity lists

---

## 🗂️ Supabase Schema Status

### Current Schema (As Documented)

Your existing database has:

```sql
-- Athletes table (Strava OAuth)
CREATE TABLE athletes (
  id BIGINT PRIMARY KEY,  -- Strava athlete ID
  user_id UUID REFERENCES auth.users(id),
  firstname TEXT,
  lastname TEXT,
  profile TEXT,
  strava_access_token TEXT,
  strava_refresh_token TEXT,
  strava_token_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit log (for rate limiting)
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  at TIMESTAMPTZ DEFAULT NOW(),
  athlete_id BIGINT,
  note TEXT
);

-- Subscriptions (for Pro features)
CREATE TABLE subscriptions (
  -- ... Pro/Free tier management
);
```

### Wahoo Schema (Needs to be Added)

The file `supabase/migrations/003_wahoo_integration.sql` exists but **has NOT been run yet**. It will create:

```sql
-- 1. Wahoo OAuth credentials
CREATE TABLE wahoo_credentials (
  wahoo_user_id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_at TIMESTAMPTZ,
  scopes TEXT[],
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- 2. Wahoo workout/activity data
CREATE TABLE wahoo_workouts (
  id BIGSERIAL PRIMARY KEY,
  wahoo_workout_id TEXT UNIQUE NOT NULL,
  wahoo_user_id TEXT REFERENCES wahoo_credentials(wahoo_user_id),
  user_id UUID REFERENCES auth.users(id),
  workout_name TEXT,
  workout_type TEXT,
  started_at TIMESTAMPTZ,
  duration_seconds INT,
  distance_meters DOUBLE PRECISION,
  calories INT,
  avg_power_watts INT,
  max_power_watts INT,
  avg_heart_rate INT,
  max_heart_rate INT,
  normalized_power INT,
  intensity_factor DOUBLE PRECISION,
  training_stress_score DOUBLE PRECISION,
  raw_data JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- 3. Power zones from Wahoo
CREATE TABLE wahoo_power_zones (
  id BIGSERIAL PRIMARY KEY,
  wahoo_user_id TEXT REFERENCES wahoo_credentials(wahoo_user_id),
  user_id UUID REFERENCES auth.users(id),
  ftp INT NOT NULL,
  zone_1_min INT, zone_1_max INT,
  zone_2_min INT, zone_2_max INT,
  -- ... zones 3-7 ...
  effective_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);

-- 4. Webhook event log
CREATE TABLE wahoo_webhook_events (
  id BIGSERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  wahoo_user_id TEXT,
  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMPTZ,
  error TEXT,
  created_at TIMESTAMPTZ
);
```

### ⚠️ Schema Analysis: No Conflicts

**Good News:** The Wahoo schema is **completely separate** from existing tables:
- ✅ No modifications to existing `athletes` table
- ✅ No modifications to `audit_log` or other tables
- ✅ New tables have unique names (`wahoo_*`)
- ✅ Uses same `user_id` pattern as Strava (references `auth.users`)

**Safe to Run:** The migration is idempotent (uses `IF NOT EXISTS`), so it's safe to run even if some tables already exist.

---

## 🚀 Next Steps (In Order)

### Step 1: Apply Database Migration (5 minutes)

**Option A: Using Supabase CLI (Recommended)**
```bash
cd /Users/mark.boulton/Documents/dev/veloready-website

# Install Supabase CLI if not already installed
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref <your-project-ref>

# Run migration
supabase db push
```

**Option B: Using psql directly**
```bash
cd /Users/mark.boulton/Documents/dev/veloready-website

# Run migration (replace with your actual DATABASE_URL)
psql $DATABASE_URL -f supabase/migrations/003_wahoo_integration.sql
```

**Option C: Using Supabase Dashboard**
1. Go to https://app.supabase.com
2. Select your project
3. Go to SQL Editor
4. Copy/paste contents of `supabase/migrations/003_wahoo_integration.sql`
5. Click "Run"

**Verify Migration:**
```sql
-- Run in Supabase SQL Editor
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename LIKE 'wahoo%' 
ORDER BY tablename;

-- Expected output:
-- wahoo_credentials
-- wahoo_power_zones
-- wahoo_webhook_events
-- wahoo_workouts
```

### Step 2: Set Environment Variables (5 minutes)

**Get Wahoo API Credentials:**
1. Go to https://developers.wahoo.fitness/
2. Create/access your app (sandbox environment)
3. Get:
   - Client ID
   - Client Secret
   - Webhook Token

**Set in Netlify:**
```bash
cd /Users/mark.boulton/Documents/dev/veloready-website

# Set environment variables
netlify env:set WAHOO_CLIENT_ID "your_client_id_here"
netlify env:set WAHOO_CLIENT_SECRET "your_client_secret_here"
netlify env:set WAHOO_WEBHOOK_TOKEN "your_webhook_token_here"

# Verify
netlify env:list
```

### Step 3: Deploy Backend (5 minutes)

```bash
cd /Users/mark.boulton/Documents/dev/veloready-website

# Deploy to production
netlify deploy --prod

# Verify functions deployed
# Should see:
# - oauth-wahoo-start
# - oauth-wahoo-token-exchange
# - webhooks-wahoo
```

### Step 4: Configure Wahoo API Console (5 minutes)

1. Go to https://developers.wahoo.fitness/
2. Select your app
3. Update settings:
   - **Callback URL:** `https://api.veloready.app/oauth/wahoo/callback`
   - **Webhook URL:** `https://api.veloready.app/webhooks/wahoo`
   - **Scopes:** Enable all (email, power_zones_read, workouts_read, plans_read, routes_read, offline_data, user_read)
4. Save changes

### Step 5: Test OAuth Flow (10 minutes)

**From iOS App:**
1. Open VeloReady app
2. Go to Settings → Data Sources
3. Tap "Connect Wahoo" (if visible - may need to unhide in code)
4. Complete Wahoo login
5. Should redirect back to app

**Verify in Database:**
```sql
-- Check credential was stored
SELECT wahoo_user_id, user_id, created_at 
FROM wahoo_credentials 
ORDER BY created_at DESC 
LIMIT 1;
```

**Expected:** One row with your Wahoo user ID and Supabase user ID

### Step 6: Test Webhook (Optional, 5 minutes)

**Send Test Workout Webhook:**
```bash
curl -X POST https://api.veloready.app/webhooks/wahoo \
  -H "Content-Type: application/json" \
  -H "X-Wahoo-Signature: <calculated_hmac>" \
  -d '{
    "event_type": "workout.created",
    "user_id": "your_wahoo_user_id",
    "workout": {
      "id": "test-123",
      "name": "Morning Ride",
      "type": "cycling",
      "started_at": "2025-11-13T07:00:00Z",
      "duration": 3600,
      "distance": 30000,
      "avg_power": 200
    }
  }'
```

**Verify in Database:**
```sql
SELECT event_type, processed, created_at 
FROM wahoo_webhook_events 
ORDER BY created_at DESC 
LIMIT 1;

SELECT workout_name, started_at, avg_power_watts 
FROM wahoo_workouts 
ORDER BY created_at DESC 
LIMIT 1;
```

---

## 🎯 Phase 3A-E: Data Integration (Next Major Work)

**After infrastructure is tested and working, you need to:**

### Phase 3A: Data Models (2-3 hours)
1. Create `WahooWorkout.swift` model
2. Add `wahooWorkout` property to `UnifiedActivity`
3. Create `WahooDataService` to fetch workouts
4. Add `ActivityConverter.wahooToActivity()` converter

### Phase 3B: Backend API (1-2 hours)
1. Create `api-wahoo-workouts.ts` endpoint
2. Add `VeloReadyAPIClient.fetchWahooWorkouts()` method
3. Wire up caching and rate limiting

### Phase 3C: Service Integration (2-3 hours)
1. Update `UnifiedActivityService.fetchRecentActivities()` to include Wahoo
2. Implement deduplication logic (Wahoo + Strava + Intervals)
3. Update `AthleteProfile.computeFromActivities()` for adaptive FTP

### Phase 3D: View Integration (1-2 hours)
1. Update activity cards to show Wahoo workouts
2. Add Wahoo badge/icon to activity rows
3. Ensure ride detail view works with Wahoo data

### Phase 3E: Testing (2-3 hours)
1. Unit tests for converters and deduplication
2. Integration tests for multi-source sync
3. Manual testing of full flow

**Total Estimated Effort:** 9-15 hours

**Detailed Architecture:** See `WAHOO_DATA_INTEGRATION_ARCHITECTURE.md`

---

## 📊 Current Main Branch Status

Your `main` branch now contains:

### ✅ Deployed & Working
1. **Strava Cache Fixes** (Just committed)
   - 5-minute cache for recent activities
   - Pull-to-refresh invalidates cache
   - Backend smart TTL

### ✅ Ready to Deploy (Infrastructure Only)
2. **Wahoo OAuth** (Can be deployed now)
   - OAuth flow works
   - Tokens stored in database
   - Webhooks receive data

### ❌ Not Yet Functional
3. **Wahoo Data Display** (Requires Phase 3A-E)
   - Workouts stored but not fetched
   - Not shown in app UI
   - Not used in calculations

---

## 🎛️ Hiding Wahoo UI (If Not Ready to Launch)

If you want to deploy the Strava fixes **without** exposing Wahoo to users:

### Option 1: Feature Flag (Recommended)
```swift
// In ProFeatureConfig.swift or similar
var wahooEnabled: Bool {
    #if DEBUG
    return true  // Available in development
    #else
    return false  // Hidden in production
    #endif
}

// In DataSourcesSettingsView.swift
if proConfig.wahooEnabled {
    Button("Connect Wahoo") {
        // Wahoo OAuth flow
    }
}
```

### Option 2: Comment Out UI
```swift
// In DataSourcesSettingsView.swift
// Temporarily comment out Wahoo section
/*
Section("Wahoo") {
    Button("Connect Wahoo") { ... }
}
*/
```

### Option 3: Keep as-is
- Wahoo OAuth works but does nothing visible
- No harm in keeping it (just won't show workouts)
- Users won't see Wahoo in data sources list anyway (if not rendered)

---

## 🚦 Recommended Deployment Strategy

### Option A: Strava Only (Safe, Quick)
1. Hide Wahoo UI completely
2. Deploy Strava cache fixes
3. Monitor for 24-48 hours
4. Then do Wahoo infrastructure deployment
5. Then Phase 3A-E (data integration)

### Option B: Strava + Wahoo Infrastructure (Recommended)
1. Deploy Strava cache fixes ✅
2. Run Wahoo database migration
3. Deploy Wahoo OAuth backend
4. Hide Wahoo UI in production (feature flag)
5. Test OAuth flow in debug builds
6. Then implement Phase 3A-E
7. Unhide UI when data integration complete

### Option C: Full Deployment
1. Complete Phase 3A-E first (9-15 hours)
2. Deploy everything together
3. More risk but cleaner launch

**I recommend Option B:** Deploy infrastructure now, hide UI, implement data integration later.

---

## 📋 Quick Deployment Checklist

### ☑️ Strava Fixes (Already on Main)
- [x] Build passes
- [x] Tests pass  
- [x] Cache fixes committed
- [ ] Backend deployed
- [ ] Verify new activities appear within 5 min

### ☐ Wahoo Infrastructure (Optional Now)
- [ ] Database migration run
- [ ] Environment variables set in Netlify
- [ ] Backend deployed
- [ ] Wahoo API Console configured
- [ ] OAuth flow tested (debug build)
- [ ] Wahoo UI hidden in production (if not ready)

### ☐ Wahoo Data Integration (Future Work)
- [ ] WahooWorkout model created
- [ ] ActivityConverter.wahooToActivity() implemented
- [ ] WahooDataService fetches from backend
- [ ] Backend API endpoint created
- [ ] UnifiedActivityService includes Wahoo
- [ ] Activity cards show Wahoo workouts
- [ ] CTL/ATL includes Wahoo TSS
- [ ] Adaptive FTP uses Wahoo power
- [ ] All tests pass
- [ ] Wahoo UI unhidden

---

## 💡 Summary

**Where you are:**
- ✅ Strava fixes complete and committed
- ✅ Wahoo OAuth infrastructure complete (not yet deployed)
- ❌ Wahoo data integration not started (9-15 hours of work)

**Immediate next steps:**
1. **Deploy Strava fixes** (backend + iOS)
2. **Decide on Wahoo**: Deploy infrastructure now or wait?
3. If deploying Wahoo: Run migration, set env vars, deploy backend
4. **Hide Wahoo UI** in production (feature flag)
5. **Plan Phase 3A-E** implementation (separate sprint)

**Database migration:**
- ✅ File exists and is correct
- ✅ No conflicts with existing schema
- ✅ Safe to run anytime
- ⚠️ Needs to be applied before Wahoo OAuth will work

**Files to reference:**
- Infrastructure: `documentation/WAHOO_INTEGRATION_SUMMARY.md`
- Data integration: `documentation/WAHOO_DATA_INTEGRATION_ARCHITECTURE.md`
- Testing: `documentation/WAHOO_QUICK_TEST.md`
- Deployment: `DEPLOYMENT_CHECKLIST_NOV13.md`

---

**Questions to answer:**
1. Do you want to deploy Wahoo infrastructure now (with UI hidden)?
2. Should I help you run the database migration?
3. Do you want to implement Phase 3A-E now or later?


