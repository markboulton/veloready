# VeloReady Testing Strategy & Implementation Plan

**Date:** October 27, 2025  
**Status:** PROPOSED  
**Goal:** Prevent bugs like the fitness trajectory chart issue through automated testing

---

## Executive Summary

The recent fitness trajectory chart issue (CTL/ATL/TSB showing 0 values) resulted from authentication changes in the backend that broke the iOS app's API calls. This issue went undetected until manual testing revealed it. This document proposes a **comprehensive testing framework** across all three repositories (`veloready`, `veloready-website`, `veloready-agents`) to catch such issues automatically.

**Key Insight:** The bug wasn't in the code logic itself—it was in the **integration between systems** (iOS → Backend API → Authentication). This requires **integration and end-to-end tests**, not just unit tests.

---

## The Problem: What Went Wrong

### Anatomy of the Recent Bug

1. **Backend Change:** Caching was added to `listActivitiesSince()` in `veloready-website/netlify/lib/strava.ts`
2. **Unintended Side Effect:** The caching implementation or related authentication changes caused the iOS app's API calls to fail
3. **iOS Impact:** `TrainingLoadChart` couldn't fetch activities, resulting in 0 values for CTL/ATL/TSB
4. **Detection:** Only found through manual testing after deployment

### Why It Wasn't Caught

- ❌ No automated API integration tests
- ❌ No end-to-end tests simulating iOS app → Backend flow
- ❌ No contract testing between iOS and Backend
- ❌ No monitoring/alerting for API failures
- ❌ Backend changes deployed without iOS app smoke tests

---

## Testing Strategy: Multi-Layer Approach

We need **5 layers of testing** to prevent cross-repository bugs:

```
Layer 5: End-to-End Tests       (Full user flows across all systems)
Layer 4: Integration Tests      (API contracts between iOS ↔ Backend)
Layer 3: Component Tests        (Individual features in isolation)
Layer 2: Unit Tests            (Pure functions, calculations, models)
Layer 1: Static Analysis       (Linting, type checking, SwiftLint)
```

### Investment vs. Impact

| Layer | Initial Effort | Maintenance | Bug Prevention | Priority |
|-------|---------------|-------------|----------------|----------|
| **E2E Tests** | 40h | Medium | 🟢🟢🟢 Critical bugs | 🔴 HIGH |
| **Integration Tests** | 24h | Low | 🟢🟢🟢 API breaks | 🔴 CRITICAL |
| **Component Tests** | 16h | Medium | 🟢🟢 Feature bugs | 🟡 MEDIUM |
| **Unit Tests** | 12h | Low | 🟢 Logic bugs | 🟢 LOW |
| **Static Analysis** | 4h | Low | 🟢 Code quality | 🟢 LOW |

**Key Insight:** Focus on **Integration & E2E tests** first—they would have caught the fitness trajectory bug.

---

## Phase 1: Integration Testing (CRITICAL - 2 weeks)

### Goal
Catch breaking changes between iOS app and Backend API before deployment.

### Architecture

```
veloready-website/tests/integration/
├── api.activities.test.ts
├── api.streams.test.ts
├── api.ai-brief.test.ts
├── api.sync-batch.test.ts
├── auth.test.ts
└── fixtures/
    ├── mock-supabase-user.json
    └── mock-strava-activities.json
```

### Test Framework: Vitest (Backend) + XCTest (iOS)

**Backend Integration Tests:**

```typescript
// veloready-website/tests/integration/api.activities.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import { createMockRequest, createTestUser } from '../helpers';

describe('API: /api/activities', () => {
  let testUser: TestUser;
  let authToken: string;

  beforeAll(async () => {
    // Create test user in Supabase
    testUser = await createTestUser();
    authToken = await testUser.getAuthToken();
  });

  it('should return activities for authenticated user', async () => {
    const req = createMockRequest({
      method: 'POST',
      path: '/api/activities',
      headers: { Authorization: `Bearer ${authToken}` },
      body: { afterEpochSec: 0, page: 1 }
    });

    const response = await apiActivities(req);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toHaveProperty('activities');
    expect(Array.isArray(data.activities)).toBe(true);
  });

  it('should reject unauthenticated requests', async () => {
    const req = createMockRequest({
      method: 'POST',
      path: '/api/activities',
      headers: {}, // No auth token
      body: { afterEpochSec: 0, page: 1 }
    });

    const response = await apiActivities(req);
    expect(response.status).toBe(401);
  });

  it('should handle expired tokens gracefully', async () => {
    const expiredToken = await testUser.getExpiredToken();
    const req = createMockRequest({
      method: 'POST',
      path: '/api/activities',
      headers: { Authorization: `Bearer ${expiredToken}` },
      body: { afterEpochSec: 0, page: 1 }
    });

    const response = await apiActivities(req);
    expect(response.status).toBe(401);
    expect(await response.json()).toHaveProperty('error');
  });

  it('should return cached activities on second call', async () => {
    const req1 = createMockRequest({
      method: 'POST',
      path: '/api/activities',
      headers: { Authorization: `Bearer ${authToken}` },
      body: { afterEpochSec: 0, page: 1 }
    });

    // First call - cache miss
    const response1 = await apiActivities(req1);
    const data1 = await response1.json();

    // Second call - cache hit
    const req2 = createMockRequest({
      method: 'POST',
      path: '/api/activities',
      headers: { Authorization: `Bearer ${authToken}` },
      body: { afterEpochSec: 0, page: 1 }
    });
    const response2 = await apiActivities(req2);
    const data2 = await response2.json();

    expect(data1).toEqual(data2);
    expect(response2.headers.get('X-Cache')).toBe('HIT'); // Assuming we add cache headers
  });
});
```

**iOS API Contract Tests:**

```swift
// VeloReady/Tests/Integration/VeloReadyAPIClientTests.swift
import XCTest
import Testing
@testable import VeloReady

@Suite("VeloReady API Client Integration Tests")
struct VeloReadyAPIClientTests {
    
    @Test("Fetch activities with valid authentication")
    func testFetchActivitiesAuthenticated() async throws {
        let client = VeloReadyAPIClient.shared
        
        // Use test account credentials
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        let activities = try await client.fetchActivities(afterEpochSec: 0, page: 1)
        
        #expect(activities.activities.count >= 0) // May be empty for new user
        #expect(activities.athleteId == testUser.athleteId)
    }
    
    @Test("Fetch activities without authentication fails gracefully")
    func testFetchActivitiesUnauthenticated() async throws {
        let client = VeloReadyAPIClient.shared
        
        // Ensure no auth token
        SupabaseClient.shared.signOut()
        
        do {
            _ = try await client.fetchActivities(afterEpochSec: 0, page: 1)
            Issue.record("Expected error but call succeeded")
        } catch VeloReadyAPIError.notAuthenticated {
            // Expected - test passes
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test("Fetch activities returns data matching backend schema")
    func testFetchActivitiesSchema() async throws {
        let client = VeloReadyAPIClient.shared
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        let response = try await client.fetchActivities(afterEpochSec: 0, page: 1)
        
        // Validate schema matches backend contract
        #expect(response.activities is [StravaActivity])
        if let firstActivity = response.activities.first {
            #expect(firstActivity.id != nil)
            #expect(firstActivity.name != nil)
            #expect(firstActivity.startDate != nil)
            // If activity has power data, validate structure
            if firstActivity.hasPower {
                #expect(firstActivity.averageWatts != nil)
                #expect(firstActivity.normalizedPower != nil)
            }
        }
    }
}
```

### CI/CD Integration

**GitHub Actions Workflow:**

```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  backend-integration:
    runs-on: ubuntu-latest
    environment: Test
    
    steps:
      - uses: actions/checkout@v4
        with:
          repository: markboulton/veloready-website
          
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run integration tests
        run: npm run test:integration
        env:
          SUPABASE_URL: ${{ secrets.TEST_SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.TEST_SUPABASE_KEY }}
          STRAVA_CLIENT_ID: ${{ secrets.TEST_STRAVA_CLIENT_ID }}
          STRAVA_CLIENT_SECRET: ${{ secrets.TEST_STRAVA_CLIENT_SECRET }}
          
  ios-integration:
    runs-on: macos-14
    
    steps:
      - uses: actions/checkout@v4
        with:
          repository: markboulton/veloready
          
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
          
      - name: Run integration tests
        run: |
          xcodebuild test \
            -scheme VeloReady \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -only-testing:VeloReadyTests/Integration \
            -resultBundlePath ./test-results.xcresult
            
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: integration-test-results
          path: ./test-results.xcresult
```

### Contract Testing with Pact

For even stronger guarantees, implement **Pact** contract testing:

```typescript
// veloready-website/tests/pacts/activities.pact.test.ts
import { Pact } from '@pact-foundation/pact';

describe('Activities API Contract', () => {
  const provider = new Pact({
    consumer: 'VeloReadyiOSApp',
    provider: 'VeloReadyBackend'
  });

  it('should fetch activities matching iOS expectations', async () => {
    await provider.addInteraction({
      uponReceiving: 'a request for activities',
      withRequest: {
        method: 'POST',
        path: '/api/activities',
        headers: { Authorization: 'Bearer validToken' },
        body: { afterEpochSec: 0, page: 1 }
      },
      willRespondWith: {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          activities: Pact.eachLike({
            id: Pact.like(123456789),
            name: Pact.like('Morning Ride'),
            distance: Pact.like(25000),
            moving_time: Pact.like(3600),
            average_watts: Pact.like(200),
            normalized_power: Pact.like(210),
            start_date: Pact.iso8601DateTime()
          }),
          athleteId: Pact.like(987654321)
        }
      }
    });

    // Test that iOS client can handle this response
    // ...
  });
});
```

---

## Phase 2: End-to-End Testing (HIGH - 3 weeks)

### Goal
Simulate real user flows across iOS app, backend API, and external services (Strava, Supabase).

### Architecture

```
veloready-agents/tests/e2e/
├── scenarios/
│   ├── onboarding.spec.ts
│   ├── activity-sync.spec.ts
│   ├── training-load-calculation.spec.ts
│   ├── ai-brief-generation.spec.ts
│   └── recovery-score.spec.ts
└── helpers/
    ├── ios-simulator.ts
    ├── backend-client.ts
    └── test-data-factory.ts
```

### Test Framework: Maestro (iOS UI Automation) + Playwright (Web)

**Example: Training Load Calculation E2E Test**

```yaml
# veloready-agents/tests/e2e/scenarios/training-load.yaml
appId: com.markboulton.veloready
---
- launchApp
- tapOn: "Today"
- assertVisible: "Training Load"

# Verify CTL/ATL/TSB are not zero
- assertVisible: 
    id: "ctl-value"
    matches: "^(?!0$).*" # Not zero

- assertVisible:
    id: "atl-value"
    matches: "^(?!0$).*"

- assertVisible:
    id: "tsb-value"
    matches: "^-?(?!0$).*" # Not zero (can be negative)

# Navigate to activity detail
- tapOn: "Recent Activities"
- tapOn:
    index: 0 # First activity

- assertVisible: "Fitness Trajectory"
- assertVisible: "CTL"
- assertVisible: "ATL"
- assertVisible: "TSB"

# Verify chart has data points
- assertVisible:
    id: "fitness-chart"
    matches: ".*data-points.*"
```

**Run with:**
```bash
maestro test tests/e2e/scenarios/training-load.yaml
```

### Backend Mocking for E2E Tests

```typescript
// veloready-agents/tests/e2e/helpers/backend-mock.ts
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

export const mockBackend = setupServer(
  http.post('/api/activities', async ({ request }) => {
    const authHeader = request.headers.get('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return HttpResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    return HttpResponse.json({
      activities: [
        {
          id: 123456789,
          name: 'Morning Ride',
          distance: 25000,
          moving_time: 3600,
          average_watts: 200,
          normalized_power: 210,
          start_date: '2025-10-27T06:00:00Z',
          type: 'Ride'
        }
      ],
      athleteId: 987654321
    });
  }),
  
  http.post('/api/ai-brief', async ({ request }) => {
    return HttpResponse.json({
      brief: 'Great recovery! Ready for 50 TSS Z2 ride today.',
      cached: false
    });
  })
);
```

---

## Phase 3: Component Testing (MEDIUM - 2 weeks)

### Goal
Test individual features (Recovery Score, Strain Score, AI Brief) in isolation.

### Architecture

```
VeloReady/Tests/Components/
├── RecoveryScoreTests.swift
├── StrainScoreTests.swift
├── SleepScoreTests.swift
├── TrainingLoadCalculatorTests.swift
└── ActivityConverterTests.swift
```

### Example: Training Load Calculator Tests

```swift
// VeloReady/Tests/Components/TrainingLoadCalculatorTests.swift
import Testing
@testable import VeloReady

@Suite("Training Load Calculator")
struct TrainingLoadCalculatorTests {
    
    @Test("Calculate CTL from daily TSS")
    func testCTLCalculation() {
        let calculator = TrainingLoadCalculator()
        
        // Mock 42 days of TSS data (consistent 50 TSS/day)
        let dailyTSS: [Date: Double] = (0..<42).reduce(into: [:]) { result, dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            result[date] = 50.0
        }
        
        let ctl = calculator.calculateCTL(dailyTSS: dailyTSS)
        
        // CTL should converge towards daily TSS (50) with 42-day decay
        #expect(ctl > 45.0 && ctl < 52.0)
    }
    
    @Test("Calculate ATL from recent TSS")
    func testATLCalculation() {
        let calculator = TrainingLoadCalculator()
        
        // Mock last 7 days: 100 TSS/day (hard training block)
        let dailyTSS: [Date: Double] = (0..<7).reduce(into: [:]) { result, dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            result[date] = 100.0
        }
        
        let atl = calculator.calculateATL(dailyTSS: dailyTSS)
        
        // ATL should converge towards daily TSS (100) with 7-day decay
        #expect(atl > 85.0 && atl < 100.0)
    }
    
    @Test("TSB calculation (CTL - ATL)")
    func testTSBCalculation() {
        let calculator = TrainingLoadCalculator()
        
        let ctl = 60.0
        let atl = 70.0
        
        let tsb = calculator.calculateTSB(ctl: ctl, atl: atl)
        
        #expect(tsb == -10.0) // Negative TSB = fatigued
    }
    
    @Test("Calculate TSS from power data")
    func testTSSFromPower() {
        let calculator = TrainingLoadCalculator()
        
        let activity = MockActivity(
            duration: 3600, // 1 hour
            averageWatts: 200,
            normalizedPower: 210,
            ftp: 250
        )
        
        let tss = calculator.calculateTSS(activity: activity)
        
        // TSS = (3600 * 210 * (210/250)) / (250 * 3600) * 100
        // TSS ≈ 70.56
        #expect(tss > 68.0 && tss < 73.0)
    }
    
    @Test("Calculate TSS from heart rate (no power)")
    func testTSSFromHeartRate() {
        let calculator = TrainingLoadCalculator()
        
        let activity = MockActivity(
            duration: 3600, // 1 hour
            averageHeartRate: 150,
            maxHeartRate: 185,
            restingHeartRate: 55
        )
        
        let tss = calculator.calculateTSS(activity: activity)
        
        // TRIMP-based estimation
        #expect(tss > 40.0 && tss < 80.0)
    }
    
    @Test("CTL, ATL, TSB with zero values should return 0")
    func testZeroTSSHandling() {
        let calculator = TrainingLoadCalculator()
        
        let emptyTSS: [Date: Double] = [:]
        
        let ctl = calculator.calculateCTL(dailyTSS: emptyTSS)
        let atl = calculator.calculateATL(dailyTSS: emptyTSS)
        let tsb = calculator.calculateTSB(ctl: ctl, atl: atl)
        
        #expect(ctl == 0.0)
        #expect(atl == 0.0)
        #expect(tsb == 0.0)
    }
}
```

---

## Phase 4: Unit Testing (LOW - 1 week)

### Goal
Test pure functions, calculations, and data models.

### Example: Activity Converter Unit Tests

```swift
// VeloReady/Tests/Unit/ActivityConverterTests.swift
import Testing
@testable import VeloReady

@Suite("Activity Converter")
struct ActivityConverterTests {
    
    @Test("Convert Strava activity to IntervalsActivity")
    func testStravaToIntervalsConversion() {
        let stravaActivity = StravaActivity(
            id: 123456789,
            name: "Morning Ride",
            distance: 25000, // meters
            movingTime: 3600, // seconds
            elevationGain: 300, // meters
            type: "Ride",
            startDate: Date(),
            averageWatts: 200,
            normalizedPower: 210,
            averageHeartrate: 150,
            maxHeartrate: 175
        )
        
        let intervalsActivity = ActivityConverter.convert(stravaActivity)
        
        #expect(intervalsActivity.id == "strava-123456789")
        #expect(intervalsActivity.name == "Morning Ride")
        #expect(intervalsActivity.distance == 25.0) // Converted to km
        #expect(intervalsActivity.duration == 3600)
        #expect(intervalsActivity.elevation == 300)
        #expect(intervalsActivity.avgPower == 200)
        #expect(intervalsActivity.npPower == 210)
        #expect(intervalsActivity.avgHr == 150)
        #expect(intervalsActivity.maxHr == 175)
    }
    
    @Test("Enrich activity with TSS calculation")
    func testActivityEnrichment() async {
        let activity = IntervalsActivity(
            id: "test-123",
            name: "Test Ride",
            duration: 3600,
            avgPower: 200,
            npPower: 210
        )
        
        let userFTP = 250.0
        
        let enriched = await ActivityConverter.enrich(activity, ftp: userFTP)
        
        #expect(enriched.tss != nil)
        #expect(enriched.tss! > 0)
        #expect(enriched.intensityFactor != nil)
        #expect(enriched.intensityFactor! == 210 / 250) // NP / FTP
    }
}
```

---

## Phase 5: Static Analysis & Linting (LOW - 1 day)

### Already Implemented ✅

You already have:
- SwiftLint for iOS code quality
- TypeScript for backend type safety
- ESLint for JavaScript/TypeScript linting

### Additional Recommendations

**Add Pre-Commit Hooks:**

```bash
# .husky/pre-commit (iOS repo)
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running SwiftLint..."
swiftlint lint --strict

if [ $? -ne 0 ]; then
  echo "❌ SwiftLint failed. Fix errors and try again."
  exit 1
fi

echo "Running unit tests..."
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Unit

if [ $? -ne 0 ]; then
  echo "❌ Unit tests failed. Fix errors and try again."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
```

```bash
# .husky/pre-commit (Backend repo)
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running ESLint..."
npm run lint

if [ $? -ne 0 ]; then
  echo "❌ ESLint failed. Fix errors and try again."
  exit 1
fi

echo "Running TypeScript type check..."
npm run type-check

if [ $? -ne 0 ]; then
  echo "❌ Type check failed. Fix errors and try again."
  exit 1
fi

echo "Running unit tests..."
npm run test:unit

if [ $? -ne 0 ]; then
  echo "❌ Unit tests failed. Fix errors and try again."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
```

---

## Implementation Timeline

### Week 1-2: Integration Tests (CRITICAL)
- [ ] Set up Vitest for backend integration tests
- [ ] Create test Supabase database and test users
- [ ] Write API contract tests for 6 critical endpoints:
  - `/api/activities`
  - `/api/streams`
  - `/api/ai-brief`
  - `/api/sync-batch`
  - `/oauth/strava/start`
  - `/oauth/strava/token-exchange`
- [ ] Set up XCTest integration suite for iOS
- [ ] Write iOS API client integration tests
- [ ] Configure GitHub Actions for automated integration tests

### Week 3-4: E2E Tests (HIGH)
- [ ] Set up Maestro for iOS UI automation
- [ ] Write critical user flow scenarios:
  - Onboarding & Strava connection
  - Activity sync & training load calculation
  - AI brief generation
  - Recovery score calculation
- [ ] Set up backend mocking with MSW
- [ ] Configure E2E test pipeline in CI

### Week 5-6: Component Tests (MEDIUM)
- [ ] Write component tests for:
  - `TrainingLoadCalculator`
  - `RecoveryScoreService`
  - `StrainScoreService`
  - `SleepScoreService`
  - `ActivityConverter`
- [ ] Achieve 70%+ code coverage for core services

### Week 7: Unit Tests & Static Analysis (LOW)
- [ ] Write unit tests for pure functions and models
- [ ] Set up pre-commit hooks
- [ ] Add TypeScript strict mode
- [ ] Configure SwiftLint strict mode

---

## Recommended Testing Tools

### iOS (Swift)
- **XCTest** (built-in) - Unit, integration, and UI tests
- **Swift Testing** (iOS 18+) - Modern testing framework with `@Test` macro
- **Maestro** - Cross-platform UI automation (better than XCUITest)
- **Quick/Nimble** (optional) - BDD-style testing for Swift

### Backend (TypeScript/JavaScript)
- **Vitest** - Fast unit and integration testing (Vite-powered)
- **MSW (Mock Service Worker)** - API mocking for integration tests
- **Pact** - Contract testing between iOS and Backend
- **Playwright** (optional) - For web UI testing (ops dashboard)

### E2E & Monitoring
- **Maestro** - iOS UI automation
- **Sentry** - Error tracking and performance monitoring (recommended in backend audit)
- **BrowserStack/TestFlight** - Real device testing

### CI/CD
- **GitHub Actions** - Already in use, perfect for automated testing
- **Netlify Deploy Previews** - Test backend changes before production
- **TestFlight** - Distribute beta builds with integration tests

---

## Success Metrics

### Code Coverage Targets

| Repository | Target | Current | Priority |
|------------|--------|---------|----------|
| **veloready (iOS)** | 70% | ~0% | 🔴 HIGH |
| **veloready-website (Backend)** | 80% | ~0% | 🔴 CRITICAL |
| **veloready-agents** | 50% | ~0% | 🟢 LOW |

### Test Execution Time Targets

- Unit Tests: <10 seconds
- Component Tests: <30 seconds
- Integration Tests: <2 minutes
- E2E Tests: <10 minutes

### Bug Prevention Metrics

**Goal:** Catch 90% of cross-repository bugs before production

**How to Measure:**
1. Track bugs found in production vs. caught by tests
2. Monitor test failure rate in CI
3. Track time to detect bugs (production vs. CI)

---

## Cost & Maintenance

### Initial Investment
- **Phase 1 (Integration):** 2 weeks (~80 hours) - **CRITICAL**
- **Phase 2 (E2E):** 3 weeks (~120 hours) - **HIGH**
- **Phase 3 (Component):** 2 weeks (~80 hours) - **MEDIUM**
- **Phase 4 (Unit):** 1 week (~40 hours) - **LOW**
- **Total:** 8 weeks (~320 hours)

### Ongoing Maintenance
- Add tests for new features: +20% development time
- Update tests when APIs change: ~2 hours/month
- Fix flaky tests: ~1 hour/month
- Review test coverage reports: 30 minutes/week

### CI/CD Costs
- GitHub Actions (Free tier): 2,000 minutes/month (sufficient)
- Netlify Deploy Previews: Free
- TestFlight: Free
- Sentry: $26/month (recommended)

**Total Monthly Cost:** ~$26/month (Sentry only)

---

## Preventing the Recent Bug: A Retrospective

### How Tests Would Have Caught It

**Integration Test (Backend):**
```typescript
it('should return activities with valid authentication', async () => {
  const response = await apiActivities(authenticatedRequest);
  expect(response.status).toBe(200); // Would fail with 401
});
```
✅ **Would have failed** when authentication broke

**Integration Test (iOS):**
```swift
@Test("Fetch activities with valid auth")
func testFetchActivities() async throws {
  let activities = try await client.fetchActivities()
  #expect(activities.count > 0) // Would fail with empty array
}
```
✅ **Would have failed** when API returned 401

**E2E Test:**
```yaml
- assertVisible: "Training Load"
- assertVisible:
    id: "ctl-value"
    matches: "^(?!0$).*" # Not zero
```
✅ **Would have failed** when CTL showed 0

### Deployment Gate

**Proposed Rule:** Don't deploy if integration tests fail

```yaml
# .github/workflows/deploy.yml
jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - run: npm run test:integration
      
  deploy:
    needs: integration-tests # Block deploy if tests fail
    if: success()
    runs-on: ubuntu-latest
    steps:
      - run: netlify deploy --prod
```

---

## Next Steps

### Immediate Action Items

1. **Set up test environment** (1 day)
   - Create test Supabase database
   - Create test Strava app
   - Configure test secrets in GitHub

2. **Write first integration test** (1 day)
   - Pick the most critical API: `/api/activities`
   - Write both backend and iOS tests
   - Configure CI to run on every PR

3. **Add pre-commit hooks** (2 hours)
   - SwiftLint for iOS
   - ESLint for backend
   - Run unit tests before commit

4. **Gradual rollout** (8 weeks)
   - Phase 1: Integration tests
   - Phase 2: E2E tests
   - Phase 3: Component tests
   - Phase 4: Unit tests

### Decision Points

**Question 1:** Start with integration tests or E2E tests?  
**Recommendation:** Integration tests first—faster to write and run, catch most cross-repo bugs.

**Question 2:** Which tests are mandatory before merging PRs?  
**Recommendation:** Integration tests only. Component/unit tests can be optional initially.

**Question 3:** Should we pause feature development to add tests?  
**Recommendation:** Hybrid approach—add integration tests this week (Phase 1), then add tests incrementally with new features.

---

## Conclusion

The fitness trajectory bug was a **preventable integration failure** between iOS and Backend. By implementing a comprehensive testing strategy with emphasis on **integration and E2E tests**, we can catch such issues automatically before they reach production.

**Key Takeaways:**

1. ✅ **Integration tests are CRITICAL** for multi-repo projects
2. ✅ **E2E tests catch user-impacting bugs** that unit tests miss
3. ✅ **CI/CD gates prevent broken code from deploying**
4. ✅ **Invest in tests incrementally**—start with high-value integration tests

**Estimated ROI:**
- 8 weeks upfront investment
- Prevents 90% of cross-repo bugs
- Saves 10-20 hours/month debugging production issues
- Pays for itself in 3-6 months

**Next Step:** Review and approve this strategy, then start with Phase 1 (Integration Tests) immediately.

---

**Questions? Let's discuss the implementation approach and prioritization.**

