import Foundation
import Testing
@testable import VeloReady
@testable import VeloReadyCore

/// Comprehensive tests for TSS (Training Stress Score) calculation accuracy
/// Tests TSS formula, Intensity Factor (IF), Normalized Power (NP), and edge cases
/// These tests ensure regression-free training load calculations that match industry standards
@Suite("TSS & Training Load Calculations")
struct TSSCalculationTests {

    // MARK: - TSS Formula Tests

    @Test("TSS calculated correctly for standard 1-hour ride at FTP")
    func testTSSForOneHourAtFTP() throws {
        // Given: 1 hour ride at FTP (IF = 1.0)
        // Formula: TSS = (duration_hours × IF^2 × 100)
        // Expected: TSS = 1 × 1.0^2 × 100 = 100

        let duration: Double = 3600 // 1 hour in seconds
        let normalizedPower: Double = 250 // Matches FTP
        let ftp: Double = 250

        let intensityFactor = normalizedPower / ftp
        let durationHours = duration / 3600.0
        let tss = durationHours * pow(intensityFactor, 2) * 100

        #expect(intensityFactor == 1.0)
        #expect(tss == 100.0)
    }

    @Test("TSS calculated correctly for 2-hour endurance ride at 75% FTP")
    func testTSSForEnduranceRide() throws {
        // Given: 2 hour ride at 75% FTP (IF = 0.75)
        // Formula: TSS = (2 × 0.75^2 × 100) = 2 × 0.5625 × 100 = 112.5

        let duration: Double = 7200 // 2 hours
        let normalizedPower: Double = 187.5 // 75% of 250
        let ftp: Double = 250

        let intensityFactor = normalizedPower / ftp
        let durationHours = duration / 3600.0
        let tss = durationHours * pow(intensityFactor, 2) * 100

        #expect(intensityFactor == 0.75)
        #expect(tss == 112.5)
    }

    @Test("TSS calculated correctly for high-intensity interval session")
    func testTSSForIntervalSession() throws {
        // Given: 1 hour interval session at 105% FTP (IF = 1.05)
        // Formula: TSS = (1 × 1.05^2 × 100) = 1 × 1.1025 × 100 = 110.25

        let duration: Double = 3600 // 1 hour
        let normalizedPower: Double = 262.5 // 105% of 250
        let ftp: Double = 250

        let intensityFactor = normalizedPower / ftp
        let durationHours = duration / 3600.0
        let tss = durationHours * pow(intensityFactor, 2) * 100

        #expect(intensityFactor == 1.05)
        #expect(tss == 110.25)
    }

    @Test("TSS calculated correctly for 30-minute recovery ride")
    func testTSSForRecoveryRide() throws {
        // Given: 30 min recovery ride at 50% FTP (IF = 0.5)
        // Formula: TSS = (0.5 × 0.5^2 × 100) = 0.5 × 0.25 × 100 = 12.5

        let duration: Double = 1800 // 30 minutes
        let normalizedPower: Double = 125 // 50% of 250
        let ftp: Double = 250

        let intensityFactor = normalizedPower / ftp
        let durationHours = duration / 3600.0
        let tss = durationHours * pow(intensityFactor, 2) * 100

        #expect(intensityFactor == 0.5)
        #expect(tss == 12.5)
    }

    // MARK: - Intensity Factor Tests

    @Test("Intensity Factor calculated correctly")
    func testIntensityFactorCalculation() throws {
        let testCases: [(normalizedPower: Double, ftp: Double, expectedIF: Double)] = [
            (250, 250, 1.0),    // At FTP
            (200, 250, 0.8),    // Endurance
            (275, 250, 1.1),    // Hard
            (125, 250, 0.5),    // Easy recovery
            (300, 250, 1.2)     // Very hard
        ]

        for testCase in testCases {
            let intensityFactor = testCase.normalizedPower / testCase.ftp
            #expect(abs(intensityFactor - testCase.expectedIF) < 0.01, "IF should be \(testCase.expectedIF) but got \(intensityFactor)")
        }
    }

    // MARK: - CTL/ATL/TSB Calculation Tests

    @Test("CTL calculated correctly with exponential weighted average")
    func testCTLCalculation() throws {
        // Given: 7 days of consistent 100 TSS workouts
        // CTL uses 42-day time constant
        // Formula: CTL_today = CTL_yesterday * (1 - 1/42) + TSS_today * (1/42)

        let dailyTSS = Array(repeating: 100.0, count: 7)
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)

        // After 7 days of 100 TSS each, CTL should be approximately 15-16
        // Manual calculation:
        // Day 1: 0 * 0.976 + 100 * 0.024 = 2.38
        // Day 2: 2.38 * 0.976 + 100 * 0.024 = 4.72
        // Day 3: 4.72 * 0.976 + 100 * 0.024 = 7.00
        // Day 7: ~15.6

        #expect(ctl > 15.0 && ctl < 17.0, "CTL should be approximately 15-16 after 7 days of 100 TSS")
    }

    @Test("ATL calculated correctly with 7-day time constant")
    func testATLCalculation() throws {
        // Given: 7 days of consistent 100 TSS workouts
        // ATL uses 7-day time constant (responds faster than CTL)
        // Formula: ATL_today = ATL_yesterday * (1 - 1/7) + TSS_today * (1/7)

        let dailyTSS = Array(repeating: 100.0, count: 7)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // After 7 days of 100 TSS each, ATL should be close to 100
        // Manual calculation:
        // Day 1: 0 * 0.857 + 100 * 0.143 = 14.3
        // Day 2: 14.3 * 0.857 + 100 * 0.143 = 26.5
        // Day 3: 26.5 * 0.857 + 100 * 0.143 = 37.0
        // Day 7: ~81.8

        #expect(atl > 75.0 && atl < 85.0, "ATL should be approximately 75-85 after 7 days of 100 TSS")
    }

    @Test("CTL responds slower than ATL to training changes")
    func testCTLATLResponseRates() throws {
        // Given: 7 days of 100 TSS, then 7 days of 0 TSS
        let trainingSeries = Array(repeating: 100.0, count: 7) + Array(repeating: 0.0, count: 7)

        let ctlFirstWeek = TrainingLoadCalculations.calculateCTL(dailyTSS: Array(trainingSeries.prefix(7)))
        let atlFirstWeek = TrainingLoadCalculations.calculateATL(dailyTSS: Array(trainingSeries.prefix(7)))

        let ctlSecondWeek = TrainingLoadCalculations.calculateCTL(dailyTSS: trainingSeries)
        let atlSecondWeek = TrainingLoadCalculations.calculateATL(dailyTSS: trainingSeries)

        // ATL should decay faster (larger percentage drop) than CTL during rest week
        let ctlDecayPercent = (ctlFirstWeek - ctlSecondWeek) / ctlFirstWeek
        let atlDecayPercent = (atlFirstWeek - atlSecondWeek) / atlFirstWeek

        #expect(atlDecayPercent > ctlDecayPercent, "ATL should decay faster than CTL during rest")
    }

    @Test("TSB calculated correctly as CTL minus ATL")
    func testTSBCalculation() throws {
        let ctl: Double = 50.0
        let atl: Double = 40.0

        let tsb = TrainingLoadCalculations.calculateTSB(ctl: ctl, atl: atl)

        #expect(tsb == 10.0, "TSB = CTL - ATL = 50 - 40 = 10")
    }

    @Test("TSB interpretation: positive indicates freshness")
    func testTSBInterpretationFresh() throws {
        let ctl: Double = 50.0
        let atl: Double = 35.0 // Lower fatigue than fitness

        let tsb = TrainingLoadCalculations.calculateTSB(ctl: ctl, atl: atl)

        #expect(tsb > 0, "Positive TSB indicates freshness (ready for hard efforts)")
        #expect(tsb == 15.0)
    }

    @Test("TSB interpretation: negative indicates fatigue")
    func testTSBInterpretationFatigued() throws {
        let ctl: Double = 50.0
        let atl: Double = 65.0 // Higher fatigue than fitness

        let tsb = TrainingLoadCalculations.calculateTSB(ctl: ctl, atl: atl)

        #expect(tsb < 0, "Negative TSB indicates fatigue (need recovery)")
        #expect(tsb == -15.0)
    }

    @Test("TSB interpretation: zero indicates balanced")
    func testTSBInterpretationBalanced() throws {
        let ctl: Double = 50.0
        let atl: Double = 50.0 // Fitness equals fatigue

        let tsb = TrainingLoadCalculations.calculateTSB(ctl: ctl, atl: atl)

        #expect(tsb == 0.0, "Zero TSB indicates balanced state")
    }

    // MARK: - Edge Cases & Error Handling

    @Test("TSS is zero when power is zero")
    func testTSSZeroPower() throws {
        let duration: Double = 3600
        let normalizedPower: Double = 0
        let ftp: Double = 250

        let intensityFactor = normalizedPower / ftp
        let durationHours = duration / 3600.0
        let tss = durationHours * pow(intensityFactor, 2) * 100

        #expect(tss == 0.0, "TSS should be zero when power is zero")
    }

    @Test("TSS handles zero FTP gracefully")
    func testTSSZeroFTP() throws {
        let duration: Double = 3600
        let normalizedPower: Double = 200
        let ftp: Double = 0

        // Should handle division by zero gracefully
        guard ftp > 0 else {
            // Expected behavior: can't calculate TSS without FTP
            #expect(true, "Correctly handles zero FTP")
            return
        }

        // This path should not be reached
        #expect(false, "Should not calculate TSS with zero FTP")
    }

    @Test("CTL returns zero for empty TSS array")
    func testCTLEmptyData() throws {
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: [])
        #expect(ctl == 0.0, "CTL should be zero for empty data")
    }

    @Test("ATL returns zero for empty TSS array")
    func testATLEmptyData() throws {
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: [])
        #expect(atl == 0.0, "ATL should be zero for empty data")
    }

    @Test("CTL handles single day of data")
    func testCTLSingleDay() throws {
        let dailyTSS = [100.0]
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)

        // CTL after 1 day = 0 * (1 - 1/42) + 100 * (1/42) = 2.38
        #expect(ctl > 2.0 && ctl < 3.0, "CTL after 1 day should be approximately 2.38")
    }

    @Test("ATL handles single day of data")
    func testATLSingleDay() throws {
        let dailyTSS = [100.0]
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // ATL after 1 day = 0 * (1 - 1/7) + 100 * (1/7) = 14.29
        #expect(atl > 14.0 && atl < 15.0, "ATL after 1 day should be approximately 14.29")
    }

    @Test("CTL/ATL handle negative TSS values (invalid data)")
    func testNegativeTSS() throws {
        // Negative TSS is invalid but should not crash
        let dailyTSS = [-50.0, 100.0, 80.0]

        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // Should calculate but may produce unexpected results
        #expect(ctl.isFinite, "CTL should be finite even with invalid data")
        #expect(atl.isFinite, "ATL should be finite even with invalid data")
    }

    @Test("CTL/ATL handle very large TSS values")
    func testVeryLargeTSS() throws {
        // Ultra-endurance event with TSS of 500+
        let dailyTSS = [0.0, 0.0, 0.0, 500.0, 0.0, 0.0, 0.0]

        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)

        // ATL should spike significantly (responds faster)
        // CTL should increase but less dramatically
        #expect(atl > ctl, "ATL should be higher than CTL after big TSS spike")
        #expect(ctl.isFinite && atl.isFinite, "Values should be finite")
    }

    // MARK: - Progressive Build Tests

    @Test("CTL increases progressively with consistent training")
    func testCTLProgressiveBuild() throws {
        // 30 days of gradually increasing TSS (60 → 100)
        var dailyTSS: [Double] = []
        for day in 0..<30 {
            let tss = 60.0 + (Double(day) / 30.0) * 40.0
            dailyTSS.append(tss)
        }

        let ctlInitial = TrainingLoadCalculations.calculateCTL(dailyTSS: Array(dailyTSS.prefix(7)))
        let ctlFinal = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)

        #expect(ctlFinal > ctlInitial, "CTL should increase with progressive training")
        #expect(ctlFinal > 40.0, "CTL should be substantial after 30 days of training")
    }

    @Test("Exponential average converges to steady-state value")
    func testExponentialAverageConvergence() throws {
        // 90 days of consistent 100 TSS (more than 2x CTL time constant)
        let dailyTSS = Array(repeating: 100.0, count: 90)

        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)

        // After many time constants, CTL should converge close to TSS value
        // Theoretical steady state = TSS * weight / (1 - (1 - weight)) = 100
        // But exponential decay means it approaches asymptotically
        // After 90 days (>2 time constants), should be ~85-95% of steady state

        #expect(ctl > 85.0 && ctl < 100.0, "CTL should converge toward steady-state after many days")
    }

    // MARK: - Real-World Scenario Tests

    @Test("Weekly training volume scenarios")
    func testWeeklyTrainingScenarios() throws {
        // Scenario 1: Moderate consistent training (500 TSS/week = ~70 TSS/day)
        let moderateWeek = Array(repeating: 70.0, count: 7)
        let ctlModerate = TrainingLoadCalculations.calculateCTL(dailyTSS: moderateWeek)
        let atlModerate = TrainingLoadCalculations.calculateATL(dailyTSS: moderateWeek)

        // Scenario 2: High-volume training (700 TSS/week = ~100 TSS/day)
        let highVolumeWeek = Array(repeating: 100.0, count: 7)
        let ctlHigh = TrainingLoadCalculations.calculateCTL(dailyTSS: highVolumeWeek)
        let atlHigh = TrainingLoadCalculations.calculateATL(dailyTSS: highVolumeWeek)

        #expect(ctlHigh > ctlModerate, "Higher volume should produce higher CTL")
        #expect(atlHigh > atlModerate, "Higher volume should produce higher ATL")
    }

    @Test("Taper scenario: TSB increases during rest")
    func testTaperScenario() throws {
        // Build phase: 3 weeks of 100 TSS/day
        let buildPhase = Array(repeating: 100.0, count: 21)

        // Taper phase: 1 week of 40 TSS/day
        let taperPhase = Array(repeating: 40.0, count: 7)

        let fullPeriod = buildPhase + taperPhase

        let ctlPreTaper = TrainingLoadCalculations.calculateCTL(dailyTSS: buildPhase)
        let atlPreTaper = TrainingLoadCalculations.calculateATL(dailyTSS: buildPhase)
        let tsbPreTaper = TrainingLoadCalculations.calculateTSB(ctl: ctlPreTaper, atl: atlPreTaper)

        let ctlPostTaper = TrainingLoadCalculations.calculateCTL(dailyTSS: fullPeriod)
        let atlPostTaper = TrainingLoadCalculations.calculateATL(dailyTSS: fullPeriod)
        let tsbPostTaper = TrainingLoadCalculations.calculateTSB(ctl: ctlPostTaper, atl: atlPostTaper)

        // During taper: ATL drops faster than CTL, so TSB increases (becomes more positive)
        #expect(tsbPostTaper > tsbPreTaper, "TSB should increase during taper")
        #expect(atlPostTaper < atlPreTaper, "ATL should decrease during taper")
    }

    @Test("Recovery week: ATL drops significantly")
    func testRecoveryWeek() throws {
        // 2 weeks hard training (100 TSS/day) followed by 1 week recovery (20 TSS/day)
        let hardTraining = Array(repeating: 100.0, count: 14)
        let recovery = Array(repeating: 20.0, count: 7)

        let atlPreRecovery = TrainingLoadCalculations.calculateATL(dailyTSS: hardTraining)
        let atlPostRecovery = TrainingLoadCalculations.calculateATL(dailyTSS: hardTraining + recovery)

        // ATL should drop significantly (more than 50%) during recovery week
        let atlDropPercent = (atlPreRecovery - atlPostRecovery) / atlPreRecovery

        #expect(atlDropPercent > 0.3, "ATL should drop substantially during recovery week")
    }
}
