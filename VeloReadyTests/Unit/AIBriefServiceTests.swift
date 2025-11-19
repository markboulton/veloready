import Foundation
import Testing
import CoreData
@testable import VeloReady

/// Unit tests for AIBriefService cache staleness detection
/// These tests verify that cached AI briefs are properly invalidated when recovery scores change
@Suite("AI Brief Service")
@MainActor
struct AIBriefServiceTests {

    // MARK: - Test Setup

    func createTestContext() -> NSManagedObjectContext {
        let container = CoreDataTestHelper.createInMemoryContainer()
        return container.viewContext
    }

    // MARK: - Test Helpers

    func createMockRecoveryScore(score: Int) -> RecoveryScore {
        let inputs = RecoveryScore.RecoveryInputs(
            hrv: 50.0,
            overnightHrv: 48.0,
            hrvBaseline: 45.0,
            rhr: 55.0,
            rhrBaseline: 60.0,
            sleepDuration: 28800.0,
            sleepBaseline: 28800.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0,
            atl: 25.0,
            ctl: 30.0,
            recentStrain: 8.0,
            sleepScore: nil
        )

        let subScores = RecoveryScore.SubScores(
            hrv: 85,
            rhr: 90,
            sleep: 85,
            form: 80,
            respiratory: 88
        )

        let band: RecoveryScore.RecoveryBand = score >= 80 ? .optimal : score >= 60 ? .good : score >= 40 ? .fair : .payAttention

        return RecoveryScore(
            score: score,
            band: band,
            subScores: subScores,
            inputs: inputs,
            calculatedAt: Date()
        )
    }

    // MARK: - Mock Client

    class MockAIBriefClient: AIBriefClientProtocol {
        var mockResponse: AIBriefResponse?
        var fetchCallCount = 0

        func fetchBrief(request: AIBriefRequest, userId: String, bypassCache: Bool) async throws -> AIBriefResponse {
            fetchCallCount += 1
            guard let response = mockResponse else {
                throw AIBriefError.networkError("No mock response configured")
            }
            return response
        }
    }

    // MARK: - Cache Staleness Tests

    @Test("Detects stale cache when recovery score changes")
    func testDetectsStaleCacheWhenRecoveryScoreChanges() async throws {
        let context = createTestContext()
        let today = Calendar.current.startOfDay(for: Date())

        // Given: Core Data has cached AI brief with old recovery score (70)
        let dailyScore = DailyScores(context: context)
        dailyScore.date = today
        dailyScore.recoveryScore = 70.0
        dailyScore.aiBriefText = "Old brief based on recovery 70%"

        try context.save()

        // Given: Recovery service now has updated score (85)
        RecoveryScoreService.shared.currentRecoveryScore = createMockRecoveryScore(score: 85)

        // When: AI Brief Service loads from Core Data
        let mockClient = MockAIBriefClient()
        mockClient.mockResponse = AIBriefResponse(text: "Fresh brief based on recovery 85%", cached: false)

        let service = AIBriefService(client: mockClient)
        await service.fetchBrief(bypassCache: false)

        // Then: Should detect staleness and regenerate (call API, not use cache)
        #expect(mockClient.fetchCallCount == 1, "Should have called API due to stale cache")
        #expect(service.briefText == "Fresh brief based on recovery 85%", "Should use fresh brief")
    }

    @Test("Uses cache when recovery score unchanged")
    func testUsesCacheWhenRecoveryScoreUnchanged() async throws {
        let context = createTestContext()
        let today = Calendar.current.startOfDay(for: Date())

        // Given: Core Data has cached AI brief with current recovery score (72)
        let dailyScore = DailyScores(context: context)
        dailyScore.date = today
        dailyScore.recoveryScore = 72.0
        dailyScore.aiBriefText = "Cached brief based on recovery 72%"

        try context.save()

        // Given: Recovery service has same score (72)
        RecoveryScoreService.shared.currentRecoveryScore = createMockRecoveryScore(score: 72)

        // When: AI Brief Service loads from Core Data
        let mockClient = MockAIBriefClient()
        mockClient.mockResponse = AIBriefResponse(text: "Should not be called", cached: false)

        let service = AIBriefService(client: mockClient)
        await service.fetchBrief(bypassCache: false)

        // Then: Should use cached brief without calling API
        #expect(mockClient.fetchCallCount == 0, "Should NOT call API when cache is fresh")
        #expect(service.briefText == "Cached brief based on recovery 72%", "Should use cached brief")
        #expect(service.isCached == true, "Should indicate data is from cache")
    }

    @Test("Tolerates minor recovery score fluctuations within 1 point")
    func testToleratesMinorRecoveryScoreFluctuations() async throws {
        let context = createTestContext()
        let today = Calendar.current.startOfDay(for: Date())

        // Given: Core Data has cached AI brief with recovery score 72.0
        let dailyScore = DailyScores(context: context)
        dailyScore.date = today
        dailyScore.recoveryScore = 72.0
        dailyScore.aiBriefText = "Cached brief"

        try context.save()

        // Given: Recovery service has very similar score (73 - within 1.0 tolerance)
        RecoveryScoreService.shared.currentRecoveryScore = createMockRecoveryScore(score: 73)

        // When: AI Brief Service loads from Core Data
        let mockClient = MockAIBriefClient()
        let service = AIBriefService(client: mockClient)
        await service.fetchBrief(bypassCache: false)

        // Then: Should use cached brief (minor fluctuation within tolerance)
        #expect(mockClient.fetchCallCount == 0, "Should NOT call API for minor fluctuation")
        #expect(service.briefText == "Cached brief", "Should use cached brief")
    }

    @Test("Regenerates when recovery score differs by more than 1 point")
    func testRegeneratesWhenRecoveryScoreDiffersSignificantly() async throws {
        let context = createTestContext()
        let today = Calendar.current.startOfDay(for: Date())

        // Given: Core Data has cached AI brief with recovery score 70
        let dailyScore = DailyScores(context: context)
        dailyScore.date = today
        dailyScore.recoveryScore = 70.0
        dailyScore.aiBriefText = "Old brief"

        try context.save()

        // Given: Recovery service has significantly different score (75 - more than 1.0 difference)
        RecoveryScoreService.shared.currentRecoveryScore = createMockRecoveryScore(score: 75)

        // When: AI Brief Service loads from Core Data
        let mockClient = MockAIBriefClient()
        mockClient.mockResponse = AIBriefResponse(text: "Fresh brief", cached: false)

        let service = AIBriefService(client: mockClient)
        await service.fetchBrief(bypassCache: false)

        // Then: Should regenerate due to significant difference
        #expect(mockClient.fetchCallCount == 1, "Should call API for significant change")
        #expect(service.briefText == "Fresh brief", "Should use fresh brief")
    }

    @Test("Handles missing cached brief gracefully")
    func testHandlesMissingCachedBrief() async throws {
        let context = createTestContext()
        let today = Calendar.current.startOfDay(for: Date())

        // Given: Core Data has DailyScores but no cached brief
        let dailyScore = DailyScores(context: context)
        dailyScore.date = today
        dailyScore.recoveryScore = 72.0
        dailyScore.aiBriefText = nil  // No cached brief

        try context.save()

        // Given: Recovery service has score
        RecoveryScoreService.shared.currentRecoveryScore = createMockRecoveryScore(score: 72)

        // When: AI Brief Service tries to load from Core Data
        let mockClient = MockAIBriefClient()
        mockClient.mockResponse = AIBriefResponse(text: "New brief", cached: false)

        let service = AIBriefService(client: mockClient)
        await service.fetchBrief(bypassCache: false)

        // Then: Should fetch new brief from API
        #expect(mockClient.fetchCallCount == 1, "Should call API when no cache exists")
        #expect(service.briefText == "New brief", "Should use new brief")
    }

    @Test("Handles missing recovery score gracefully")
    func testHandlesMissingRecoveryScore() async throws {
        let context = createTestContext()

        // Given: Core Data has cached brief
        let today = Calendar.current.startOfDay(for: Date())
        let dailyScore = DailyScores(context: context)
        dailyScore.date = today
        dailyScore.recoveryScore = 72.0
        dailyScore.aiBriefText = "Cached brief"

        try context.save()

        // Given: Recovery service has NO score
        RecoveryScoreService.shared.currentRecoveryScore = nil

        // When: AI Brief Service tries to fetch
        let mockClient = MockAIBriefClient()
        mockClient.mockResponse = AIBriefResponse(text: "Should not be used", cached: false)

        let service = AIBriefService(client: mockClient)
        await service.fetchBrief(bypassCache: false)

        // Then: Should handle gracefully (likely throw error or use fallback)
        // This tests that the service doesn't crash when recovery score is nil
        #expect(service.error != nil, "Should have error when recovery score missing")
    }
}
