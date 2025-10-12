import Foundation
import CoreData

extension DailyScores {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyScores> {
        return NSFetchRequest<DailyScores>(entityName: "DailyScores")
    }
    
    @NSManaged public var date: Date
    @NSManaged public var recoveryScore: Double
    @NSManaged public var recoveryBand: String?
    @NSManaged public var sleepScore: Double
    @NSManaged public var strainScore: Double
    @NSManaged public var effortTarget: Double
    @NSManaged public var lastUpdated: Date
    @NSManaged public var aiBriefText: String?
    @NSManaged public var physio: DailyPhysio?
    @NSManaged public var load: DailyLoad?
    
}

extension DailyScores : Identifiable {
    
}
