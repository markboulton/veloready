import Foundation
import CoreData
@testable import VeloReady

/// Helper utilities for Core Data testing
class CoreDataTestHelper {
    
    // MARK: - In-Memory Container
    
    /// Creates an in-memory Core Data container for testing
    /// - Returns: NSPersistentContainer configured for in-memory storage
    static func createInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "VeloReady")
        
        // Use in-memory store for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }
    
    // MARK: - Data Management
    
    /// Clears all data from the test container
    /// - Parameter context: The managed object context to clear
    static func clearAllData(context: NSManagedObjectContext) {
        let entities = ["DailyScores", "DailyPhysio", "DailyLoad", "MLTrainingData"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Failed to clear \(entityName): \(error)")
            }
        }
    }
    
    /// Seeds test data for a specified number of days
    /// - Parameters:
    ///   - context: The managed object context
    ///   - days: Number of days of historical data to create
    ///   - endDate: The end date for the historical data (defaults to today)
    static func seedTestData(
        context: NSManagedObjectContext,
        days: Int = 7,
        endDate: Date = Date()
    ) {
        let calendar = Calendar.current
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            // Create DailyScores
            let scores = DailyScores(context: context)
            scores.date = startOfDay
            scores.recoveryScore = Double.random(in: 60...90)
            scores.sleepScore = Double.random(in: 60...90)
            scores.strainScore = Double.random(in: 50...80)
            
            // Create DailyPhysio
            let physio = DailyPhysio(context: context)
            physio.date = startOfDay
            physio.hrv = Double.random(in: 35...55)
            physio.hrvBaseline = 44.0
            physio.rhr = Double.random(in: 55...65)
            physio.rhrBaseline = 60.0
            physio.sleepDuration = Double.random(in: 6.5...8.5)
            physio.sleepBaseline = 7.0
            
            // Create DailyLoad
            let load = DailyLoad(context: context)
            load.date = startOfDay
            load.ctl = Double.random(in: 70...100)
            load.atl = Double.random(in: 60...90)
            load.tsb = Double.random(in: -20...20)
            load.tss = Double.random(in: 0...150)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to seed test data: \(error)")
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Counts records for a specific entity
    /// - Parameters:
    ///   - entityName: Name of the entity to count
    ///   - context: The managed object context
    /// - Returns: Number of records
    static func countRecords(
        entityName: String,
        context: NSManagedObjectContext
    ) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("Failed to count \(entityName): \(error)")
            return 0
        }
    }
    
    /// Fetches all records for a specific entity
    /// - Parameters:
    ///   - entityName: Name of the entity to fetch
    ///   - context: The managed object context
    /// - Returns: Array of managed objects
    static func fetchAll<T: NSManagedObject>(
        entityName: String,
        context: NSManagedObjectContext
    ) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch \(entityName): \(error)")
            return []
        }
    }
    
    /// Validates that a value is nil (not zero)
    /// - Parameter value: The value to check
    /// - Returns: True if the value is truly nil, false if it's zero
    static func isNil(_ value: Double) -> Bool {
        return value == 0.0
    }
    
    /// Validates that a value is zero (not nil)
    /// - Parameter value: The value to check
    /// - Returns: True if the value is zero, false otherwise
    static func isZero(_ value: Double) -> Bool {
        return value == 0.0
    }
}
