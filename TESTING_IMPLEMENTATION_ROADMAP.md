# VeloReady Testing Implementation Roadmap

**Date:** October 27, 2025  
**Goal:** Implement comprehensive testing framework to prevent cross-repository bugs  
**Timeline:** 8 weeks  
**Code Examples:** See `TESTING_STRATEGY.md` and `TESTING_QUICK_START.md`

---

## Executive Summary

This roadmap provides a step-by-step plan to implement automated testing across all three VeloReady repositories. The focus is on **integration tests first** (highest ROI), followed by E2E, component, and unit tests.

**Key Insight:** The recent fitness trajectory bug was an integration failure between iOS and Backend that unit tests alone would NOT have caught. Integration and E2E tests are critical for multi-repository projects.

---

## Overview: 4 Phases Over 8 Weeks

| Phase | Priority | Duration | Focus | Deliverable |
|-------|----------|----------|-------|-------------|
| **1** | 🔴 CRITICAL | 2 weeks | Integration Tests | 6 critical APIs tested |
| **2** | 🟡 HIGH | 3 weeks | E2E Tests | 5 user flows tested |
| **3** | 🟢 MEDIUM | 2 weeks | Component Tests | 70% service coverage |
| **4** | 🟢 LOW | 1 week | Unit Tests & Polish | Complete framework |

---

## Phase 1: Integration Tests (CRITICAL)

**Duration:** 2 weeks (Weeks 1-2)  
**Priority:** 🔴 CRITICAL  
**Goal:** Test that iOS app can communicate with Backend API

**Why Start Here:**
- Would have caught the fitness trajectory bug
- Highest ROI (catches cross-repository breaks)
- Fastest to implement
- Most critical for multi-repo projects

### Week 1: Setup & First Tests

#### Day 1: Infrastructure Setup

**Backend (veloready-website):**
1. Install testing dependencies
   - Vitest (test runner)
   - MSW (API mocking)
   - @vitest/ui (test UI)

2. Create test directory structure
   - `tests/integration/`
   - `tests/unit/`
   - `tests/helpers/`
   - `tests/fixtures/`

3. Configure test environment
   - Create test Supabase database
   - Create test Strava application
   - Set up environment variables for testing

4. Add test scripts to package.json
   - `test` - Run all tests
   - `test:integration` - Run integration tests only
   - `test:unit` - Run unit tests only
   - `test:watch` - Watch mode for development

**iOS (veloready):**
1. Create test targets in Xcode
   - Integration test bundle
   - Unit test bundle

2. Create test helpers
   - Mock user creation
   - Authentication helpers
   - Test data factories

3. Configure test schemes
   - Separate schemes for different test types
   - Configure test destinations

**Shared:**
1. Document test environment setup in README
2. Create GitHub secrets for test environment
   - Test Supabase URL and keys
   - Test Strava credentials

#### Day 2: First Backend Integration Test

**Target:** `/api/activities` endpoint

1. Create test file: `tests/integration/api.activities.test.ts`

2. Write 3 test cases:
   - Authenticated request returns activities
   - Unauthenticated request returns 401
   - Expired token is handled gracefully

3. Run tests locally
   - Verify all tests pass
   - Fix any failures

4. Document test patterns in comments

**Reference:** See `TESTING_STRATEGY.md` section "Phase 1: Integration Testing"

#### Day 3: First iOS Integration Test

**Target:** `VeloReadyAPIClient.fetchActivities()`

1. Create test file: `VeloReadyAPIClientTests.swift`

2. Write 3 test cases:
   - Fetch activities with valid authentication
   - Fetch activities without authentication fails gracefully
   - Response data matches backend schema

3. Run tests in Xcode
   - Verify all tests pass
   - Fix any failures

4. Document test patterns in comments

**Reference:** See `TESTING_STRATEGY.md` section "Phase 1: Integration Testing"

#### Day 4-5: Remaining Critical API Tests

**Test these 5 additional APIs:**

1. `/api/streams` - Power/HR stream data
   - Test authenticated access
   - Test data format
   - Test error handling

2. `/api/ai-brief` - AI daily brief generation
   - Test with valid inputs
   - Test caching behavior
   - Test rate limiting

3. `/api/sync-batch` - SwiftData batch sync
   - Test delta sync logic
   - Test pagination
   - Test conflict resolution

4. `/oauth/strava/start` - OAuth initiation
   - Test redirect URLs
   - Test state parameter
   - Test error cases

5. `/oauth/strava/token-exchange` - OAuth completion
   - Test token exchange
   - Test user creation
   - Test error handling

**For each API:**
- Write backend integration tests
- Write iOS integration tests
- Verify tests pass locally

### Week 2: CI/CD & Pre-Commit Hooks

#### Day 1: GitHub Actions Workflow

1. Create `.github/workflows/tests.yml` in veloready-website
   - Run backend integration tests on PR
   - Run on push to main
   - Report failures

2. Create `.github/workflows/tests.yml` in veloready
   - Run iOS integration tests on PR
   - Run on macos-14 runner
   - Upload test results

3. Test workflows
   - Create test PR
   - Verify workflows run
   - Verify failures are reported

**Reference:** See `TESTING_STRATEGY.md` section "CI/CD Integration"

#### Day 2: Pre-Commit Hooks

**Backend:**
1. Install Husky
2. Create pre-commit hook
   - Run ESLint
   - Run TypeScript type check
   - Run integration tests
   - Block commit if failures

**iOS:**
1. Create `.git/hooks/pre-commit`
   - Run SwiftLint
   - Run integration tests
   - Block commit if failures

2. Make hook executable
3. Test hook by making a commit

**Reference:** See `TESTING_QUICK_START.md` section "Pre-Commit Hooks"

#### Day 3-4: Contract Testing with Pact

1. Install Pact dependencies
   - `@pact-foundation/pact` for backend

2. Define API contracts
   - Activities API contract
   - Streams API contract
   - AI Brief API contract

3. Write Pact tests
   - Consumer tests (iOS expectations)
   - Provider tests (Backend implementation)

4. Verify contracts match
   - Run pact verification
   - Fix any mismatches

**Reference:** See `TESTING_STRATEGY.md` section "Contract Testing with Pact"

#### Day 5: Documentation & Coverage

1. Document test patterns
   - How to write integration tests
   - How to run tests locally
   - How to debug test failures

2. Set up code coverage reporting
   - Istanbul for backend
   - Xcode coverage for iOS

3. Create coverage badges
   - Add to README files
   - Link to coverage reports

4. Review and refine
   - Identify gaps in coverage
   - Plan improvements for Phase 2

### Phase 1 Deliverables ✅

- [ ] 6 critical APIs have integration tests (backend + iOS)
- [ ] GitHub Actions workflows run on every PR
- [ ] Pre-commit hooks prevent untested code
- [ ] Pact contracts define API expectations
- [ ] Documentation for writing tests
- [ ] Code coverage reporting configured
- [ ] All tests passing

---

## Phase 2: End-to-End Tests (HIGH)

**Duration:** 3 weeks (Weeks 3-5)  
**Priority:** 🟡 HIGH  
**Goal:** Test full user flows from iOS app through backend

**Why E2E Tests:**
- Catch bugs that integration tests miss
- Validate real user experiences
- Test UI alongside business logic
- Ensure features work end-to-end

### Week 3: E2E Setup & First Test

#### Day 1: Maestro Setup

1. Install Maestro
   - `brew tap mobile-dev-inc/tap`
   - `brew install maestro`

2. Create E2E test directory
   - `tests/e2e/scenarios/`
   - `tests/e2e/helpers/`
   - `tests/e2e/fixtures/`

3. Configure Maestro
   - Set app ID
   - Configure test devices
   - Set up environment variables

4. Test Maestro installation
   - Run sample test
   - Verify iOS simulator works

#### Day 2-3: First E2E Test - Training Load

**Scenario:** User opens app and sees training load with non-zero CTL/ATL/TSB

1. Create test file: `tests/e2e/scenarios/training-load.yaml`

2. Define test steps:
   - Launch app
   - Navigate to Today tab
   - Verify Training Load section visible
   - Verify CTL is not zero
   - Verify ATL is not zero
   - Verify TSB is displayed
   - Navigate to activity detail
   - Verify Fitness Trajectory chart has data

3. Run test against real backend
4. Run test against mocked backend
5. Document test patterns

**Reference:** See `TESTING_STRATEGY.md` section "Phase 2: End-to-End Testing"

#### Day 4-5: Backend Mocking for E2E

1. Set up MSW for E2E tests
   - Create mock handlers for all APIs
   - Define response fixtures
   - Handle edge cases

2. Create test data factory
   - Generate realistic test data
   - Support different user states
   - Create edge case scenarios

3. Configure E2E tests to use mocks
   - Environment variable to toggle mocking
   - Fast test execution with mocks
   - Occasional tests against real backend

4. Document mocking patterns

**Reference:** See `TESTING_STRATEGY.md` section "Backend Mocking for E2E Tests"

### Week 4: Critical User Flows

**Write E2E tests for these 4 flows:**

#### Day 1: Onboarding Flow

**Scenario:** New user signs up and connects Strava

1. Create test: `tests/e2e/scenarios/onboarding.yaml`

2. Test steps:
   - Launch app (first time)
   - See welcome screen
   - Tap "Connect Strava"
   - OAuth flow completes
   - Return to app
   - See initial data sync
   - Navigate to Today tab

3. Verify success state
4. Test error cases (OAuth cancellation, network failure)

#### Day 2: Activity Sync Flow

**Scenario:** User triggers manual activity sync

1. Create test: `tests/e2e/scenarios/activity-sync.yaml`

2. Test steps:
   - Navigate to Activities tab
   - Pull to refresh
   - See loading indicator
   - Activities appear
   - Verify activity details
   - Verify power/HR data if available

3. Test with mocked Strava API
4. Test error cases (no internet, API failure)

#### Day 3: AI Brief Generation Flow

**Scenario:** User views daily AI brief

1. Create test: `tests/e2e/scenarios/ai-brief.yaml`

2. Test steps:
   - Navigate to Today tab
   - See AI Brief card
   - Verify brief text appears
   - Verify loading states
   - Tap for detail view
   - Verify metrics displayed

3. Test cached vs fresh briefs
4. Test error cases (API failure, rate limiting)

#### Day 4: Recovery Score Flow

**Scenario:** User views recovery score breakdown

1. Create test: `tests/e2e/scenarios/recovery-score.yaml`

2. Test steps:
   - Navigate to Today tab
   - See Recovery Score card
   - Tap to view breakdown
   - Verify HRV displayed
   - Verify RHR displayed
   - Verify Sleep Score displayed
   - Verify trend chart

3. Test different recovery states (excellent, good, poor)
4. Test missing data scenarios

#### Day 5: Review & Polish

1. Run all E2E tests
2. Fix flaky tests
3. Optimize test execution time
4. Document common issues
5. Create troubleshooting guide

### Week 5: E2E CI/CD & Advanced Scenarios

#### Day 1-2: E2E in GitHub Actions

1. Update `.github/workflows/tests.yml`
   - Add E2E test job
   - Run on macos-14
   - Use iOS simulator

2. Configure test environment
   - Mock backend for CI
   - Seed test data
   - Handle authentication

3. Test workflow
   - Create test PR
   - Verify E2E tests run
   - Verify results are reported

4. Add test artifacts
   - Upload screenshots
   - Upload test logs
   - Upload video recordings

#### Day 3: Advanced E2E Scenarios

**Test these edge cases:**

1. Offline mode
   - No internet connection
   - Cached data displayed
   - Sync queued for later

2. Poor network conditions
   - Slow API responses
   - Timeout handling
   - Retry logic

3. Large datasets
   - User with 1000+ activities
   - Pagination works correctly
   - Performance acceptable

4. Multiple simultaneous syncs
   - Strava + HealthKit + Intervals.icu
   - No data conflicts
   - Consistent state

#### Day 4-5: Performance & Accessibility Testing

1. Add performance assertions
   - App launch time < 2 seconds
   - API response time < 500ms
   - Chart rendering < 200ms

2. Add accessibility tests
   - VoiceOver navigation works
   - All buttons have labels
   - Contrast ratios meet standards
   - Dynamic Type supported

3. Document performance benchmarks
4. Create accessibility checklist

### Phase 2 Deliverables ✅

- [ ] 5 critical user flows tested end-to-end
- [ ] E2E tests run in CI on every PR
- [ ] Backend mocking configured for fast tests
- [ ] Performance benchmarks established
- [ ] Accessibility standards validated
- [ ] Screenshots/videos captured for failures
- [ ] Documentation for E2E test patterns

---

## Phase 3: Component Tests (MEDIUM)

**Duration:** 2 weeks (Weeks 6-7)  
**Priority:** 🟢 MEDIUM  
**Goal:** Test individual services and features in isolation

**Why Component Tests:**
- Test business logic without UI
- Faster than E2E tests
- Easier to debug
- Good coverage of edge cases

### Week 6: Core Services

#### Day 1: Training Load Calculator

**Target:** `TrainingLoadCalculator.swift`

1. Create test file: `TrainingLoadCalculatorTests.swift`

2. Test cases to write:
   - Calculate CTL from daily TSS
   - Calculate ATL from recent TSS
   - Calculate TSB (CTL - ATL)
   - Calculate TSS from power data
   - Calculate TSS from heart rate data
   - Handle zero/missing data gracefully
   - Edge cases (negative values, very large numbers)

3. Achieve 90%+ coverage
4. Document calculation formulas

**Reference:** See `TESTING_STRATEGY.md` section "Phase 3: Component Testing"

#### Day 2: Recovery Score Service

**Target:** `RecoveryScoreService.swift`

1. Create test file: `RecoveryScoreTests.swift`

2. Test cases to write:
   - Calculate recovery from HRV/RHR/Sleep
   - Weight components correctly
   - Handle missing metrics
   - Detect illness signals
   - Calculate trends
   - Persist to Core Data

3. Test different scenarios:
   - Excellent recovery (90%+)
   - Good recovery (70-89%)
   - Poor recovery (<70%)
   - Illness detected

4. Mock dependencies (HealthKit, Core Data)

#### Day 3: Strain Score Service

**Target:** `StrainScoreService.swift`

1. Create test file: `StrainScoreTests.swift`

2. Test cases to write:
   - Fetch activities from API
   - Calculate daily TSS
   - Build 42-day history
   - Calculate CTL/ATL/TSB
   - Determine training phase
   - Cache results in Core Data

3. Mock API responses
4. Test error handling
5. Test cache invalidation

#### Day 4: Sleep Score Service

**Target:** `SleepScoreService.swift`

1. Create test file: `SleepScoreTests.swift`

2. Test cases to write:
   - Fetch sleep data from HealthKit
   - Calculate sleep duration
   - Calculate sleep quality
   - Detect sleep debt
   - Calculate 7-day trend
   - Handle missing data

3. Mock HealthKit data
4. Test edge cases (naps, split sleep, travel)

#### Day 5: Activity Converter

**Target:** `ActivityConverter.swift`

1. Create test file: `ActivityConverterTests.swift`

2. Test cases to write:
   - Convert Strava activity to IntervalsActivity
   - Enrich with TSS calculation
   - Calculate intensity factor
   - Map all fields correctly
   - Handle missing fields
   - Handle different activity types

3. Test with real Strava data samples
4. Verify all edge cases handled

### Week 7: Remaining Services & Review

#### Day 1: Adaptive Zones Service

**Target:** `AdaptiveZonesService.swift`

1. Create test file: `AdaptiveZonesTests.swift`

2. Test cases to write:
   - Detect FTP from power curve
   - Detect max HR from activities
   - Calculate power zones
   - Calculate HR zones
   - Adjust zones for fatigue
   - Update zones over time

3. Mock power curve data
4. Test confidence scoring

#### Day 2: AI Brief Service

**Target:** `AIBriefService.swift`

1. Create test file: `AIBriefServiceTests.swift`

2. Test cases to write:
   - Build request with all metrics
   - Send request to backend
   - Parse response
   - Cache response
   - Handle API errors
   - Retry logic

3. Mock backend API
4. Test all decision rules

#### Day 3: Illness Detection Service

**Target:** `IllnessDetectionService.swift`

1. Create test file: `IllnessDetectionTests.swift`

2. Test cases to write:
   - Detect HRV spike (>100%)
   - Detect elevated RHR + low HRV
   - Calculate confidence score
   - Distinguish from overtraining
   - Handle ambiguous signals

3. Test with real illness data patterns
4. Verify sensitivity/specificity

#### Day 4: Coverage Review & Gaps

1. Run code coverage report
   - Identify services below 70% coverage
   - Prioritize gaps by importance

2. Add missing tests
   - Focus on untested edge cases
   - Add tests for recently found bugs

3. Refactor for testability
   - Extract dependencies
   - Add dependency injection
   - Improve separation of concerns

#### Day 5: Performance & Optimization

1. Run performance tests
   - Identify slow calculations
   - Profile with Instruments
   - Optimize hot paths

2. Add performance benchmarks
   - Recovery score < 50ms
   - Training load < 100ms
   - Activity conversion < 10ms per activity

3. Document performance targets

### Phase 3 Deliverables ✅

- [ ] 70%+ code coverage for core services
- [ ] All business logic tested in isolation
- [ ] Mock dependencies properly
- [ ] Performance benchmarks established
- [ ] Edge cases covered
- [ ] Documentation for component test patterns

---

## Phase 4: Unit Tests & Polish (LOW)

**Duration:** 1 week (Week 8)  
**Priority:** 🟢 LOW  
**Goal:** Test pure functions and final polish

### Day 1: Utility Functions

**Test pure functions:**

1. Date utilities
   - Format dates
   - Calculate date ranges
   - Time zone handling

2. Number formatters
   - Duration formatting
   - Distance formatting
   - Power/HR formatting

3. String utilities
   - Truncation
   - Validation
   - Sanitization

4. Calculation utilities
   - Statistical functions
   - Moving averages
   - Percentiles

**Achieve 90%+ coverage for utilities**

### Day 2: Data Models & Validation

**Test data models:**

1. StravaActivity model
   - Decoding from JSON
   - Encoding to JSON
   - Field validation
   - Default values

2. IntervalsActivity model
   - Initialization
   - Computed properties
   - Relationships

3. User settings models
   - Validation rules
   - Default values
   - Persistence

### Day 3: Static Analysis & Linting

1. Enable TypeScript strict mode (backend)
   - Fix all type errors
   - Add missing type annotations
   - Remove `any` types

2. Enable SwiftLint strict mode (iOS)
   - Fix all linting errors
   - Configure custom rules
   - Add to pre-commit hook

3. Add additional linters
   - Prettier for formatting
   - ESLint plugins
   - Swift Format

### Day 4: Documentation & Training

1. Write testing guidelines
   - When to write each test type
   - How to structure tests
   - Common patterns and anti-patterns

2. Create testing examples
   - Sample tests for each type
   - Before/after refactoring examples
   - Best practices

3. Document troubleshooting
   - Common test failures
   - How to debug tests
   - Flaky test remediation

4. Team training materials
   - Testing philosophy
   - Running tests locally
   - Writing new tests

### Day 5: Final Review & Launch

1. Run full test suite
   - All tests passing
   - No flaky tests
   - Good performance

2. Review coverage reports
   - Verify coverage targets met
   - Document remaining gaps
   - Plan for future improvements

3. Update project documentation
   - Add testing section to README
   - Link to test documentation
   - Add coverage badges

4. Celebrate! 🎉
   - Testing framework complete
   - Ready to catch bugs before production
   - More confident deployments

### Phase 4 Deliverables ✅

- [ ] 90%+ coverage for utility functions
- [ ] All data models tested
- [ ] Strict linting enabled
- [ ] Comprehensive testing documentation
- [ ] Team trained on testing practices
- [ ] All tests passing
- [ ] Coverage badges added to READMEs

---

## Success Metrics

### Technical Metrics

| Metric | Baseline | Target | How to Measure |
|--------|----------|--------|----------------|
| **Code Coverage** | 0% | 70% iOS, 80% Backend | Coverage reports |
| **Test Execution Time** | N/A | <10 minutes | CI pipeline timing |
| **CI Pass Rate** | N/A | >95% | GitHub Actions history |
| **Bugs Caught in CI** | 0% | 90% | Issue tracking |
| **Flaky Test Rate** | N/A | <1% | Test result analysis |

### Business Metrics

| Metric | Target | Timeline |
|--------|--------|----------|
| Production Bug Rate | -80% | 3 months |
| Time to Detect Bugs | <5 min (CI) vs hours (prod) | Immediate |
| User-Reported Issues | -50% | 6 months |
| App Store Rating | Maintain 4.5+ | Ongoing |
| Developer Confidence | High | Immediate |

---

## Implementation Approaches

### Option A: Full Pause (8 weeks)

**Timeline:** Stop all feature development, focus on testing only

**Pros:**
- Most thorough approach
- Dedicated focus
- Complete coverage quickly

**Cons:**
- Delays new features 2 months
- Opportunity cost
- Team morale impact

**Recommendation:** ❌ Not recommended unless in crisis mode

---

### Option B: Hybrid (2 weeks + gradual) ⭐ **RECOMMENDED**

**Timeline:**
- **Weeks 1-2:** Full pause, implement Phase 1 (integration tests)
- **Weeks 3-8:** Add tests incrementally with new features

**Pros:**
- Critical integration tests in place quickly
- Prevents immediate bugs
- Maintains feature velocity
- Sustainable pace

**Cons:**
- Phases 2-4 take longer
- Requires discipline

**Recommendation:** ✅ Best balance of safety and velocity

---

### Option C: Gradual Only

**Timeline:** Add tests only when building new features

**Pros:**
- No pause in feature development
- Tests added naturally
- No opportunity cost

**Cons:**
- Existing code remains untested
- Another bug could slip through
- Takes 6+ months for full coverage
- Lacks systematic approach

**Recommendation:** ⚠️ Only if testing is truly not urgent

---

## Weekly Rhythm During Implementation

### Sprint Planning (Monday)
1. Review last week's test results
2. Plan this week's test targets
3. Assign test writing to team members
4. Review any test failures

### Daily Standup
- Tests written yesterday
- Tests to write today
- Any blockers (flaky tests, environment issues)

### Mid-Week Check (Wednesday)
- Review test coverage progress
- Address flaky tests
- Help with test writing blockers

### End of Week (Friday)
- Review week's test additions
- Run full test suite
- Celebrate progress
- Plan next week

---

## Troubleshooting Common Issues

### Issue: Tests are flaky

**Solutions:**
1. Add explicit waits instead of arbitrary delays
2. Use proper test isolation (reset state between tests)
3. Mock time-dependent code
4. Retry tests 3x before marking failure
5. Track flaky tests separately

### Issue: Tests are too slow

**Solutions:**
1. Run tests in parallel
2. Use test mocking more aggressively
3. Separate fast unit tests from slow E2E tests
4. Only run relevant tests on PR (full suite on main)

### Issue: Tests are hard to write

**Solutions:**
1. Refactor code for testability (dependency injection)
2. Create test helpers and utilities
3. Document common patterns
4. Pair programming on test writing
5. Review test structure in code reviews

### Issue: Coverage not improving

**Solutions:**
1. Make test coverage visible (badges, reports)
2. Set coverage thresholds (fail if below target)
3. Review coverage in PRs
4. Focus on high-value untested code
5. Refactor untestable code

### Issue: Team resistance to testing

**Solutions:**
1. Show examples of bugs tests would have caught
2. Demonstrate faster debugging with tests
3. Make tests easy to write (good infrastructure)
4. Lead by example
5. Celebrate test milestones

---

## Cost Analysis

### Development Time Investment

| Phase | Hours | Cost @ $100/hr |
|-------|-------|----------------|
| Phase 1: Integration | 80h | $8,000 |
| Phase 2: E2E | 120h | $12,000 |
| Phase 3: Component | 80h | $8,000 |
| Phase 4: Unit & Polish | 40h | $4,000 |
| **Total** | **320h** | **$32,000** |

### Infrastructure Costs

| Item | Monthly Cost |
|------|--------------|
| GitHub Actions | $0 (free tier sufficient) |
| Sentry (monitoring) | $26 |
| Test Supabase database | $0 (free tier) |
| Test Strava app | $0 |
| **Total** | **$26/month** |

### Time Savings (Monthly)

| Activity | Hours Saved |
|----------|-------------|
| Debugging production bugs | 10-20h |
| Manual testing before releases | 4h |
| Hotfix deployments | 2h |
| **Total Monthly Savings** | **16-26h** |

**Break-even:** 12-20 months @ $100/hr

**Intangible Benefits:**
- Better user experience
- Higher app store ratings
- More confident deployments
- Faster feature development
- Reduced stress

---

## Next Steps

### Immediate (This Week)

1. **Review this roadmap** with team
   - Discuss approach (Full Pause vs Hybrid vs Gradual)
   - Assign Phase 1 tasks
   - Set timeline commitment

2. **Set up test environment**
   - Create test Supabase database
   - Create test Strava application
   - Configure GitHub secrets

3. **Install test dependencies**
   - Vitest for backend
   - XCTest for iOS (already available)
   - Maestro for E2E (Phase 2)

### Week 1 Start

1. **Backend:** Write first integration test (`/api/activities`)
2. **iOS:** Write first integration test (`fetchActivities`)
3. **Document:** Test patterns and best practices
4. **Celebrate:** First tests running! 🎉

---

## Questions & Decisions Needed

### Q1: Which implementation approach?

**Options:** Full Pause | Hybrid | Gradual  
**Recommendation:** Hybrid (2 weeks focused + gradual)  
**Decision:** [ ] To be decided

### Q2: Who owns test infrastructure?

**Options:** Dedicated QA engineer | Whole team | Rotating ownership  
**Recommendation:** Whole team (shift left philosophy)  
**Decision:** [ ] To be decided

### Q3: Coverage thresholds?

**Current:** 0% across all repos  
**Targets:** 80% backend, 70% iOS, 50% agents  
**Enforcement:** Block PRs below threshold? Warning only?  
**Decision:** [ ] To be decided

### Q4: Test frequency?

**Integration tests:** Every PR (fast, critical)  
**E2E tests:** Every PR on main, nightly on branches?  
**Component tests:** Every PR  
**Unit tests:** Every PR  
**Decision:** [ ] To be decided

### Q5: When to implement qa-agent?

**Options:** Now (Phase 1) | After Phase 2 | After Phase 4  
**Recommendation:** After Phase 2 (when E2E tests stable)  
**Decision:** [ ] To be decided

---

## References

### Detailed Implementation Guides
- `TESTING_STRATEGY.md` - Comprehensive strategy with code examples
- `TESTING_QUICK_START.md` - Quick reference and first test examples
- `TESTING_INTEGRATION_PLAN.md` - Agent system integration

### Test Examples
All code examples are in the above documents:
- Backend integration tests
- iOS integration tests
- E2E test scenarios
- Component test examples
- Unit test examples

### External Resources
- Vitest: https://vitest.dev/
- Maestro: https://maestro.mobile.dev/
- Pact: https://docs.pact.io/
- XCTest: https://developer.apple.com/documentation/xctest
- Swift Testing: https://developer.apple.com/documentation/testing

---

## Conclusion

This roadmap provides a clear, phased approach to implementing comprehensive testing across VeloReady. By focusing on **integration tests first** (Phase 1), you'll catch the most critical bugs quickly. Then gradually add E2E, component, and unit tests to achieve full coverage.

**Key Success Factors:**
1. ✅ Start with integration tests (highest ROI)
2. ✅ Use hybrid approach (2 weeks focused + gradual)
3. ✅ Make tests easy to write (good infrastructure)
4. ✅ Run tests automatically (CI/CD)
5. ✅ Make coverage visible (badges, reports)
6. ✅ Celebrate milestones (maintain momentum)

**Expected Outcome:**
- 90% of bugs caught before production
- 16-26 hours/month saved on debugging
- More confident deployments
- Better user experience
- Higher app store ratings

**Ready to start? Begin with Phase 1, Day 1! 🚀**

