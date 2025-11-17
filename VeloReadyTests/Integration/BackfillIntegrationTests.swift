import XCTest
import HealthKit
import CoreData
@testable import VeloReady

/// Integration tests for backfill functionality
/// Validates end-to-end backfill flow with real HealthKit data
final class BackfillIntegrationTests: XCTestCase {

    // Use shared instances for integration testing
    var persistence: PersistenceController { PersistenceController.shared }
    var healthKit: HealthKitManager { HealthKitManager.shared }
    var backfillService: BackfillService { BackfillService.shared }

    override func setUp() async throws {
        try await super.setUp()
        print("🧪 [BACKFILL TEST] Setup complete")
    }

    override func tearDown() async throws {
        try await super.tearDown()
        print("🧪 [BACKFILL TEST] Teardown complete")
    }

    // MARK: - Integration Tests

    /// Test 1: Verify HealthKit data is available
    func testHealthKitDataAvailability() async throws {
        print("\n🧪 [TEST 1] Checking HealthKit data availability...")

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -60, to: today)!

        // Fetch HRV samples
        let hrvSamples = await healthKit.fetchHRVSamples(from: startDate, to: Date())
        print("   📊 HRV samples: \(hrvSamples.count)")
        XCTAssertGreaterThan(hrvSamples.count, 0, "Should have HRV data from HealthKit")

        // Fetch RHR samples
        let rhrSamples = await healthKit.fetchRHRSamples(from: startDate, to: Date())
        print("   📊 RHR samples: \(rhrSamples.count)")
        XCTAssertGreaterThan(rhrSamples.count, 0, "Should have RHR data from HealthKit")

        // Fetch sleep samples
        let sleepSamples = (try? await healthKit.fetchSleepData(from: startDate, to: Date())) ?? []
        print("   📊 Sleep samples: \(sleepSamples.count)")
        XCTAssertGreaterThan(sleepSamples.count, 0, "Should have sleep data from HealthKit")

        // Group by day to see coverage
        var daysWithHRV: Set<Date> = []
        var daysWithRHR: Set<Date> = []
        var daysWithSleep: Set<Date> = []

        for sample in hrvSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            daysWithHRV.insert(day)
        }

        for sample in rhrSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            daysWithRHR.insert(day)
        }

        for sample in sleepSamples {
            let day = calendar.startOfDay(for: sample.startDate)
            daysWithSleep.insert(day)
        }

        print("   📊 Days with HRV: \(daysWithHRV.count)")
        print("   📊 Days with RHR: \(daysWithRHR.count)")
        print("   📊 Days with Sleep: \(daysWithSleep.count)")

        XCTAssertGreaterThan(daysWithHRV.count, 30, "Should have HRV data for at least 30 days")
        XCTAssertGreaterThan(daysWithRHR.count, 30, "Should have RHR data for at least 30 days")
        XCTAssertGreaterThan(daysWithSleep.count, 30, "Should have sleep data for at least 30 days")

        print("✅ [TEST 1] HealthKit data availability verified")
    }

    /// Test 2: Run physio backfill and verify data is stored
    func testPhysioDataBackfill() async throws {
        print("\n🧪 [TEST 2] Testing physio data backfill...")

        // Run backfill
        await backfillService.backfillHistoricalPhysioData(days: 60)

        // Query Core Data for results
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -60, to: today)!

        let request = DailyPhysio.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let physioRecords = try persistence.viewContext.fetch(request)
        print("   📊 DailyPhysio records created: \(physioRecords.count)")

        XCTAssertGreaterThan(physioRecords.count, 0, "Backfill should create DailyPhysio records")

        // Analyze the data
        var recordsWithHRV = 0
        var recordsWithRHR = 0
        var recordsWithSleep = 0
        var hrvValues: [Double] = []
        var rhrValues: [Double] = []
        var sleepHours: [Double] = []

        for physio in physioRecords {
            if physio.hrv > 0 {
                recordsWithHRV += 1
                hrvValues.append(physio.hrv)
            }
            if physio.rhr > 0 {
                recordsWithRHR += 1
                rhrValues.append(physio.rhr)
            }
            if physio.sleepDuration > 0 {
                recordsWithSleep += 1
                sleepHours.append(physio.sleepDuration / 3600.0)
            }
        }

        print("   📊 Records with HRV: \(recordsWithHRV)")
        print("   📊 Records with RHR: \(recordsWithRHR)")
        print("   📊 Records with Sleep: \(recordsWithSleep)")

        if !hrvValues.isEmpty {
            let avgHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)
            let minHRV = hrvValues.min() ?? 0
            let maxHRV = hrvValues.max() ?? 0
            print("   📊 HRV range: \(String(format: "%.1f", minHRV)) - \(String(format: "%.1f", maxHRV)) ms (avg: \(String(format: "%.1f", avgHRV)))")
        }

        if !rhrValues.isEmpty {
            let avgRHR = rhrValues.reduce(0, +) / Double(rhrValues.count)
            let minRHR = rhrValues.min() ?? 0
            let maxRHR = rhrValues.max() ?? 0
            print("   📊 RHR range: \(String(format: "%.1f", minRHR)) - \(String(format: "%.1f", maxRHR)) bpm (avg: \(String(format: "%.1f", avgRHR)))")
        }

        if !sleepHours.isEmpty {
            let avgSleep = sleepHours.reduce(0, +) / Double(sleepHours.count)
            let minSleep = sleepHours.min() ?? 0
            let maxSleep = sleepHours.max() ?? 0
            print("   📊 Sleep range: \(String(format: "%.1f", minSleep)) - \(String(format: "%.1f", maxSleep)) hours (avg: \(String(format: "%.1f", avgSleep)))")
        }

        print("✅ [TEST 2] Physio data backfill completed")
    }

    /// Test 3: Run recovery score backfill and analyze variance
    func testRecoveryScoreBackfill() async throws {
        print("\n🧪 [TEST 3] Testing recovery score backfill and variance...")

        // First run physio backfill to ensure we have data
        await backfillService.backfillHistoricalPhysioData(days: 60)

        // Run recovery score backfill with force refresh
        await backfillService.backfillHistoricalRecoveryScores(days: 60, forceRefresh: true)

        // Query Core Data for results
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -60, to: today)!

        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND recoveryScore > 0", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let scoreRecords = try persistence.viewContext.fetch(request)
        print("   📊 DailyScores records with recovery: \(scoreRecords.count)")

        XCTAssertGreaterThan(scoreRecords.count, 0, "Backfill should create DailyScores with recovery scores")

        // Analyze recovery score distribution
        var recoveryScores: [Double] = []
        var scoresInRange_0_40 = 0
        var scoresInRange_40_60 = 0
        var scoresInRange_60_80 = 0
        var scoresInRange_80_100 = 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"

        print("\n   📊 RECOVERY SCORE BREAKDOWN:")
        for scores in scoreRecords {
            let score = scores.recoveryScore
            recoveryScores.append(score)

            if let date = scores.date, let physio = scores.physio {
                print("      \(dateFormatter.string(from: date)): \(Int(score)) (HRV: \(String(format: "%.1f", physio.hrv)), RHR: \(String(format: "%.1f", physio.rhr)), Sleep: \(String(format: "%.1f", physio.sleepDuration / 3600.0))h)")
            }

            switch score {
            case 0..<40:
                scoresInRange_0_40 += 1
            case 40..<60:
                scoresInRange_40_60 += 1
            case 60..<80:
                scoresInRange_60_80 += 1
            case 80...100:
                scoresInRange_80_100 += 1
            default:
                break
            }
        }

        print("\n   📊 RECOVERY SCORE DISTRIBUTION:")
        print("      0-40: \(scoresInRange_0_40) days (\(Int(Double(scoresInRange_0_40) / Double(scoreRecords.count) * 100))%)")
        print("      40-60: \(scoresInRange_40_60) days (\(Int(Double(scoresInRange_40_60) / Double(scoreRecords.count) * 100))%)")
        print("      60-80: \(scoresInRange_60_80) days (\(Int(Double(scoresInRange_60_80) / Double(scoreRecords.count) * 100))%)")
        print("      80-100: \(scoresInRange_80_100) days (\(Int(Double(scoresInRange_80_100) / Double(scoreRecords.count) * 100))%)")

        if !recoveryScores.isEmpty {
            let avgScore = recoveryScores.reduce(0, +) / Double(recoveryScores.count)
            let minScore = recoveryScores.min() ?? 0
            let maxScore = recoveryScores.max() ?? 0
            let stdDev = sqrt(recoveryScores.map { pow($0 - avgScore, 2) }.reduce(0, +) / Double(recoveryScores.count))

            print("\n   📊 RECOVERY SCORE STATISTICS:")
            print("      Average: \(String(format: "%.1f", avgScore))")
            print("      Range: \(String(format: "%.1f", minScore)) - \(String(format: "%.1f", maxScore))")
            print("      Std Dev: \(String(format: "%.1f", stdDev))")
            print("      Variance (max-min): \(String(format: "%.1f", maxScore - minScore))")

            // CRITICAL ASSERTIONS
            XCTAssertGreaterThan(maxScore - minScore, 20, "Recovery scores should have at least 20 points of variance (currently: \(String(format: "%.1f", maxScore - minScore)))")
            XCTAssertGreaterThan(stdDev, 10, "Recovery scores should have standard deviation > 10 (currently: \(String(format: "%.1f", stdDev)))")

            // Check that we have good distribution (not all clustered in 40-60 range)
            let percentInHealthyRange = Double(scoresInRange_60_80 + scoresInRange_80_100) / Double(scoreRecords.count) * 100
            print("      Healthy range (60-100): \(Int(percentInHealthyRange))%")

            // CRITICAL: User complained all scores are 40-60. This should NOT be the case.
            let percentStuckInMidRange = Double(scoresInRange_40_60) / Double(scoreRecords.count) * 100
            XCTAssertLessThan(percentStuckInMidRange, 50, "More than half of scores should NOT be stuck in 40-60 range (currently: \(Int(percentStuckInMidRange))%)")

            if percentStuckInMidRange > 50 {
                print("⚠️  WARNING: \(Int(percentStuckInMidRange))% of scores are in 40-60 range. This indicates a calculation problem!")
            }
        }

        print("✅ [TEST 3] Recovery score backfill and variance analysis complete")
    }

    /// Test 4: Run sleep score backfill and analyze variance
    func testSleepScoreBackfill() async throws {
        print("\n🧪 [TEST 4] Testing sleep score backfill and variance...")

        // First run physio backfill
        await backfillService.backfillHistoricalPhysioData(days: 60)

        // Run sleep score backfill with force refresh
        await backfillService.backfillSleepScores(days: 60, forceRefresh: true)

        // Query Core Data for results
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -60, to: today)!

        let request = DailyScores.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND sleepScore > 0", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let scoreRecords = try persistence.viewContext.fetch(request)
        print("   📊 DailyScores records with sleep: \(scoreRecords.count)")

        XCTAssertGreaterThan(scoreRecords.count, 0, "Backfill should create DailyScores with sleep scores")

        // Analyze sleep score distribution
        var sleepScores: [Double] = []
        var scoresInRange_0_40 = 0
        var scoresInRange_40_60 = 0
        var scoresInRange_60_80 = 0
        var scoresInRange_80_100 = 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"

        print("\n   📊 SLEEP SCORE BREAKDOWN:")
        for scores in scoreRecords {
            let score = scores.sleepScore
            sleepScores.append(score)

            if let date = scores.date, let physio = scores.physio {
                print("      \(dateFormatter.string(from: date)): \(Int(score)) (Duration: \(String(format: "%.1f", physio.sleepDuration / 3600.0))h)")
            }

            switch score {
            case 0..<40:
                scoresInRange_0_40 += 1
            case 40..<60:
                scoresInRange_40_60 += 1
            case 60..<80:
                scoresInRange_60_80 += 1
            case 80...100:
                scoresInRange_80_100 += 1
            default:
                break
            }
        }

        print("\n   📊 SLEEP SCORE DISTRIBUTION:")
        print("      0-40: \(scoresInRange_0_40) days (\(Int(Double(scoresInRange_0_40) / Double(scoreRecords.count) * 100))%)")
        print("      40-60: \(scoresInRange_40_60) days (\(Int(Double(scoresInRange_40_60) / Double(scoreRecords.count) * 100))%)")
        print("      60-80: \(scoresInRange_60_80) days (\(Int(Double(scoresInRange_60_80) / Double(scoreRecords.count) * 100))%)")
        print("      80-100: \(scoresInRange_80_100) days (\(Int(Double(scoresInRange_80_100) / Double(scoreRecords.count) * 100))%)")

        if !sleepScores.isEmpty {
            let avgScore = sleepScores.reduce(0, +) / Double(sleepScores.count)
            let minScore = sleepScores.min() ?? 0
            let maxScore = sleepScores.max() ?? 0
            let stdDev = sqrt(sleepScores.map { pow($0 - avgScore, 2) }.reduce(0, +) / Double(sleepScores.count))

            print("\n   📊 SLEEP SCORE STATISTICS:")
            print("      Average: \(String(format: "%.1f", avgScore))")
            print("      Range: \(String(format: "%.1f", minScore)) - \(String(format: "%.1f", maxScore))")
            print("      Std Dev: \(String(format: "%.1f", stdDev))")
            print("      Variance (max-min): \(String(format: "%.1f", maxScore - minScore))")

            // CRITICAL ASSERTIONS
            XCTAssertGreaterThan(maxScore - minScore, 20, "Sleep scores should have at least 20 points of variance")
            XCTAssertGreaterThan(stdDev, 10, "Sleep scores should have standard deviation > 10")
        }

        print("✅ [TEST 4] Sleep score backfill and variance analysis complete")
    }

    /// Test 5: End-to-end full backfill test
    func testFullBackfillFlow() async throws {
        print("\n🧪 [TEST 5] Testing full end-to-end backfill flow...")

        // Run complete backfill
        await backfillService.backfillAll(days: 60, forceRefresh: true)

        // Verify all data is present
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -60, to: today)!

        // Check DailyPhysio
        let physioRequest = DailyPhysio.fetchRequest()
        physioRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        let physioRecords = try persistence.viewContext.fetch(physioRequest)
        print("   📊 DailyPhysio records: \(physioRecords.count)")

        // Check DailyScores
        let scoresRequest = DailyScores.fetchRequest()
        scoresRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        let scoreRecords = try persistence.viewContext.fetch(scoresRequest)
        print("   📊 DailyScores records: \(scoreRecords.count)")

        // Count records with actual scores
        let recoveryCount = scoreRecords.filter { $0.recoveryScore > 0 }.count
        let sleepCount = scoreRecords.filter { $0.sleepScore > 0 }.count
        let strainCount = scoreRecords.filter { $0.strainScore > 0 }.count

        print("   📊 Records with recovery scores: \(recoveryCount)")
        print("   📊 Records with sleep scores: \(sleepCount)")
        print("   📊 Records with strain scores: \(strainCount)")

        XCTAssertGreaterThan(recoveryCount, 20, "Should have at least 20 days with recovery scores")
        XCTAssertGreaterThan(sleepCount, 20, "Should have at least 20 days with sleep scores")

        print("✅ [TEST 5] Full backfill flow complete")
    }
}
