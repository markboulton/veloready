import XCTest
@testable import VeloReadyCore

final class StrainCalculationsTests: XCTestCase {
    
    // MARK: - TRIMP Tests
    
    func testCalculateTRIMP_WithValidData_ReturnsPositive() {
        let hrData: [(time: TimeInterval, hr: Double)] = [
            (0, 140),
            (60, 150),
            (120, 160),
            (180, 155)
        ]
        
        let trimp = VeloReadyCore.StrainCalculations.calculateTRIMP(
            heartRateData: hrData,
            restingHR: 60,
            maxHR: 180
        )
        
        XCTAssertGreaterThan(trimp, 0)
    }
    
    func testCalculateTRIMP_WithEmptyData_ReturnsZero() {
        let trimp = VeloReadyCore.StrainCalculations.calculateTRIMP(
            heartRateData: [],
            restingHR: 60,
            maxHR: 180
        )
        
        XCTAssertEqual(trimp, 0)
    }
    
    func testCalculateBlendedTRIMP_WithValidData_ReturnsPositive() {
        let hrData: [(time: TimeInterval, hr: Double, power: Double)] = [
            (0, 140, 200),
            (60, 150, 220),
            (120, 160, 240)
        ]
        
        let trimp = VeloReadyCore.StrainCalculations.calculateBlendedTRIMP(
            heartRateData: hrData,
            restingHR: 60,
            maxHR: 180,
            ftp: 250
        )
        
        XCTAssertGreaterThan(trimp, 0)
    }
    
    // MARK: - EPOC & Whoop Strain Tests
    
    func testConvertTRIMPToEPOC_ReturnsPositiveValue() {
        let trimp = 100.0
        let epoc = VeloReadyCore.StrainCalculations.convertTRIMPToEPOC(trimp: trimp)
        
        XCTAssertGreaterThan(epoc, 0)
        // EPOC formula: 0.25 * trimp^1.1, so result varies
    }
    
    func testCalculateWhoopStrain_ReturnsInRange() {
        let epoc = 50.0
        let strain = VeloReadyCore.StrainCalculations.calculateWhoopStrain(epoc: epoc)
        
        XCTAssertGreaterThanOrEqual(strain, 0)
        XCTAssertLessThanOrEqual(strain, 18)
    }
    
    func testCalculateWhoopStrain_HighEPOC_ReturnsHighStrain() {
        let lowEpoc = 10.0
        let highEpoc = 100.0
        
        let lowStrain = VeloReadyCore.StrainCalculations.calculateWhoopStrain(epoc: lowEpoc)
        let highStrain = VeloReadyCore.StrainCalculations.calculateWhoopStrain(epoc: highEpoc)
        
        XCTAssertGreaterThan(highStrain, lowStrain)
    }
    
    // MARK: - Cardio Load Tests
    
    func testCalculateCardioLoad_WithModerateTRIMP_ReturnsModerateScore() {
        let score = VeloReadyCore.StrainCalculations.calculateCardioLoad(
            dailyTRIMP: 100,
            durationMinutes: 60,
            intensityFactor: 0.7
        )
        
        XCTAssertGreaterThan(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }
    
    func testCalculateCardioLoad_ZeroTRIMP_ReturnsZero() {
        let score = VeloReadyCore.StrainCalculations.calculateCardioLoad(
            dailyTRIMP: 0
        )
        
        XCTAssertEqual(score, 0)
    }
    
    func testCalculateCardioLoad_LongDuration_AddsBonus() {
        let shortScore = VeloReadyCore.StrainCalculations.calculateCardioLoad(
            dailyTRIMP: 100,
            durationMinutes: 30
        )
        let longScore = VeloReadyCore.StrainCalculations.calculateCardioLoad(
            dailyTRIMP: 100,
            durationMinutes: 120
        )
        
        XCTAssertGreaterThan(longScore, shortScore)
    }
    
    // MARK: - Strength Load Tests
    
    func testCalculateStrengthLoad_WithValidRPE_ReturnsScore() {
        let score = VeloReadyCore.StrainCalculations.calculateStrengthLoad(
            rpe: 7.0,
            durationMinutes: 60
        )
        
        XCTAssertGreaterThan(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }
    
    func testCalculateStrengthLoad_HigherRPE_ReturnsHigherScore() {
        let easyScore = VeloReadyCore.StrainCalculations.calculateStrengthLoad(
            rpe: 4.0,
            durationMinutes: 60
        )
        let hardScore = VeloReadyCore.StrainCalculations.calculateStrengthLoad(
            rpe: 9.0,
            durationMinutes: 60
        )
        
        XCTAssertGreaterThan(hardScore, easyScore)
    }
    
    // MARK: - Non-Exercise Load Tests
    
    func testCalculateNonExerciseLoad_WithSteps_ReturnsScore() {
        let score = VeloReadyCore.StrainCalculations.calculateNonExerciseLoad(
            steps: 10000
        )
        
        XCTAssertGreaterThan(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }
    
    func testCalculateNonExerciseLoad_MoreSteps_ReturnsHigherScore() {
        let lowScore = VeloReadyCore.StrainCalculations.calculateNonExerciseLoad(
            steps: 5000
        )
        let highScore = VeloReadyCore.StrainCalculations.calculateNonExerciseLoad(
            steps: 15000
        )
        
        XCTAssertGreaterThan(highScore, lowScore)
    }
    
    // MARK: - Recovery Factor Tests
    
    func testCalculateRecoveryFactor_NeutralInputs_ReturnsOne() {
        let factor = VeloReadyCore.StrainCalculations.calculateRecoveryFactor()
        
        XCTAssertEqual(factor, 1.0, accuracy: 0.01)
    }
    
    func testCalculateRecoveryFactor_GoodRecovery_ReturnsHigher() {
        let poorFactor = VeloReadyCore.StrainCalculations.calculateRecoveryFactor(
            hrvToday: 30,
            hrvBaseline: 50,
            rhrToday: 70,
            rhrBaseline: 60
        )
        let goodFactor = VeloReadyCore.StrainCalculations.calculateRecoveryFactor(
            hrvToday: 70,
            hrvBaseline: 50,
            rhrToday: 55,
            rhrBaseline: 60
        )
        
        XCTAssertGreaterThan(goodFactor, poorFactor)
    }
    
    func testCalculateRecoveryFactor_InRange() {
        let factor = VeloReadyCore.StrainCalculations.calculateRecoveryFactor(
            hrvToday: 60,
            hrvBaseline: 50,
            rhrToday: 58,
            rhrBaseline: 60,
            sleepQuality: 80
        )
        
        // Factor should be in range 0.85-1.15
        XCTAssertGreaterThanOrEqual(factor, 0.85)
        XCTAssertLessThanOrEqual(factor, 1.15)
    }
    
    // MARK: - Band Determination Tests
    
    func testDetermineBand_LightScore_ReturnsLight() {
        let band = VeloReadyCore.StrainCalculations.determineBand(score: 3.0)
        XCTAssertEqual(band, "light")
    }
    
    func testDetermineBand_ModerateScore_ReturnsModerate() {
        let band = VeloReadyCore.StrainCalculations.determineBand(score: 8.0)
        XCTAssertEqual(band, "moderate")
    }
    
    func testDetermineBand_HardScore_ReturnsHard() {
        let band = VeloReadyCore.StrainCalculations.determineBand(score: 13.0)
        XCTAssertEqual(band, "hard")
    }
    
    func testDetermineBand_VeryHardScore_ReturnsVeryHard() {
        let band = VeloReadyCore.StrainCalculations.determineBand(score: 17.0)
        XCTAssertEqual(band, "veryHard")
    }
}
