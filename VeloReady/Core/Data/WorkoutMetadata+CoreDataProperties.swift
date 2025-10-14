import Foundation
import CoreData

extension WorkoutMetadata {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutMetadata> {
        return NSFetchRequest<WorkoutMetadata>(entityName: "WorkoutMetadata")
    }
    
    @NSManaged public var workoutUUID: String
    @NSManaged public var workoutDate: Date
    @NSManaged public var rpe: Double
    @NSManaged public var muscleGroups: [String]?
    @NSManaged public var isEccentricFocused: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    /// Computed property to convert string array to MuscleGroup array
    var muscleGroupEnums: [MuscleGroup]? {
        get {
            muscleGroups?.compactMap { MuscleGroup(rawValue: $0) }
        }
        set {
            muscleGroups = newValue?.map { $0.rawValue }
        }
    }
}

extension WorkoutMetadata: Identifiable {
    
}
