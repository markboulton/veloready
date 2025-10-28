# Phase 2: End-to-End Testing

This directory contains E2E tests for VeloReady using Maestro for iOS UI automation.

## Overview

E2E tests simulate real user flows across the iOS app, backend API, and external services. These tests catch bugs that integration tests miss and validate real user experiences.

## Test Scenarios

### 1. Training Load Test (`training-load.yaml`)
**Critical test that would have caught the recent fitness trajectory bug**

- Verifies CTL/ATL/TSB are not zero
- Tests Fitness Trajectory chart has data
- Includes pull-to-refresh functionality
- Validates training load calculations

### 2. Onboarding Flow (`onboarding.yaml`)
**Tests new user signup and Strava connection**

- Welcome screen navigation
- Sport ranking selection (critical for AI personalization)
- HealthKit permission flow
- Strava OAuth integration
- Profile setup and subscription flow

### 3. Activity Sync (`activity-sync.yaml`)
**Tests manual activity sync and data loading**

- Pull-to-refresh functionality
- Activity list display
- Activity detail views
- Search and filter functionality

### 4. AI Brief Generation (`ai-brief.yaml`)
**Tests daily AI brief generation and display**

- Brief generation and loading states
- Detailed metrics display
- Error handling and retry logic
- Refresh functionality

### 5. Recovery Score (`recovery-score.yaml`)
**Tests recovery score calculation and breakdown**

- Recovery score display
- Detailed breakdown views
- Trend charts
- Metric detail views
- Different recovery states

## Running Tests

### Prerequisites

1. **Install Maestro:**
   ```bash
   brew tap mobile-dev-inc/tap
   brew install maestro
   ```

2. **Set up Java environment:**
   ```bash
   export JAVA_HOME=/opt/homebrew/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home
   ```

3. **Start iOS Simulator:**
   ```bash
   xcrun simctl boot "iPhone 17"
   ```

4. **Build and install VeloReady app:**
   ```bash
   xcodebuild build -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

### Running All Tests

```bash
cd tests/e2e
./run-e2e-tests.sh
```

### Running Individual Tests

```bash
# Training load test (most critical)
maestro test scenarios/training-load.yaml

# Onboarding flow
maestro test scenarios/onboarding.yaml

# Activity sync
maestro test scenarios/activity-sync.yaml

# AI brief generation
maestro test scenarios/ai-brief.yaml

# Recovery score
maestro test scenarios/recovery-score.yaml
```

### Running with Backend Mocking

```bash
# Start backend mocking server
cd /Users/mark.boulton/Documents/dev/veloready-website
npm run test:e2e:mock

# In another terminal, run E2E tests
cd /Users/mark.boulton/Documents/dev/veloready/tests/e2e
MAESTRO_MOCK_BACKEND=true ./run-e2e-tests.sh
```

## Test Configuration

### Maestro Configuration (`maestro.yaml`)

- App ID: `com.markboulton.veloready`
- Timeout: 30 seconds per action
- Clear state: true (fresh app state for each test)
- Parallel execution: false (run tests sequentially)

### Environment Variables

- `TEST_MODE=true` - Enables test mode in the app
- `MOCK_BACKEND=false` - Use real backend (set to true for mocked tests)
- `LOG_LEVEL=debug` - Verbose logging for debugging

## Backend Mocking

E2E tests can run against mocked backend APIs for faster, more reliable testing:

### Mock Server Setup

```typescript
// tests/e2e/backend-mock.ts
import { startE2EMocking, stopE2EMocking } from './backend-mock';

// Start mocking
startE2EMocking();

// Run tests...

// Stop mocking
stopE2EMocking();
```

### Mocked APIs

- `/api/activities` - Returns realistic activity data
- `/api/streams` - Returns power/HR stream data
- `/api/ai-brief` - Returns AI brief with metrics
- `/api/wellness` - Returns recovery metrics
- `/oauth/strava/*` - OAuth flow simulation

## CI/CD Integration

E2E tests run automatically on:
- Pull requests to main branch
- Pushes to main branch
- Manual workflow dispatch

### GitHub Actions Workflow

The workflow (`e2e-tests.yml`) includes:
- iOS Simulator setup
- Maestro installation
- App building and installation
- Test execution
- Artifact upload (screenshots, videos, logs)

## Debugging Failed Tests

### 1. Check Test Logs

```bash
maestro test scenarios/training-load.yaml --debug
```

### 2. View Screenshots

Screenshots are automatically captured on test failures and saved to:
- `tests/e2e/screenshots/`
- `tests/e2e/reports/`

### 3. Common Issues

**Simulator not responding:**
```bash
xcrun simctl shutdown "iPhone 17"
xcrun simctl boot "iPhone 17"
```

**App not installed:**
```bash
xcodebuild build -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 17'
```

**Java environment issues:**
```bash
export JAVA_HOME=/opt/homebrew/Cellar/openjdk/25.0.1/libexec/openjdk.jdk/Contents/Home
```

### 4. Test-Specific Debugging

**Training Load Test:**
- Verify app has activity data
- Check API authentication
- Ensure CTL/ATL/TSB calculations are working

**Onboarding Test:**
- Verify OAuth flow works
- Check HealthKit permissions
- Ensure profile setup completes

**Activity Sync Test:**
- Verify pull-to-refresh works
- Check activity data loading
- Ensure detail views display correctly

## Best Practices

### 1. Test Reliability

- Use explicit waits instead of arbitrary delays
- Test with realistic data
- Handle loading states properly
- Test error conditions

### 2. Test Maintenance

- Keep tests focused on user flows
- Avoid testing implementation details
- Use descriptive test names
- Document test assumptions

### 3. Performance

- Run tests in parallel when possible
- Use mocked backend for faster execution
- Clean up test data between runs
- Monitor test execution time

## Troubleshooting

### Maestro Issues

```bash
# Check Maestro version
maestro --version

# Check Java environment
echo $JAVA_HOME
java -version

# Reset Maestro cache
maestro clean
```

### iOS Simulator Issues

```bash
# List available simulators
xcrun simctl list devices

# Reset simulator
xcrun simctl erase "iPhone 17"

# Check simulator status
xcrun simctl list devices | grep "iPhone 17"
```

### App Installation Issues

```bash
# Check app bundle
ls -la /Users/mark.boulton/Library/Developer/Xcode/DerivedData/VeloReady-*/Build/Products/Debug-iphonesimulator/

# Rebuild app
xcodebuild clean build -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Future Enhancements

### Planned Improvements

1. **Parallel Test Execution** - Run multiple tests simultaneously
2. **Visual Regression Testing** - Compare screenshots across versions
3. **Performance Testing** - Measure app performance during tests
4. **Accessibility Testing** - Validate VoiceOver and accessibility features
5. **Cross-Device Testing** - Test on different iPhone models

### Test Coverage Expansion

1. **More User Flows** - Add tests for Trends, Settings, Profile
2. **Edge Cases** - Test offline mode, poor network, large datasets
3. **Error Scenarios** - Test API failures, network timeouts
4. **Performance Scenarios** - Test with large activity datasets

## References

- [Maestro Documentation](https://maestro.mobile.dev/)
- [iOS Simulator Guide](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator)
- [E2E Testing Best Practices](https://docs.cypress.io/guides/references/best-practices)
- [VeloReady Testing Strategy](../TESTING_STRATEGY.md)
