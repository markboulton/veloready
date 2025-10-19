# 🔐 Dashboard Password Protection Setup

**Status:** Files created, ready to deploy!

---

## ✅ **Files Created**

1. **`_headers`** - Configures authentication for `/ops/*` only
2. **`_redirects`** - Routes `/ops/*` to `/dashboard/*`
3. **`netlify.toml`** - Netlify configuration

---

## 🚀 **Deployment Steps**

### **Step 1: Set Environment Variable in Netlify**

1. **Go to Netlify Dashboard:**
   ```
   https://app.netlify.com/sites/veloready/settings/deploys#environment
   ```

2. **Click "Add variable"**

3. **Add this variable:**
   ```
   Key:   DASHBOARD_PASSWORD
   Value: YourSecurePassword123!
   ```
   
   **⚠️ Choose a strong password:**
   - At least 20 characters
   - Mix of letters, numbers, symbols
   - Example: `Vr!D@sh2025$ecure#Ops`

4. **Click "Save"**

---

### **Step 2: Commit and Push Files**

```bash
# Check what we created
ls -la _headers _redirects netlify.toml

# Add files to git
git add _headers _redirects netlify.toml

# Commit
git commit -m "Add password protection to /ops/ dashboard"

# Push to trigger Netlify deploy
git push origin main
```

---

### **Step 3: Wait for Deployment**

1. **Watch deployment:**
   ```
   https://app.netlify.com/sites/veloready/deploys
   ```

2. **Wait for "Published" status** (usually 1-2 minutes)

---

### **Step 4: Test Authentication**

#### **Test 1: Dashboard requires password**
```bash
# Should prompt for username/password
open https://veloready.app/ops/

# Or test with curl
curl https://veloready.app/ops/
# Should return: 401 Unauthorized
```

#### **Test 2: Login works**
```bash
# Test with credentials (replace with your password)
curl -u admin:YourSecurePassword123! https://veloready.app/ops/
# Should return: 200 OK with dashboard HTML
```

#### **Test 3: App functionality still works**
```bash
# These should work WITHOUT authentication:

# Universal Links
curl https://veloready.app/.well-known/apple-app-site-association
# Should return: JSON (no auth required)

# OAuth callback
curl https://veloready.app/auth/strava/callback
# Should work (no auth required)

# API endpoints
curl https://veloready.app/api/me/strava/token
# Should work (no auth required)
```

---

## 🔐 **How to Access Dashboard**

### **In Browser:**

1. **Navigate to:**
   ```
   https://veloready.app/ops/
   ```

2. **Browser will prompt for credentials:**
   ```
   Username: admin
   Password: [your DASHBOARD_PASSWORD]
   ```

3. **Click "Sign In"**

4. **Dashboard loads!** ✅

### **Credentials:**
- **Username:** `admin` (hardcoded in `_headers`)
- **Password:** Whatever you set in `DASHBOARD_PASSWORD` env var

---

## 🔧 **Configuration Details**

### **What's Protected:**
- ✅ `/ops/*` - Requires authentication
- ✅ `/dashboard/*` - Also protected (legacy path)

### **What's Public:**
- ✅ `/.well-known/*` - Universal Links (iOS app needs this)
- ✅ `/auth/*` - OAuth callbacks (Strava login needs this)
- ✅ `/api/*` - API endpoints (app needs this)
- ✅ `/ai-brief` - AI Brief endpoint
- ✅ `/ai-ride-summary` - Ride Summary endpoint

### **Security Headers Added:**
- `X-Robots-Tag: noindex` - Prevents search engine indexing
- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME sniffing
- `Cache-Control: no-cache` - Prevents caching of sensitive data

---

## 🔄 **How the Redirect Works**

```
User visits: https://veloready.app/ops/
              ↓
_headers checks: Is this /ops/*? YES
              ↓
Requires: Basic-Auth with admin:${DASHBOARD_PASSWORD}
              ↓
User enters credentials
              ↓
_redirects routes: /ops/* → /dashboard/*
              ↓
Dashboard loads at /ops/ URL ✅
```

---

## 🛠️ **Troubleshooting**

### **Issue: "401 Unauthorized" even with correct password**

**Solution:**
1. Check environment variable is set correctly in Netlify
2. Redeploy the site (sometimes env vars need a redeploy)
3. Clear browser cache and try again

### **Issue: "Entire site requires password"**

**Solution:**
- This shouldn't happen with our `_headers` config
- Check that `_headers` file was deployed
- Verify paths in `_headers` are correct

### **Issue: "Dashboard not found at /ops/"**

**Solution:**
1. Check if dashboard exists at `/dashboard/`
2. Verify `_redirects` file is correct
3. Check Netlify deploy logs for errors

### **Issue: "App functionality broken"**

**Solution:**
1. Check that public paths in `_headers` are correct
2. Test each endpoint individually
3. Review Netlify function logs

---

## 🔒 **Security Best Practices**

### **Password Management:**
- ✅ Use a password manager to generate strong password
- ✅ Store password in Netlify env vars (never in code)
- ✅ Rotate password every 90 days
- ✅ Don't share password via email/Slack

### **Access Control:**
- ✅ Only share credentials with authorized users
- ✅ Use different passwords for different environments
- ✅ Monitor Netlify access logs regularly

### **Additional Security (Optional):**
- Add IP whitelisting in Netlify
- Enable Netlify Analytics to track access
- Set up alerts for failed login attempts

---

## 📊 **What Happens Next**

### **After Deployment:**

1. **Dashboard accessible at:**
   ```
   https://veloready.app/ops/
   ```

2. **Requires authentication:**
   - Username: `admin`
   - Password: Your `DASHBOARD_PASSWORD`

3. **App continues working normally:**
   - iOS Universal Links ✅
   - OAuth authentication ✅
   - API endpoints ✅

4. **Dashboard is private:**
   - Not indexed by search engines ✅
   - Protected from unauthorized access ✅
   - Secure headers applied ✅

---

## 🎯 **Quick Checklist**

Before deploying, make sure:

- [ ] Set `DASHBOARD_PASSWORD` in Netlify env vars
- [ ] Choose a strong password (20+ characters)
- [ ] Commit `_headers`, `_redirects`, `netlify.toml`
- [ ] Push to GitHub
- [ ] Wait for Netlify deployment
- [ ] Test authentication works
- [ ] Test app functionality still works
- [ ] Save credentials in password manager

---

## 📞 **Need Help?**

If you encounter issues:

1. **Check Netlify deploy logs:**
   ```
   https://app.netlify.com/sites/veloready/deploys
   ```

2. **Check Netlify function logs:**
   ```
   https://app.netlify.com/sites/veloready/logs
   ```

3. **Test with curl:**
   ```bash
   # Test dashboard auth
   curl -v https://veloready.app/ops/
   
   # Test with credentials
   curl -v -u admin:password https://veloready.app/ops/
   ```

---

## ✅ **Ready to Deploy!**

Run these commands to deploy:

```bash
# Add files
git add _headers _redirects netlify.toml DASHBOARD_SETUP_INSTRUCTIONS.md

# Commit
git commit -m "Add password protection to /ops/ dashboard"

# Push
git push origin main
```

Then set the `DASHBOARD_PASSWORD` environment variable in Netlify! 🚀
