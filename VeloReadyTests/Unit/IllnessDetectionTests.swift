import Foundation
import Testing
@testable import VeloReady

/// Comprehensive tests for illness detection thresholds and algorithm
/// Tests HRV spike detection, signal classification, and severity determination
@Suite("Illness Detection")
struct IllnessDetectionTests {

    // MARK: - HRV Drop Detection Tests

    @Test("HRV drop detected at 10% threshold")
    func testHRVDropThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 45.0,        // 10% below baseline
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.signals.contains(where: { $0.type == .hrvDrop }) == true)

        if let signal = indicator?.signals.first(where: { $0.type == .hrvDrop }) {
            #expect(signal.deviation == -10.0)
        }
    }

    @Test("HRV drop NOT detected below threshold")
    func testHRVDropBelowThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 46.0,        // Only 8% below baseline (below 10% threshold)
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator == nil)
    }

    // MARK: - HRV Spike Detection Tests (Illness Signal)

    @Test("HRV spike detected at 100% threshold - illness signal")
    func testHRVSpikeThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 100.0,       // 100% above baseline (illness/inflammation)
            hrvBaseline: 50.0,
            rhr: 65.0,        // Also elevated
            rhrBaseline: 60.0,
            sleepScore: 70,   // Also reduced
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.signals.contains(where: { $0.type == .hrvSpike }) == true)

        if let signal = indicator?.signals.first(where: { $0.type == .hrvSpike }) {
            #expect(signal.deviation == 100.0)
        }
    }

    @Test("HRV spike with 150% deviation indicates severe illness")
    func testHRVSpikeSevere() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 125.0,       // 150% above baseline
            hrvBaseline: 50.0,
            rhr: 68.0,        // 13% elevated
            rhrBaseline: 60.0,
            sleepScore: 65,   // Poor sleep
            sleepBaseline: 85.0,
            activityLevel: 50.0, // Activity down 50%
            activityBaseline: 100.0,
            respiratoryRate: 18.0, // Elevated
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.severity == .high)
        #expect(indicator?.confidence ?? 0 > 0.6)
    }

    @Test("HRV spike NOT detected below 100% threshold")
    func testHRVSpikeBelowThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 90.0,        // 80% above baseline (below 100% threshold)
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        // No signal should be detected (no HRV spike at 80%)
        if let indicator = indicator {
            #expect(indicator.signals.contains(where: { $0.type == .hrvSpike }) == false)
        }
    }

    // MARK: - Elevated RHR Detection Tests

    @Test("Elevated RHR detected at 3% threshold")
    func testElevatedRHRThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 61.8,        // 3% above baseline (60 * 1.03 = 61.8)
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.signals.contains(where: { $0.type == .elevatedRHR }) == true)
    }

    @Test("Elevated RHR NOT detected below threshold")
    func testElevatedRHRBelowThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 61.0,        // Only 1.67% above baseline
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator == nil)
    }

    // MARK: - Sleep Disruption Detection Tests

    @Test("Sleep disruption detected at 15% drop threshold")
    func testSleepDisruptionThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 72,   // 15% below baseline (85 * 0.85 = 72.25)
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.signals.contains(where: { $0.type == .sleepDisruption }) == true)
    }

    @Test("Sleep disruption detected in moderate range (60-84)")
    func testSleepDisruptionModerateRange() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 70,   // In 60-84 range with negative deviation
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.signals.contains(where: { $0.type == .sleepDisruption }) == true)
    }

    // MARK: - Respiratory Rate Detection Tests

    @Test("Elevated respiratory rate detected at 8% threshold")
    func testRespiratoryRateElevationThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 17.28, // 8% above baseline (16 * 1.08 = 17.28)
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.signals.contains(where: { $0.type == .respiratoryRate }) == true)
    }

    @Test("Lower respiratory rate NOT flagged (good sign)")
    func testRespiratoryRateLowerNotFlagged() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 14.0, // Lower respiratory rate (good)
            respiratoryBaseline: 16.0
        )

        // Lower respiratory rate should NOT be flagged
        if let indicator = indicator {
            #expect(indicator.signals.contains(where: { $0.type == .respiratoryRate }) == false)
        }
    }

    // MARK: - Activity Drop Detection Tests

    @Test("Activity drop detected at 25% threshold")
    func testActivityDropThreshold() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 60.0,
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 75.0, // 25% below baseline
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.signals.contains(where: { $0.type == .activityDrop }) == true)
    }

    // MARK: - Severity Classification Tests

    @Test("High severity for multiple strong signals")
    func testSeverityHighMultipleSignals() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 125.0,       // Severe spike (150% above baseline)
            hrvBaseline: 50.0,
            rhr: 68.0,        // 13% elevated
            rhrBaseline: 60.0,
            sleepScore: 60,   // 29% below baseline
            sleepBaseline: 85.0,
            activityLevel: 50.0, // 50% below baseline
            activityBaseline: 100.0,
            respiratoryRate: 18.0, // 12.5% elevated
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.severity == .high)
        #expect(indicator?.signals.count ?? 0 >= 4)
    }

    @Test("Moderate severity for 2-3 signals")
    func testSeverityModerate() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 105.0,       // Moderate spike (110% above baseline)
            hrvBaseline: 50.0,
            rhr: 63.0,        // 5% elevated
            rhrBaseline: 60.0,
            sleepScore: 80,   // Within normal range
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.severity == .moderate || indicator?.severity == .low)
        #expect(indicator?.signals.count ?? 0 >= 2)
    }

    @Test("Low severity for single weak signal")
    func testSeverityLow() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 61.8,        // Just above threshold (3%)
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        #expect(indicator != nil)
        #expect(indicator?.severity == .low)
        #expect(indicator?.signals.count == 1)
    }

    // MARK: - Confidence Calculation Tests

    @Test("Confidence increases with signal count")
    func testConfidenceMultipleSignals() throws {
        let indicator1 = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 62.0,        // 1 signal
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        let indicator2 = IllnessIndicator.detect(
            hrv: 105.0,       // 3 signals
            hrvBaseline: 50.0,
            rhr: 63.0,
            rhrBaseline: 60.0,
            sleepScore: 70,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        let confidence1 = indicator1?.confidence ?? 0
        let confidence2 = indicator2?.confidence ?? 0

        #expect(confidence2 > confidence1)
    }

    @Test("Confidence increases with deviation magnitude")
    func testConfidenceDeviationMagnitude() throws {
        let indicator1 = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 62.0,        // Small deviation (3%)
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        let indicator2 = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 50.0,
            rhr: 72.0,        // Large deviation (20%)
            rhrBaseline: 60.0,
            sleepScore: 85,
            sleepBaseline: 85.0,
            activityLevel: 100.0,
            activityBaseline: 100.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 16.0
        )

        let confidence1 = indicator1?.confidence ?? 0
        let confidence2 = indicator2?.confidence ?? 0

        #expect(confidence2 > confidence1)
    }

    // MARK: - Edge Cases

    @Test("No detection with all nil values")
    func testNoDetectionNilValues() throws {
        let indicator = IllnessIndicator.detect(
            hrv: nil,
            hrvBaseline: nil,
            rhr: nil,
            rhrBaseline: nil,
            sleepScore: nil,
            sleepBaseline: nil,
            activityLevel: nil,
            activityBaseline: nil,
            respiratoryRate: nil,
            respiratoryBaseline: nil
        )

        #expect(indicator == nil)
    }

    @Test("No detection with zero baseline")
    func testNoDetectionZeroBaseline() throws {
        let indicator = IllnessIndicator.detect(
            hrv: 50.0,
            hrvBaseline: 0.0,  // Invalid baseline
            rhr: 60.0,
            rhrBaseline: 0.0,
            sleepScore: 85,
            sleepBaseline: 0.0,
            activityLevel: 100.0,
            activityBaseline: 0.0,
            respiratoryRate: 16.0,
            respiratoryBaseline: 0.0
        )

        #expect(indicator == nil)
    }

    @Test("isSignificant returns true for moderate/high with good confidence")
    func testIsSignificantProperty() throws {
        let indicator = IllnessIndicator(
            date: Date(),
            severity: .moderate,
            confidence: 0.75,
            signals: [
                IllnessIndicator.Signal(
                    type: .hrvSpike,
                    deviation: 120.0,
                    value: 110.0,
                    baseline: 50.0
                )
            ],
            recommendation: "Rest recommended"
        )

        #expect(indicator.isSignificant == true)
    }

    @Test("isSignificant returns false for low severity")
    func testIsSignificantLowSeverity() throws {
        let indicator = IllnessIndicator(
            date: Date(),
            severity: .low,
            confidence: 0.75,
            signals: [
                IllnessIndicator.Signal(
                    type: .elevatedRHR,
                    deviation: 5.0,
                    value: 63.0,
                    baseline: 60.0
                )
            ],
            recommendation: "Monitor recovery"
        )

        #expect(indicator.isSignificant == false)
    }

    @Test("isRecent returns true for detection within 24 hours")
    func testIsRecentProperty() throws {
        let indicator = IllnessIndicator(
            date: Date().addingTimeInterval(-3600), // 1 hour ago
            severity: .moderate,
            confidence: 0.75,
            signals: [],
            recommendation: "Rest"
        )

        #expect(indicator.isRecent == true)
    }

    @Test("isRecent returns false for old detection")
    func testIsRecentOldDetection() throws {
        let indicator = IllnessIndicator(
            date: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            severity: .moderate,
            confidence: 0.75,
            signals: [],
            recommendation: "Rest"
        )

        #expect(indicator.isRecent == false)
    }
}
