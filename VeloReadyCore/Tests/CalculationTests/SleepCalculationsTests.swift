import XCTest
@testable import VeloReadyCore

final class SleepCalculationsTests: XCTestCase {
    
    // MARK: - Performance Tests
    
    func testPerformanceScore_MeetsNeed_Returns100() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 28800, // 8 hours
            sleepNeed: 28800
        )
        let score = VeloReadyCore.SleepCalculations.calculatePerformanceScore(inputs: inputs)
        XCTAssertEqual(score, 100)
    }
    
    func testPerformanceScore_BelowNeed_ReturnsProportional() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 21600, // 6 hours
            sleepNeed: 28800 // 8 hours
        )
        let score = VeloReadyCore.SleepCalculations.calculatePerformanceScore(inputs: inputs)
        XCTAssertEqual(score, 75) // 6/8 * 100
    }
    
    // MARK: - Efficiency Tests
    
    func testEfficiencyScore_Perfect_Returns100() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 28800
        )
        let score = VeloReadyCore.SleepCalculations.calculateEfficiencyScore(inputs: inputs)
        XCTAssertEqual(score, 100)
    }
    
    func testEfficiencyScore_Normal_ReturnsCalculated() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 25200, // 7 hours
            timeInBed: 28800 // 8 hours
        )
        let score = VeloReadyCore.SleepCalculations.calculateEfficiencyScore(inputs: inputs)
        XCTAssertEqual(score, 87) // 87.5% efficiency
    }
    
    // MARK: - Stage Quality Tests
    
    func testStageQualityScore_Excellent_Returns100() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 28800,
            deepSleepDuration: 7200, // 2 hours
            remSleepDuration: 4320 // 1.2 hours (total 40%+)
        )
        let score = VeloReadyCore.SleepCalculations.calculateStageQualityScore(inputs: inputs)
        XCTAssertEqual(score, 100)
    }
    
    func testStageQualityScore_Good_ReturnsMid() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 28800,
            deepSleepDuration: 5760, // 1.6 hours
            remSleepDuration: 4320 // 1.2 hours (total 35%)
        )
        let score = VeloReadyCore.SleepCalculations.calculateStageQualityScore(inputs: inputs)
        XCTAssertGreaterThan(score, 50)
        XCTAssertLessThan(score, 100)
    }
    
    // MARK: - Disturbances Tests
    
    func testDisturbancesScore_NoWakes_Returns100() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(wakeEvents: 0)
        let score = VeloReadyCore.SleepCalculations.calculateDisturbancesScore(inputs: inputs)
        XCTAssertEqual(score, 100)
    }
    
    func testDisturbancesScore_FewWakes_Returns75() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(wakeEvents: 4)
        let score = VeloReadyCore.SleepCalculations.calculateDisturbancesScore(inputs: inputs)
        XCTAssertEqual(score, 75)
    }
    
    func testDisturbancesScore_ManyWakes_Returns25() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(wakeEvents: 10)
        let score = VeloReadyCore.SleepCalculations.calculateDisturbancesScore(inputs: inputs)
        XCTAssertEqual(score, 25)
    }
    
    // MARK: - Timing Tests
    
    func testTimingScore_OnSchedule_Returns100() {
        let bedtime = Date()
        let wakeTime = Date().addingTimeInterval(28800)
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            bedtime: bedtime,
            wakeTime: wakeTime,
            baselineBedtime: bedtime,
            baselineWakeTime: wakeTime
        )
        let score = VeloReadyCore.SleepCalculations.calculateTimingScore(inputs: inputs)
        XCTAssertEqual(score, 100)
    }
    
    func testTimingScore_SlightDeviation_Returns75() {
        let baseline = Date()
        let bedtime = baseline.addingTimeInterval(40 * 60) // 40 min late
        let baselineWake = baseline.addingTimeInterval(28800)
        let wakeTime = baselineWake.addingTimeInterval(40 * 60)
        
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            bedtime: bedtime,
            wakeTime: wakeTime,
            baselineBedtime: baseline,
            baselineWakeTime: baselineWake
        )
        let score = VeloReadyCore.SleepCalculations.calculateTimingScore(inputs: inputs)
        XCTAssertEqual(score, 75)
    }
    
    // MARK: - Full Score Tests
    
    func testCalculateScore_OptimalSleep_ReturnsHighScore() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 28800,
            timeInBed: 28800,
            sleepNeed: 28800,
            deepSleepDuration: 7200,
            remSleepDuration: 4320,
            wakeEvents: 1,
            bedtime: Date(),
            wakeTime: Date().addingTimeInterval(28800),
            baselineBedtime: Date(),
            baselineWakeTime: Date().addingTimeInterval(28800)
        )
        let result = VeloReadyCore.SleepCalculations.calculateScore(inputs: inputs)
        
        XCTAssertGreaterThanOrEqual(result.score, 90)
        XCTAssertLessThanOrEqual(result.score, 100)
    }
    
    func testCalculateScore_PoorSleep_ReturnsLowScore() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs(
            sleepDuration: 18000, // 5 hours
            timeInBed: 28800, // 8 hours
            sleepNeed: 28800,
            deepSleepDuration: 1800, // 30 min
            remSleepDuration: 1800, // 30 min
            wakeEvents: 12
        )
        let result = VeloReadyCore.SleepCalculations.calculateScore(inputs: inputs)
        
        XCTAssertLessThan(result.score, 60)
        XCTAssertGreaterThanOrEqual(result.score, 0)
    }
    
    func testCalculateScore_NoData_ReturnsNeutralScore() {
        let inputs = VeloReadyCore.SleepCalculations.SleepInputs()
        let result = VeloReadyCore.SleepCalculations.calculateScore(inputs: inputs)
        
        // All components return 50, so overall should be 50
        XCTAssertEqual(result.score, 50)
        XCTAssertEqual(result.subScores.performance, 50)
        XCTAssertEqual(result.subScores.efficiency, 50)
        XCTAssertEqual(result.subScores.stageQuality, 50)
        XCTAssertEqual(result.subScores.disturbances, 50)
        XCTAssertEqual(result.subScores.timing, 50)
    }
}
