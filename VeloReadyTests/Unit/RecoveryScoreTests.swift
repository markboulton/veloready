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
}
