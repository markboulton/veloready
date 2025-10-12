# ✅ VeloReady Netlify Deployment Complete!

**Date:** 2025-10-12  
**Status:** ✅ Deployed and Live!

---

## 🎉 What's Been Done

### 1. GitHub Repository ✅
- **URL:** https://github.com/markboulton/veloready
- **Status:** Public repository created
- **Branches:** main (4 commits)
- **Contents:** Full VeloReady source code + infrastructure

### 2. Netlify Site ✅
- **Site Name:** veloready
- **Site ID:** f434092e-0965-40f9-b3ef-87f1ff0a0378
- **URL:** https://veloready.netlify.app
- **Admin:** https://app.netlify.com/projects/veloready
- **Status:** ✅ LIVE

### 3. Deployment ✅
- **Deploy ID:** 68ebab882bc0b3ef1d2f19d4
- **Status:** ✅ Success
- **Files Deployed:** 2 (apple-app-site-association.json)
- **CDN:** Global distribution active

### 4. Files Live ✅
- ✅ `apple-app-site-association.json`
- ✅ Accessible at: https://veloready.netlify.app/apple-app-site-association.json
- ✅ Accessible at: https://veloready.netlify.app/.well-known/apple-app-site-association

---

## 🌐 Current URLs

**Netlify URL (Working Now):**
- https://veloready.netlify.app

**Custom Domain (Needs Configuration):**
- veloready.app (pending DNS setup)

**Universal Links File:**
- https://veloready.netlify.app/.well-known/apple-app-site-association
- https://veloready.netlify.app/apple-app-site-association.json

---

## ⏳ Manual Steps Needed (You Do These)

### Step 1: Add Custom Domain in Netlify (5 minutes)

1. **Go to Netlify Dashboard:**
   ```
   https://app.netlify.com/projects/veloready
   ```

2. **Click "Domain settings"**

3. **Click "Add custom domain"**

4. **Enter:** `veloready.app`

5. **Click "Verify"** and **"Add domain"**

6. Netlify will show you DNS records to configure

### Step 2: Configure DNS (10 minutes)

**Where is veloready.app registered?**

You need to add these DNS records at your domain registrar:

**Option A: If Using Netlify DNS (Recommended):**
```
1. Click "Set up Netlify DNS" in domain settings
2. Update nameservers at your registrar to Netlify's nameservers
3. Wait 24-48 hours for propagation
```

**Option B: If Using External DNS (e.g., Cloudflare):**
```
Type    Name    Value                           TTL
A       @       75.2.60.5 (Netlify's IP)       Auto
CNAME   www     veloready.netlify.app          Auto
```

**To get Netlify's exact IP:**
1. In Netlify Dashboard → Domain Settings → veloready.app
2. Look for "Netlify DNS records" or "External DNS"
3. Copy the IP address shown

### Step 3: Enable HTTPS (Automatic)

Once DNS is configured:
1. Netlify will automatically provision SSL certificate
2. Takes 1-2 hours after DNS propagates
3. HTTPS will be enabled automatically

### Step 4: Test Universal Links (After DNS)

```bash
# Test that the file is accessible
curl https://veloready.app/.well-known/apple-app-site-association

# Should return JSON with your Team ID
```

---

## 🔧 Current Configuration

### netlify.toml (Deployed)
```toml
[build]
  command = "echo 'No build needed for static OAuth callbacks'"
  publish = "public"

# Redirect legacy domain
[[redirects]]
  from = "https://rideready.icu/*"
  to = "https://veloready.app/:splat"
  status = 301
  force = true

# Serve apple-app-site-association
[[redirects]]
  from = "/.well-known/apple-app-site-association"
  to = "/apple-app-site-association.json"
  status = 200
  force = true
```

### apple-app-site-association.json (Deployed)
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "C79WM3NZ27.com.veloready.app",
        "paths": [
          "/auth/strava/callback",
          "/auth/intervals/callback",
          "/oauth/*",
          "/activities/*",
          "/trends/*"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "C79WM3NZ27.com.veloready.app"
    ]
  }
}
```

---

## 🧪 Testing

### Test Now (Netlify URL):
```bash
# Test apple-app-site-association is live
curl https://veloready.netlify.app/.well-known/apple-app-site-association

# Should return JSON (not 404)
```

### Test After DNS (Custom Domain):
```bash
# Test custom domain works
curl https://veloready.app/.well-known/apple-app-site-association

# Test redirects work
curl -I https://rideready.icu
# Should show 301 redirect to veloready.app
```

---

## 📊 Deployment Status

✅ **Complete:**
- [x] GitHub repository created
- [x] Code pushed to GitHub
- [x] Netlify site created
- [x] Initial deployment successful
- [x] apple-app-site-association deployed
- [x] Universal Links file accessible
- [x] netlify.toml configured
- [x] Redirects configured

⏳ **Pending (Manual):**
- [ ] Custom domain added in Netlify (you do this)
- [ ] DNS configured at registrar (you do this)
- [ ] SSL certificate provisioned (automatic after DNS)
- [ ] Test Universal Links on physical device

---

## 🎯 Where We Are

### What Works Right Now:
- ✅ https://veloready.netlify.app (live!)
- ✅ https://veloready.netlify.app/.well-known/apple-app-site-association
- ✅ GitHub repo live with all code
- ✅ Automatic deployments on push

### What Needs Configuration:
- ⏳ veloready.app domain (add in Netlify + configure DNS)
- ⏳ SSL certificate (automatic after DNS)
- ⏳ Universal Links testing (after DNS + SSL)

---

## 🚀 Next Steps

### Immediate (5 minutes):
1. **Test current deployment:**
   ```bash
   open https://veloready.netlify.app/.well-known/apple-app-site-association
   ```
   Should see JSON with your Team ID!

### Short Term (15 minutes):
1. **Add custom domain in Netlify:**
   - Go to: https://app.netlify.com/projects/veloready
   - Domain settings → Add custom domain → veloready.app

2. **Configure DNS:**
   - At your domain registrar (where you bought veloready.app)
   - Add A record pointing to Netlify's IP
   - Or use Netlify DNS (easier)

### After DNS Propagates (24-48 hours):
1. **Test custom domain:**
   ```bash
   curl https://veloready.app/.well-known/apple-app-site-association
   ```

2. **Test on iPhone:**
   - Send email with: https://veloready.app/auth/strava/callback?code=test
   - Tap link → Should open VeloReady app!

---

## 💡 Pro Tips

### Automatic Deployments:
Every time you push to GitHub, Netlify will automatically:
- Pull the latest code
- Deploy to production
- Update the live site

To deploy manually:
```bash
cd /Users/markboulton/Dev/VeloReady
git push origin main
# Netlify deploys automatically!
```

### Update apple-app-site-association:
```bash
# Edit the file
nano public/apple-app-site-association.json

# Commit and push
git add public/apple-app-site-association.json
git commit -m "Update Universal Links configuration"
git push origin main

# Netlify deploys automatically in ~30 seconds
```

---

## 🆘 Troubleshooting

### "Domain already in use" in Netlify:
- The domain might be registered to another Netlify site
- Check if rideready.icu is using it
- You may need to remove it from the old site first

### DNS not propagating:
- Wait 24-48 hours
- Check with: `dig veloready.app`
- Use: https://dnschecker.org to check globally

### apple-app-site-association returns 404:
- Check file exists in `public/` directory
- Check netlify.toml redirects are correct
- Redeploy if needed: `netlify deploy --prod --dir=public`

---

## 📞 Useful Links

**Netlify:**
- Dashboard: https://app.netlify.com/projects/veloready
- Deploys: https://app.netlify.com/projects/veloready/deploys
- Domain Settings: https://app.netlify.com/sites/veloready/settings/domain

**GitHub:**
- Repository: https://github.com/markboulton/veloready
- Commits: https://github.com/markboulton/veloready/commits/main

**Live Site:**
- Netlify URL: https://veloready.netlify.app
- apple-app-site-association: https://veloready.netlify.app/.well-known/apple-app-site-association

---

## ✅ Success Criteria

Deployment is complete when:
- [x] Site is live on Netlify URL
- [x] apple-app-site-association is accessible
- [x] GitHub repo is created and synced
- [ ] Custom domain veloready.app is configured
- [ ] DNS is propagated
- [ ] SSL certificate is active
- [ ] Universal Links tested on physical iPhone

---

**Status:** ✅ **Netlify deployment complete! Just need DNS configuration.**

**Next Action:** Go to https://app.netlify.com/projects/veloready and add your custom domain!
