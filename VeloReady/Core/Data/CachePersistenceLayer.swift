import Foundation
import CoreData

/// Actor-based cache persistence layer that bridges memory cache to Core Data
/// Provides thread-safe, persistent storage for cache entries across app restarts
actor CachePersistenceLayer {
    static let shared = CachePersistenceLayer()
    
    private let persistenceController = PersistenceController.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Statistics
    private var saveCount = 0
    private var loadCount = 0
    private var hitCount = 0
    private var missCount = 0
    
    private init() {
        Logger.debug("💾 [CachePersistence] Initialized")
    }
    
    // MARK: - Public Methods
    
    /// Save a cache entry to Core Data
    /// - Parameters:
    ///   - key: Cache key (e.g., "strava:activities:365")
    ///   - value: Value to cache (must be Codable)
    ///   - cachedAt: Timestamp when cached
    ///   - ttl: Time-to-live in seconds
    func saveToCoreData<T: Codable>(key: String, value: T, cachedAt: Date = Date(), ttl: TimeInterval) async {
        let context = persistenceController.newBackgroundContext()
        
        await context.perform {
            do {
                // Check if entry already exists
                let fetchRequest: NSFetchRequest<CacheEntry> = CacheEntry.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "key == %@", key)
                fetchRequest.fetchLimit = 1
                
                let existingEntries = try context.fetch(fetchRequest)
                let entry = existingEntries.first ?? CacheEntry(context: context)
                
                // Encode value to JSON Data
                let valueData = try self.encoder.encode(value)
                
                // Update entry
                entry.key = key
                entry.valueData = valueData
                entry.cachedAt = cachedAt
                entry.expiresAt = cachedAt.addingTimeInterval(ttl)
                
                // Save context
                try context.save()
                
                self.saveCount += 1
                Logger.debug("💾 [CachePersistence] Saved \(key) (\(valueData.count / 1024)KB, expires: \(Int(ttl/60))min)")
            } catch {
                Logger.error("💾 [CachePersistence] Failed to save \(key): \(error.localizedDescription)")
            }
        }
    }
    
    /// Load a cache entry from Core Data
    /// - Parameters:
    ///   - key: Cache key to load
    /// - Returns: Decoded value if found and not expired, nil otherwise
    func loadFromCoreData<T: Codable>(key: String, as type: T.Type) async -> (value: T, cachedAt: Date)? {
        let context = persistenceController.newBackgroundContext()
        
        return await context.perform {
            do {
                // Fetch entry
                let fetchRequest: NSFetchRequest<CacheEntry> = CacheEntry.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "key == %@", key)
                fetchRequest.fetchLimit = 1
                
                guard let entry = try context.fetch(fetchRequest).first,
                      let valueData = entry.valueData,
                      let cachedAt = entry.cachedAt else {
                    self.missCount += 1
                    Logger.debug("💾 [CachePersistence] MISS \(key)")
                    return nil
                }
                
                // Check expiration
                if let expiresAt = entry.expiresAt, expiresAt < Date() {
                    // Expired - delete it
                    context.delete(entry)
                    try? context.save()
                    
                    self.missCount += 1
                    Logger.debug("💾 [CachePersistence] MISS \(key) (expired)")
                    return nil
                }
                
                // Decode value
                let value = try self.decoder.decode(T.self, from: valueData)
                
                self.loadCount += 1
                self.hitCount += 1
                let age = Date().timeIntervalSince(cachedAt)
                Logger.debug("💾 [CachePersistence] HIT \(key) (age: \(Int(age))s, \(valueData.count / 1024)KB)")
                
                return (value: value, cachedAt: cachedAt)
            } catch {
                self.missCount += 1
                Logger.error("💾 [CachePersistence] Failed to load \(key): \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    /// Delete a cache entry from Core Data
    /// - Parameter key: Cache key to delete
    func deleteFromCoreData(key: String) async {
        let context = persistenceController.newBackgroundContext()
        
        await context.perform {
            do {
                let fetchRequest: NSFetchRequest<CacheEntry> = CacheEntry.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "key == %@", key)
                
                let entries = try context.fetch(fetchRequest)
                for entry in entries {
                    context.delete(entry)
                }
                
                if !entries.isEmpty {
                    try context.save()
                    Logger.debug("💾 [CachePersistence] Deleted \(key)")
                }
            } catch {
                Logger.error("💾 [CachePersistence] Failed to delete \(key): \(error.localizedDescription)")
            }
        }
    }
    
    /// Clear all expired cache entries
    func clearExpiredEntries() async {
        let context = persistenceController.newBackgroundContext()
        
        await context.perform {
            do {
                let fetchRequest: NSFetchRequest<CacheEntry> = CacheEntry.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "expiresAt < %@", Date() as NSDate)
                
                let expiredEntries = try context.fetch(fetchRequest)
                for entry in expiredEntries {
                    context.delete(entry)
                }
                
                if !expiredEntries.isEmpty {
                    try context.save()
                    Logger.debug("💾 [CachePersistence] Cleared \(expiredEntries.count) expired entries")
                }
            } catch {
                Logger.error("💾 [CachePersistence] Failed to clear expired entries: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clear all cache entries
    func clearAll() async {
        let context = persistenceController.newBackgroundContext()
        
        await context.perform {
            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CacheEntry.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                try context.execute(deleteRequest)
                try context.save()
                
                self.saveCount = 0
                self.loadCount = 0
                self.hitCount = 0
                self.missCount = 0
                
                Logger.debug("💾 [CachePersistence] Cleared all entries")
            } catch {
                Logger.error("💾 [CachePersistence] Failed to clear all entries: \(error.localizedDescription)")
            }
        }
    }
    
    /// Get cache statistics
    func getStatistics() async -> (saves: Int, loads: Int, hits: Int, misses: Int, hitRate: Double) {
        let total = hitCount + missCount
        let hitRate = total > 0 ? Double(hitCount) / Double(total) : 0.0
        return (saveCount, loadCount, hitCount, missCount, hitRate)
    }
    
    /// Get count of cached entries
    func getCachedEntriesCount() async -> Int {
        let context = persistenceController.newBackgroundContext()
        
        return await context.perform {
            do {
                let fetchRequest: NSFetchRequest<CacheEntry> = CacheEntry.fetchRequest()
                return try context.count(for: fetchRequest)
            } catch {
                Logger.error("💾 [CachePersistence] Failed to count entries: \(error.localizedDescription)")
                return 0
            }
        }
    }
}
