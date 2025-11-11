# Pre-Commit Hook Update

## What Changed

The pre-commit hook (`.git/hooks/pre-commit`) has been updated to run the **comprehensive test suite** before allowing commits.

### Before
```bash
./Scripts/quick-test.sh  # Was running only quick tests
```

### After
```bash
./Scripts/full-test.sh   # Now runs ALL critical tests
```

## Why This Change?

With the new 3-tier testing system, we wanted to ensure:

1. **Fast iteration during development** → Use `quick-test.sh` or `super-quick-test.sh` manually
2. **Comprehensive validation before commit** → Pre-commit hook runs `full-test.sh` automatically

## What Runs in Pre-Commit Hook

The hook automatically runs **`./Scripts/full-test.sh`** which includes:

- ✅ Build validation (30s)
- ✅ All 5 critical test suites (28 tests, 60s)
  - CoreDataPersistenceTests (7 tests)
  - TrainingLoadCalculatorTests (5 tests)
  - RecoveryScoreTests (8 tests)
  - CacheManagerTests (4 tests)
  - MLModelRegistryTests (4 tests)
- ✅ Lint check (optional, 15s)

**Total time:** ~65-90 seconds

## Test Results

**Verified working:**
```bash
$ git commit -m "test: verify pre-commit hook"
🔍 Running pre-commit checks...

⚡ VeloReady Full Test (90 seconds max)
========================================
✅ Build successful
✅ All critical unit tests passed
✅ 🎉 Full test completed successfully in 65s!

✅ Pre-commit checks passed!
   Proceeding with commit...
```

## How to Use

### Normal Workflow (Automatic)

Just commit as usual - the hook runs automatically:

```bash
git add .
git commit -m "fix: your changes"
# Pre-commit hook runs full-test.sh automatically
# Commit proceeds only if all tests pass
```

### Bypass Hook (Emergency Only)

If you need to commit despite test failures:

```bash
git commit --no-verify -m "wip: emergency fix"
```

**⚠️ Warning:** Only use `--no-verify` in emergencies. The hook exists to prevent broken code from being committed.

## Development Workflow

The complete workflow with 3-tier testing:

```bash
# 1. During rapid development (10+ times/hour)
./Scripts/super-quick-test.sh  # 20s - build + smoke test

# 2. Feature complete (few times/day)
./Scripts/quick-test.sh  # 45s - build + essential tests

# 3. Ready to commit (automatic via hook)
git commit -m "feat: your feature"
# Pre-commit hook runs full-test.sh automatically (65-90s)
# ✅ All 28 critical tests must pass

# 4. Push to remote
git push
# CI runs complete test suite (5-10 minutes)
```

## Speed Tiers Summary

| Tier | Script | Time | Tests | Trigger | Purpose |
|------|--------|------|-------|---------|---------|
| Lightning | `super-quick-test.sh` | 20s | 5 | Manual | Rapid iteration |
| Quick | `quick-test.sh` | 45s | 13 | Manual | Active development |
| Full | `full-test.sh` | 65-90s | 28 | **Pre-commit hook** | Comprehensive validation |
| CI | All tests | 5-10m | All | `git push` | Complete suite |

## Files Modified

- `.git/hooks/pre-commit` - Updated to run `full-test.sh` instead of `quick-test.sh`

## Testing

The hook has been tested and verified:
- ✅ Runs automatically on `git commit`
- ✅ Blocks commits if tests fail
- ✅ Completes in ~65 seconds
- ✅ All 28 critical tests pass
- ✅ Can be bypassed with `--no-verify` if needed

---

**Result:** Pre-commit hook now provides comprehensive validation while still allowing fast iteration during development with the quick test tiers.
