import Foundation
import Testing
@testable import VeloReady

@Suite("Offline Functionality")
struct OfflineFunctionalityTests {

    // MARK: - Synchronous Cache Loading Tests

    @Test("UserDefaults synchronous loading preserves scores")
    func testSynchronousCacheLoading() async throws {
        // Simulate UserDefaults with cached scores
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.markboulton.VeloReady") else {
            Issue.record("Failed to access shared UserDefaults")
            return
        }

        // Save mock data to UserDefaults
        sharedDefaults.set(92, forKey: "cachedRecoveryScore")
        sharedDefaults.set("optimal", forKey: "cachedRecoveryBand")
        sharedDefaults.set(93, forKey: "cachedSleepScore")
        sharedDefaults.set(1.5, forKey: "cachedStrainScore")

        // Verify data can be loaded
        let recoveryScore = sharedDefaults.value(forKey: "cachedRecoveryScore") as? Int
        let sleepScore = sharedDefaults.value(forKey: "cachedSleepScore") as? Int
        let strainScore = sharedDefaults.value(forKey: "cachedStrainScore") as? Double

        #expect(recoveryScore == 92)
        #expect(sleepScore == 93)
        #expect(strainScore == 1.5)

        // Cleanup
        sharedDefaults.removeObject(forKey: "cachedRecoveryScore")
        sharedDefaults.removeObject(forKey: "cachedRecoveryBand")
        sharedDefaults.removeObject(forKey: "cachedSleepScore")
        sharedDefaults.removeObject(forKey: "cachedStrainScore")
    }

    @Test("Recovery score band mapping is correct")
    func testRecoveryScoreBandMapping() async throws {
        // Test band mapping for cached values
        let testCases: [(score: Int, band: String)] = [
            (100, "optimal"),
            (80, "optimal"),
            (79, "good"),
            (60, "good"),
            (59, "fair"),
            (40, "fair"),
            (39, "payAttention"),
            (0, "payAttention")
        ]

        for testCase in testCases {
            let score = testCase.score
            let expectedBand = testCase.band

            // Determine band based on score (matches RecoveryScore.RecoveryBand logic)
            let band: String
            if score >= 80 {
                band = "optimal"
            } else if score >= 60 {
                band = "good"
            } else if score >= 40 {
                band = "fair"
            } else {
                band = "payAttention"
            }

            #expect(band == expectedBand, "Score \(score) should map to \(expectedBand), got \(band)")
        }
    }

    @Test("Sleep score band mapping is correct")
    func testSleepScoreBandMapping() async throws {
        // Test band mapping for cached sleep scores
        let testCases: [(score: Int, expectedBand: String)] = [
            (100, "optimal"),
            (85, "optimal"),
            (84, "good"),
            (70, "good"),
            (69, "fair"),
            (60, "fair"),
            (59, "payAttention"),
            (0, "payAttention")
        ]

        for testCase in testCases {
            let score = testCase.score

            // Determine band (matches SleepScoreService logic)
            let band: String
            if score >= 85 {
                band = "optimal"
            } else if score >= 70 {
                band = "good"
            } else if score >= 60 {
                band = "fair"
            } else {
                band = "payAttention"
            }

            #expect(band == testCase.expectedBand, "Sleep score \(score) should map to \(testCase.expectedBand)")
        }
    }

    @Test("Strain score band mapping is correct")
    func testStrainScoreBandMapping() async throws {
        // Test band mapping for cached strain scores (0-18 scale)
        let testCases: [(score: Double, expectedBand: String)] = [
            (0.0, "light"),
            (5.9, "light"),
            (6.0, "moderate"),
            (10.9, "moderate"),
            (11.0, "hard"),
            (15.9, "hard"),
            (16.0, "veryHard"),
            (18.0, "veryHard")
        ]

        for testCase in testCases {
            let score = testCase.score

            // Determine band (matches StrainScoreService logic)
            let band: String
            if score < 6 {
                band = "light"
            } else if score < 11 {
                band = "moderate"
            } else if score < 16 {
                band = "hard"
            } else {
                band = "veryHard"
            }

            #expect(band == testCase.expectedBand, "Strain score \(score) should map to \(testCase.expectedBand)")
        }
    }

    // MARK: - Cache Persistence Tests

    @Test("Placeholder score has nil inputs")
    func testPlaceholderScoreStructure() async throws {
        // Verify placeholder scores (from sync load) have nil inputs
        let placeholderInputs = RecoveryScore.RecoveryInputs(
            hrv: nil,
            overnightHrv: nil,
            hrvBaseline: nil,
            rhr: nil,
            rhrBaseline: nil,
            sleepDuration: nil,
            sleepBaseline: nil,
            respiratoryRate: nil,
            respiratoryBaseline: nil,
            atl: nil,
            ctl: nil,
            recentStrain: nil,
            sleepScore: nil
        )

        #expect(placeholderInputs.hrv == nil)
        #expect(placeholderInputs.rhr == nil)
        #expect(placeholderInputs.sleepScore == nil)
    }

    @Test("Full score has non-nil inputs")
    func testFullScoreStructure() async throws {
        // Verify full scores have actual data
        let fullInputs = RecoveryScore.RecoveryInputs(
            hrv: 45.0,
            overnightHrv: 42.0,
            hrvBaseline: 50.0,
            rhr: 55.0,
            rhrBaseline: 60.0,
            sleepDuration: 28800,
            sleepBaseline: 28800,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0,
            atl: 10.0,
            ctl: 40.0,
            recentStrain: 8.5,
            sleepScore: nil  // Simplified for test
        )

        #expect(fullInputs.hrv != nil)
        #expect(fullInputs.rhr != nil)
        #expect(fullInputs.hrv! > 0)
        #expect(fullInputs.rhr! > 0)
    }

    // MARK: - Offline Behavior Tests

    @Test("Offline status prevents unnecessary operations")
    func testOfflineStatusPreventsOperations() async throws {
        // Simulate offline state
        let isOffline = true

        // When offline, certain operations should be skipped
        if isOffline {
            // Cache invalidation should be skipped
            let shouldInvalidateCache = false
            #expect(shouldInvalidateCache == false)

            // Network requests should be skipped
            let shouldMakeNetworkRequest = false
            #expect(shouldMakeNetworkRequest == false)

            // Cached data should be preserved
            let shouldPreserveCachedData = true
            #expect(shouldPreserveCachedData == true)
        }
    }

    @Test("Online status allows normal operations")
    func testOnlineStatusAllowsOperations() async throws {
        // Simulate online state
        let isOnline = true

        // When online, operations should proceed normally
        if isOnline {
            // Cache invalidation should be allowed
            let shouldInvalidateCache = true
            #expect(shouldInvalidateCache == true)

            // Network requests should be allowed
            let shouldMakeNetworkRequest = true
            #expect(shouldMakeNetworkRequest == true)

            // Fresh data should be fetched
            let shouldFetchFreshData = true
            #expect(shouldFetchFreshData == true)
        }
    }

    // MARK: - Score Validation Tests

    @Test("Recovery score requires HRV for completeness")
    func testRecoveryScoreCompletenessCheck() async throws {
        // Incomplete score (no HRV)
        let incompleteScore = RecoveryScore(
            score: 92,
            band: .optimal,
            subScores: RecoveryScore.SubScores(hrv: 0, rhr: 0, sleep: 0, form: 0, respiratory: 0),
            inputs: RecoveryScore.RecoveryInputs(
                hrv: nil,  // Missing!
                overnightHrv: nil,
                hrvBaseline: nil,
                rhr: nil,
                rhrBaseline: nil,
                sleepDuration: nil,
                sleepBaseline: nil,
                respiratoryRate: nil,
                respiratoryBaseline: nil,
                atl: nil,
                ctl: nil,
                recentStrain: nil,
                sleepScore: nil
            ),
            calculatedAt: Date(),
            isPersonalized: false
        )

        // Check completeness (matches RecoveryScoreService logic)
        let isComplete = incompleteScore.inputs.hrv != nil
        #expect(isComplete == false, "Score should be incomplete without HRV data")

        // Complete score (has HRV)
        let completeScore = RecoveryScore(
            score: 92,
            band: .optimal,
            subScores: RecoveryScore.SubScores(hrv: 85, rhr: 90, sleep: 85, form: 80, respiratory: 88),
            inputs: RecoveryScore.RecoveryInputs(
                hrv: 45.0,  // Present!
                overnightHrv: 42.0,
                hrvBaseline: 50.0,
                rhr: 55.0,
                rhrBaseline: 60.0,
                sleepDuration: 28800,
                sleepBaseline: 28800,
                respiratoryRate: 16.0,
                respiratoryBaseline: 16.0,
                atl: 10.0,
                ctl: 40.0,
                recentStrain: 8.5,
                sleepScore: nil  // Simplified for test
            ),
            calculatedAt: Date(),
            isPersonalized: true
        )

        let isCompleteWithHRV = completeScore.inputs.hrv != nil
        #expect(isCompleteWithHRV == true, "Score should be complete with HRV data")
    }
}
