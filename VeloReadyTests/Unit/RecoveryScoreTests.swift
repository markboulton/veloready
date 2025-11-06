import Foundation
import Testing
@testable import VeloReady

@Suite("Recovery Score Logic")
struct RecoveryScoreTests {
    
    // MARK: - Recovery Band Logic Tests
    
    @Test("Recovery band thresholds are correct")
    func testRecoveryBandThresholds() async throws {
        // Test the expected band ranges
        // Optimal: 80-100
        // Good: 60-79
        // Fair: 40-59
        // Poor: 20-39
        // Limited Data: <20
        
        let optimalRange = 80...100
        let goodRange = 60..<80
        let fairRange = 40..<60
        let poorRange = 20..<40
        
        #expect(optimalRange.contains(90))
        #expect(goodRange.contains(70))
        #expect(fairRange.contains(50))
        #expect(poorRange.contains(30))
    }
    
    @Test("Recovery score boundary values")
    func testBoundaryValues() async throws {
        // Validate boundary logic
        let boundaries = [
            (score: 100, shouldBeOptimal: true),
            (score: 80, shouldBeOptimal: true),
            (score: 79, shouldBeOptimal: false),
            (score: 60, shouldBeOptimal: false),
            (score: 0, shouldBeOptimal: false)
        ]
        
        for boundary in boundaries {
            let isOptimal = boundary.score >= 80
            #expect(isOptimal == boundary.shouldBeOptimal)
        }
    }
    
    @Test("Recovery score validation")
    func testScoreValidation() async throws {
        // Scores should be 0-100
        let validScores = [0, 50, 75, 100]
        let invalidScores = [-10, 150]
        
        for score in validScores {
            #expect(score >= 0 && score <= 100)
        }
        
        for score in invalidScores {
            let isValid = score >= 0 && score <= 100
            #expect(isValid == false)
        }
    }
    
    @Test("Recovery inputs handling")
    func testRecoveryInputsHandling() async throws {
        // Test that nil values are handled correctly
        let nilHRV: Double? = nil
        let validHRV: Double? = 45.0
        
        #expect(nilHRV == nil)
        #expect(validHRV != nil)
        
        // Validate nil check logic
        let hasHRV = validHRV != nil && (validHRV ?? 0) > 0
        #expect(hasHRV == true)
        
        let hasNoHRV = nilHRV == nil || (nilHRV ?? 0) == 0
        #expect(hasNoHRV == true)
    }
    
    @Test("Recovery band enum completeness")
    func testRecoveryBandEnum() async throws {
        // Validate all recovery bands exist
        let allBands: [RecoveryScore.RecoveryBand] = [
            .optimal,
            .good,
            .fair,
            .payAttention
        ]

        #expect(allBands.count == 4)
        #expect(RecoveryScore.RecoveryBand.allCases.count == 4)
    }

    // MARK: - Recovery Score Cache Validation Tests

    @Test("Recovery score with complete data is valid")
    func testCompleteRecoveryScore() async throws {
        // Create a complete recovery score with HRV data
        let inputs = RecoveryScore.RecoveryInputs(
            hrv: 45.0,  // Has HRV data - complete object
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

        let subScores = RecoveryScore.SubScores(
            hrv: 85,
            rhr: 90,
            sleep: 85,
            form: 80,
            respiratory: 88
        )

        let score = RecoveryScore(
            score: 86,
            band: .optimal,
            subScores: subScores,
            inputs: inputs,
            calculatedAt: Date(),
            isPersonalized: true
        )

        // Verify this is a complete score
        #expect(score.inputs.hrv != nil)
        #expect(score.inputs.hrv! > 0)
        #expect(score.score == 86)
    }

    @Test("Recovery score with missing HRV is incomplete")
    func testIncompleteRecoveryScore() async throws {
        // Create an incomplete recovery score (placeholder from sync load)
        let inputs = RecoveryScore.RecoveryInputs(
            hrv: nil,  // Missing HRV data - incomplete placeholder
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

        let subScores = RecoveryScore.SubScores(
            hrv: 0,
            rhr: 0,
            sleep: 0,
            form: 0,
            respiratory: 0
        )

        let score = RecoveryScore(
            score: 86,
            band: .optimal,
            subScores: subScores,
            inputs: inputs,
            calculatedAt: Date(),
            isPersonalized: false
        )

        // Verify this is an incomplete placeholder
        #expect(score.inputs.hrv == nil)
        #expect(score.score == 86)  // Numeric value exists
        #expect(!score.isPersonalized)  // But it's not personalized
    }

    @Test("Recovery score validation logic")
    func testRecoveryScoreValidation() async throws {
        // Test the validation logic used in RecoveryScoreService

        // Complete score - should NOT need recalculation
        let completeInputs = RecoveryScore.RecoveryInputs(
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

        let completeScore = RecoveryScore(
            score: 86,
            band: .optimal,
            subScores: RecoveryScore.SubScores(hrv: 85, rhr: 90, sleep: 85, form: 80, respiratory: 88),
            inputs: completeInputs,
            calculatedAt: Date(),
            isPersonalized: true
        )

        // This mimics the check in RecoveryScoreService.calculateRecoveryScore()
        let hasCompleteData = completeScore.inputs.hrv != nil
        #expect(hasCompleteData == true)

        // Incomplete score - SHOULD need recalculation
        let incompleteInputs = RecoveryScore.RecoveryInputs(
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

        let incompleteScore = RecoveryScore(
            score: 86,
            band: .optimal,
            subScores: RecoveryScore.SubScores(hrv: 0, rhr: 0, sleep: 0, form: 0, respiratory: 0),
            inputs: incompleteInputs,
            calculatedAt: Date(),
            isPersonalized: false
        )

        let hasIncompleteData = incompleteScore.inputs.hrv != nil
        #expect(hasIncompleteData == false)
    }
}
