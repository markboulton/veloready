import Foundation
import CoreData

extension DailyPhysio {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyPhysio> {
        return NSFetchRequest<DailyPhysio>(entityName: "DailyPhysio")
    }
    
    @NSManaged public var date: Date
    @NSManaged public var hrv: Double
    @NSManaged public var hrvBaseline: Double
    @NSManaged public var rhr: Double
    @NSManaged public var rhrBaseline: Double
    @NSManaged public var sleepDuration: Double
    @NSManaged public var sleepBaseline: Double
    @NSManaged public var lastUpdated: Date
    @NSManaged public var scores: DailyScores?
    
}

extension DailyPhysio : Identifiable {
    
}
