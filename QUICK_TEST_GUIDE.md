# 🚀 Quick Cache Testing Guide (2 Minutes)

## Test Stream Cache (Most Important)

### ✅ Test 1: First Open
```
1. Force quit app
2. Launch
3. Open "2 x 10" ride
4. Wait for load (~3-5s)
5. Look for log: "💾 Cached X stream samples"
```

### ✅ Test 2: Second Open (In-Memory)
```
1. Go back
2. Open same ride again
3. Should load instantly
4. Look for: "⚡ Using cached stream data"
```

### ✅ Test 3: After Restart (THE BIG TEST)
```
1. Force quit app
2. Relaunch
3. Open SAME ride ("2 x 10")
4. Should load in <1s ⚡
5. Look for: "⚡ Stream cache HIT"
```

---

## Expected Logs

### ✅ GOOD (Cache Working):
```
⚡ Stream cache HIT: strava_16158393835 (10 samples, age: 2m)
⚡ Using cached stream data (10 samples)
⚡ Training Load: Using cached data (age: 5m, 22 activities)
```

### ❌ BAD (Cache Not Working):
```
📡 Cache miss - fetching from API
📊 [Data] ✅ Fetched 22 activities from Strava
```

---

## Success = Speed

| Test | Before | After | Status |
|------|--------|-------|--------|
| 1st open | 3-5s | 3-5s | ⏱️ (fetch) |
| 2nd open | 3-5s | **<500ms** | ⚡ (cached) |
| After restart | 3-5s | **<500ms** | ⚡ (cached) |

---

## Quick Check

Run app and open a ride 3 times:
1. **First:** Takes 3-5s (fetching) ✅
2. **Second:** Instant (<500ms) ✅
3. **After restart:** Fast (<1s) ✅

If #3 is slow → cache not working ❌

---

**That's it! If you see ⚡ symbols and fast loads, it's working!** 🎉
