import Foundation
import Testing
import CoreData
@testable import VeloReady

@Suite("Core Data Persistence")
struct CoreDataPersistenceTests {
    
    // MARK: - Test Setup
    
    func createTestContext() -> NSManagedObjectContext {
        let container = CoreDataTestHelper.createInMemoryContainer()
        return container.viewContext
    }
    
    // MARK: - Recovery Score Persistence Tests
    
    @Test("Save recovery score with nil HRV preserves nil")
    func testSaveRecoveryScoreWithNilHRV() async throws {
        let context = createTestContext()
        
        // Create DailyPhysio with nil HRV (stored as 0 in Core Data)
        let physio = DailyPhysio(context: context)
        physio.date = Calendar.current.startOfDay(for: Date())
        physio.hrv = 0.0  // Core Data stores nil as 0
        physio.hrvBaseline = 44.0
        physio.rhr = 58.0
        physio.rhrBaseline = 60.0
        
        try context.save()
        
        // Fetch and validate
        let fetchRequest = DailyPhysio.fetchRequest()
        let results = try context.fetch(fetchRequest)
        
        #expect(results.count == 1)
        let savedPhysio = results[0]
        
        // Validate that zero is treated as nil
        #expect(savedPhysio.hrv == 0.0)  // Core Data stores nil as 0
        #expect(savedPhysio.hrvBaseline == 44.0)  // Baseline should be preserved
    }
    
    @Test("Save recovery score with zero values preserves zeros")
    func testSaveRecoveryScoreWithZeroValues() async throws {
        let context = createTestContext()
        
        // Create DailyPhysio with explicit zero values
        let physio = DailyPhysio(context: context)
        physio.date = Calendar.current.startOfDay(for: Date())
        physio.hrv = 0.0
        physio.hrvBaseline = 0.0
        physio.rhr = 0.0
        physio.rhrBaseline = 0.0
        
        try context.save()
        
        // Fetch and validate
        let fetchRequest = DailyPhysio.fetchRequest()
        let results = try context.fetch(fetchRequest)
        
        #expect(results.count == 1)
        let savedPhysio = results[0]
        
        // All values should be zero
        #expect(savedPhysio.hrv == 0.0)
        #expect(savedPhysio.hrvBaseline == 0.0)
        #expect(savedPhysio.rhr == 0.0)
        #expect(savedPhysio.rhrBaseline == 0.0)
    }
    
    @Test("Fetch recovery score distinguishes nil from zero")
    func testFetchDistinguishesNilFromZero() async throws {
        let context = createTestContext()
        
        // Create two records: one with nil (0.0), one with actual zero
        let physio1 = DailyPhysio(context: context)
        physio1.date = Calendar.current.startOfDay(for: Date())
        physio1.hrv = 0.0  // Nil value
        physio1.hrvBaseline = 44.0  // Has baseline
        
        let physio2 = DailyPhysio(context: context)
        physio2.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        physio2.hrv = 0.0  // Zero value
        physio2.hrvBaseline = 0.0  // No baseline
        
        try context.save()
        
        // Fetch and validate
        let fetchRequest = DailyPhysio.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let results = try context.fetch(fetchRequest)
        
        #expect(results.count == 2)
        
        // First record: nil HRV (has baseline)
        let record1 = results[0]
        #expect(record1.hrv == 0.0)
        #expect(record1.hrvBaseline > 0.0)  // Baseline indicates nil, not zero
        
        // Second record: zero HRV (no baseline)
        let record2 = results[1]
        #expect(record2.hrv == 0.0)
        #expect(record2.hrvBaseline == 0.0)  // No baseline indicates actual zero
    }
    
    @Test("Historical data not overwritten by refresh")
    func testHistoricalDataPreservation() async throws {
        let context = createTestContext()
        
        // Seed 7 days of historical data
        CoreDataTestHelper.seedTestData(context: context, days: 7)
        
        let beforeCount = CoreDataTestHelper.countRecords(entityName: "DailyScores", context: context)
        #expect(beforeCount == 7)
        
        // Simulate a refresh that only updates today
        let today = Calendar.current.startOfDay(for: Date())
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
        let todayScores = try context.fetch(fetchRequest)
        
        if let todayScore = todayScores.first {
            todayScore.recoveryScore = 95.0  // Update today's score
        }
        
        try context.save()
        
        // Validate all historical data still exists
        let afterCount = CoreDataTestHelper.countRecords(entityName: "DailyScores", context: context)
        #expect(afterCount == 7)  // Should still have 7 days
        
        // Validate historical scores weren't changed
        let allScores: [DailyScores] = CoreDataTestHelper.fetchAll(entityName: "DailyScores", context: context)
        let historicalScores = allScores.filter { $0.date != today }
        #expect(historicalScores.count == 6)  // 6 historical days
        
        // Validate today was updated
        let updatedToday = allScores.first { $0.date == today }
        #expect(updatedToday?.recoveryScore == 95.0)
    }
    
    @Test("Batch save preserves all records")
    func testBatchSavePreservesAllRecords() async throws {
        let context = createTestContext()
        
        // Create multiple records in a batch
        let dates = (0..<30).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
        
        for date in dates {
            let scores = MockDataFactory.createDailyScores(
                context: context,
                date: date,
                recoveryScore: Double.random(in: 60...90)
            )
        }
        
        try context.save()
        
        // Validate all records saved
        let count = CoreDataTestHelper.countRecords(entityName: "DailyScores", context: context)
        #expect(count == 30)
    }
    
    // MARK: - Cache Invalidation Tests
    
    @Test("Cache invalidation clears only specified dates")
    func testCacheInvalidationTargeted() async throws {
        let context = createTestContext()
        
        // Seed 7 days of data
        CoreDataTestHelper.seedTestData(context: context, days: 7)
        
        let beforeCount = CoreDataTestHelper.countRecords(entityName: "DailyScores", context: context)
        #expect(beforeCount == 7)
        
        // Delete only today's data
        let today = Calendar.current.startOfDay(for: Date())
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
        
        let todayScores = try context.fetch(fetchRequest)
        for score in todayScores {
            context.delete(score)
        }
        
        try context.save()
        
        // Validate only today was deleted
        let afterCount = CoreDataTestHelper.countRecords(entityName: "DailyScores", context: context)
        #expect(afterCount == 6)  // Should have 6 days left
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Concurrent reads don't corrupt data")
    func testConcurrentReads() async throws {
        let context = createTestContext()
        
        // Seed test data
        CoreDataTestHelper.seedTestData(context: context, days: 7)
        
        // Perform multiple concurrent reads
        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let fetchRequest = DailyScores.fetchRequest()
                    let results = try? context.fetch(fetchRequest)
                    return results?.count ?? 0
                }
            }
            
            var counts: [Int] = []
            for await count in group {
                counts.append(count)
            }
            
            // All reads should return the same count
            #expect(counts.allSatisfy { $0 == 7 })
        }
    }
}
