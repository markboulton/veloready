# 🔐 VeloReady Dashboard Deployment with Authentication

**Goal:** Deploy dashboard from `veloready.netlify.app/dashboard` to `veloready.app/ops/` with password protection

---

## 📋 **Prerequisites**

- ✅ Netlify site: `veloready` (Site ID: f434092e-0965-40f9-b3ef-87f1ff0a0378)
- ✅ Custom domain: `veloready.app` (already configured)
- ⏳ Dashboard code repository location needed

---

## 🔍 **Step 1: Locate Dashboard Repository**

The dashboard at `https://veloready.netlify.app/dashboard` needs to be identified.

**Questions to answer:**
1. Is the dashboard in a separate GitHub repo?
2. Or is it in a subdirectory of the main VeloReady repo?
3. What's the GitHub URL for the dashboard code?

**Common locations:**
- Separate repo: `github.com/markboulton/veloready-dashboard`
- Subdirectory: `github.com/markboulton/veloready/dashboard`
- Different branch: `github.com/markboulton/veloready` (branch: dashboard)

---

## 🚀 **Step 2: Deploy Dashboard to /ops/ Path**

### **Option A: Using Netlify Redirects (Recommended)**

If the dashboard is already deployed, we can redirect `/ops/` to `/dashboard/`:

**Create `netlify.toml` in your dashboard repo:**
```toml
# Redirect /ops/ to /dashboard/
[[redirects]]
  from = "/ops/*"
  to = "/dashboard/:splat"
  status = 200
  force = true

# Or if you want to move it, use rewrite
[[redirects]]
  from = "/ops/*"
  to = "/dashboard/:splat"
  status = 200
```

### **Option B: Change Build Output Path**

If you want `/ops/` to be the actual path:

**Update build settings in `netlify.toml`:**
```toml
[build]
  publish = "ops"  # Change from "dashboard" to "ops"
  command = "npm run build"  # Your build command
```

---

## 🔐 **Step 3: Add Password Protection**

Netlify offers several authentication options:

### **Option 1: Basic Auth with Netlify (Simplest)**

**Add to `netlify.toml`:**
```toml
# Password protect the /ops/ directory
[[redirects]]
  from = "/ops/*"
  to = "/ops/:splat"
  status = 200
  force = true
  conditions = {Role = ["admin"]}

# Set up basic auth
[context.production]
  [context.production.environment]
    BASIC_AUTH_USERNAME = "admin"
    BASIC_AUTH_PASSWORD = "your-secure-password"
```

**Then add to your `_headers` file:**
```
/ops/*
  Basic-Auth: admin:your-secure-password
```

### **Option 2: Netlify Identity (More Secure)**

**1. Enable Netlify Identity:**
```bash
# In Netlify Dashboard:
# Site Settings → Identity → Enable Identity
```

**2. Add to `netlify.toml`:**
```toml
# Protect /ops/ with Netlify Identity
[[redirects]]
  from = "/ops/*"
  to = "/ops/:splat"
  status = 200
  force = true
  conditions = {Role = ["admin"]}
```

**3. Create admin user in Netlify Dashboard**

### **Option 3: Custom Auth with Environment Variables (Most Flexible)**

**1. Add environment variables in Netlify:**
```
Site Settings → Environment Variables → Add:
- DASHBOARD_USERNAME = "your-username"
- DASHBOARD_PASSWORD = "your-secure-password"
```

**2. Create `_headers` file in your dashboard root:**
```
/ops/*
  X-Robots-Tag: noindex
  Cache-Control: no-cache
```

**3. Add authentication middleware to your dashboard code:**

**For Next.js:**
```javascript
// middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  const basicAuth = request.headers.get('authorization');
  const url = request.nextUrl;

  if (url.pathname.startsWith('/ops')) {
    if (basicAuth) {
      const authValue = basicAuth.split(' ')[1];
      const [user, pwd] = atob(authValue).split(':');

      if (
        user === process.env.DASHBOARD_USERNAME &&
        pwd === process.env.DASHBOARD_PASSWORD
      ) {
        return NextResponse.next();
      }
    }

    return new NextResponse('Authentication required', {
      status: 401,
      headers: {
        'WWW-Authenticate': 'Basic realm="Secure Area"',
      },
    });
  }
}
```

**For Static Site:**
```javascript
// netlify/functions/auth-check.js
exports.handler = async (event) => {
  const authHeader = event.headers.authorization;
  
  if (!authHeader) {
    return {
      statusCode: 401,
      headers: {
        'WWW-Authenticate': 'Basic realm="Secure Area"'
      },
      body: 'Authentication required'
    };
  }

  const base64Credentials = authHeader.split(' ')[1];
  const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
  const [username, password] = credentials.split(':');

  if (
    username === process.env.DASHBOARD_USERNAME &&
    password === process.env.DASHBOARD_PASSWORD
  ) {
    return {
      statusCode: 200,
      body: JSON.stringify({ authenticated: true })
    };
  }

  return {
    statusCode: 401,
    body: 'Invalid credentials'
  };
};
```

---

## 🔧 **Step 4: Complete Setup**

### **1. Create/Update `netlify.toml`**

**Minimal secure setup:**
```toml
[build]
  publish = "dashboard"  # or "ops" if you renamed
  command = "npm run build"

# Redirect /ops/ to dashboard content
[[redirects]]
  from = "/ops/*"
  to = "/dashboard/:splat"
  status = 200
  force = true

# Password protection via headers
[[headers]]
  for = "/ops/*"
  [headers.values]
    X-Robots-Tag = "noindex"
    Cache-Control = "no-cache, no-store, must-revalidate"
```

### **2. Create `_headers` file**

```
/ops/*
  Basic-Auth: ${DASHBOARD_USERNAME}:${DASHBOARD_PASSWORD}
  X-Robots-Tag: noindex
  Cache-Control: no-cache
```

### **3. Set Environment Variables in Netlify**

```bash
# Go to: https://app.netlify.com/sites/veloready/settings/deploys#environment

Add variables:
- DASHBOARD_USERNAME = "admin"  # Choose your username
- DASHBOARD_PASSWORD = "your-secure-password-here"  # Choose strong password
```

### **4. Deploy**

```bash
# Commit changes
git add netlify.toml _headers
git commit -m "Add password protection to /ops/ dashboard"
git push origin main

# Netlify will auto-deploy
```

---

## 🧪 **Step 5: Test**

### **1. Test Authentication**
```bash
# Should prompt for username/password
open https://veloready.app/ops/

# Test with curl
curl -u admin:your-password https://veloready.app/ops/
```

### **2. Verify Protection**
- ✅ Visiting `/ops/` requires authentication
- ✅ Wrong credentials are rejected
- ✅ Correct credentials grant access
- ✅ Dashboard functions correctly

---

## 📊 **Recommended: Simple Basic Auth Setup**

**The easiest approach for private dashboard:**

### **1. Create `netlify.toml`:**
```toml
[build]
  publish = "dashboard"

[[redirects]]
  from = "/ops/*"
  to = "/dashboard/:splat"
  status = 200
  force = true

[[headers]]
  for = "/ops/*"
  [headers.values]
    X-Robots-Tag = "noindex"
```

### **2. Create `_redirects` file:**
```
/ops/* /dashboard/:splat 200
```

### **3. Add Basic Auth via Netlify UI:**
```
Site Settings → Access control → Visitor access
→ Enable password protection
→ Set password
```

This is the **simplest method** - Netlify handles everything!

---

## 🔒 **Security Best Practices**

### **Environment Variables:**
- ✅ Store credentials in Netlify environment variables
- ✅ Never commit passwords to git
- ✅ Use strong, unique passwords (20+ characters)
- ✅ Rotate passwords periodically

### **Access Control:**
- ✅ Use HTTPS only (Netlify provides this)
- ✅ Add `X-Robots-Tag: noindex` to prevent search indexing
- ✅ Set `Cache-Control: no-cache` for sensitive pages
- ✅ Consider IP whitelisting for extra security

### **Monitoring:**
- ✅ Enable Netlify Analytics
- ✅ Review access logs regularly
- ✅ Set up alerts for failed auth attempts

---

## ❓ **What I Need From You**

To proceed, please provide:

1. **Dashboard Repository Location:**
   - GitHub URL?
   - Branch name?
   - Is it in the main VeloReady repo or separate?

2. **Dashboard Technology:**
   - Static HTML/JS?
   - Next.js?
   - React?
   - Other framework?

3. **Preferred Auth Method:**
   - Simple: Netlify built-in password protection (easiest)
   - Medium: Basic Auth with environment variables
   - Advanced: Netlify Identity with user management

4. **Credentials:**
   - Desired username (e.g., "admin")
   - I'll help you set a secure password via env vars

---

## 🚀 **Quick Start (If Dashboard is Already Deployed)**

If the dashboard at `veloready.netlify.app/dashboard` is already working:

### **Fastest Path:**

1. **Go to Netlify Dashboard:**
   ```
   https://app.netlify.com/sites/veloready/settings/access
   ```

2. **Enable Password Protection:**
   - Click "Visitor access"
   - Enable "Password protection"
   - Set password
   - Save

3. **Add Redirect:**
   Create `_redirects` file:
   ```
   /ops/* /dashboard/:splat 200
   ```

4. **Deploy:**
   ```bash
   git add _redirects
   git commit -m "Add /ops/ redirect with password protection"
   git push
   ```

**Done!** Dashboard will be at `https://veloready.app/ops/` with password protection.

---

## 📞 **Next Steps**

Please tell me:
1. Where is the dashboard code located?
2. Which authentication method do you prefer?
3. Should I create the configuration files?

Then I can create the exact files you need and guide you through deployment! 🚀
