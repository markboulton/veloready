import XCTest
@testable import VeloReadyCore

/// Tests for baseline calculations
/// These tests verify the pure calculation logic works correctly
final class BaselineCalculationsTests: XCTestCase {
    
    // MARK: - HRV Baseline Tests
    
    func testCalculateHRVBaseline_WithValidData_ReturnsAverage() {
        // Given
        let hrvValues = [45.0, 50.0, 48.0, 52.0, 46.0, 49.0, 51.0]
        
        // When
        let baseline = BaselineCalculations.calculateHRVBaseline(hrvValues: hrvValues)
        
        // Then
        XCTAssertNotNil(baseline)
        XCTAssertEqual(baseline!, 48.71, accuracy: 0.01, "Should calculate average HRV")
    }
    
    func testCalculateHRVBaseline_WithEmptyArray_ReturnsNil() {
        // Given
        let hrvValues: [Double] = []
        
        // When
        let baseline = BaselineCalculations.calculateHRVBaseline(hrvValues: hrvValues)
        
        // Then
        XCTAssertNil(baseline, "Should return nil for empty data")
    }
    
    // MARK: - RHR Baseline Tests
    
    func testCalculateRHRBaseline_WithValidData_ReturnsAverage() {
        // Given
        let rhrValues = [58.0, 60.0, 59.0, 61.0, 58.0, 60.0, 59.0]
        
        // When
        let baseline = BaselineCalculations.calculateRHRBaseline(rhrValues: rhrValues)
        
        // Then
        XCTAssertNotNil(baseline)
        XCTAssertEqual(baseline!, 59.29, accuracy: 0.01, "Should calculate average RHR")
    }
    
    // MARK: - Sleep Baseline Tests
    
    func testCalculateSleepBaseline_WithValidData_ReturnsAverage() {
        // Given
        let sleepDurations = [7.5, 8.0, 7.0, 8.5, 7.5, 8.0, 7.5]
        
        // When
        let baseline = BaselineCalculations.calculateSleepBaseline(sleepDurations: sleepDurations)
        
        // Then
        XCTAssertNotNil(baseline)
        XCTAssertEqual(baseline!, 7.71, accuracy: 0.01, "Should calculate average sleep duration")
    }
    
    // MARK: - Sleep Score Baseline Tests
    
    func testCalculateSleepScoreBaseline_WithValidData_ReturnsAverage() {
        // Given
        let sleepScores = [85.0, 90.0, 82.0, 88.0, 86.0, 89.0, 87.0]
        
        // When
        let baseline = BaselineCalculations.calculateSleepScoreBaseline(sleepScores: sleepScores)
        
        // Then
        XCTAssertNotNil(baseline)
        XCTAssertEqual(baseline!, 86.71, accuracy: 0.01, "Should calculate average sleep score")
    }
    
    // MARK: - Respiratory Baseline Tests
    
    func testCalculateRespiratoryBaseline_WithValidData_ReturnsAverage() {
        // Given
        let respiratoryRates = [14.0, 15.0, 14.5, 15.5, 14.0, 15.0, 14.5]
        
        // When
        let baseline = BaselineCalculations.calculateRespiratoryBaseline(respiratoryRates: respiratoryRates)
        
        // Then
        XCTAssertNotNil(baseline)
        XCTAssertEqual(baseline!, 14.64, accuracy: 0.01, "Should calculate average respiratory rate")
    }
}
