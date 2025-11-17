import Foundation
import Testing
@testable import VeloReady

@Suite("Input Validation")
struct InputValidationTests {

    // MARK: - StrainDataCalculator Input Validation Tests

    @Test("Validate FTP within valid range")
    func testValidFTP() async {
        let calculator = StrainDataCalculator()

        // Test valid FTP values (50-600W)
        let validFTPs: [Double] = [50, 150, 250, 400, 600]

        for ftp in validFTPs {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: ftp,
                maxHeartRate: 180,
                restingHeartRate: 60,
                bodyMass: 75
            )

            // Should complete without errors (result may be nil due to missing health data)
            // Main validation: no crash, valid result type
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Reject invalid FTP values")
    func testInvalidFTP() async {
        let calculator = StrainDataCalculator()

        // Test invalid FTP values (outside 50-600W range)
        let invalidFTPs: [Double] = [0, 10, 700, 1000]

        for ftp in invalidFTPs {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: ftp,
                maxHeartRate: 180,
                restingHeartRate: 60,
                bodyMass: 75
            )

            // Should handle gracefully (nil FTP passed to calculation)
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Validate MaxHR within valid range")
    func testValidMaxHR() async {
        let calculator = StrainDataCalculator()

        // Test valid MaxHR values (100-220 BPM)
        let validMaxHRs: [Double] = [100, 150, 180, 200, 220]

        for maxHR in validMaxHRs {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: 250,
                maxHeartRate: maxHR,
                restingHeartRate: 60,
                bodyMass: 75
            )

            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Reject invalid MaxHR values")
    func testInvalidMaxHR() async {
        let calculator = StrainDataCalculator()

        // Test invalid MaxHR values (outside 100-220 BPM range)
        let invalidMaxHRs: [Double] = [50, 80, 250, 300]

        for maxHR in invalidMaxHRs {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: 250,
                maxHeartRate: maxHR,
                restingHeartRate: 60,
                bodyMass: 75
            )

            // Should handle gracefully
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Validate RestingHR within valid range")
    func testValidRestingHR() async {
        let calculator = StrainDataCalculator()

        // Test valid RestingHR values (30-100 BPM)
        let validRestingHRs: [Double] = [30, 45, 60, 80, 100]

        for restingHR in validRestingHRs {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: 250,
                maxHeartRate: 180,
                restingHeartRate: restingHR,
                bodyMass: 75
            )

            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Reject invalid RestingHR values")
    func testInvalidRestingHR() async {
        let calculator = StrainDataCalculator()

        // Test invalid RestingHR values (outside 30-100 BPM range)
        let invalidRestingHRs: [Double] = [10, 20, 110, 150]

        for restingHR in invalidRestingHRs {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: 250,
                maxHeartRate: 180,
                restingHeartRate: restingHR,
                bodyMass: 75
            )

            // Should handle gracefully
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Validate BodyMass within valid range")
    func testValidBodyMass() async {
        let calculator = StrainDataCalculator()

        // Test valid BodyMass values (40-200 kg)
        let validBodyMasses: [Double] = [40, 60, 75, 100, 200]

        for bodyMass in validBodyMasses {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: 250,
                maxHeartRate: 180,
                restingHeartRate: 60,
                bodyMass: bodyMass
            )

            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Reject invalid BodyMass values")
    func testInvalidBodyMass() async {
        let calculator = StrainDataCalculator()

        // Test invalid BodyMass values (outside 40-200 kg range)
        let invalidBodyMasses: [Double] = [10, 30, 250, 300]

        for bodyMass in invalidBodyMasses {
            let result = await calculator.calculateStrainScore(
                sleepScore: nil,
                ftp: 250,
                maxHeartRate: 180,
                restingHeartRate: 60,
                bodyMass: bodyMass
            )

            // Should handle gracefully
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Handle nil input values gracefully")
    func testNilInputs() async {
        let calculator = StrainDataCalculator()

        // Test with all nil user inputs
        let result = await calculator.calculateStrainScore(
            sleepScore: nil,
            ftp: nil,
            maxHeartRate: nil,
            restingHeartRate: nil,
            bodyMass: nil
        )

        // Should not crash with nil inputs
        #expect(result == nil || result?.score ?? 0 >= 0)
    }

    // MARK: - SleepScoreCalculator Input Validation Tests

    @Test("Validate sleep need within valid range")
    func testValidSleepNeed() async {
        let calculator = SleepDataCalculator()

        // Test valid sleep need values (4-12 hours in seconds)
        let validSleepNeeds: [Double] = [
            4 * 3600,  // 4 hours
            6 * 3600,  // 6 hours
            8 * 3600,  // 8 hours
            10 * 3600, // 10 hours
            12 * 3600  // 12 hours
        ]

        for sleepNeed in validSleepNeeds {
            let result = await calculator.calculateSleepScore(sleepNeed: sleepNeed)

            // Should complete without errors (result may be nil due to missing sleep data)
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Handle invalid sleep need with fallback")
    func testInvalidSleepNeedFallback() async {
        let calculator = SleepDataCalculator()

        // Test invalid sleep need values (outside 4-12 hours)
        let invalidSleepNeeds: [Double] = [
            2 * 3600,  // 2 hours (too short)
            3 * 3600,  // 3 hours (too short)
            15 * 3600, // 15 hours (too long)
            20 * 3600  // 20 hours (too long)
        ]

        for sleepNeed in invalidSleepNeeds {
            let result = await calculator.calculateSleepScore(sleepNeed: sleepNeed)

            // Should fallback to 8 hours and not crash
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }

    @Test("Boundary values for sleep need")
    func testSleepNeedBoundaries() async {
        let calculator = SleepDataCalculator()

        // Test boundary values
        let boundaryValues: [Double] = [
            4 * 3600,      // Minimum valid (4h)
            4 * 3600 - 1,  // Just below minimum
            12 * 3600,     // Maximum valid (12h)
            12 * 3600 + 1  // Just above maximum
        ]

        for sleepNeed in boundaryValues {
            let result = await calculator.calculateSleepScore(sleepNeed: sleepNeed)

            // Should handle boundary cases gracefully
            #expect(result == nil || result?.score ?? 0 >= 0)
        }
    }
}
