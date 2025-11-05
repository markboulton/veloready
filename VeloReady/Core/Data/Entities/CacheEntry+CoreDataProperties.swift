import Foundation
import CoreData

extension CacheEntry {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheEntry> {
        return NSFetchRequest<CacheEntry>(entityName: "CacheEntry")
    }
    
    @NSManaged public var key: String?
    @NSManaged public var valueData: Data?
    @NSManaged public var cachedAt: Date?
    @NSManaged public var expiresAt: Date?
    
}

extension CacheEntry : Identifiable {
    
}
