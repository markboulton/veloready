import CoreData
import Foundation

/// Manages the Core Data stack for VeloReady
final class PersistenceController {
    // MARK: - Singleton
    
    static let shared = PersistenceController()
    
    // MARK: - Preview Support
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        let today = Calendar.current.startOfDay(for: Date())
        
        for dayOffset in 0..<7 {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Create physio data
            let physio = DailyPhysio(context: context)
            physio.date = date
            physio.hrv = Double.random(in: 45...75)
            physio.hrvBaseline = 60.0
            physio.rhr = Double.random(in: 48...58)
            physio.rhrBaseline = 52.0
            physio.sleepDuration = Double.random(in: 6...9) * 3600
            physio.sleepBaseline = 7.5 * 3600
            physio.lastUpdated = Date()
            
            // Create load data
            let load = DailyLoad(context: context)
            load.date = date
            load.ctl = Double.random(in: 55...75)
            load.atl = Double.random(in: 45...85)
            load.tsb = load.ctl - load.atl
            load.tss = dayOffset == 0 ? 0 : Double.random(in: 40...120)
            load.eftp = 280.0
            load.lastUpdated = Date()
            
            // Create scores
            let scores = DailyScores(context: context)
            scores.date = date
            scores.recoveryScore = Double.random(in: 50...85)
            scores.sleepScore = Double.random(in: 60...90)
            scores.strainScore = Double.random(in: 30...70)
            scores.effortTarget = Double.random(in: 40...80)
            scores.recoveryBand = scores.recoveryScore >= 70 ? "green" : scores.recoveryScore >= 40 ? "amber" : "red"
            scores.physio = physio
            scores.load = load
            scores.lastUpdated = Date()
        }
        
        try? context.save()
        return controller
    }()
    
    // MARK: - Properties
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Initialization
    
    private init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "VeloReady")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit sync
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description")
            }
            
            // Enable CloudKit sync
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.markboulton.VeloReady2"
            )
            
            // Configure persistent store options
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            Logger.debug("☁️ Core Data stack loaded with CloudKit sync enabled")
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Setup notifications for CloudKit sync
        setupCloudKitNotifications()
    }
    
    // MARK: - CloudKit Notifications
    
    private func setupCloudKitNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitImport(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container
        )
    }
    
    @objc private func handleCloudKitImport(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        if event.type == .import {
            Logger.debug("☁️ CloudKit import completed")
        } else if event.type == .export {
            Logger.debug("☁️ CloudKit export completed")
        }
        
        if let error = event.error {
            Logger.error("CloudKit sync error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Background Context
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save
    
    func save(context: NSManagedObjectContext? = nil) {
        let targetContext = context ?? viewContext
        
        guard targetContext.hasChanges else { return }
        
        do {
            try targetContext.save()
        } catch {
            Logger.error("Failed to save Core Data context: \(error)")
        }
    }
    
    // MARK: - Fetch
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>, context: NSManagedObjectContext? = nil) -> [T] {
        let targetContext = context ?? viewContext
        
        do {
            return try targetContext.fetch(request)
        } catch {
            Logger.error("Failed to fetch \(T.self): \(error)")
            return []
        }
    }
    
    // MARK: - Delete
    
    func delete(_ object: NSManagedObject, context: NSManagedObjectContext? = nil) {
        let targetContext = context ?? viewContext
        targetContext.delete(object)
        save(context: targetContext)
    }
    
    func deleteAll<T: NSManagedObject>(_ type: T.Type, context: NSManagedObjectContext? = nil) {
        let targetContext = context ?? viewContext
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type))
        
        do {
            let objects = try targetContext.fetch(fetchRequest)
            objects.forEach { targetContext.delete($0) }
            save(context: targetContext)
        } catch {
            Logger.error("Failed to delete all \(type): \(error)")
        }
    }
    
    // MARK: - Prune Old Data
    
    /// Remove data older than specified days
    func pruneOldData(olderThanDays days: Int = 90) {
        let context = newBackgroundContext()
        
        context.perform {
            guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return }
            
            // Prune DailyPhysio
            let physioRequest = NSFetchRequest<DailyPhysio>(entityName: "DailyPhysio")
            physioRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
            
            if let physioObjects = try? context.fetch(physioRequest) {
                physioObjects.forEach { context.delete($0) }
            }
            
            // Prune DailyLoad
            let loadRequest = NSFetchRequest<DailyLoad>(entityName: "DailyLoad")
            loadRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
            
            if let loadObjects = try? context.fetch(loadRequest) {
                loadObjects.forEach { context.delete($0) }
            }
            
            // Prune DailyScores
            let scoresRequest = NSFetchRequest<DailyScores>(entityName: "DailyScores")
            scoresRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
            
            if let scoresObjects = try? context.fetch(scoresRequest) {
                scoresObjects.forEach { context.delete($0) }
            }
            
            self.save(context: context)
            Logger.debug("🗑️ Pruned data older than \(days) days")
        }
    }
}
