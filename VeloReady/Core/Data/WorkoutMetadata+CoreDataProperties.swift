import Foundation
import CoreData

extension WorkoutMetadata {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutMetadata> {
        return NSFetchRequest<WorkoutMetadata>(entityName: "WorkoutMetadata")
    }
    
    @NSManaged public var workoutUUID: String?
    @NSManaged public var workoutDate: Date?
    @NSManaged public var rpe: Double
    @NSManaged private var muscleGroups: NSObject?
    @NSManaged public var isEccentricFocused: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    /// Computed property to convert string array to MuscleGroup array
    var muscleGroupEnums: [MuscleGroup]? {
        get {
            guard let data = muscleGroups as? [String] else { return nil }
            return data.compactMap { MuscleGroup(rawValue: $0) }
        }
        set {
            if let groups = newValue {
                muscleGroups = groups.map { $0.rawValue } as NSObject
            } else {
                muscleGroups = nil
            }
        }
    }
    
    /// Helper to get raw string array
    var muscleGroupStrings: [String]? {
        return muscleGroups as? [String]
    }
}

extension WorkoutMetadata: Identifiable {
    
}
