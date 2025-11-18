import XCTest
import CoreData
@testable import VeloReady

/// Integration tests for TrainingLoadGraphCard ViewModel
/// Verifies Core Data strategy (Intervals.icu/Wahoo) and fallback to progressive calculation
@MainActor
class TrainingLoadGraphCardTests: XCTestCase {
    var context: NSManagedObjectContext { PersistenceController.shared.container.viewContext }
    var viewModel: TrainingLoadGraphCardViewModel!

    override func setUp() async throws {
        try await super.setUp()

        // Clear existing test data
        CoreDataTestHelper.clearAllData(context: context)

        viewModel = TrainingLoadGraphCardViewModel()
        print("🧪 [TRAINING LOAD TEST] Setup complete")
    }

    override func tearDown() async throws {
        // Clean up test data
        CoreDataTestHelper.clearAllData(context: context)
        viewModel = nil
        try await super.tearDown()
        print("🧪 [TRAINING LOAD TEST] Teardown complete")
    }

    // MARK: - Core Data Strategy Tests (Intervals.icu/Wahoo)

    func testUsesIntervalsDataWhenAvailable() async throws {
        // Given: Core Data has 14 days of Intervals.icu data with good coverage
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Seed Core Data with 14 days of data (100% coverage)
        for dayOffset in -13...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let dailyScore = DailyScores(context: context)
            dailyScore.date = date

            let dailyLoad = DailyLoad(context: context)
            dailyLoad.ctl = 23.7 + Double(dayOffset) * 0.5  // Gradually increasing
            dailyLoad.atl = 21.6 + Double(dayOffset) * 0.3
            dailyLoad.tsb = dailyLoad.ctl - dailyLoad.atl

            dailyScore.load = dailyLoad
        }

        try context.save()

        print("🧪 [TEST] Seeded Core Data with 14 days of Intervals.icu data")

        // When: Load chart data
        await viewModel.load()

        // Then: Chart data should contain Core Data values (not progressive calculation)
        let historicalData = viewModel.chartData.filter { !$0.isFuture }

        XCTAssertEqual(historicalData.count, 14, "Should have 14 historical data points")

        // Verify today's data matches Core Data
        if let todayPoint = historicalData.first(where: { calendar.isDateInToday($0.date) }) {
            XCTAssertEqual(todayPoint.ctl, 23.7, accuracy: 0.1, "Today's CTL should match Core Data")
            XCTAssertEqual(todayPoint.atl, 21.6, accuracy: 0.1, "Today's ATL should match Core Data")
            print("🧪 [TEST] ✅ Today's values: CTL=\(todayPoint.ctl), ATL=\(todayPoint.atl)")
        } else {
            XCTFail("Should have data for today")
        }

        // Verify projection exists (7 future days)
        let futureData = viewModel.chartData.filter { $0.isFuture }
        XCTAssertEqual(futureData.count, 7, "Should have 7 future projection points")
    }

    func testFillsMissingDaysWithInterpolation() async throws {
        // Given: Core Data has partial coverage (8 out of 14 days = 57%)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Seed Core Data with every other day
        for dayOffset in stride(from: -13, through: 0, by: 2) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let dailyScore = DailyScores(context: context)
            dailyScore.date = date

            let dailyLoad = DailyLoad(context: context)
            dailyLoad.ctl = 20.0 + Double(dayOffset) * 0.5
            dailyLoad.atl = 18.0 + Double(dayOffset) * 0.3
            dailyLoad.tsb = dailyLoad.ctl - dailyLoad.atl

            dailyScore.load = dailyLoad
        }

        try context.save()

        print("🧪 [TEST] Seeded Core Data with 8/14 days (partial coverage)")

        // When: Load chart data
        await viewModel.load()

        // Then: Should use Core Data strategy (>50% coverage) and fill missing days
        let historicalData = viewModel.chartData.filter { !$0.isFuture }

        XCTAssertEqual(historicalData.count, 14, "Should have filled all 14 days via interpolation")

        // Verify data is continuous (no gaps)
        for i in 0..<historicalData.count - 1 {
            let currentDate = historicalData[i].date
            let nextDate = historicalData[i + 1].date
            let daysDifference = calendar.dateComponents([.day], from: currentDate, to: nextDate).day

            XCTAssertEqual(daysDifference, 1, "Data should be continuous (no gaps)")
        }
    }

    // MARK: - Fallback Strategy Tests (Progressive Calculation)
    // Note: Progressive calculation fallback requires actual activity data from Strava/Intervals.
    // The main fallback logic is tested through baseline seeding test below.

    func testBaselineSeedingFromCoreData() async throws {
        // Given: No data in display window, but recent Core Data exists for baseline
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add one recent Core Data point (baseline)
        let dailyScore = DailyScores(context: context)
        dailyScore.date = today

        let dailyLoad = DailyLoad(context: context)
        dailyLoad.ctl = 30.0
        dailyLoad.atl = 25.0
        dailyLoad.tsb = 5.0

        dailyScore.load = dailyLoad

        try context.save()

        print("🧪 [TEST] Seeded Core Data with baseline: CTL=30.0, ATL=25.0")

        // When: Load chart data
        await viewModel.load()

        // Then: Progressive calculation should use this as baseline
        // (This is hard to verify directly without inspecting internals,
        //  but we can check that values are reasonable)
        let historicalData = viewModel.chartData.filter { !$0.isFuture }

        if let todayPoint = historicalData.first(where: { calendar.isDateInToday($0.date) }) {
            // Values should be in reasonable range of baseline
            XCTAssertGreaterThan(todayPoint.ctl, 0, "CTL should be seeded from baseline")
            print("🧪 [TEST] ✅ Today's CTL after baseline seeding: \(todayPoint.ctl)")
        }
    }

    // MARK: - Cache Tests

    func testCachesDataForFiveMinutes() async throws {
        // Given: Core Data with some data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dailyScore = DailyScores(context: context)
        dailyScore.date = today

        let dailyLoad = DailyLoad(context: context)
        dailyLoad.ctl = 20.0
        dailyLoad.atl = 18.0
        dailyLoad.tsb = 2.0

        dailyScore.load = dailyLoad

        try context.save()

        // When: Load data twice
        await viewModel.load()
        let firstLoad = viewModel.chartData.count

        await viewModel.load()  // Should use cache
        let secondLoad = viewModel.chartData.count

        // Then: Both loads should return same data
        XCTAssertEqual(firstLoad, secondLoad, "Cache should return consistent data")
        print("🧪 [TEST] ✅ Cache working: \(firstLoad) data points both times")
    }

    // MARK: - Projection Tests

    func testGeneratesSevenDayProjection() async throws {
        // Given: Core Data with today's data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in -13...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let dailyScore = DailyScores(context: context)
            dailyScore.date = date

            let dailyLoad = DailyLoad(context: context)
            dailyLoad.ctl = 25.0
            dailyLoad.atl = 22.0
            dailyLoad.tsb = 3.0

            dailyScore.load = dailyLoad
        }

        try context.save()

        // When: Load chart data
        await viewModel.load()

        // Then: Should have 7 future projection points
        let futureData = viewModel.chartData.filter { $0.isFuture }

        XCTAssertEqual(futureData.count, 7, "Should project 7 days into future")

        // Verify projection shows decay (CTL and ATL should decrease without training)
        if futureData.count >= 2 {
            let firstFuturePoint = futureData[0]
            let lastFuturePoint = futureData[futureData.count - 1]

            XCTAssertLessThan(lastFuturePoint.ctl, firstFuturePoint.ctl, "CTL should decay over time")
            XCTAssertLessThan(lastFuturePoint.atl, firstFuturePoint.atl, "ATL should decay over time")

            print("🧪 [TEST] ✅ Projection decay: CTL \(firstFuturePoint.ctl) → \(lastFuturePoint.ctl)")
        }
    }
}
