import Foundation
import CoreData
import Combine

/// Service for managing iCloud synchronization of user data, settings, and workout metadata
@MainActor
class iCloudSyncService: ObservableObject {
    static let shared = iCloudSyncService()
    
    // MARK: - Published Properties
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isCloudAvailable = false
    
    // MARK: - Private Properties
    
    private let ubiquityIdentityToken: (NSCoding & NSCopying & NSObjectProtocol)?
    private var cancellables = Set<AnyCancellable>()
    private var lastSyncTime: Date = Date.distantPast
    private let syncDebounceInterval: TimeInterval = 300  // 5 minutes minimum between syncs
    
    // MARK: - Keys
    
    private enum CloudKeys {
        static let userSettings = "userSettings"
        static let rpeData = "rpeData"
        static let muscleGroupData = "muscleGroupData"
        static let lastSyncDate = "lastSyncDate"
        static let workoutMetadataSync = "workoutMetadataSync"
        static let todaySectionOrder = "todaySectionOrder"
    }
    
    // MARK: - Initialization
    
    private init() {
        // Check if iCloud is available
        ubiquityIdentityToken = FileManager.default.ubiquityIdentityToken
        isCloudAvailable = ubiquityIdentityToken != nil
        
        if isCloudAvailable {
            Logger.debug("☁️ iCloud is available for sync")
            loadLastSyncDate()
            setupCloudNotifications()
        } else {
            Logger.warning("️ iCloud is not available")
        }
    }
    
    // MARK: - Setup
    
    private func setupCloudNotifications() {
        // Listen for iCloud changes
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.handleCloudChange(notification)
                }
            }
            .store(in: &cancellables)
        
        // Start observing changes
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func handleCloudChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        // Handle different change reasons
        switch changeReason {
        case NSUbiquitousKeyValueStoreServerChange, NSUbiquitousKeyValueStoreInitialSyncChange:
            Logger.debug("☁️ iCloud data changed externally, syncing...")
            Task {
                await syncFromCloud()
            }
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            syncError = "iCloud storage quota exceeded"
        case NSUbiquitousKeyValueStoreAccountChange:
            Logger.debug("☁️ iCloud account changed")
            isCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        default:
            break
        }
    }
    
    // MARK: - Sync Operations
    
    /// Sync all data to iCloud (debounced to prevent excessive syncs)
    func syncToCloud() async {
        guard isCloudAvailable else {
            syncError = "iCloud is not available"
            return
        }
        
        // Debounce: skip if synced within last 5 minutes
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
        if timeSinceLastSync < syncDebounceInterval {
            let remainingWait = Int(syncDebounceInterval - timeSinceLastSync)
            Logger.debug("☁️ [iCloud] Sync skipped - last sync was \(Int(timeSinceLastSync))s ago (wait \(remainingWait)s)")
            return
        }
        
        isSyncing = true
        syncError = nil
        lastSyncTime = Date()
        
        do {
            // Sync UserDefaults data to iCloud
            try await syncUserDefaultsToCloud()
            
            // Sync Core Data metadata
            try await syncCoreDataMetadataToCloud()
            
            // Trigger CloudKit backup (Core Data sync)
            let persistence = PersistenceController.shared
            try await persistence.backupToCloudKit()
            
            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()
            
            Logger.debug("☁️ Successfully synced to iCloud")
        } catch {
            syncError = "Failed to sync to iCloud: \(error.localizedDescription)"
            Logger.error("iCloud sync error: \(error)")
        }
        
        isSyncing = false
    }
    
    /// Sync data from iCloud to local storage
    func syncFromCloud() async {
        guard isCloudAvailable else {
            syncError = "iCloud is not available"
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Force synchronize with iCloud
            NSUbiquitousKeyValueStore.default.synchronize()
            
            // Restore UserDefaults data
            try await restoreUserDefaultsFromCloud()
            
            // Restore Core Data metadata
            try await restoreCoreDataMetadataFromCloud()
            
            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()
            
            Logger.debug("☁️ Successfully restored from iCloud")
        } catch {
            syncError = "Failed to restore from iCloud: \(error.localizedDescription)"
            Logger.error("iCloud restore error: \(error)")
        }
        
        isSyncing = false
    }
    
    /// Manually trigger a restore from iCloud
    func restoreFromCloud() async throws -> Int {
        guard isCloudAvailable else {
            throw iCloudError.notAvailable
        }
        
        isSyncing = true
        syncError = nil
        
        // Restore UserDefaults and workout metadata
        await syncFromCloud()
        
        // Restore Core Data (DailyScores, DailyPhysio, DailyLoad) from CloudKit
        let persistence = PersistenceController.shared
        let recordCount = try await persistence.restoreFromCloudKit()
        
        isSyncing = false
        
        return recordCount
    }
    
    // MARK: - UserDefaults Sync
    
    private func syncUserDefaultsToCloud() async throws {
        let cloudStore = NSUbiquitousKeyValueStore.default
        let localDefaults = UserDefaults.standard
        
        // Sync user settings
        if let settingsData = localDefaults.data(forKey: "UserSettings") {
            cloudStore.set(settingsData, forKey: CloudKeys.userSettings)
        }
        
        // Sync RPE data
        let rpeDict = collectRPEData()
        if let rpeData = try? JSONEncoder().encode(rpeDict) {
            cloudStore.set(rpeData, forKey: CloudKeys.rpeData)
        }
        
        // Sync muscle group data
        let muscleGroupDict = collectMuscleGroupData()
        if let muscleGroupData = try? JSONEncoder().encode(muscleGroupDict) {
            cloudStore.set(muscleGroupData, forKey: CloudKeys.muscleGroupData)
        }
        
        // Synchronize with iCloud
        cloudStore.synchronize()
    }
    
    private func restoreUserDefaultsFromCloud() async throws {
        let cloudStore = NSUbiquitousKeyValueStore.default
        let localDefaults = UserDefaults.standard
        
        // Restore user settings
        if let settingsData = cloudStore.data(forKey: CloudKeys.userSettings) {
            localDefaults.set(settingsData, forKey: "UserSettings")
            
            // Reload settings in UserSettings singleton
            await MainActor.run {
                // Trigger settings reload by posting notification
                NotificationCenter.default.post(name: .userSettingsDidRestore, object: nil)
            }
        }
        
        // Restore RPE data
        if let rpeData = cloudStore.data(forKey: CloudKeys.rpeData),
           let rpeDict = try? JSONDecoder().decode([String: Double].self, from: rpeData) {
            restoreRPEData(rpeDict)
        }
        
        // Restore muscle group data
        if let muscleGroupData = cloudStore.data(forKey: CloudKeys.muscleGroupData),
           let muscleGroupDict = try? JSONDecoder().decode([String: [String]].self, from: muscleGroupData) {
            restoreMuscleGroupData(muscleGroupDict)
        }
    }
    
    // MARK: - RPE Data Collection
    
    private func collectRPEData() -> [String: Double] {
        let defaults = UserDefaults.standard
        var rpeData: [String: Double] = [:]
        
        // Collect all RPE entries (keys starting with "rpe_")
        for (key, value) in defaults.dictionaryRepresentation() {
            if key.hasPrefix("rpe_"), let rpeValue = value as? Double {
                rpeData[key] = rpeValue
            }
        }
        
        return rpeData
    }
    
    private func restoreRPEData(_ data: [String: Double]) {
        let defaults = UserDefaults.standard
        
        for (key, value) in data {
            defaults.set(value, forKey: key)
        }
        
        Logger.debug("☁️ Restored \(data.count) RPE entries from iCloud")
    }
    
    // MARK: - Muscle Group Data Collection
    
    private func collectMuscleGroupData() -> [String: [String]] {
        let defaults = UserDefaults.standard
        var muscleGroupData: [String: [String]] = [:]
        
        // Collect all muscle group entries (keys starting with "muscle_groups_")
        for (key, value) in defaults.dictionaryRepresentation() {
            if key.hasPrefix("muscle_groups_"), let groups = value as? [String] {
                muscleGroupData[key] = groups
            }
        }
        
        return muscleGroupData
    }
    
    private func restoreMuscleGroupData(_ data: [String: [String]]) {
        let defaults = UserDefaults.standard
        
        for (key, value) in data {
            defaults.set(value, forKey: key)
        }
        
        Logger.debug("☁️ Restored \(data.count) muscle group entries from iCloud")
    }
    
    // MARK: - Core Data Metadata Sync
    
    private func syncCoreDataMetadataToCloud() async throws {
        let context = PersistenceController.shared.viewContext
        
        try await context.perform {
            let fetchRequest = WorkoutMetadata.fetchRequest()
            
            do {
                let metadata = try context.fetch(fetchRequest)
                
                // Convert to dictionary for iCloud storage
                var metadataDict: [[String: Any]] = []
                
                for item in metadata {
                    guard let workoutUUID = item.workoutUUID,
                          let workoutDate = item.workoutDate,
                          let createdAt = item.createdAt,
                          let updatedAt = item.updatedAt else {
                        continue
                    }
                    
                    var dict: [String: Any] = [
                        "workoutUUID": workoutUUID,
                        "workoutDate": workoutDate.timeIntervalSince1970,
                        "rpe": item.rpe,
                        "isEccentricFocused": item.isEccentricFocused,
                        "createdAt": createdAt.timeIntervalSince1970,
                        "updatedAt": updatedAt.timeIntervalSince1970
                    ]
                    
                    if let muscleGroups = item.muscleGroupStrings {
                        dict["muscleGroups"] = muscleGroups
                    }
                    
                    metadataDict.append(dict)
                }
                
                // Store in iCloud
                if let data = try? JSONSerialization.data(withJSONObject: metadataDict) {
                    NSUbiquitousKeyValueStore.default.set(data, forKey: CloudKeys.workoutMetadataSync)
                }
                
                Logger.debug("☁️ Synced \(metadata.count) workout metadata entries to iCloud")
            } catch {
                Logger.error("Failed to sync Core Data metadata: \(error)")
                throw error
            }
        }
    }
    
    private func restoreCoreDataMetadataFromCloud() async throws {
        let cloudStore = NSUbiquitousKeyValueStore.default
        
        guard let data = cloudStore.data(forKey: CloudKeys.workoutMetadataSync),
              let metadataArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            Logger.debug("☁️ No workout metadata found in iCloud")
            return
        }
        
        let context = PersistenceController.shared.newBackgroundContext()
        
        try await context.perform {
            for dict in metadataArray {
                guard let workoutUUID = dict["workoutUUID"] as? String,
                      let workoutDateInterval = dict["workoutDate"] as? TimeInterval,
                      let rpe = dict["rpe"] as? Double,
                      let isEccentricFocused = dict["isEccentricFocused"] as? Bool,
                      let createdAtInterval = dict["createdAt"] as? TimeInterval,
                      let updatedAtInterval = dict["updatedAt"] as? TimeInterval else {
                    continue
                }
                
                // Check if metadata already exists
                let fetchRequest = WorkoutMetadata.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "workoutUUID == %@", workoutUUID)
                
                let existingMetadata = try? context.fetch(fetchRequest).first
                let metadata = existingMetadata ?? WorkoutMetadata(context: context)
                
                metadata.workoutUUID = workoutUUID
                metadata.workoutDate = Date(timeIntervalSince1970: workoutDateInterval)
                metadata.rpe = rpe
                metadata.isEccentricFocused = isEccentricFocused
                metadata.createdAt = Date(timeIntervalSince1970: createdAtInterval)
                metadata.updatedAt = Date(timeIntervalSince1970: updatedAtInterval)
                
                if let muscleGroups = dict["muscleGroups"] as? [String] {
                    metadata.muscleGroupEnums = muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
                }
            }
            
            try context.save()
            Logger.debug("☁️ Restored \(metadataArray.count) workout metadata entries from iCloud")
        }
    }
    
    // MARK: - Last Sync Date
    
    private func loadLastSyncDate() {
        if let timestamp = NSUbiquitousKeyValueStore.default.object(forKey: CloudKeys.lastSyncDate) as? TimeInterval {
            lastSyncDate = Date(timeIntervalSince1970: timestamp)
        }
    }
    
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            NSUbiquitousKeyValueStore.default.set(date.timeIntervalSince1970, forKey: CloudKeys.lastSyncDate)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    // MARK: - Automatic Sync
    
    /// Enable automatic syncing when data changes
    func enableAutomaticSync() {
        // Listen for RPE updates
        NotificationCenter.default.publisher(for: .rpeDidUpdate)
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.syncToCloud()
                }
            }
            .store(in: &cancellables)
        
        // Listen for settings updates
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.syncToCloud()
                }
            }
            .store(in: &cancellables)
        
        Logger.debug("☁️ Automatic iCloud sync enabled")
    }
    
    // MARK: - Error Handling
    
    enum iCloudError: LocalizedError {
        case notAvailable
        case syncFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "iCloud is not available. Please check your iCloud settings."
            case .syncFailed(let message):
                return "Sync failed: \(message)"
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let userSettingsDidRestore = Notification.Name("userSettingsDidRestore")
}
