import Foundation
import HealthKit

/// Service for storing and retrieving RPE (Rate of Perceived Exertion) and muscle groups for workouts
class RPEStorageService {
    static let shared = RPEStorageService()
    
    private let userDefaults = UserDefaults.standard
    private let rpePrefix = "rpe_"
    private let muscleGroupsPrefix = "muscle_groups_"
    
    private init() {}
    
    // MARK: - Storage
    
    /// Save RPE and optional muscle groups for a workout
    func saveRPE(_ rpe: Double, muscleGroups: [MuscleGroup]? = nil, for workout: HKWorkout) {
        let rpeKey = rpeKey(for: workout)
        userDefaults.set(rpe, forKey: rpeKey)
        
        // Save muscle groups if provided
        if let muscleGroups = muscleGroups, !muscleGroups.isEmpty {
            let muscleGroupStrings = muscleGroups.map { $0.rawValue }
            let muscleKey = muscleGroupsKey(for: workout)
            userDefaults.set(muscleGroupStrings, forKey: muscleKey)
            Logger.debug("💪 Saved RPE \(rpe) with muscle groups \(muscleGroupStrings) for workout: \(workout.uuid)")
        } else {
            Logger.debug("💪 Saved RPE \(rpe) for workout: \(workout.uuid)")
        }
        
        // Post notification that RPE was updated
        NotificationCenter.default.post(name: .rpeDidUpdate, object: nil, userInfo: ["workoutUUID": workout.uuid.uuidString])
    }
    
    /// Get RPE for a workout
    func getRPE(for workout: HKWorkout) -> Double? {
        let key = rpeKey(for: workout)
        let value = userDefaults.double(forKey: key)
        
        // UserDefaults returns 0.0 if key doesn't exist
        guard value > 0 else { return nil }
        
        return value
    }
    
    /// Check if workout has RPE set
    func hasRPE(for workout: HKWorkout) -> Bool {
        return getRPE(for: workout) != nil
    }
    
    /// Get muscle groups for a workout
    func getMuscleGroups(for workout: HKWorkout) -> [MuscleGroup]? {
        let key = muscleGroupsKey(for: workout)
        guard let muscleGroupStrings = userDefaults.stringArray(forKey: key) else {
            return nil
        }
        
        return muscleGroupStrings.compactMap { MuscleGroup(rawValue: $0) }
    }
    
    /// Delete RPE and muscle groups for a workout
    func deleteRPE(for workout: HKWorkout) {
        let rpeKey = rpeKey(for: workout)
        let muscleKey = muscleGroupsKey(for: workout)
        userDefaults.removeObject(forKey: rpeKey)
        userDefaults.removeObject(forKey: muscleKey)
    }
    
    // MARK: - Helpers
    
    private func rpeKey(for workout: HKWorkout) -> String {
        return "\(rpePrefix)\(workout.uuid.uuidString)"
    }
    
    private func muscleGroupsKey(for workout: HKWorkout) -> String {
        return "\(muscleGroupsPrefix)\(workout.uuid.uuidString)"
    }
}

// MARK: - Notification

extension Notification.Name {
    static let rpeDidUpdate = Notification.Name("rpeDidUpdate")
}
