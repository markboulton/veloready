import XCTest
@testable import VeloReadyCore

/// Comprehensive tests for recovery calculations
/// Tests extracted logic from RecoveryScoreCalculator
final class RecoveryCalculationsTests: XCTestCase {
    
    // MARK: - HRV Component Tests
    
    func testCalculateHRVComponent_AboveBaseline_Returns100() {
        // Given: HRV at or above baseline
        let hrv = 50.0
        let baseline = 45.0
        
        // When
        let score = RecoveryCalculations.calculateHRVComponent(hrv: hrv, baseline: baseline)
        
        // Then
        XCTAssertEqual(score, 100, "HRV at or above baseline should return 100")
    }
    
    func testCalculateHRVComponent_SmallDrop_ReturnsMinimalPenalty() {
        // Given: HRV dropped 5% (small drop)
        let hrv = 42.75 // 5% drop from 45
        let baseline = 45.0
        
        // When
        let score = RecoveryCalculations.calculateHRVComponent(hrv: hrv, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 85, "Small HRV drop (5%) should score >= 85")
        XCTAssertLessThan(score, 100, "Small drop should have some penalty")
    }
    
    func testCalculateHRVComponent_ModerateDrop_ReturnsModeratePenalty() {
        // Given: HRV dropped 15% (moderate drop)
        let hrv = 38.25 // 15% drop from 45
        let baseline = 45.0
        
        // When
        let score = RecoveryCalculations.calculateHRVComponent(hrv: hrv, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 60, "Moderate HRV drop (15%) should score >= 60")
        XCTAssertLessThan(score, 85, "Moderate drop should score < 85")
    }
    
    func testCalculateHRVComponent_SignificantDrop_ReturnsLargePenalty() {
        // Given: HRV dropped 30% (significant drop)
        let hrv = 31.5 // 30% drop from 45
        let baseline = 45.0
        
        // When
        let score = RecoveryCalculations.calculateHRVComponent(hrv: hrv, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 30, "Significant HRV drop (30%) should score >= 30")
        XCTAssertLessThan(score, 60, "Significant drop should score < 60")
    }
    
    func testCalculateHRVComponent_ExtremeDrop_ReturnsMaximumPenalty() {
        // Given: HRV dropped 40% (extreme drop)
        let hrv = 27.0 // 40% drop from 45
        let baseline = 45.0
        
        // When
        let score = RecoveryCalculations.calculateHRVComponent(hrv: hrv, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 0, "Score should not be negative")
        XCTAssertLessThan(score, 30, "Extreme HRV drop (40%) should score < 30")
    }
    
    func testCalculateHRVComponent_NoData_Returns50() {
        // Given: No HRV data
        
        // When
        let score = RecoveryCalculations.calculateHRVComponent(hrv: nil, baseline: nil)
        
        // Then
        XCTAssertEqual(score, 50, "No HRV data should return neutral score of 50")
    }
    
    func testCalculateHRVComponent_ZeroBaseline_Returns50() {
        // Given: Zero baseline (invalid)
        let hrv = 45.0
        let baseline = 0.0
        
        // When
        let score = RecoveryCalculations.calculateHRVComponent(hrv: hrv, baseline: baseline)
        
        // Then
        XCTAssertEqual(score, 50, "Zero baseline should return neutral score of 50")
    }
    
    // MARK: - RHR Component Tests
    
    func testCalculateRHRComponent_AtOrBelowBaseline_Returns100() {
        // Given: RHR at or below baseline
        let rhr = 58.0
        let baseline = 60.0
        
        // When
        let score = RecoveryCalculations.calculateRHRComponent(rhr: rhr, baseline: baseline)
        
        // Then
        XCTAssertEqual(score, 100, "RHR at or below baseline should return 100")
    }
    
    func testCalculateRHRComponent_SmallIncrease_ReturnsMinimalPenalty() {
        // Given: RHR increased 5% (small increase)
        let rhr = 63.0 // 5% increase from 60
        let baseline = 60.0
        
        // When
        let score = RecoveryCalculations.calculateRHRComponent(rhr: rhr, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 88, "Small RHR increase (5%) should score >= 88")
        XCTAssertLessThan(score, 100, "Small increase should have some penalty")
    }
    
    func testCalculateRHRComponent_ModerateIncrease_ReturnsModeratePenalty() {
        // Given: RHR increased 12% (moderate increase)
        let rhr = 67.2 // 12% increase from 60
        let baseline = 60.0
        
        // When
        let score = RecoveryCalculations.calculateRHRComponent(rhr: rhr, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 67, "Moderate RHR increase (12%) should score >= 67")
        XCTAssertLessThan(score, 88, "Moderate increase should score < 88")
    }
    
    func testCalculateRHRComponent_NoData_Returns50() {
        // Given: No RHR data
        
        // When
        let score = RecoveryCalculations.calculateRHRComponent(rhr: nil, baseline: nil)
        
        // Then
        XCTAssertEqual(score, 50, "No RHR data should return neutral score of 50")
    }
    
    // MARK: - Sleep Component Tests
    
    func testCalculateSleepComponent_WithSleepScore_UsesSleepScore() {
        // Given: Comprehensive sleep score available
        let sleepScore = 85
        
        // When
        let score = RecoveryCalculations.calculateSleepComponent(sleepScore: sleepScore, sleepDuration: nil, baseline: nil)
        
        // Then
        XCTAssertEqual(score, 85, "Should use comprehensive sleep score when available")
    }
    
    func testCalculateSleepComponent_WithoutSleepScore_UsesDuration() {
        // Given: No sleep score, but duration available
        let sleepDuration = 28800.0 // 8 hours in seconds
        let baseline = 25200.0 // 7 hours in seconds
        
        // When
        let score = RecoveryCalculations.calculateSleepComponent(sleepScore: nil, sleepDuration: sleepDuration, baseline: baseline)
        
        // Then
        // 8/7 * 100 = 114.28, capped at 100
        XCTAssertEqual(score, 100, "Should calculate from duration when sleep score unavailable")
    }
    
    func testCalculateSleepComponent_BelowBaseline_ReturnsProportionalScore() {
        // Given: Slept less than baseline
        let sleepDuration = 21600.0 // 6 hours in seconds
        let baseline = 28800.0 // 8 hours in seconds
        
        // When
        let score = RecoveryCalculations.calculateSleepComponent(sleepScore: nil, sleepDuration: sleepDuration, baseline: baseline)
        
        // Then
        // 6/8 * 100 = 75
        XCTAssertEqual(score, 75, "Should return proportional score when below baseline")
    }
    
    func testCalculateSleepComponent_NoData_Returns50() {
        // Given: No sleep data
        
        // When
        let score = RecoveryCalculations.calculateSleepComponent(sleepScore: nil, sleepDuration: nil, baseline: nil)
        
        // Then
        XCTAssertEqual(score, 50, "No sleep data should return neutral score of 50")
    }
    
    // MARK: - Respiratory Component Tests
    
    func testCalculateRespiratoryComponent_VeryStable_Returns100() {
        // Given: Respiratory rate within 5% of baseline
        let respiratory = 14.5
        let baseline = 14.0
        
        // When
        let score = RecoveryCalculations.calculateRespiratoryComponent(respiratory: respiratory, baseline: baseline)
        
        // Then
        XCTAssertEqual(score, 100, "Very stable respiratory rate (within 5%) should return 100")
    }
    
    func testCalculateRespiratoryComponent_ModerateVariability_ReturnsModerateScore() {
        // Given: Respiratory rate 10% from baseline
        let respiratory = 15.4 // 10% from 14
        let baseline = 14.0
        
        // When
        let score = RecoveryCalculations.calculateRespiratoryComponent(respiratory: respiratory, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 50, "Moderate variability (10%) should score >= 50")
        XCTAssertLessThan(score, 100, "Moderate variability should score < 100")
    }
    
    func testCalculateRespiratoryComponent_HighVariability_ReturnsLowScore() {
        // Given: Respiratory rate 20% from baseline
        let respiratory = 16.8 // 20% from 14
        let baseline = 14.0
        
        // When
        let score = RecoveryCalculations.calculateRespiratoryComponent(respiratory: respiratory, baseline: baseline)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 0, "Score should not be negative")
        XCTAssertLessThan(score, 50, "High variability (20%) should score < 50")
    }
    
    func testCalculateRespiratoryComponent_NoData_Returns50() {
        // Given: No respiratory data
        
        // When
        let score = RecoveryCalculations.calculateRespiratoryComponent(respiratory: nil, baseline: nil)
        
        // Then
        XCTAssertEqual(score, 50, "No respiratory data should return neutral score of 50")
    }
    
    // MARK: - Form Component Tests
    
    func testCalculateFormComponent_Fresh_Returns100() {
        // Given: ATL < CTL (fresh state)
        let atl = 80.0
        let ctl = 100.0
        
        // When
        let score = RecoveryCalculations.calculateFormComponent(atl: atl, ctl: ctl, recentStrain: nil)
        
        // Then
        XCTAssertEqual(score, 100, "Fresh state (ATL < CTL) should return 100")
    }
    
    func testCalculateFormComponent_Fatigued_ReturnsLowerScore() {
        // Given: ATL > CTL (fatigued state)
        let atl = 120.0
        let ctl = 100.0
        
        // When
        let score = RecoveryCalculations.calculateFormComponent(atl: atl, ctl: ctl, recentStrain: nil)
        
        // Then
        XCTAssertLessThan(score, 100, "Fatigued state (ATL > CTL) should score < 100")
        XCTAssertGreaterThanOrEqual(score, 0, "Score should not be negative")
    }
    
    func testCalculateFormComponent_WithRecentStrain_AppliesPenalty() {
        // Given: Fresh state with high recent strain
        let atl = 80.0
        let ctl = 100.0
        let recentStrain = 150.0 // High TSS yesterday
        
        // When
        let score = RecoveryCalculations.calculateFormComponent(atl: atl, ctl: ctl, recentStrain: recentStrain)
        
        // Then
        XCTAssertLessThan(score, 100, "Recent high strain should apply penalty")
    }
    
    func testCalculateFormComponent_NoData_Returns50() {
        // Given: No training load data
        
        // When
        let score = RecoveryCalculations.calculateFormComponent(atl: nil, ctl: nil, recentStrain: nil)
        
        // Then
        XCTAssertEqual(score, 50, "No training load data should return neutral score of 50")
    }
    
    // MARK: - TSS Penalty Tests
    
    func testCalculateTSSPenalty_EasyDay_ReturnsZero() {
        // Given: Easy day (TSS < 50)
        let tss = 30.0
        
        // When
        let penalty = RecoveryCalculations.calculateTSSPenalty(yesterdayTSS: tss)
        
        // Then
        XCTAssertEqual(penalty, 0, "Easy day (TSS < 50) should have no penalty")
    }
    
    func testCalculateTSSPenalty_ModerateDay_ReturnsSmallPenalty() {
        // Given: Moderate day (TSS 75)
        let tss = 75.0
        
        // When
        let penalty = RecoveryCalculations.calculateTSSPenalty(yesterdayTSS: tss)
        
        // Then
        // (75 - 50) * 0.2 = 5
        XCTAssertEqual(penalty, 5.0, accuracy: 0.1, "Moderate day should have small penalty")
    }
    
    func testCalculateTSSPenalty_HardDay_ReturnsLargePenalty() {
        // Given: Hard day (TSS 150)
        let tss = 150.0
        
        // When
        let penalty = RecoveryCalculations.calculateTSSPenalty(yesterdayTSS: tss)
        
        // Then
        // 10 + ((150 - 100) * 0.15) = 17.5
        XCTAssertEqual(penalty, 17.5, accuracy: 0.1, "Hard day should have large penalty")
    }
    
    func testCalculateTSSPenalty_VeryHardDay_ReturnsMaximumPenalty() {
        // Given: Very hard day (TSS 250)
        let tss = 250.0
        
        // When
        let penalty = RecoveryCalculations.calculateTSSPenalty(yesterdayTSS: tss)
        
        // Then
        // Should be capped at 40
        XCTAssertLessThanOrEqual(penalty, 40, "Penalty should be capped at 40")
        XCTAssertGreaterThan(penalty, 25, "Very hard day should have significant penalty")
    }
    
    // MARK: - Alcohol Detection Tests
    
    func testApplyAlcoholCompoundEffect_WithIllness_SkipsDetection() {
        // Given: Base score with illness indicator
        let baseScore = 85.0
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 30.0, // Dropped 33%
            overnightHrv: 30.0,
            hrvBaseline: 45.0,
            sleepScore: 60
        )
        
        // When
        let adjustedScore = RecoveryCalculations.applyAlcoholCompoundEffect(
            baseScore: baseScore,
            hrvScore: 40,
            rhrScore: 50,
            sleepScore: 60,
            inputs: inputs,
            hasIllnessIndicator: true
        )
        
        // Then
        XCTAssertEqual(adjustedScore, baseScore, "Should skip alcohol detection when illness detected")
    }
    
    func testApplyAlcoholCompoundEffect_NoSleepData_SkipsDetection() {
        // Given: Base score without sleep data
        let baseScore = 85.0
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 30.0,
            overnightHrv: 30.0,
            hrvBaseline: 45.0,
            sleepScore: nil
        )
        
        // When
        let adjustedScore = RecoveryCalculations.applyAlcoholCompoundEffect(
            baseScore: baseScore,
            hrvScore: 40,
            rhrScore: 50,
            sleepScore: 50,
            inputs: inputs,
            hasIllnessIndicator: false
        )
        
        // Then
        XCTAssertEqual(adjustedScore, baseScore, "Should skip alcohol detection without sleep data")
    }
    
    func testApplyAlcoholCompoundEffect_HeavyDrinking_AppliesLargePenalty() {
        // Given: Heavy drinking pattern (>35% HRV drop)
        let baseScore = 85.0
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 27.0, // 40% drop from 45
            overnightHrv: 27.0,
            hrvBaseline: 45.0,
            sleepScore: 60
        )
        
        // When
        let adjustedScore = RecoveryCalculations.applyAlcoholCompoundEffect(
            baseScore: baseScore,
            hrvScore: 30,
            rhrScore: 50,
            sleepScore: 60,
            inputs: inputs,
            hasIllnessIndicator: false
        )
        
        // Then
        XCTAssertLessThan(adjustedScore, baseScore, "Should apply penalty for heavy drinking")
        XCTAssertGreaterThanOrEqual(adjustedScore, baseScore - 15, "Penalty should be capped at 15 points")
    }
    
    func testApplyAlcoholCompoundEffect_ModerateDrinking_AppliesModeratePenalty() {
        // Given: Moderate drinking pattern (20-25% HRV drop)
        let baseScore = 85.0
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 35.0, // 22% drop from 45
            overnightHrv: 35.0,
            hrvBaseline: 45.0,
            sleepScore: 70
        )
        
        // When
        let adjustedScore = RecoveryCalculations.applyAlcoholCompoundEffect(
            baseScore: baseScore,
            hrvScore: 60,
            rhrScore: 80,
            sleepScore: 70,
            inputs: inputs,
            hasIllnessIndicator: false
        )
        
        // Then
        XCTAssertLessThan(adjustedScore, baseScore, "Should apply penalty for moderate drinking")
        XCTAssertGreaterThan(adjustedScore, baseScore - 8, "Moderate penalty should be ~5 points")
    }
    
    func testApplyAlcoholCompoundEffect_ExcellentSleep_MitigatesPenalty() {
        // Given: Moderate drinking with excellent sleep
        let baseScore = 85.0
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 35.0, // 22% drop
            overnightHrv: 35.0,
            hrvBaseline: 45.0,
            sleepScore: 90 // Excellent sleep
        )
        
        // When
        let adjustedScore = RecoveryCalculations.applyAlcoholCompoundEffect(
            baseScore: baseScore,
            hrvScore: 60,
            rhrScore: 80,
            sleepScore: 90,
            inputs: inputs,
            hasIllnessIndicator: false
        )
        
        // Then
        // Penalty should be reduced by 30% due to excellent sleep
        XCTAssertGreaterThan(adjustedScore, baseScore - 5.0, "Excellent sleep should mitigate alcohol penalty")
    }
    
    // MARK: - Full Score Calculation Tests
    
    func testCalculateScore_OptimalInputs_ReturnsHighScore() {
        // Given: All optimal inputs
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 50.0,
            hrvBaseline: 45.0,
            rhr: 58.0,
            rhrBaseline: 60.0,
            respiratoryRate: 14.0,
            respiratoryBaseline: 14.0,
            atl: 80.0,
            ctl: 100.0,
            recentStrain: 50.0,
            sleepScore: 90
        )
        
        // When
        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasIllnessIndicator: false, hasSleepData: true)
        
        // Then
        XCTAssertGreaterThanOrEqual(result.score, 90, "Optimal inputs should return high score (>= 90)")
        XCTAssertLessThanOrEqual(result.score, 100, "Score should not exceed 100")
    }
    
    func testCalculateScore_PoorInputs_ReturnsLowScore() {
        // Given: All poor inputs
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 30.0, // 33% drop
            hrvBaseline: 45.0,
            rhr: 75.0, // 25% increase
            rhrBaseline: 60.0,
            respiratoryRate: 17.0, // 21% above baseline
            respiratoryBaseline: 14.0,
            atl: 150.0,
            ctl: 100.0,
            recentStrain: 200.0,
            sleepScore: 40
        )
        
        // When
        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasIllnessIndicator: false, hasSleepData: true)
        
        // Then
        XCTAssertLessThan(result.score, 50, "Poor inputs should return low score (< 50)")
        XCTAssertGreaterThanOrEqual(result.score, 0, "Score should not be negative")
    }
    
    func testCalculateScore_WithoutSleepData_UsesRebalancedWeights() {
        // Given: Inputs without sleep data
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 50.0,
            hrvBaseline: 45.0,
            rhr: 58.0,
            rhrBaseline: 60.0,
            respiratoryRate: 14.0,
            respiratoryBaseline: 14.0,
            atl: 80.0,
            ctl: 100.0
        )
        
        // When
        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasIllnessIndicator: false, hasSleepData: false)
        
        // Then
        // Should still return a valid score using rebalanced weights
        XCTAssertGreaterThan(result.score, 0, "Should return valid score without sleep data")
        XCTAssertLessThanOrEqual(result.score, 100, "Score should not exceed 100")
    }
    
    func testCalculateScore_MinimalData_ReturnsNeutralScore() {
        // Given: Minimal data (only HRV at baseline)
        let inputs = RecoveryCalculations.RecoveryInputs(
            hrv: 45.0,
            hrvBaseline: 45.0
        )
        
        // When
        let result = RecoveryCalculations.calculateScore(inputs: inputs, hasIllnessIndicator: false, hasSleepData: false)
        
        // Then
        // HRV at baseline (100) with rebalanced weights + other components at 50 = higher score
        XCTAssertGreaterThanOrEqual(result.score, 60, "HRV at baseline should return above-neutral score")
        XCTAssertLessThanOrEqual(result.score, 80, "With minimal data, score should be reasonable")
    }
}
