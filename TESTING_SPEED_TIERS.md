# Testing Speed Tiers - Solo Developer Optimized

## Problem
The original `quick-test.sh` was running 5 test suites (28 tests total) which took too long for rapid iteration during solo development, hampering development speed.

## Solution: 3-Tier Testing System

### ⚡ Lightning Tier: `./Scripts/super-quick-test.sh` (~20s)
**Purpose:** Rapid iteration during active coding

**What it runs:**
- ✅ Build validation (15s)
- ✅ 1 smoke test suite (TrainingLoadCalculatorTests - 5 tests)

**When to use:**
- During rapid feature development
- After small code changes
- Multiple times per hour

**Test count:** 5 tests

---

### 🚀 Quick Tier: `./Scripts/quick-test.sh` (~45s)
**Purpose:** Fast feedback during development

**What it runs:**
- ✅ Build validation (15s)
- ✅ 2 essential test suites (13 tests)
  - TrainingLoadCalculatorTests (5 tests)
  - RecoveryScoreTests (8 tests)
- ✅ Lint check (optional, 15s)

**When to use:**
- After completing a feature
- Before taking a break
- A few times per day

**Test count:** 13 tests

**Reduced from original:** Was 28 tests, now 13 tests (54% faster)

---

### 🎯 Full Tier: `./Scripts/full-test.sh` (~90s)
**Purpose:** Comprehensive validation before commit

**What it runs:**
- ✅ Build validation (30s)
- ✅ All 5 critical test suites (28 tests)
  - CoreDataPersistenceTests (7 tests)
  - TrainingLoadCalculatorTests (5 tests)
  - RecoveryScoreTests (8 tests)
  - CacheManagerTests (4 tests)
  - MLModelRegistryTests (4 tests)
- ✅ Lint check (optional, 15s)

**When to use:**
- **BEFORE every commit** (mandatory)
- Before pushing to remote
- Once or twice per day

**Test count:** 28 tests

**This is the original quick-test.sh scope**

---

## Why This Works

### Speed vs Coverage Trade-off
| Tier | Time | Tests | Coverage | Use Case |
|------|------|-------|----------|----------|
| Lightning | 20s | 5 | Smoke | Rapid iteration |
| Quick | 45s | 13 | Essential | Active development |
| Full | 90s | 28 | Critical | Pre-commit |
| CI | 5-10m | All | Complete | Pre-merge |

### Development Workflow

```bash
# 1. Start coding
vim RecoveryScoreService.swift

# 2. Quick validation (run 5-10 times/hour)
./Scripts/super-quick-test.sh  # 20s

# 3. Feature complete, test essential paths
./Scripts/quick-test.sh  # 45s

# 4. Before commit, comprehensive validation
./Scripts/full-test.sh  # 90s

# 5. Commit and push
git commit -m "fix: recovery detail shows full data"
git push

# 6. CI runs full suite (all tests, integration, E2E)
# Wait for green check, then merge/ship
```

### Key Insight: Test Distribution

**Tests excluded from quick tier (but still in full tier):**
- `CoreDataPersistenceTests` - Contains slow concurrent tests
- `CacheManagerTests` - Cache invalidation tests can be slow
- `MLModelRegistryTests` - Model loading overhead

**Why keep TrainingLoad + RecoveryScore in quick tier:**
- Pure calculation tests (fast, no I/O)
- Cover the most critical business logic
- Recently added RecoveryScore validation tests (relevant to current work)

---

## Solo Developer Benefits

### Time Savings
- **Before:** Run 28 tests every time = 90s per run
- **After (lightning):** Run 5 tests = 20s per run
- **After (quick):** Run 13 tests = 45s per run

**If you run tests 10 times/hour during active coding:**
- Old way: 10 × 90s = 15 minutes/hour
- New way (lightning): 10 × 20s = 3.3 minutes/hour
- **Savings: 11.7 minutes/hour = 78% faster**

### Reduced Friction
- No "ugh, tests take too long" mental resistance
- Encourages more frequent testing
- Catch bugs earlier in smaller increments

### Still Safe
- Full test suite runs before commit (mandatory)
- CI runs complete suite before merge
- Nothing is skipped, just deferred to appropriate tier

---

## Test Suite Details

### TrainingLoadCalculatorTests (5 tests) - FAST ⚡
```
✓ Calculate training load from activities
✓ Calculate progressive training load
✓ Get daily TSS from activities
✓ Calculate TSB (form)
✓ Empty activities handling
```
**Speed:** ~5 seconds
**Why fast:** Pure calculations, no I/O

### RecoveryScoreTests (8 tests) - FAST ⚡
```
✓ Recovery score initialization
✓ Recovery score validation
✓ Recovery band calculation
✓ Missing data handling
✓ All recovery bands exist
✓ Complete recovery score validation
✓ Incomplete recovery score detection
✓ Recovery score cache validation logic
```
**Speed:** ~10 seconds
**Why fast:** Model validation, no database or API calls

### CoreDataPersistenceTests (7 tests) - SLOW 🐌
```
✓ Save recovery score with nil HRV
✓ Save recovery score with zero values
✓ Fetch distinguishes nil from zero
✓ Historical data preservation
✓ Batch save preserves all records
✓ Cache invalidation targeted
✓ Concurrent reads (SLOW!)
```
**Speed:** ~30 seconds
**Why slow:** Database operations, concurrent tests

### CacheManagerTests (4 tests) - MODERATE 🔄
```
✓ Cache manager basic operations
✓ Cache expiration
✓ Cache invalidation
✓ Memory pressure handling
```
**Speed:** ~10 seconds

### MLModelRegistryTests (4 tests) - MODERATE 🔄
```
✓ ML model registration
✓ Model versioning
✓ Model feature validation
✓ Disabled when no data
```
**Speed:** ~10 seconds

---

## When to Add New Tests

### Add to Lightning Tier (super-quick)
- ❌ Never add here - it's intentionally minimal
- Keep as smoke test only

### Add to Quick Tier
- ✅ Pure calculation tests
- ✅ Model validation tests
- ✅ Fast business logic tests
- ❌ Database or API tests
- ❌ Concurrent tests
- ❌ Heavy I/O tests

### Add to Full Tier
- ✅ Database persistence tests
- ✅ Cache invalidation tests
- ✅ Concurrent operation tests
- ✅ Integration tests
- ✅ Any test that takes >2 seconds

### Add to CI Only
- ✅ E2E tests
- ✅ UI tests
- ✅ Network integration tests
- ✅ Performance benchmarks

---

## Migrating Existing Projects

If you have an existing project with slow tests:

1. **Measure test times:**
   ```bash
   xcodebuild test -only-testing:MyTests | grep "Test Case"
   ```

2. **Categorize tests by speed:**
   - Fast (<2s): Quick tier
   - Moderate (2-5s): Full tier
   - Slow (>5s): Full tier or CI only

3. **Create 3 scripts:**
   - `super-quick-test.sh`: Build + 1-2 fastest suites
   - `quick-test.sh`: Build + 3-5 fast suites
   - `full-test.sh`: Build + all critical suites

4. **Update pre-commit hook:**
   ```bash
   # .git/hooks/pre-commit
   ./Scripts/full-test.sh
   ```

---

## Results

### Before (Original quick-test.sh)
- **Time:** 90 seconds
- **Tests:** 28
- **Usage:** Reluctant (too slow)
- **Frequency:** 1-2 times/day

### After (New system)
- **Lightning:** 20s, 5 tests → 10+ times/hour
- **Quick:** 45s, 13 tests → 5+ times/hour
- **Full:** 90s, 28 tests → Before every commit

### Impact
- ✅ 78% faster for rapid iteration
- ✅ More frequent testing = catch bugs earlier
- ✅ Less mental friction
- ✅ Same comprehensive coverage before commit
- ✅ Perfect for solo development

---

## Commands Summary

```bash
# Development iteration (use most frequently)
./Scripts/super-quick-test.sh  # 20s - build + smoke test

# Active development (use several times/day)
./Scripts/quick-test.sh  # 45s - build + essential tests

# Before commit (mandatory)
./Scripts/full-test.sh  # 90s - all critical tests

# CI handles the rest
# - All unit tests
# - Integration tests
# - E2E tests
# - Performance benchmarks
```

---

**Remember:** Speed tiers are about **when** you run tests, not **whether** you run them. All tests still run before code is merged, just at the appropriate stage of development.
