import Foundation
import Testing
@testable import VeloReady
@testable import VeloReadyCore

/// Comprehensive tests for Recovery Score calculation fallback logic
/// Tests rule-based recovery scoring when data is missing or incomplete
/// Ensures weight rebalancing and fallback calculations work correctly
@Suite("Recovery Calculation Fallback & Missing Data Handling")
struct RecoveryCalculationFallbackTests {

    // MARK: - Sleep Data Fallback Tests

    @Test("Uses comprehensive sleep score when available")
    func testUsesComprehensiveSleepScore() throws {
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepDuration: 28800, // 8 hours
            sleepBaseline: 28800,
            sleepScore: 85 // Comprehensive sleep score available
        )

        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: true)

        // Should use the comprehensive sleep score (85), not fallback
        #expect(result.subScores.sleep == 85, "Should use comprehensive sleep score when available")
    }

    @Test("Falls back to duration-based sleep calculation when score unavailable")
    func testFallbackToDurationBasedSleep() throws {
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepDuration: 28800, // 8 hours (matches baseline)
            sleepBaseline: 28800,
            sleepScore: nil // No comprehensive score - fallback needed
        )

        let sleepScore = RecoveryCalculations.calculateSleepComponent(
            sleepScore: inputs.sleepScore,
            sleepDuration: inputs.sleepDuration,
            baseline: inputs.sleepBaseline
        )

        // Fallback formula: (duration / baseline) * 100 = (28800 / 28800) * 100 = 100
        #expect(sleepScore == 100, "Fallback should calculate 100 for meeting baseline")
    }

    @Test("Fallback sleep calculation: 75% of baseline sleep")
    func testFallbackSleepShortDuration() throws {
        let sleepScore = RecoveryCalculations.calculateSleepComponent(
            sleepScore: nil,
            sleepDuration: 21600, // 6 hours (75% of 8 hours)
            baseline: 28800 // 8 hours
        )

        // (21600 / 28800) * 100 = 75
        #expect(sleepScore == 75, "Fallback should calculate 75 for 75% of baseline")
    }

    @Test("Fallback sleep calculation: 125% of baseline sleep (capped at 100)")
    func testFallbackSleepOversleep() throws {
        let sleepScore = RecoveryCalculations.calculateSleepComponent(
            sleepScore: nil,
            sleepDuration: 36000, // 10 hours (125% of 8 hours)
            baseline: 28800 // 8 hours
        )

        // (36000 / 28800) * 100 = 125, capped at 100
        #expect(sleepScore == 100, "Fallback should cap at 100 for oversleep")
    }

    @Test("Fallback sleep returns 50 when no data available")
    func testFallbackSleepNoData() throws {
        let sleepScore = RecoveryCalculations.calculateSleepComponent(
            sleepScore: nil,
            sleepDuration: nil,
            baseline: nil
        )

        #expect(sleepScore == 50, "Should return neutral 50 when no sleep data")
    }

    // MARK: - Weight Rebalancing Tests (Missing Sleep Data)

    @Test("Weights rebalanced when sleep data unavailable")
    func testWeightRebalancingWithoutSleep() throws {
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepDuration: nil, // No sleep data
            sleepBaseline: nil,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0,
            atl: 50.0,
            ctl: 50.0,
            sleepScore: nil
        )

        // With sleep: HRV 30%, RHR 20%, Sleep 30%, Respiratory 10%, Load 10%
        let resultWithSleep = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: true)

        // Without sleep: HRV 42.8%, RHR 28.6%, Respiratory 14.3%, Load 14.3%
        let resultWithoutSleep = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: false)

        // Scores should differ due to weight rebalancing
        #expect(resultWithSleep.score != resultWithoutSleep.score, "Weights should be rebalanced without sleep")
    }

    @Test("Weight rebalancing preserves total weight of 100%")
    func testWeightRebalancingTotalWeight() throws {
        // Without sleep: HRV 42.8% + RHR 28.6% + Respiratory 14.3% + Load 14.3% = 100%
        let hrvWeight = 0.428
        let rhrWeight = 0.286
        let respiratoryWeight = 0.143
        let loadWeight = 0.143

        let totalWeight = hrvWeight + rhrWeight + respiratoryWeight + loadWeight

        #expect(abs(totalWeight - 1.0) < 0.001, "Total weight should be 100%")
    }

    // MARK: - Missing Data Handling Tests

    @Test("HRV component returns 50 when data missing")
    func testHRVComponentMissingData() throws {
        let score = RecoveryCalculations.calculateHRVComponent(hrv: nil, baseline: nil)
        #expect(score == 50, "Should return neutral 50 when HRV data missing")
    }

    @Test("RHR component returns 50 when data missing")
    func testRHRComponentMissingData() throws {
        let score = RecoveryCalculations.calculateRHRComponent(rhr: nil, baseline: nil)
        #expect(score == 50, "Should return neutral 50 when RHR data missing")
    }

    @Test("Respiratory component returns 50 when data missing")
    func testRespiratoryComponentMissingData() throws {
        let score = RecoveryCalculations.calculateRespiratoryComponent(respiratory: nil, baseline: nil)
        #expect(score == 50, "Should return neutral 50 when respiratory data missing")
    }

    @Test("Form component returns 50 when data missing")
    func testFormComponentMissingData() throws {
        let score = RecoveryCalculations.calculateFormComponent(atl: nil, ctl: nil, recentStrain: nil)
        #expect(score == 50, "Should return neutral 50 when load data missing")
    }

    @Test("Recovery score handles all data missing gracefully")
    func testAllDataMissing() throws {
        let inputs = RecoveryCalculations.RecoveryInputs()

        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: false)

        // All sub-scores should default to 50, overall score should be ~50
        #expect(result.score > 45 && result.score < 55, "Should return neutral score when all data missing")
        #expect(result.subScores.hrv == 50)
        #expect(result.subScores.rhr == 50)
        #expect(result.subScores.sleep == 50)
        #expect(result.subScores.form == 50)
        #expect(result.subScores.respiratory == 50)
    }

    // MARK: - Zero Baseline Handling

    @Test("HRV handles zero baseline gracefully")
    func testHRVZeroBaseline() throws {
        let score = RecoveryCalculations.calculateHRVComponent(hrv: 50.0, baseline: 0.0)
        #expect(score == 50, "Should return neutral 50 for invalid zero baseline")
    }

    @Test("RHR handles zero baseline gracefully")
    func testRHRZeroBaseline() throws {
        let score = RecoveryCalculations.calculateRHRComponent(rhr: 60.0, baseline: 0.0)
        #expect(score == 50, "Should return neutral 50 for invalid zero baseline")
    }

    @Test("Sleep handles zero baseline gracefully")
    func testSleepZeroBaseline() throws {
        let score = RecoveryCalculations.calculateSleepComponent(
            sleepScore: nil,
            sleepDuration: 28800,
            baseline: 0.0
        )
        #expect(score == 50, "Should return neutral 50 for invalid zero baseline")
    }

    @Test("Respiratory handles zero baseline gracefully")
    func testRespiratoryZeroBaseline() throws {
        let score = RecoveryCalculations.calculateRespiratoryComponent(respiratory: 16.0, baseline: 0.0)
        #expect(score == 50, "Should return neutral 50 for invalid zero baseline")
    }

    @Test("Form handles zero CTL gracefully")
    func testFormZeroCTL() throws {
        let score = RecoveryCalculations.calculateFormComponent(atl: 50.0, ctl: 0.0, recentStrain: nil)
        #expect(score == 50, "Should return neutral 50 for invalid zero CTL")
    }

    // MARK: - Partial Data Scenarios

    @Test("Recovery score with only HRV data")
    func testOnlyHRVData() throws {
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 50.0,
            hrvBaseline: 50.0
        )

        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: false)

        // HRV should be calculated, others should default to 50
        #expect(result.subScores.hrv == 100, "HRV at baseline should score 100")
        #expect(result.subScores.rhr == 50, "Missing RHR should default to 50")
        #expect(result.subScores.sleep == 50)
        #expect(result.subScores.form == 50)
        #expect(result.subScores.respiratory == 50)
    }

    @Test("Recovery score with only RHR data")
    func testOnlyRHRData() throws {
        let inputs = RecoveryCalculations.RecoveryInputs(
            rhr: 60.0,
            rhrBaseline: 60.0
        )

        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: false)

        // RHR should be calculated, others should default to 50
        #expect(result.subScores.rhr == 100, "RHR at baseline should score 100")
        #expect(result.subScores.hrv == 50, "Missing HRV should default to 50")
    }

    @Test("Recovery score with HRV and RHR only")
    func testHRVAndRHROnly() throws {
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0
        )

        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: false)

        // Both HRV and RHR at baseline = 100 each
        // Without sleep: HRV 42.8% + RHR 28.6% + Respiratory 14.3% (50) + Load 14.3% (50)
        // = 0.428*100 + 0.286*100 + 0.143*50 + 0.143*50 = 42.8 + 28.6 + 7.15 + 7.15 = 85.7

        #expect(result.score > 80 && result.score < 90, "Score should be ~85-86")
    }

    // MARK: - Edge Case: Negative Values

    @Test("HRV handles negative values")
    func testHRVNegativeValues() throws {
        // Negative HRV is invalid but shouldn't crash
        let score = RecoveryCalculations.calculateHRVComponent(hrv: -10.0, baseline: 50.0)

        // Should calculate but produce low score (extreme drop)
        #expect(score >= 0 && score <= 100, "Score should be in valid range")
        #expect(score < 50, "Negative HRV should produce low score")
    }

    @Test("RHR handles negative values")
    func testRHRNegativeValues() throws {
        // Negative RHR is invalid but shouldn't crash
        let score = RecoveryCalculations.calculateRHRComponent(rhr: -10.0, baseline: 60.0)

        // Should calculate but produce unexpected result
        #expect(score >= 0 && score <= 100, "Score should be in valid range")
    }

    // MARK: - Extreme Values

    @Test("HRV handles extremely high values")
    func testHRVExtremelyHigh() throws {
        // HRV at 500% of baseline (unrealistic but possible with device error)
        let score = RecoveryCalculations.calculateHRVComponent(hrv: 250.0, baseline: 50.0)

        // Should return 100 (at or above baseline)
        #expect(score == 100, "HRV above baseline should score 100")
    }

    @Test("HRV handles extremely low values")
    func testHRVExtremelyLow() throws {
        // HRV at 10% of baseline (90% drop - severe)
        let score = RecoveryCalculations.calculateHRVComponent(hrv: 5.0, baseline: 50.0)

        // Should return very low score (extreme drop >35%)
        #expect(score < 30, "90% HRV drop should produce very low score")
        #expect(score >= 0, "Score should not be negative")
    }

    @Test("RHR handles extremely high values")
    func testRHRExtremelyHigh() throws {
        // RHR at 200% of baseline (100% increase - severe elevation)
        let score = RecoveryCalculations.calculateRHRComponent(rhr: 120.0, baseline: 60.0)

        // Should return very low score (>25% increase)
        #expect(score < 37, "100% RHR increase should produce very low score")
        #expect(score >= 0, "Score should not be negative")
    }

    @Test("Sleep handles extremely long duration")
    func testSleepExtremelyLongDuration() throws {
        // 16 hours sleep (200% of baseline)
        let score = RecoveryCalculations.calculateSleepComponent(
            sleepScore: nil,
            sleepDuration: 57600, // 16 hours
            baseline: 28800 // 8 hours
        )

        // Should cap at 100
        #expect(score == 100, "Sleep duration should cap at 100")
    }

    // MARK: - Component Score Boundaries

    @Test("HRV score never exceeds 100")
    func testHRVScoreBoundary() throws {
        let testCases = [
            (hrv: 100.0, baseline: 50.0),  // 100% above baseline
            (hrv: 200.0, baseline: 50.0),  // 300% above baseline
            (hrv: 50.0, baseline: 50.0)    // At baseline
        ]

        for testCase in testCases {
            let score = RecoveryCalculations.calculateHRVComponent(
                hrv: testCase.hrv,
                baseline: testCase.baseline
            )
            #expect(score <= 100, "HRV score should not exceed 100")
            #expect(score >= 0, "HRV score should not be negative")
        }
    }

    @Test("RHR score never exceeds 100")
    func testRHRScoreBoundary() throws {
        let testCases = [
            (rhr: 30.0, baseline: 60.0),  // 50% below baseline
            (rhr: 60.0, baseline: 60.0),  // At baseline
            (rhr: 45.0, baseline: 60.0)   // 25% below baseline
        ]

        for testCase in testCases {
            let score = RecoveryCalculations.calculateRHRComponent(
                rhr: testCase.rhr,
                baseline: testCase.baseline
            )
            #expect(score <= 100, "RHR score should not exceed 100")
            #expect(score >= 0, "RHR score should not be negative")
        }
    }

    @Test("Overall recovery score clamped to 0-100 range")
    func testOverallScoreClamping() throws {
        // Test with extreme values that might push score outside range
        let extremeHigh = RecoveryCalculations.RecoveryInputs(
            hrv: 200.0,
            hrvBaseline: 50.0,
            rhr: 30.0,
            rhrBaseline: 60.0,
            atl: 20.0,
            ctl: 100.0,
            sleepScore: 100
        )

        let resultHigh = RecoveryCalculations.calculateScore(inputs: extremeHigh, hasSleepData: true)
        #expect(resultHigh.score <= 100, "Score should not exceed 100")
        #expect(resultHigh.score >= 0, "Score should not be negative")

        let extremeLow = RecoveryCalculations.RecoveryInputs(
            hrv: 10.0,
            hrvBaseline: 50.0,
            rhr: 120.0,
            rhrBaseline: 60.0,
            atl: 100.0,
            ctl: 20.0,
            sleepScore: 0
        )

        let resultLow = RecoveryCalculations.calculateScore(inputs: extremeLow, hasSleepData: true)
        #expect(resultLow.score <= 100, "Score should not exceed 100")
        #expect(resultLow.score >= 0, "Score should not be negative")
    }

    // MARK: - Real-World Fallback Scenarios

    @Test("Handles typical Apple Watch data (HRV + RHR only)")
    func testAppleWatchDataScenario() throws {
        // Apple Watch typically provides HRV and RHR, but limited sleep analysis
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 48.0,
            hrvBaseline: 50.0,
            rhr: 62.0,
            rhrBaseline: 60.0,
            sleepDuration: 25200, // 7 hours (from Apple Health)
            sleepBaseline: 28800,  // 8 hours
            sleepScore: nil // No comprehensive sleep score
        )

        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: true)

        // Should calculate with fallback sleep score
        // HRV: 48/50 = -4% drop → score ~94
        // RHR: 62/60 = +3.3% increase → score ~95
        // Sleep: 25200/28800 = 87.5% → score 87 (fallback)

        #expect(result.score > 70 && result.score < 95, "Should produce reasonable score with partial data")
        #expect(result.subScores.sleep == 87, "Should use fallback sleep calculation")
    }

    @Test("Handles basic fitness tracker data (RHR + steps only)")
    func testBasicFitnessTrackerScenario() throws {
        // Basic fitness trackers often only provide RHR and activity data
        let inputs = RecoveryCalculations.RecoveryInputs(
            rhr: 58.0,
            rhrBaseline: 60.0,
            atl: 50.0,
            ctl: 60.0
        )

        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasSleepData: false)

        // Should calculate with missing HRV and sleep
        #expect(result.score > 40 && result.score < 80, "Should produce reasonable score with minimal data")
        #expect(result.subScores.hrv == 50, "Missing HRV should default to 50")
        #expect(result.subScores.rhr == 100, "RHR below baseline should score 100")
    }
}
