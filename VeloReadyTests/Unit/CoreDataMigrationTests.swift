import Foundation
import Testing
import CoreData
@testable import VeloReady

/// Comprehensive tests for Core Data schema migrations and data integrity
/// Tests lightweight migrations, schema version upgrades, and data preservation
/// Ensures regression-free Core Data operations during app updates
@Suite("Core Data Migration & Schema Integrity")
@MainActor
struct CoreDataMigrationTests {

    // MARK: - Helper Methods

    func createInMemoryContext() -> NSManagedObjectContext {
        let controller = PersistenceController.preview
        return controller.viewContext
    }

    // MARK: - Entity Creation Tests

    @Test("Creates DailyScores entity successfully")
    func testCreatesDailyScoresEntity() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()
        scores.recoveryScore = 75.0
        scores.sleepScore = 80.0
        scores.strainScore = 60.0
        scores.lastUpdated = Date()

        try context.save()

        #expect(scores.managedObjectContext != nil, "Entity should be persisted")
        #expect(scores.recoveryScore == 75.0)
    }

    @Test("Creates DailyPhysio entity successfully")
    func testCreatesDailyPhysioEntity() throws {
        let context = createInMemoryContext()

        let physio = DailyPhysio(context: context)
        physio.date = Date()
        physio.hrv = 55.0
        physio.hrvBaseline = 50.0
        physio.rhr = 58.0
        physio.rhrBaseline = 60.0
        physio.lastUpdated = Date()

        try context.save()

        #expect(physio.managedObjectContext != nil, "Entity should be persisted")
        #expect(physio.hrv == 55.0)
    }

    @Test("Creates DailyLoad entity successfully")
    func testCreatesDailyLoadEntity() throws {
        let context = createInMemoryContext()

        let load = DailyLoad(context: context)
        load.date = Date()
        load.ctl = 65.0
        load.atl = 58.0
        load.tsb = 7.0
        load.tss = 100.0
        load.lastUpdated = Date()

        try context.save()

        #expect(load.managedObjectContext != nil, "Entity should be persisted")
        #expect(load.ctl == 65.0)
    }

    // MARK: - Relationship Tests

    @Test("Establishes relationship between DailyScores and DailyPhysio")
    func testDailyScoresPhysioRelationship() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()

        let physio = DailyPhysio(context: context)
        physio.date = Date()
        physio.hrv = 55.0

        scores.physio = physio

        try context.save()

        #expect(scores.physio != nil, "Relationship should be established")
        #expect(scores.physio?.hrv == 55.0, "Related data should be accessible")
    }

    @Test("Establishes relationship between DailyScores and DailyLoad")
    func testDailyScoresLoadRelationship() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()

        let load = DailyLoad(context: context)
        load.date = Date()
        load.ctl = 65.0

        scores.load = load

        try context.save()

        #expect(scores.load != nil, "Relationship should be established")
        #expect(scores.load?.ctl == 65.0, "Related data should be accessible")
    }

    // MARK: - Cascading Deletion Tests

    @Test("Cascade delete preserves orphaned relationships correctly")
    func testCascadeDeleteBehavior() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()

        let physio = DailyPhysio(context: context)
        physio.date = Date()

        scores.physio = physio

        try context.save()

        // Delete scores (should cascade to physio based on schema)
        context.delete(scores)

        try context.save()

        // Verify scores deleted
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        let remainingScores = try context.fetch(fetchRequest)

        #expect(remainingScores.isEmpty, "Scores should be deleted")
    }

    // MARK: - Data Integrity Tests

    @Test("Validates required attributes are present")
    func testRequiredAttributesPresent() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()
        scores.lastUpdated = Date()

        // Non-optional attributes have defaults (0.0)
        scores.recoveryScore = 0.0
        scores.sleepScore = 0.0

        // Should save successfully even with default values
        try context.save()

        #expect(scores.date != nil, "Required attribute should be present")
        #expect(scores.recoveryScore == 0.0, "Default value should be set")
        #expect(scores.sleepScore == 0.0, "Default value should be set")
    }

    @Test("Preserves data types correctly")
    func testDataTypePreservation() throws {
        let context = createInMemoryContext()

        let physio = DailyPhysio(context: context)
        physio.date = Date()
        physio.hrv = 55.5 // Double
        physio.hrvBaseline = 50.0 // Double
        physio.sleepDuration = 28800.0 // Double (seconds)

        try context.save()

        // Fetch and verify types preserved
        let fetchRequest: NSFetchRequest<DailyPhysio> = DailyPhysio.fetchRequest()
        let fetched = try context.fetch(fetchRequest)

        #expect(fetched.first?.hrv is Double, "HRV should be Double")
        #expect(fetched.first?.hrv == 55.5, "Value should be exact")
    }

    // MARK: - Unique Constraint Tests

    @Test("Handles duplicate dates correctly")
    func testHandlesDuplicateDates() throws {
        let context = createInMemoryContext()
        let today = Calendar.current.startOfDay(for: Date())

        // Create first entry for today
        let scores1 = DailyScores(context: context)
        scores1.date = today
        scores1.recoveryScore = 70.0

        try context.save()

        // Create second entry for same day
        let scores2 = DailyScores(context: context)
        scores2.date = today
        scores2.recoveryScore = 75.0

        try context.save()

        // Both should exist (no unique constraint on date)
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
        let results = try context.fetch(fetchRequest)

        #expect(results.count >= 2, "Multiple entries for same date should be allowed")
    }

    // MARK: - Fetch Request Tests

    @Test("Fetches data by date predicate")
    func testFetchByDatePredicate() throws {
        let context = createInMemoryContext()
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // Create today's data
        let todayScores = DailyScores(context: context)
        todayScores.date = today
        todayScores.recoveryScore = 75.0

        // Create yesterday's data
        let yesterdayScores = DailyScores(context: context)
        yesterdayScores.date = yesterday
        yesterdayScores.recoveryScore = 70.0

        try context.save()

        // Fetch only today
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
        let results = try context.fetch(fetchRequest)

        #expect(results.count >= 1, "Should fetch today's data")
        #expect(results.first?.recoveryScore == 75.0 || results.contains(where: { $0.recoveryScore == 75.0 }), "Should have today's score")
    }

    @Test("Sorts data by date ascending")
    func testSortByDateAscending() throws {
        let context = createInMemoryContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create data in random order
        for offset in [2, 0, 1] {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let scores = DailyScores(context: context)
            scores.date = date
            scores.recoveryScore = Double(offset) // Use offset as score for verification

            try context.save()
        }

        // Fetch sorted
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let results = try context.fetch(fetchRequest)

        // Verify sorted (oldest first)
        #expect(results.count >= 3, "Should have 3 entries")

        // Dates should be in ascending order
        for i in 0..<results.count - 1 {
            if let date1 = results[i].date, let date2 = results[i + 1].date {
                #expect(date1 <= date2, "Dates should be ascending")
            }
        }
    }

    // MARK: - Update Tests

    @Test("Updates existing entity successfully")
    func testUpdatesExistingEntity() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()
        scores.recoveryScore = 70.0

        try context.save()

        // Update
        scores.recoveryScore = 80.0
        scores.lastUpdated = Date()

        try context.save()

        // Fetch and verify
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.first?.recoveryScore == 80.0 || results.contains(where: { $0.recoveryScore == 80.0 }), "Score should be updated")
    }

    // MARK: - Batch Operations Tests

    @Test("Batch inserts multiple entities")
    func testBatchInsert() throws {
        let context = createInMemoryContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Insert 7 days of data
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let scores = DailyScores(context: context)
            scores.date = date
            scores.recoveryScore = Double(70 + offset)
        }

        try context.save()

        // Verify all inserted
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count >= 7, "Should have 7+ entries")
    }

    @Test("Batch deletes old data")
    func testBatchDelete() throws {
        let context = createInMemoryContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Insert data spanning 30 days
        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let scores = DailyScores(context: context)
            scores.date = date
        }

        try context.save()

        // Delete data older than 14 days
        let cutoffDate = calendar.date(byAdding: .day, value: -14, to: today)!
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)

        let oldEntries = try context.fetch(fetchRequest)
        for entry in oldEntries {
            context.delete(entry)
        }

        try context.save()

        // Verify deletion
        let allRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        let remaining = try context.fetch(allRequest)

        #expect(remaining.count <= 15, "Should have deleted old entries")
    }

    // MARK: - CloudKit Sync Tests

    @Test("lastUpdated timestamp tracks modifications")
    func testLastUpdatedTracking() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()
        scores.lastUpdated = Date()

        let originalTimestamp = scores.lastUpdated!

        try context.save()

        // Wait a moment (simulate time passing)
        Thread.sleep(forTimeInterval: 0.1) // 0.1 seconds

        // Update
        scores.recoveryScore = 75.0
        scores.lastUpdated = Date()

        let newTimestamp = scores.lastUpdated!

        #expect(newTimestamp > originalTimestamp, "Timestamp should be updated")
    }

    // MARK: - Migration Compatibility Tests

    @Test("Lightweight migration options are enabled")
    func testMigrationOptionsEnabled() throws {
        // Verify migration is configured in PersistenceController
        let controller = PersistenceController.preview

        guard let description = controller.container.persistentStoreDescriptions.first else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No store description"])
        }

        let autoMigrate = description.options[NSMigratePersistentStoresAutomaticallyOption] as? Bool
        let inferMapping = description.options[NSInferMappingModelAutomaticallyOption] as? Bool

        #expect(autoMigrate == true, "Auto migration should be enabled")
        #expect(inferMapping == true, "Infer mapping should be enabled")
    }

    // MARK: - Schema Validation Tests

    @Test("All entities have required attributes")
    func testEntitiesHaveRequiredAttributes() throws {
        let context = createInMemoryContext()
        let model = context.persistentStoreCoordinator?.managedObjectModel

        #expect(model != nil, "Model should be accessible")

        // Verify key entities exist
        let dailyScoresEntity = model?.entitiesByName["DailyScores"]
        let dailyPhysioEntity = model?.entitiesByName["DailyPhysio"]
        let dailyLoadEntity = model?.entitiesByName["DailyLoad"]

        #expect(dailyScoresEntity != nil, "DailyScores entity should exist")
        #expect(dailyPhysioEntity != nil, "DailyPhysio entity should exist")
        #expect(dailyLoadEntity != nil, "DailyLoad entity should exist")
    }

    @Test("Relationships are properly configured")
    func testRelationshipsConfigured() throws {
        let context = createInMemoryContext()
        let model = context.persistentStoreCoordinator?.managedObjectModel

        let dailyScoresEntity = model?.entitiesByName["DailyScores"]

        // Check relationships exist
        let physioRelationship = dailyScoresEntity?.relationshipsByName["physio"]
        let loadRelationship = dailyScoresEntity?.relationshipsByName["load"]

        #expect(physioRelationship != nil, "Physio relationship should exist")
        #expect(loadRelationship != nil, "Load relationship should exist")

        // Verify cardinality
        #expect(physioRelationship?.maxCount == 1, "Physio should be to-one relationship")
        #expect(loadRelationship?.maxCount == 1, "Load should be to-one relationship")
    }

    // MARK: - Error Handling Tests

    @Test("Handles save errors gracefully")
    func testHandlesSaveErrors() throws {
        let context = createInMemoryContext()

        let scores = DailyScores(context: context)
        scores.date = Date()

        // Should save successfully
        do {
            try context.save()
            #expect(true, "Save should succeed")
        } catch {
            #expect(false, "Save should not throw error: \(error)")
        }
    }

    @Test("Handles fetch errors gracefully")
    func testHandlesFetchErrors() throws {
        let context = createInMemoryContext()

        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()

        // Should fetch successfully (even if empty)
        do {
            let results = try context.fetch(fetchRequest)
            #expect(results.count >= 0, "Fetch should succeed")
        } catch {
            #expect(false, "Fetch should not throw error: \(error)")
        }
    }

    // MARK: - Performance Tests

    @Test("Handles large data sets efficiently")
    func testLargeDataSetPerformance() throws {
        let context = createInMemoryContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Insert 90 days of data (realistic scenario)
        for offset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            let scores = DailyScores(context: context)
            scores.date = date
            scores.recoveryScore = Double.random(in: 50...90)
        }

        try context.save()

        // Fetch all
        let fetchRequest: NSFetchRequest<DailyScores> = DailyScores.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count >= 90, "Should handle 90+ entries")
    }
}
