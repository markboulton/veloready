# VeloReady Testing - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Run Local Tests
```bash
# Quick test before pushing
./scripts/local-test.sh
```

### 2. Understanding the Tiers

#### Tier 1: Fast Feedback (5-10 min)
- **When**: Every push
- **What**: Lint + Unit tests
- **Why**: Immediate feedback, no blocking

#### Tier 2: Pre-Merge (15-30 min)
- **When**: PR ready for review
- **What**: Integration + E2E smoke tests
- **Why**: Prevent broken code in main

#### Tier 3: Post-Merge (30-60 min)
- **When**: After merging to main
- **What**: Full E2E suite + multi-device
- **Why**: Ensure main is always stable

### 3. Development Workflow

```bash
# Start new feature
git checkout main
git pull
git checkout -b feature/my-feature

# Code and test locally (Xcode 26 + iOS 26)
./scripts/local-test.sh  # Fast feedback

# Push for CI (Xcode 16.0 + iOS 18.0/19.0)
git push -u origin feature/my-feature

# Open PR when ready (triggers Tier 2)
# Merge when all checks pass (triggers Tier 3)
```

**Note**: Local development uses Xcode 26 with iOS 26, while CI uses Xcode 16.0 with iOS 18.0/19.0 simulators for compatibility.

## 🛠️ Available Commands

### Local Testing
```bash
# Run all Tier 1 tests
./scripts/local-test.sh

# Unit tests only
xcodebuild test -workspace VeloReady.xcworkspace -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Unit

# Integration tests only
xcodebuild test -workspace VeloReady.xcworkspace -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Integration

# Backend tests
cd ../veloready-website && npm test
```

### E2E Testing
```bash
# Run specific E2E scenario
maestro test tests/e2e/scenarios/training-load.yaml

# Run all E2E scenarios
maestro test tests/e2e/scenarios/

# Run E2E with backend mock
cd ../veloready-website && npm run test:e2e
```

## 📊 Test Coverage

### Unit Tests
- ✅ TrainingLoadCalculator
- ✅ VeloReadyAPIClient
- ✅ TestHelpers

### Integration Tests
- ✅ API Client integration
- ✅ Database operations
- ✅ Authentication flow

### E2E Tests
- ✅ Training load display
- ✅ User onboarding
- ✅ Activity synchronization
- ✅ AI brief generation
- ✅ Recovery score display

## 🔧 Troubleshooting

### Common Issues

#### "SwiftLint not installed"
```bash
brew install swiftlint
```

#### "Maestro not found"
```bash
brew tap mobile-dev-inc/tap
brew install maestro
```

#### "Java not found"
```bash
brew install openjdk@17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

#### "Tests failing locally but passing in CI"
- Check iOS Simulator is running
- Verify Xcode version matches CI
- Clear DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### Performance Tips

#### Speed up local testing
```bash
# Use specific simulator
xcrun simctl list devices

# Run tests on specific device
xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 15 Pro' ...

# Skip building if not needed
xcodebuild test -workspace VeloReady.xcworkspace -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Unit
```

#### Speed up CI
- Keep PRs focused (smaller changes = faster tests)
- Use draft PRs for work in progress
- Fix issues locally before pushing

## 📈 Monitoring

### GitHub Actions
- Check Actions tab for test results
- Green checkmark = all tests passed
- Red X = tests failed, check logs

### Test Results
- Unit tests: ~2-3 minutes
- Integration tests: ~5-8 minutes
- E2E smoke tests: ~10-15 minutes
- Full E2E suite: ~30-45 minutes

## 🎯 Best Practices

### Before Pushing
1. Run `./scripts/local-test.sh`
2. Fix any issues locally
3. Push when green

### Before Opening PR
1. Ensure all Tier 1 tests pass
2. Write clear PR description
3. Mark as "Ready for Review" when done

### After Merging
1. Monitor Tier 3 test results
2. Fix any issues immediately
3. Keep main branch stable

## 🚨 Emergency Procedures

### If Main Branch Breaks
1. **Immediate**: Revert the breaking commit
2. **Short-term**: Fix the issue in a hotfix branch
3. **Long-term**: Improve tests to catch the issue

### If Tests Are Flaky
1. **Immediate**: Disable the flaky test temporarily
2. **Short-term**: Fix the root cause
3. **Long-term**: Improve test reliability

### If CI Is Slow
1. **Immediate**: Check for resource constraints
2. **Short-term**: Optimize test execution
3. **Long-term**: Review test strategy

## 📚 Additional Resources

- [Testing Strategy](TESTING_STRATEGY_OPTIMIZED.md) - Detailed strategy document
- [E2E Test Scenarios](tests/e2e/README.md) - E2E test documentation
- [Backend Testing](../veloready-website/tests/README.md) - Backend test documentation
- [GitHub Actions Workflows](.github/workflows/) - CI/CD configuration

## 💡 Pro Tips

1. **Use draft PRs** for work in progress (only runs Tier 1)
2. **Keep PRs small** for faster feedback
3. **Test locally first** to avoid CI delays
4. **Monitor test trends** to catch regressions early
5. **Fix flaky tests immediately** to maintain trust

---

**Remember**: The goal is to develop rapidly while maintaining quality. The tiered approach ensures you get fast feedback when you need it and comprehensive testing when it matters most.
