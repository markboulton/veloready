import Foundation
import HealthKit

/// Service for storing and retrieving RPE (Rate of Perceived Exertion) values for workouts
class RPEStorageService {
    static let shared = RPEStorageService()
    
    private let userDefaults = UserDefaults.standard
    private let rpePrefix = "rpe_"
    
    private init() {}
    
    // MARK: - Storage
    
    /// Save RPE for a workout
    func saveRPE(_ rpe: Double, for workout: HKWorkout) {
        let key = rpeKey(for: workout)
        userDefaults.set(rpe, forKey: key)
        
        print("💪 Saved RPE \(rpe) for workout: \(workout.uuid)")
        
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
    
    /// Delete RPE for a workout
    func deleteRPE(for workout: HKWorkout) {
        let key = rpeKey(for: workout)
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Helpers
    
    private func rpeKey(for workout: HKWorkout) -> String {
        return "\(rpePrefix)\(workout.uuid.uuidString)"
    }
}

// MARK: - Notification

extension Notification.Name {
    static let rpeDidUpdate = Notification.Name("rpeDidUpdate")
}
