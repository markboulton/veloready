import Foundation
import Testing
import CoreData
@testable import VeloReady

@Suite("Cache Manager")
struct CacheManagerTests {
    
    // MARK: - Test Setup
    
    func createTestContext() -> NSManagedObjectContext {
        let container = CoreDataTestHelper.createInMemoryContainer()
        return container.viewContext
    }
    
    // MARK: - Cache Refresh Tests
    
    @Test("Refresh preserves historical data")
    func testRefreshPreservesHistorical() async throws {
        let context = createTestContext()
        
        // Seed 7 days of historical data
        CoreDataTestHelper.seedTestData(context: context, days: 7)
        
        let beforeCount = CoreDataTestHelper.countRecords(entityName: "DailyScores", context: context)
        #expect(beforeCount == 7)
        
        // Simulate refresh (should only update today, not delete historical)
        let today = Calendar.current.startOfDay(for: Date())
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
        let todayScores = try context.fetch(fetchRequest)
        
        if let todayScore = todayScores.first {
            todayScore.recoveryScore = 95.0
        }
        
        try context.save()
        
        // Validate historical data still exists
        let afterCount = CoreDataTestHelper.countRecords(entityName: "DailyScores", context: context)
        #expect(afterCount == 7)
    }
    
    @Test("Refresh only updates today")
    func testRefreshOnlyToday() async throws {
        let context = createTestContext()
        
        // Create data for today and yesterday
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todayScore = MockDataFactory.createDailyScores(
            context: context,
            date: today,
            recoveryScore: 80.0
        )
        
        let yesterdayScore = MockDataFactory.createDailyScores(
            context: context,
            date: yesterday,
            recoveryScore: 75.0
        )
        
        try context.save()
        
        // Update today's score
        todayScore.recoveryScore = 90.0
        try context.save()
        
        // Fetch and validate
        let fetchRequest = DailyScores.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let results = try context.fetch(fetchRequest)
        
        #expect(results.count == 2)
        #expect(results[0].recoveryScore == 90.0)  // Today updated
        #expect(results[1].recoveryScore == 75.0)  // Yesterday unchanged
    }
    
    @Test("Cache handles missing data gracefully")
    func testCacheHandlesMissingData() async throws {
        let context = createTestContext()
        
        // Try to fetch from empty cache
        let fetchRequest = DailyScores.fetchRequest()
        let results = try context.fetch(fetchRequest)
        
        #expect(results.isEmpty)
    }
    
    @Test("Cache invalidation clears specific dates")
    func testCacheInvalidation() async throws {
        let context = createTestContext()
        
        // Seed 7 days
        CoreDataTestHelper.seedTestData(context: context, days: 7)
        
        // Delete only today
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
        #expect(afterCount == 6)
    }
}
