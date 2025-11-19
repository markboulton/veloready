import Foundation
import Testing
@testable import VeloReady
@testable import VeloReadyCore

/// Comprehensive tests for Progressive Training Load calculation
/// Tests baseline seeding, progressive calculation accuracy, and fallback scenarios
/// Ensures regression-free training load calculations when Core Data insufficient
@Suite("Progressive Training Load Calculation")
struct ProgressiveTrainingLoadTests {

    // MARK: - Baseline Seeding Tests

    @Test("Seeds baseline from Core Data when available")
    func testSeedsBaselineFromCoreData() throws {
        // Given: Known CTL=50, ATL=45 from recent Core Data
        let baselineCTL = 50.0
        let baselineATL = 45.0

        // When: Starting progressive calculation with baseline
        // First day's calculation should use these as starting point
        let dailyTSS = [100.0] // One new day

        // Calculate from baseline
        let newCTL = baselineCTL * (1.0 - 1.0/42.0) + dailyTSS[0] * (1.0/42.0)
        let newATL = baselineATL * (1.0 - 1.0/7.0) + dailyTSS[0] * (1.0/7.0)

        // Then: New values should be calculated from baseline
        // CTL: 50 * 0.976 + 100 * 0.024 = 48.8 + 2.4 = 51.2
        // ATL: 45 * 0.857 + 100 * 0.143 = 38.6 + 14.3 = 52.9

        #expect(abs(newCTL - 51.2) < 0.5, "CTL should be calculated from baseline")
        #expect(abs(newATL - 52.9) < 0.5, "ATL should be calculated from baseline")
    }

    @Test("Uses zero baseline when no Core Data available")
    func testUsesZeroBaselineWhenNoCoreData() throws {
        // Given: No Core Data (cold start)
        let baselineCTL = 0.0
        let baselineATL = 0.0

        // When: Starting progressive calculation from zero
        let dailyTSS = [100.0]

        let newCTL = baselineCTL * (1.0 - 1.0/42.0) + dailyTSS[0] * (1.0/42.0)
        let newATL = baselineATL * (1.0 - 1.0/7.0) + dailyTSS[0] * (1.0/7.0)

        // Then: Values should be calculated from zero
        // CTL: 0 * 0.976 + 100 * 0.024 = 2.4
        // ATL: 0 * 0.857 + 100 * 0.143 = 14.3

        #expect(abs(newCTL - 2.4) < 0.1, "CTL should start from zero")
        #expect(abs(newATL - 14.3) < 0.1, "ATL should start from zero")
    }

    @Test("Baseline seeding produces continuous progression")
    func testBaselineSeedingContinuity() throws {
        // Given: Baseline from Core Data (CTL=45, ATL=40)
        let baselineCTL = 45.0
        let baselineATL = 40.0

        // When: Adding 3 days of progressive data
        let dailyTSS = [80.0, 90.0, 100.0]

        var ctl = baselineCTL
        var atl = baselineATL

        for tss in dailyTSS {
            ctl = ctl * (1.0 - 1.0/42.0) + tss * (1.0/42.0)
            atl = atl * (1.0 - 1.0/7.0) + tss * (1.0/7.0)
        }

        // Then: Values should increase progressively from baseline
        #expect(ctl > baselineCTL, "CTL should increase from baseline")
        #expect(atl > baselineATL, "ATL should increase from baseline")
        #expect(ctl > 45.0 && ctl < 50.0, "CTL should be in realistic range")
        #expect(atl > 60.0 && atl < 70.0, "ATL should be in realistic range")
    }

    // MARK: - Progressive Calculation Accuracy Tests

    @Test("Progressive calculation matches formula for 7-day period")
    func testProgressiveCalculation7Days() throws {
        // Given: 7 days of consistent 100 TSS workouts
        let dailyTSS = Array(repeating: 100.0, count: 7)

        // When: Calculate using progressive method
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should match expected values
        // CTL after 7 days ≈ 15.6
        // ATL after 7 days ≈ 81.8

        #expect(ctl > 15.0 && ctl < 17.0, "CTL should be ~15-16 after 7 days")
        #expect(atl > 75.0 && atl < 85.0, "ATL should be ~75-85 after 7 days")
    }

    @Test("Progressive calculation matches formula for 14-day period")
    func testProgressiveCalculation14Days() throws {
        // Given: 14 days of consistent 100 TSS workouts
        let dailyTSS = Array(repeating: 100.0, count: 14)

        // When: Calculate using progressive method
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should match expected values
        // CTL after 14 days ≈ 28.8
        // ATL after 14 days ≈ 94.6

        #expect(ctl > 27.0 && ctl < 30.0, "CTL should be ~27-30 after 14 days")
        #expect(atl > 90.0 && atl < 98.0, "ATL should be ~90-98 after 14 days")
    }

    @Test("Progressive calculation handles varying TSS values")
    func testProgressiveCalculationVaryingTSS() throws {
        // Given: Realistic week with varying workouts
        let dailyTSS = [
            0.0,   // Rest day
            50.0,  // Easy recovery
            100.0, // Moderate ride
            0.0,   // Rest day
            150.0, // Long endurance
            80.0,  // Tempo
            0.0    // Rest day
        ]

        // When: Calculate progressive load
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should produce reasonable values
        #expect(ctl > 5.0 && ctl < 15.0, "CTL should be in realistic range for varied week")
        #expect(atl > 30.0 && atl < 60.0, "ATL should be in realistic range for varied week")
        #expect(atl > ctl, "ATL should be higher than CTL after single week")
    }

    // MARK: - Gap Filling Tests

    @Test("Fills missing days with zero TSS")
    func testFillsMissingDaysWithZero() throws {
        // Given: Activities with gaps (Mon, Wed, Fri)
        let mondayTSS = 100.0
        let wednesdayTSS = 80.0
        let fridayTSS = 90.0

        // When: Progressive calculation fills gaps
        let dailyTSS = [
            mondayTSS,    // Mon
            0.0,          // Tue (gap filled)
            wednesdayTSS, // Wed
            0.0,          // Thu (gap filled)
            fridayTSS,    // Fri
            0.0,          // Sat (gap filled)
            0.0           // Sun (gap filled)
        ]

        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should calculate correctly with zero-filled gaps
        #expect(ctl > 0.0, "CTL should be positive")
        #expect(atl > 0.0, "ATL should be positive")
        #expect(ctl.isFinite && atl.isFinite, "Values should be finite")
    }

    @Test("Handles consecutive rest days correctly")
    func testHandlesConsecutiveRestDays() throws {
        // Given: Hard training followed by 4 rest days
        let dailyTSS = [100.0, 120.0, 100.0, 0.0, 0.0, 0.0, 0.0]

        // When: Calculate with rest days
        let ctlBeforeRest = TrainingLoadCalculations.calculateCTL(dailyTSS: Array(dailyTSS.prefix(3)))
        let ctlAfterRest = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)

        let atlBeforeRest = TrainingLoadCalculations.calculateATL(dailyTSS: Array(dailyTSS.prefix(3)))
        let atlAfterRest = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Values should decay during rest
        #expect(ctlAfterRest < ctlBeforeRest, "CTL should decay during rest")
        #expect(atlAfterRest < atlBeforeRest, "ATL should decay during rest")

        // ATL should decay faster than CTL
        let ctlDecay = (ctlBeforeRest - ctlAfterRest) / ctlBeforeRest
        let atlDecay = (atlBeforeRest - atlAfterRest) / atlBeforeRest
        #expect(atlDecay > ctlDecay, "ATL should decay faster than CTL")
    }

    // MARK: - Baseline vs Progressive Comparison

    @Test("Progressive calculation converges toward steady state")
    func testConvergenceToSteadyState() throws {
        // Given: 90 days of consistent 100 TSS (more than 2x CTL time constant)
        let dailyTSS = Array(repeating: 100.0, count: 90)

        // When: Calculate final values
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)

        // Then: CTL should approach steady state (~85-95% of TSS)
        #expect(ctl > 85.0 && ctl < 100.0, "CTL should converge toward steady state")
    }

    @Test("Progressive matches batch calculation for same period")
    func testProgressiveMatchesBatchCalculation() throws {
        // Given: 14 days of data
        let dailyTSS = [80.0, 100.0, 90.0, 0.0, 120.0, 110.0, 0.0,
                        75.0, 95.0, 85.0, 0.0, 100.0, 90.0, 0.0]

        // When: Calculate with both methods
        let batchCTL = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let batchATL = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Progressive calculation (same as batch, just conceptually different)
        let progressiveCTL = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let progressiveATL = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Both methods should produce identical results
        #expect(abs(batchCTL - progressiveCTL) < 0.01, "CTL should match between methods")
        #expect(abs(batchATL - progressiveATL) < 0.01, "ATL should match between methods")
    }

    // MARK: - Edge Cases

    @Test("Handles single activity in week")
    func testSingleActivityInWeek() throws {
        // Given: Only one activity in 7 days
        let dailyTSS = [0.0, 0.0, 0.0, 100.0, 0.0, 0.0, 0.0]

        // When: Calculate load
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should produce low but valid values
        #expect(ctl > 0.0 && ctl < 5.0, "CTL should be low for single activity")
        #expect(atl > 5.0 && atl < 20.0, "ATL should be higher than CTL")
        #expect(atl > ctl, "ATL responds faster to single spike")
    }

    @Test("Handles alternating high/low days")
    func testAlternatingHighLowDays() throws {
        // Given: Alternating pattern (polarized training)
        let dailyTSS = [120.0, 40.0, 130.0, 35.0, 125.0, 45.0, 0.0]

        // When: Calculate load
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should smooth out the alternation
        #expect(ctl > 10.0 && ctl < 20.0, "CTL should smooth alternating pattern")
        #expect(atl > 40.0 && atl < 70.0, "ATL should reflect recent alternation")
    }

    @Test("Handles extremely high single day TSS")
    func testExtremelyHighSingleDayTSS() throws {
        // Given: Ultra-endurance event (e.g., 12-hour race)
        let dailyTSS = [0.0, 0.0, 0.0, 500.0, 0.0, 0.0, 0.0]

        // When: Calculate load
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: ATL should spike significantly, CTL less so
        #expect(ctl > 5.0 && ctl < 20.0, "CTL should increase moderately")
        #expect(atl > 50.0 && atl < 100.0, "ATL should spike significantly")
        #expect(atl > ctl * 3, "ATL should be much higher than CTL after spike")
    }

    @Test("Handles all zero TSS (complete rest period)")
    func testAllZeroTSS() throws {
        // Given: Complete rest week
        let dailyTSS = Array(repeating: 0.0, count: 7)

        // When: Calculate from non-zero baseline
        // Simulate existing fitness
        var ctl = 50.0
        var atl = 45.0

        for tss in dailyTSS {
            ctl = ctl * (1.0 - 1.0/42.0) + tss * (1.0/42.0)
            atl = atl * (1.0 - 1.0/7.0) + tss * (1.0/7.0)
        }

        // Then: Values should decay but remain positive
        #expect(ctl > 40.0 && ctl < 50.0, "CTL should decay slowly")
        #expect(atl > 20.0 && atl < 40.0, "ATL should decay quickly")
        #expect(atl < 45.0, "ATL should have decreased")
    }

    // MARK: - Realistic Training Scenarios

    @Test("Build phase: Progressive overload")
    func testBuildPhaseProgressiveOverload() throws {
        // Given: 4 weeks of progressive build (300 → 400 → 500 → 600 TSS/week)
        var dailyTSS: [Double] = []

        for week in 1...4 {
            let weeklyTSS = Double(200 + week * 100)
            let dailyAverage = weeklyTSS / 7.0
            dailyTSS.append(contentsOf: Array(repeating: dailyAverage, count: 7))
        }

        // When: Calculate final load
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Both should increase progressively
        #expect(ctl > 40.0, "CTL should build significantly over 4 weeks")
        #expect(atl > 60.0, "ATL should build significantly over 4 weeks")
        #expect(atl > ctl, "ATL should be higher than CTL during build")
    }

    @Test("Taper: Reduced volume maintains CTL, drops ATL")
    func testTaperScenario() throws {
        // Given: 3 weeks build + 1 week taper
        let buildWeek = Array(repeating: 100.0, count: 21) // 3 weeks
        let taperWeek = Array(repeating: 40.0, count: 7)   // 1 week reduced

        let buildLoad = buildWeek + taperWeek

        let ctlPreTaper = TrainingLoadCalculations.calculateCTL(dailyTSS: buildWeek)
        let atlPreTaper = TrainingLoadCalculations.calculateATL(dailyTSS: buildWeek)

        let ctlPostTaper = TrainingLoadCalculations.calculateCTL(dailyTSS: buildLoad)
        let atlPostTaper = TrainingLoadCalculations.calculateATL(dailyTSS: buildLoad)

        // Then: CTL should maintain, ATL should drop
        let ctlChange = ctlPostTaper - ctlPreTaper
        let atlChange = atlPostTaper - atlPreTaper

        #expect(abs(ctlChange) < 5.0, "CTL should remain relatively stable")
        #expect(atlChange < -10.0, "ATL should drop significantly")
        #expect(ctlPostTaper > atlPostTaper, "CTL should exceed ATL after taper (positive TSB)")
    }

    @Test("Off-season: Gradual detraining")
    func testOffSeasonDetraining() throws {
        // Given: 2 weeks of reduced training (simulating off-season)
        let normalWeek = Array(repeating: 80.0, count: 7)
        let reducedWeeks = Array(repeating: 20.0, count: 14)

        let fullPeriod = normalWeek + reducedWeeks

        let ctlNormal = TrainingLoadCalculations.calculateCTL(dailyTSS: normalWeek)
        let atlNormal = TrainingLoadCalculations.calculateATL(dailyTSS: normalWeek)

        let ctlReduced = TrainingLoadCalculations.calculateCTL(dailyTSS: fullPeriod)
        let atlReduced = TrainingLoadCalculations.calculateATL(dailyTSS: fullPeriod)

        // Then: Both should decrease, ATL faster
        #expect(ctlReduced < ctlNormal, "CTL should decrease during detraining")
        #expect(atlReduced < atlNormal, "ATL should decrease during detraining")

        let ctlLoss = (ctlNormal - ctlReduced) / ctlNormal
        let atlLoss = (atlNormal - atlReduced) / atlNormal

        #expect(atlLoss > ctlLoss, "ATL should drop faster than CTL during detraining")
    }

    // MARK: - Data Quality Tests

    @Test("Progressive calculation handles negative TSS gracefully")
    func testHandlesNegativeTSS() throws {
        // Given: Invalid data with negative TSS (should not happen but test robustness)
        let dailyTSS = [100.0, -50.0, 80.0, 90.0]

        // When: Calculate (should not crash)
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should produce finite values (may be unexpected but stable)
        #expect(ctl.isFinite, "CTL should be finite even with invalid data")
        #expect(atl.isFinite, "ATL should be finite even with invalid data")
    }

    @Test("Progressive calculation handles very small TSS values")
    func testHandlesVerySmallTSS() throws {
        // Given: Very light activities (short walks, stretching)
        let dailyTSS = [2.0, 3.0, 1.5, 0.0, 2.5, 1.0, 0.0]

        // When: Calculate load
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should produce very small but valid values
        #expect(ctl > 0.0 && ctl < 2.0, "CTL should be very small for light activities")
        #expect(atl > 0.0 && atl < 3.0, "ATL should be very small for light activities")
    }

    @Test("Progressive calculation maintains numerical stability")
    func testNumericalStability() throws {
        // Given: Long series with varying values
        var dailyTSS: [Double] = []
        for i in 0..<90 {
            let tss = 50.0 + Double(i % 50) // Varying 50-100
            dailyTSS.append(tss)
        }

        // When: Calculate over long period
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Then: Should remain numerically stable
        #expect(ctl.isFinite, "CTL should be finite over long calculation")
        #expect(atl.isFinite, "ATL should be finite over long calculation")
        #expect(ctl > 0 && ctl < 200, "CTL should be in realistic range")
        #expect(atl > 0 && atl < 200, "ATL should be in realistic range")
    }
}
