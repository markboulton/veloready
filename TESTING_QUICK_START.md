# Testing Quick Start Guide

**Goal:** Prevent bugs like the fitness trajectory chart issue through automated testing

---

## TL;DR

The recent bug (CTL/ATL/TSB showing 0) happened because:
1. Backend API authentication changed
2. iOS app couldn't fetch activities anymore
3. No automated tests caught the integration break

**Solution:** Add automated tests, focusing on **integration tests** between iOS and Backend.

---

## What Type of Testing Do We Need?

### 1. Integration Tests (CRITICAL - Start Here)

**What:** Test that iOS app can talk to Backend API

**Why:** Would have caught the fitness trajectory bug

**Example:**
```swift
@Test("Fetch activities works")
func testFetchActivities() async throws {
  let activities = try await VeloReadyAPIClient.shared.fetchActivities()
  #expect(activities.count >= 0) // Fails if auth is broken
}
```

**Effort:** 2 weeks  
**Priority:** 🔴 CRITICAL

### 2. End-to-End Tests (HIGH)

**What:** Simulate real user flows (open app → see training load → CTL/ATL/TSB displayed)

**Why:** Catches UI bugs and integration issues together

**Example:**
```yaml
- launchApp
- tapOn: "Today"
- assertVisible: "Training Load"
- assertVisible:
    id: "ctl-value"
    matches: "^(?!0$).*" # Not zero!
```

**Effort:** 3 weeks  
**Priority:** 🟡 HIGH

### 3. Component Tests (MEDIUM)

**What:** Test individual features (Recovery Score, Training Load Calculator, etc.)

**Why:** Catch logic bugs in calculations

**Example:**
```swift
@Test("CTL calculation")
func testCTL() {
  let calculator = TrainingLoadCalculator()
  let ctl = calculator.calculateCTL(dailyTSS: mockTSS)
  #expect(ctl > 0) // Would fail if calculation broken
}
```

**Effort:** 2 weeks  
**Priority:** 🟢 MEDIUM

### 4. Unit Tests (LOW)

**What:** Test pure functions and data models

**Why:** Catch simple logic errors

**Effort:** 1 week  
**Priority:** 🟢 LOW

---

## Recommended Testing Stack

### iOS
- **XCTest** or **Swift Testing** (built-in) - Unit/integration tests
- **Maestro** - UI automation (E2E tests)

### Backend
- **Vitest** - Fast testing for TypeScript
- **MSW** - Mock external APIs (Strava, Supabase)
- **Pact** - Contract testing between iOS ↔ Backend

### CI/CD
- **GitHub Actions** - Run tests on every PR
- **Pre-commit hooks** - Run linters and tests before committing

---

## Quick Start: Add Your First Test

### Backend Integration Test

```bash
cd /Users/mark.boulton/Documents/dev/veloready-website
npm install --save-dev vitest @vitest/ui
mkdir -p tests/integration
```

```typescript
// tests/integration/api.activities.test.ts
import { describe, it, expect } from 'vitest';
import { apiActivities } from '../../netlify/functions/api-activities';

describe('API: /api/activities', () => {
  it('should return activities for authenticated user', async () => {
    const mockRequest = {
      method: 'POST',
      headers: { Authorization: 'Bearer test-token' },
      body: JSON.stringify({ afterEpochSec: 0, page: 1 })
    };

    const response = await apiActivities(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toHaveProperty('activities');
  });

  it('should reject unauthenticated requests', async () => {
    const mockRequest = {
      method: 'POST',
      headers: {}, // No auth!
      body: JSON.stringify({ afterEpochSec: 0, page: 1 })
    };

    const response = await apiActivities(mockRequest);
    expect(response.status).toBe(401);
  });
});
```

```json
// package.json
{
  "scripts": {
    "test": "vitest",
    "test:integration": "vitest run tests/integration"
  }
}
```

**Run:**
```bash
npm run test:integration
```

### iOS Integration Test

```bash
cd /Users/mark.boulton/Documents/dev/veloready
```

Create new test file in Xcode:
- File → New → File → Unit Test Case Class
- Name: `VeloReadyAPIClientTests`
- Target: VeloReadyTests

```swift
// VeloReady/Tests/Integration/VeloReadyAPIClientTests.swift
import Testing
@testable import VeloReady

@Suite("VeloReady API Integration")
struct VeloReadyAPIClientTests {
    
    @Test("Fetch activities with authentication")
    func testFetchActivities() async throws {
        // Sign in test user
        try await TestHelpers.signInTestUser()
        
        // Fetch activities
        let client = VeloReadyAPIClient.shared
        let response = try await client.fetchActivities(afterEpochSec: 0, page: 1)
        
        // Verify response
        #expect(response.activities is [StravaActivity])
        #expect(response.athleteId > 0)
    }
    
    @Test("Fetch activities without auth fails gracefully")
    func testFetchActivitiesUnauthenticated() async {
        // Sign out
        SupabaseClient.shared.signOut()
        
        // Try to fetch
        let client = VeloReadyAPIClient.shared
        
        do {
            _ = try await client.fetchActivities(afterEpochSec: 0, page: 1)
            Issue.record("Expected error but call succeeded")
        } catch VeloReadyAPIError.notAuthenticated {
            // Expected - test passes ✅
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
```

**Run:**
```bash
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## GitHub Actions: Run Tests on Every PR

```yaml
# .github/workflows/tests.yml
name: Tests

on:
  pull_request:
  push:
    branches: [main]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run test:integration

  ios-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Run iOS tests
        run: |
          xcodebuild test \
            -scheme VeloReady \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## Pre-Commit Hooks: Catch Issues Before Committing

### Install Husky

```bash
# Backend repo
cd /Users/mark.boulton/Documents/dev/veloready-website
npm install --save-dev husky
npx husky install
npx husky add .husky/pre-commit "npm run test:integration"
```

```bash
# iOS repo
cd /Users/mark.boulton/Documents/dev/veloready
# Create .git/hooks/pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running SwiftLint..."
swiftlint lint --strict

echo "Running integration tests..."
xcodebuild test -scheme VeloReady -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:VeloReadyTests/Integration

if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Fix and try again."
  exit 1
fi

echo "✅ All checks passed!"
EOF

chmod +x .git/hooks/pre-commit
```

---

## Coverage Targets

| Repository | Target | Priority |
|------------|--------|----------|
| **Backend** | 80% | 🔴 CRITICAL |
| **iOS** | 70% | 🔴 HIGH |
| **Agents** | 50% | 🟢 LOW |

---

## How the Fitness Trajectory Bug Would Have Been Caught

### Integration Test (Backend)
```typescript
it('should return activities with valid auth', async () => {
  const response = await apiActivities(authenticatedRequest);
  expect(response.status).toBe(200); // ❌ FAILS with 401
});
```

### Integration Test (iOS)
```swift
@Test("Fetch activities works")
func testFetchActivities() async throws {
  let activities = try await client.fetchActivities()
  #expect(activities.count >= 0) // ❌ FAILS - throws error
}
```

### E2E Test
```yaml
- assertVisible:
    id: "ctl-value"
    matches: "^(?!0$).*" # Not zero
# ❌ FAILS - CTL shows 0
```

**All three would have failed in CI before deployment! ✅**

---

## Timeline

### Week 1-2: Integration Tests
- Set up Vitest (backend) and XCTest (iOS)
- Write tests for critical APIs
- Add GitHub Actions workflow

### Week 3-5: E2E Tests
- Set up Maestro for iOS UI automation
- Write critical user flow tests
- Add to CI pipeline

### Week 6-7: Component Tests
- Test individual services (Recovery, Strain, Training Load)
- Achieve 70% coverage

### Week 8: Unit Tests & Cleanup
- Add unit tests for pure functions
- Set up pre-commit hooks
- Document testing practices

---

## Cost

- **Initial investment:** 8 weeks (~320 hours)
- **Ongoing maintenance:** +20% per feature
- **CI/CD costs:** Free (GitHub Actions)
- **Monitoring:** $26/month (Sentry - optional)

**ROI:** Saves 10-20 hours/month debugging production bugs

---

## Next Steps

1. ✅ Review `TESTING_STRATEGY.md` for full details
2. ✅ Set up test environment (Supabase test DB, test Strava app)
3. ✅ Write first integration test (pick `/api/activities`)
4. ✅ Add GitHub Actions workflow
5. ✅ Gradually add more tests over 8 weeks

---

## Questions?

- "Which tests should I write first?" → **Integration tests for critical APIs**
- "How long will this take?" → **2 weeks for critical integration tests, 8 weeks for full coverage**
- "Is this overkill?" → **No! Would have caught the recent bug and saved hours of debugging**
- "Can I add tests gradually?" → **Yes! Start with integration tests, add more over time**

---

**See `TESTING_STRATEGY.md` for comprehensive implementation details.**

