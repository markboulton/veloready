import Foundation
import HealthKit
import CoreData

/// Service for managing workout metadata (RPE, muscle groups, etc.) with Core Data
/// Handles migration from legacy UserDefaults storage
class WorkoutMetadataService {
    static let shared = WorkoutMetadataService()
    
    private let persistenceController = PersistenceController.shared
    private let legacyRPEService = RPEStorageService.shared
    
    private var hasAttemptedMigration = false
    
    private init() {}
    
    // MARK: - Save/Update
    
    /// Save or update workout metadata
    func saveMetadata(
        for workout: HKWorkout,
        rpe: Double? = nil,
        muscleGroups: [MuscleGroup]? = nil,
        isEccentricFocused: Bool? = nil
    ) {
        let context = persistenceController.viewContext
        
        // Fetch existing or create new
        let metadata = self.fetchOrCreateMetadata(for: workout, in: context)
        
        // Update fields
        if let rpe = rpe {
            metadata.rpe = rpe
        }
        if let muscleGroups = muscleGroups {
            metadata.muscleGroupEnums = muscleGroups
            print("💪 Saving muscle groups: \(muscleGroups.map { $0.rawValue })")
        }
        if let isEccentricFocused = isEccentricFocused {
            metadata.isEccentricFocused = isEccentricFocused
        }
        
        metadata.updatedAt = Date()
        
        persistenceController.save(context: context)
        
        print("💪 Saved workout metadata for \(workout.uuid)")
        print("💪 RPE: \(metadata.rpe), Muscle Groups: \(metadata.muscleGroupStrings ?? [])")
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .workoutMetadataDidUpdate, object: nil, userInfo: ["workoutUUID": workout.uuid.uuidString])
    }
    
    // MARK: - Fetch
    
    /// Get RPE for a workout (with automatic migration from legacy storage)
    func getRPE(for workout: HKWorkout) -> Double? {
        // Try Core Data first
        if let metadata = fetchMetadata(for: workout) {
            return metadata.rpe > 0 ? metadata.rpe : nil
        }
        
        // Fallback to legacy UserDefaults
        if let legacyRPE = legacyRPEService.getRPE(for: workout) {
            // Migrate to Core Data
            migrateFromLegacy(workout: workout, rpe: legacyRPE)
            return legacyRPE
        }
        
        return nil
    }
    
    /// Get muscle groups for a workout
    func getMuscleGroups(for workout: HKWorkout) -> [MuscleGroup]? {
        print("🔍 getMuscleGroups for workout: \(workout.uuid)")
        
        // Try Core Data first
        if let metadata = fetchMetadata(for: workout) {
            let groups = metadata.muscleGroupEnums
            print("🔍 Found in Core Data: \(groups?.map { $0.rawValue } ?? [])")
            return groups
        }
        
        print("🔍 Not found in Core Data, checking legacy...")
        
        // Fallback to legacy
        if let legacyGroups = legacyRPEService.getMuscleGroups(for: workout) {
            print("🔍 Found in legacy: \(legacyGroups.map { $0.rawValue })")
            // Migrate to Core Data
            migrateFromLegacy(workout: workout, muscleGroups: legacyGroups)
            return legacyGroups
        }
        
        print("🔍 No muscle groups found anywhere")
        return nil
    }
    
    /// Check if workout has any metadata
    func hasMetadata(for workout: HKWorkout) -> Bool {
        return getRPE(for: workout) != nil || getMuscleGroups(for: workout) != nil
    }
    
    /// Fetch full metadata object
    func fetchMetadata(for workout: HKWorkout) -> WorkoutMetadata? {
        let fetchRequest = WorkoutMetadata.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutUUID == %@", workout.uuid.uuidString)
        fetchRequest.fetchLimit = 1
        
        print("🔎 Fetching metadata for UUID: \(workout.uuid.uuidString)")
        let results = persistenceController.fetch(fetchRequest)
        
        if let metadata = results.first {
            print("🔎 Found metadata - RPE: \(metadata.rpe), Muscle Groups: \(metadata.muscleGroupStrings ?? [])")
        } else {
            print("🔎 No metadata found in Core Data")
        }
        
        return results.first
    }
    
    // MARK: - Query/Analytics
    
    /// Get all workout metadata within a date range
    func fetchMetadata(from startDate: Date, to endDate: Date) -> [WorkoutMetadata] {
        let fetchRequest = WorkoutMetadata.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutDate >= %@ AND workoutDate <= %@", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "workoutDate", ascending: false)]
        
        return persistenceController.fetch(fetchRequest)
    }
    
    /// Get workout count by muscle group
    func getWorkoutCountByMuscleGroup(from startDate: Date, to endDate: Date) -> [MuscleGroup: Int] {
        let metadata = fetchMetadata(from: startDate, to: endDate)
        var counts: [MuscleGroup: Int] = [:]
        
        for item in metadata {
            if let groups = item.muscleGroupEnums {
                for group in groups {
                    counts[group, default: 0] += 1
                }
            }
        }
        
        return counts
    }
    
    /// Get average RPE by muscle group
    func getAverageRPEByMuscleGroup(from startDate: Date, to endDate: Date) -> [MuscleGroup: Double] {
        let metadata = fetchMetadata(from: startDate, to: endDate)
        var totals: [MuscleGroup: (sum: Double, count: Int)] = [:]
        
        for item in metadata where item.rpe > 0 {
            if let groups = item.muscleGroupEnums {
                for group in groups {
                    let current = totals[group] ?? (0, 0)
                    totals[group] = (current.sum + item.rpe, current.count + 1)
                }
            }
        }
        
        return totals.mapValues { $0.sum / Double($0.count) }
    }
    
    /// Get training volume (workout count) over time
    func getTrainingVolume(days: Int = 30) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
        
        let metadata = fetchMetadata(from: startDate, to: endDate)
        
        // Group by date
        var volumeByDate: [Date: Int] = [:]
        for item in metadata {
            let day = calendar.startOfDay(for: item.workoutDate)
            volumeByDate[day, default: 0] += 1
        }
        
        // Fill in missing days with 0
        var result: [(Date, Int)] = []
        var currentDate = startDate
        while currentDate <= endDate {
            result.append((currentDate, volumeByDate[currentDate] ?? 0))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return result
    }
    
    // MARK: - Export
    
    /// Export all workout metadata as JSON
    func exportToJSON() -> Data? {
        let fetchRequest = WorkoutMetadata.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "workoutDate", ascending: false)]
        
        let metadata = persistenceController.fetch(fetchRequest)
        
        let exportData = metadata.map { item in
            [
                "workoutUUID": item.workoutUUID,
                "workoutDate": ISO8601DateFormatter().string(from: item.workoutDate),
                "rpe": item.rpe,
                "muscleGroups": item.muscleGroupStrings ?? [],
                "isEccentricFocused": item.isEccentricFocused,
                "createdAt": ISO8601DateFormatter().string(from: item.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: item.updatedAt)
            ] as [String : Any]
        }
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("❌ Failed to export workout metadata: \(error)")
            return nil
        }
    }
    
    /// Export as CSV
    func exportToCSV() -> String {
        let fetchRequest = WorkoutMetadata.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "workoutDate", ascending: false)]
        
        let metadata = persistenceController.fetch(fetchRequest)
        let dateFormatter = ISO8601DateFormatter()
        
        var csv = "Workout UUID,Date,RPE,Muscle Groups,Eccentric Focused,Created At,Updated At\n"
        
        for item in metadata {
            let muscleGroupsStr = item.muscleGroupStrings?.joined(separator: "; ") ?? ""
            csv += "\"\(item.workoutUUID)\","
            csv += "\"\(dateFormatter.string(from: item.workoutDate))\","
            csv += "\(item.rpe),"
            csv += "\"\(muscleGroupsStr)\","
            csv += "\(item.isEccentricFocused),"
            csv += "\"\(dateFormatter.string(from: item.createdAt))\","
            csv += "\"\(dateFormatter.string(from: item.updatedAt))\"\n"
        }
        
        return csv
    }
    
    // MARK: - Migration
    
    /// Migrate all legacy UserDefaults data to Core Data
    func migrateAllLegacyData() {
        guard !hasAttemptedMigration else { return }
        hasAttemptedMigration = true
        
        print("🔄 Starting migration of legacy workout metadata...")
        
        // This is a one-time migration - scan UserDefaults for all workout metadata
        // Since UserDefaults keys are based on UUIDs, we can't easily enumerate them
        // Migration will happen lazily as workouts are accessed
        
        print("✅ Legacy migration configured (will migrate on-demand)")
    }
    
    /// Migrate a single workout from legacy storage
    private func migrateFromLegacy(workout: HKWorkout, rpe: Double? = nil, muscleGroups: [MuscleGroup]? = nil) {
        print("🔄 Migrating workout \(workout.uuid) from legacy storage...")
        
        let legacyRPE = rpe ?? legacyRPEService.getRPE(for: workout)
        let legacyGroups = muscleGroups ?? legacyRPEService.getMuscleGroups(for: workout)
        
        if legacyRPE != nil || legacyGroups != nil {
            saveMetadata(for: workout, rpe: legacyRPE, muscleGroups: legacyGroups)
            print("✅ Migrated workout \(workout.uuid)")
        }
    }
    
    // MARK: - Delete
    
    /// Delete metadata for a workout
    func deleteMetadata(for workout: HKWorkout) {
        guard let metadata = fetchMetadata(for: workout) else { return }
        persistenceController.delete(metadata)
        
        // Also delete from legacy storage
        legacyRPEService.deleteRPE(for: workout)
        
        print("🗑️ Deleted metadata for workout \(workout.uuid)")
    }
    
    /// Prune old workout metadata
    func pruneOldMetadata(olderThanDays days: Int = 730) {
        let context = persistenceController.newBackgroundContext()
        
        context.perform {
            guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return }
            
            let fetchRequest = WorkoutMetadata.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "workoutDate < %@", cutoffDate as NSDate)
            
            if let metadata = try? context.fetch(fetchRequest) {
                metadata.forEach { context.delete($0) }
                self.persistenceController.save(context: context)
                print("🗑️ Pruned \(metadata.count) workout metadata entries older than \(days) days")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func fetchOrCreateMetadata(for workout: HKWorkout, in context: NSManagedObjectContext) -> WorkoutMetadata {
        let fetchRequest = WorkoutMetadata.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutUUID == %@", workout.uuid.uuidString)
        fetchRequest.fetchLimit = 1
        
        if let existing = try? context.fetch(fetchRequest).first {
            return existing
        }
        
        // Create new
        let metadata = WorkoutMetadata(context: context)
        metadata.workoutUUID = workout.uuid.uuidString
        metadata.workoutDate = workout.startDate
        metadata.createdAt = Date()
        metadata.updatedAt = Date()
        
        return metadata
    }
}

// MARK: - Notification

extension Notification.Name {
    static let workoutMetadataDidUpdate = Notification.Name("workoutMetadataDidUpdate")
}
