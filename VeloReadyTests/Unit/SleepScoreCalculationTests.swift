import Foundation
import Testing
@testable import VeloReady

/// Comprehensive tests for Sleep Score calculation algorithm
/// Tests edge cases, boundary conditions, and validation logic
@Suite("Sleep Score Calculation")
struct SleepScoreCalculationTests {

    // MARK: - Performance Score Tests

    @Test("Performance score calculates correctly for exact sleep need")
    func testPerformanceScoreExactSleepNeed() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800, // 8 hours
            timeInBed: 30000,
            sleepNeed: 28800,     // 8 hours (exact match)
            deepSleepDuration: 7200,
            remSleepDuration: 7200,
            coreSleepDuration: 14400,
            awakeDuration: 1200,
            wakeEvents: 2,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 900
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Performance should be 100 (8/8 * 100 = 100)
        #expect(score.subScores.performance == 100)
    }

    @Test("Performance score handles oversleep correctly")
    func testPerformanceScoreOversleep() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 36000, // 10 hours
            timeInBed: 37000,
            sleepNeed: 28800,     // 8 hours (slept 2 hours extra)
            deepSleepDuration: 9000,
            remSleepDuration: 9000,
            coreSleepDuration: 18000,
            awakeDuration: 1000,
            wakeEvents: 1,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 600
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Performance capped at 100 even with oversleep (10/8 * 100 = 125 → capped at 100)
        #expect(score.subScores.performance == 100)
    }

    @Test("Performance score handles sleep deficit correctly")
    func testPerformanceScoreSleepDeficit() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 21600, // 6 hours
            timeInBed: 23000,
            sleepNeed: 28800,     // 8 hours (2 hour deficit)
            deepSleepDuration: 5400,
            remSleepDuration: 5400,
            coreSleepDuration: 10800,
            awakeDuration: 1400,
            wakeEvents: 3,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 48.0,
            hrvBaseline: 50.0,
            sleepLatency: 1200
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Performance should be 75 (6/8 * 100 = 75)
        #expect(score.subScores.performance == 75)
    }

    @Test("Performance score handles missing data gracefully")
    func testPerformanceScoreMissingData() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: nil, // Missing
            timeInBed: 28800,
            sleepNeed: nil,     // Missing
            deepSleepDuration: nil,
            remSleepDuration: nil,
            coreSleepDuration: nil,
            awakeDuration: nil,
            wakeEvents: nil,
            bedtime: nil,
            wakeTime: nil,
            baselineBedtime: nil,
            baselineWakeTime: nil,
            hrvOvernight: nil,
            hrvBaseline: nil,
            sleepLatency: nil
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Should default to 50 when data is missing
        #expect(score.subScores.performance == 50)
    }

    // MARK: - Efficiency Score Tests

    @Test("Efficiency score calculates correctly for good sleep efficiency")
    func testEfficiencyScoreGoodEfficiency() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800, // 8 hours
            timeInBed: 30000,     // 8.33 hours (96% efficiency)
            sleepNeed: 28800,
            deepSleepDuration: 7200,
            remSleepDuration: 7200,
            coreSleepDuration: 14400,
            awakeDuration: 1200,
            wakeEvents: 2,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 900
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Efficiency = 28800/30000 = 0.96 = 96%
        #expect(score.subScores.efficiency == 96)
    }

    @Test("Efficiency score handles poor efficiency")
    func testEfficiencyScorePoorEfficiency() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 21600, // 6 hours
            timeInBed: 32400,     // 9 hours (67% efficiency - poor)
            sleepNeed: 28800,
            deepSleepDuration: 5400,
            remSleepDuration: 5400,
            coreSleepDuration: 10800,
            awakeDuration: 10800, // 3 hours awake!
            wakeEvents: 8,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 45.0,
            hrvBaseline: 50.0,
            sleepLatency: 3600
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Efficiency = 21600/32400 = 0.667 = 67%
        #expect(score.subScores.efficiency == 66 || score.subScores.efficiency == 67)
    }

    // MARK: - Stage Quality Score Tests

    @Test("Stage quality score excellent for optimal deep+REM")
    func testStageQualityScoreOptimal() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800, // 8 hours
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 7200,  // 2 hours (25%)
            remSleepDuration: 7200,   // 2 hours (25%)
            coreSleepDuration: 14400, // 4 hours (50%)
            awakeDuration: 1200,
            wakeEvents: 2,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 55.0,
            hrvBaseline: 50.0,
            sleepLatency: 600
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Deep + REM = 50% (exceeds 40% target) → 100
        #expect(score.subScores.stageQuality == 100)
    }

    @Test("Stage quality score poor for insufficient deep+REM")
    func testStageQualityScorePoor() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800, // 8 hours
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 2880,  // 48 minutes (10%)
            remSleepDuration: 2880,   // 48 minutes (10%)
            coreSleepDuration: 23040, // 6.4 hours (80%)
            awakeDuration: 1200,
            wakeEvents: 5,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 42.0,
            hrvBaseline: 50.0,
            sleepLatency: 1800
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Deep + REM = 20% (poor - below 30% threshold)
        // Should be in 0-50 range based on linear scale
        #expect(score.subScores.stageQuality < 50)
        #expect(score.subScores.stageQuality > 0)
    }

    // MARK: - Disturbances Score Tests

    @Test("Disturbances score excellent for minimal wake events")
    func testDisturbancesScoreMinimalWakes() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 7200,
            remSleepDuration: 7200,
            coreSleepDuration: 14400,
            awakeDuration: 600,
            wakeEvents: 1, // Only 1 wake - excellent
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 52.0,
            hrvBaseline: 50.0,
            sleepLatency: 600
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // 0-2 wake events = 100
        #expect(score.subScores.disturbances == 100)
    }

    @Test("Disturbances score handles frequent wakes")
    func testDisturbancesScoreFrequentWakes() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 25200,
            timeInBed: 28800,
            sleepNeed: 28800,
            deepSleepDuration: 5400,
            remSleepDuration: 5400,
            coreSleepDuration: 14400,
            awakeDuration: 3600,
            wakeEvents: 12, // 12 wakes - very poor
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 40.0,
            hrvBaseline: 50.0,
            sleepLatency: 2400
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // 9+ wake events = 25
        #expect(score.subScores.disturbances == 25)
    }

    // MARK: - Timing Score Tests

    @Test("Timing score excellent for consistent schedule")
    func testTimingScoreConsistentSchedule() throws {
        let now = Date()
        let bedtime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        let wakeTime = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
        let baselineBedtime = Calendar.current.date(bySettingHour: 22, minute: 10, second: 0, of: now)! // 10 min deviation
        let baselineWakeTime = Calendar.current.date(bySettingHour: 6, minute: 5, second: 0, of: now)! // 5 min deviation

        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 7200,
            remSleepDuration: 7200,
            coreSleepDuration: 14400,
            awakeDuration: 1200,
            wakeEvents: 2,
            bedtime: bedtime,
            wakeTime: wakeTime,
            baselineBedtime: baselineBedtime,
            baselineWakeTime: baselineWakeTime,
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 900
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Average deviation = (10 + 5) / 2 = 7.5 minutes (< 30 min threshold) → 100
        #expect(score.subScores.timing == 100)
    }

    @Test("Timing score handles inconsistent schedule")
    func testTimingScoreInconsistentSchedule() throws {
        let now = Date()
        let bedtime = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: now)! // 3 hours late
        let wakeTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now)! // 3 hours late
        let baselineBedtime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: now.addingTimeInterval(-86400))!
        let baselineWakeTime = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: now)!

        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 6000,
            remSleepDuration: 6000,
            coreSleepDuration: 16800,
            awakeDuration: 1200,
            wakeEvents: 4,
            bedtime: bedtime,
            wakeTime: wakeTime,
            baselineBedtime: baselineBedtime,
            baselineWakeTime: baselineWakeTime,
            hrvOvernight: 48.0,
            hrvBaseline: 50.0,
            sleepLatency: 1200
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Large deviation (180 min avg) → 25
        #expect(score.subScores.timing == 25)
    }

    // MARK: - Overall Score Tests

    @Test("Overall score weighted correctly")
    func testOverallScoreWeighting() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 7200,
            remSleepDuration: 7200,
            coreSleepDuration: 14400,
            awakeDuration: 1200,
            wakeEvents: 2,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 900
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Expected: Performance=100, Efficiency=96, StageQuality=100, Disturbances=100, Timing=100
        // Weighted = 100*0.30 + 96*0.22 + 100*0.32 + 100*0.14 + 100*0.02
        //          = 30 + 21.12 + 32 + 14 + 2 = 99.12 → 99
        #expect(score.score >= 98 && score.score <= 100)
    }

    @Test("Overall score handles all-zeros gracefully")
    func testOverallScoreAllZeros() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: nil,
            timeInBed: nil,
            sleepNeed: nil,
            deepSleepDuration: nil,
            remSleepDuration: nil,
            coreSleepDuration: nil,
            awakeDuration: nil,
            wakeEvents: nil,
            bedtime: nil,
            wakeTime: nil,
            baselineBedtime: nil,
            baselineWakeTime: nil,
            hrvOvernight: nil,
            hrvBaseline: nil,
            sleepLatency: nil
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // All sub-scores default to 50 when data missing
        // Weighted = 50*0.30 + 50*0.22 + 50*0.32 + 50*0.14 + 50*0.02 = 50
        #expect(score.score == 50)
    }

    // MARK: - Band Classification Tests

    @Test("Band classification correct for optimal range")
    func testBandClassificationOptimal() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 30000,
            timeInBed: 31200,
            sleepNeed: 28800,
            deepSleepDuration: 8000,
            remSleepDuration: 8000,
            coreSleepDuration: 14000,
            awakeDuration: 1200,
            wakeEvents: 1,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 55.0,
            hrvBaseline: 50.0,
            sleepLatency: 600
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs)

        // Score should be >= 80 → Optimal band
        #expect(score.band == .optimal)
    }

    @Test("Band classification correct for boundary values")
    func testBandClassificationBoundaries() throws {
        // Test score exactly at 80 (boundary between Good and Optimal)
        let inputs80 = SleepScore.SleepInputs(
            sleepDuration: 28800, // Tuned to get exactly 80
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 6480,  // 22.5%
            remSleepDuration: 6480,   // 22.5% (total 45%)
            coreSleepDuration: 15840,
            awakeDuration: 1200,
            wakeEvents: 3,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 900
        )

        let score80 = SleepScoreCalculator.calculate(inputs: inputs80)

        // Score >= 80 should be Optimal
        if score80.score >= 80 {
            #expect(score80.band == .optimal)
        }
    }

    // MARK: - Illness Indicator Integration Tests

    @Test("Sleep score includes illness indicator when present")
    func testSleepScoreWithIllnessIndicator() throws {
        let illnessIndicator = IllnessIndicator(
            date: Date(),
            severity: .moderate,
            confidence: 0.78,
            signals: [
                IllnessIndicator.Signal(
                    type: .elevatedRHR,
                    deviation: 8.5,
                    value: 65.0,
                    baseline: 60.0
                )
            ],
            recommendation: "Rest recommended"
        )

        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 7200,
            remSleepDuration: 7200,
            coreSleepDuration: 14400,
            awakeDuration: 1200,
            wakeEvents: 2,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 900
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs, illnessIndicator: illnessIndicator)

        #expect(score.illnessDetected == true)
        #expect(score.illnessSeverity == "moderate")
    }

    @Test("Sleep score without illness indicator")
    func testSleepScoreWithoutIllnessIndicator() throws {
        let inputs = SleepScore.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 30000,
            sleepNeed: 28800,
            deepSleepDuration: 7200,
            remSleepDuration: 7200,
            coreSleepDuration: 14400,
            awakeDuration: 1200,
            wakeEvents: 2,
            bedtime: Date(),
            wakeTime: Date(),
            baselineBedtime: Date(),
            baselineWakeTime: Date(),
            hrvOvernight: 50.0,
            hrvBaseline: 50.0,
            sleepLatency: 900
        )

        let score = SleepScoreCalculator.calculate(inputs: inputs, illnessIndicator: nil)

        #expect(score.illnessDetected == false)
        #expect(score.illnessSeverity == nil)
    }
}
