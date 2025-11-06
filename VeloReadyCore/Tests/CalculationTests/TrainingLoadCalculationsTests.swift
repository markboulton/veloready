import XCTest
@testable import VeloReadyCore

/// Tests for training load calculations (CTL/ATL/TSB)
final class TrainingLoadCalculationsTests: XCTestCase {
    
    // MARK: - CTL Calculation Tests
    
    func testCalculateCTL_WithValidData_ReturnsExponentialAverage() {
        // Given
        let dailyTSS = [100.0, 120.0, 90.0, 110.0, 100.0, 130.0, 95.0]
        
        // When
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        
        // Then
        XCTAssertGreaterThan(ctl, 0, "CTL should be greater than 0")
        XCTAssertLessThan(ctl, 130, "CTL should be less than max TSS")
    }
    
    func testCalculateCTL_WithEmptyData_ReturnsZero() {
        // Given
        let dailyTSS: [Double] = []
        
        // When
        let ctl = TrainingLoadCalculations.calculateCTL(dailyTSS: dailyTSS)
        
        // Then
        XCTAssertEqual(ctl, 0.0, "CTL should be 0 for empty data")
    }
    
    // MARK: - ATL Calculation Tests
    
    func testCalculateATL_WithValidData_ReturnsExponentialAverage() {
        // Given
        let dailyTSS = [100.0, 120.0, 90.0, 110.0, 100.0, 130.0, 95.0]
        
        // When
        let atl = TrainingLoadCalculations.calculateATL(dailyTSS: dailyTSS)
        
        // Then
        XCTAssertGreaterThan(atl, 0, "ATL should be greater than 0")
        XCTAssertLessThan(atl, 130, "ATL should be less than max TSS")
    }
    
    // MARK: - TSB Calculation Tests
    
    func testCalculateTSB_WithValidData_ReturnsDifference() {
        // Given
        let ctl = 100.0
        let atl = 80.0
        
        // When
        let tsb = TrainingLoadCalculations.calculateTSB(ctl: ctl, atl: atl)
        
        // Then
        XCTAssertEqual(tsb, 20.0, "TSB should be CTL - ATL")
    }
    
    func testCalculateTSB_WhenFatigued_ReturnsNegative() {
        // Given (more fatigue than fitness)
        let ctl = 80.0
        let atl = 100.0
        
        // When
        let tsb = TrainingLoadCalculations.calculateTSB(ctl: ctl, atl: atl)
        
        // Then
        XCTAssertEqual(tsb, -20.0, "TSB should be negative when fatigued")
    }
    
    // MARK: - Exponential Average Tests
    
    func testCalculateExponentialAverage_WithTimeConstant7_ConvergesQuickly() {
        // Given
        let values = [100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0]
        
        // When
        let average = TrainingLoadCalculations.calculateExponentialAverage(
            values: values,
            timeConstant: 7.0
        )
        
        // Then
        // Exponential average converges gradually, not immediately
        // After 7 days with constant value, it reaches ~66% of target
        XCTAssertGreaterThan(average, 60.0, "Should be approaching constant value")
        XCTAssertLessThan(average, 100.0, "Should not fully converge yet")
    }
}
