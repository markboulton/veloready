# Wahoo Integration - Quick Test Instructions

## 🚀 Quick Start (5 Minutes)

### 1. Set Environment Variables
```bash
# In veloready-website/.env
WAHOO_CLIENT_ID="your_client_id"
WAHOO_CLIENT_SECRET="your_client_secret"
WAHOO_WEBHOOK_TOKEN="your_webhook_token"
```

### 2. Run Database Migration
```bash
cd veloready-website
psql $DATABASE_URL < supabase/migrations/003_wahoo_integration.sql
```

### 3. Deploy Backend
```bash
cd veloready-website
netlify deploy --prod
```

### 4. Configure Wahoo API Console
- Go to: https://developers.wahoo.fitness/
- Callback URL: `https://api.veloready.app/oauth/wahoo/callback`
- Webhook URL: `https://api.veloready.app/webhooks/wahoo`
- Save webhook token

### 5. Test OAuth Flow
```bash
cd veloready
open VeloReady.xcodeproj
# Run app → Settings → Connect Wahoo
```

## ✅ Quick Verification

### Check OAuth Worked
```sql
SELECT * FROM wahoo_credentials ORDER BY created_at DESC LIMIT 1;
```

### Test Webhook (Manual)
```bash
curl -X POST https://api.veloready.app/webhooks/wahoo \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "workout.created",
    "user_id": "YOUR_WAHOO_USER_ID",
    "workout": {"id": "test_123", "name": "Test Ride"}
  }'
```

### Check Webhook Received
```sql
SELECT * FROM wahoo_webhook_events ORDER BY created_at DESC LIMIT 1;
```

## 🐛 Quick Troubleshooting

**OAuth fails:** Check `WAHOO_CLIENT_SECRET` matches console  
**Webhook 401:** Verify `WAHOO_WEBHOOK_TOKEN` is correct  
**No data in DB:** Check Netlify function logs  
**Rate limited:** Clear Redis: `redis-cli FLUSHDB`

## 📊 Test Results Template

```markdown
## Wahoo Integration Test - [DATE]

### OAuth Flow
- [ ] App opens Wahoo login
- [ ] User authorizes successfully
- [ ] App shows "Connected"
- [ ] Database has credentials

### Webhooks
- [ ] Workout webhook received
- [ ] Workout stored in DB
- [ ] Power zones webhook received
- [ ] Zones stored in DB

### Rate Limiting
- [ ] 60th request allowed
- [ ] 61st request blocked
- [ ] Redis keys created
- [ ] Retry-after header present

### Cleanup
- [ ] Disconnect removes data
- [ ] Re-auth works

**Status:** ✅ PASS / ❌ FAIL  
**Notes:** [Any issues or observations]
```

## 🔗 Quick Links

- **Wahoo Console:** https://developers.wahoo.fitness/
- **Backend Logs:** https://app.netlify.com/sites/YOUR_SITE/logs
- **Full Test Guide:** `WAHOO_INTEGRATION_TEST_GUIDE.md`
- **Implementation Summary:** `phase3-wahoo-implementation-summary.md`

