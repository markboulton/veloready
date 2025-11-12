import XCTest
@testable import VeloReadyCore

/// Comprehensive tests for stress calculations
/// Tests all stress calculation logic independently of iOS
final class StressCalculationsTests: XCTestCase {
    
    // MARK: - Acute Stress Tests
    
    func testAcuteStressHighPhysiological() {
        let result = StressCalculations.calculateAcuteStress(
            hrv: 45,           // Low (baseline 60)
            hrvBaseline: 60,
            rhr: 58,           // High (baseline 52)
            rhrBaseline: 52,
            recoveryScore: 40, // Low recovery
            sleepScore: 50,    // Poor sleep
            atl: 80,          // High acute load
            ctl: 70           // Lower chronic load
        )
        
        XCTAssertGreaterThan(result.acuteStress, 60, "High physiological stress should exceed 60")
        XCTAssertGreaterThanOrEqual(result.contributors.count, 4, "Should have multiple contributors")
    }
    
    func testAcuteStressOptimal() {
        let result = StressCalculations.calculateAcuteStress(
            hrv: 65,           // Above baseline
            hrvBaseline: 60,
            rhr: 50,           // Below baseline
            rhrBaseline: 52,
            recoveryScore: 90,
            sleepScore: 90,
            atl: 50,
            ctl: 70           // Well recovered
        )
        
        XCTAssertLessThan(result.acuteStress, 30, "Optimal values should result in low stress")
    }
    
    func testAcuteStressMissingData() {
        let result = StressCalculations.calculateAcuteStress(
            hrv: nil,
            hrvBaseline: nil,
            rhr: nil,
            rhrBaseline: nil,
            recoveryScore: 50,
            sleepScore: 50,
            atl: nil,
            ctl: nil
        )
        
        XCTAssertGreaterThanOrEqual(result.acuteStress, 0, "Should handle missing data gracefully")
        XCTAssertLessThanOrEqual(result.acuteStress, 100, "Score should be clamped to 100")
    }
    
    func testAcuteStressOverreaching() {
        let result = StressCalculations.calculateAcuteStress(
            hrv: 60,
            hrvBaseline: 60,
            rhr: 52,
            rhrBaseline: 52,
            recoveryScore: 70,
            sleepScore: 70,
            atl: 100,  // Very high acute
            ctl: 70    // Overreaching ratio 1.43
        )
        
        // With recoveryScore: 70 and sleepScore: 70, the stress should be around 45
        // (30 points from recovery deficit + 6 from sleep + ~9 from training load)
        XCTAssertGreaterThan(result.acuteStress, 40, "Overreaching should increase stress")
        XCTAssertGreaterThan(result.contributors.count, 0, "Should have contributors")
    }
    
    // MARK: - Chronic Stress Tests
    
    func testChronicStressAverage() {
        let historicalScores = [50.0, 55.0, 60.0, 65.0, 70.0, 75.0]
        let chronic = StressCalculations.calculateChronicStress(
            historicalScores: historicalScores,
            todayStress: 80
        )
        
        // Average of [50, 55, 60, 65, 70, 75, 80] = 65
        XCTAssertEqual(chronic, 65, "Should calculate 7-day average correctly")
    }
    
    func testChronicStressStable() {
        let historicalScores = Array(repeating: 50.0, count: 6)
        let chronic = StressCalculations.calculateChronicStress(
            historicalScores: historicalScores,
            todayStress: 50
        )
        
        XCTAssertEqual(chronic, 50, "Stable stress should remain constant")
    }
    
    func testChronicStressIncreasing() {
        let historicalScores = [40.0, 45.0, 50.0, 55.0, 60.0, 65.0]
        let chronic = StressCalculations.calculateChronicStress(
            historicalScores: historicalScores,
            todayStress: 70
        )
        
        XCTAssertGreaterThan(chronic, 50, "Increasing trend should show in chronic")
        XCTAssertLessThan(chronic, 70, "Chronic should lag behind acute")
    }
    
    func testChronicStressEmptyHistory() {
        let chronic = StressCalculations.calculateChronicStress(
            historicalScores: [],
            todayStress: 60
        )
        
        XCTAssertEqual(chronic, 60, "Should fall back to today's stress")
    }
    
    // MARK: - Smart Threshold Tests
    
    func testSmartThresholdBeginner() {
        let historicalScores = Array(repeating: 50.0, count: 30)
        let threshold = StressCalculations.calculateSmartThreshold(
            historicalScores: historicalScores,
            ctl: 40  // Low fitness
        )
        
        XCTAssertGreaterThanOrEqual(threshold, 40, "Threshold should be at floor")
        XCTAssertLessThan(threshold, 55, "Beginner should have lower threshold")
    }
    
    func testSmartThresholdPro() {
        let historicalScores = Array(repeating: 50.0, count: 30)
        let threshold = StressCalculations.calculateSmartThreshold(
            historicalScores: historicalScores,
            ctl: 100  // High fitness
        )
        
        // With stable scores (stdDev=0) and CTL=100, threshold should be 50 + fitnessAdjustment
        // fitnessAdjustment = ((100-70)/60)*10 = 5, so threshold = 55
        XCTAssertGreaterThanOrEqual(threshold, 55, "Pro should have higher threshold")
        XCTAssertLessThanOrEqual(threshold, 70, "Threshold should be at ceiling")
    }
    
    func testSmartThresholdHighVariability() {
        var historicalScores: [Double] = []
        for i in 0..<30 {
            historicalScores.append(Double(30 + (i % 10) * 5))
        }
        
        let threshold = StressCalculations.calculateSmartThreshold(
            historicalScores: historicalScores,
            ctl: 70
        )
        
        XCTAssertGreaterThanOrEqual(threshold, 40, "Should handle variability")
        XCTAssertLessThanOrEqual(threshold, 70, "Should be clamped")
    }
    
    func testSmartThresholdInsufficientData() {
        let historicalScores = [45.0, 50.0, 55.0] // Only 3 days
        let threshold = StressCalculations.calculateSmartThreshold(
            historicalScores: historicalScores,
            ctl: 70
        )
        
        XCTAssertEqual(threshold, 50, "Should fall back to default 50")
    }
    
    func testSmartThresholdFitnessAdjustment() {
        let historicalScores = Array(repeating: 50.0, count: 30)
        
        let thresholdLow = StressCalculations.calculateSmartThreshold(
            historicalScores: historicalScores,
            ctl: 40
        )
        
        let thresholdHigh = StressCalculations.calculateSmartThreshold(
            historicalScores: historicalScores,
            ctl: 100
        )
        
        XCTAssertGreaterThan(thresholdHigh, thresholdLow, "Higher fitness should allow higher threshold")
    }
    
    // MARK: - Edge Cases
    
    func testStressScoreMaxClamp() {
        let result = StressCalculations.calculateAcuteStress(
            hrv: 20,           // Very low
            hrvBaseline: 80,   // Very high baseline
            rhr: 90,           // Very high
            rhrBaseline: 45,   // Very low baseline
            recoveryScore: 10, // Terrible recovery
            sleepScore: 10,    // Terrible sleep
            atl: 150,         // Extreme overreaching
            ctl: 50
        )
        
        XCTAssertLessThanOrEqual(result.acuteStress, 100, "Score should be clamped at 100")
    }
    
    func testStressScoreMinClamp() {
        let result = StressCalculations.calculateAcuteStress(
            hrv: 100,          // Super high
            hrvBaseline: 50,
            rhr: 35,           // Very low
            rhrBaseline: 60,
            recoveryScore: 100,
            sleepScore: 100,
            atl: 20,           // Very low load
            ctl: 100
        )
        
        XCTAssertGreaterThanOrEqual(result.acuteStress, 0, "Score should never be negative")
    }
    
    func testContributorsCompleteness() {
        let result = StressCalculations.calculateAcuteStress(
            hrv: 45,
            hrvBaseline: 60,
            rhr: 58,
            rhrBaseline: 52,
            recoveryScore: 40,
            sleepScore: 50,
            atl: 80,
            ctl: 70
        )
        
        XCTAssertGreaterThanOrEqual(result.contributors.count, 3, "Should have at least 3 contributors with this data")
        XCTAssertLessThanOrEqual(result.contributors.count, 5, "Should have at most 5 contributors")
    }
}

