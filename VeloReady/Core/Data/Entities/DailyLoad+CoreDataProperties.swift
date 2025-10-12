import Foundation
import CoreData

extension DailyLoad {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyLoad> {
        return NSFetchRequest<DailyLoad>(entityName: "DailyLoad")
    }
    
    @NSManaged public var date: Date
    @NSManaged public var ctl: Double
    @NSManaged public var atl: Double
    @NSManaged public var tsb: Double
    @NSManaged public var tss: Double
    @NSManaged public var eftp: Double
    @NSManaged public var workoutId: String?
    @NSManaged public var workoutName: String?
    @NSManaged public var workoutType: String?
    @NSManaged public var lastUpdated: Date
    @NSManaged public var scores: DailyScores?
    
}

extension DailyLoad : Identifiable {
    
}
