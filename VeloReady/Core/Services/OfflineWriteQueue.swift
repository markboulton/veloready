import Foundation

/// Actor that manages queuing writes when offline for later sync
/// When the device is offline, write operations (RPE ratings, manual activities, settings)
/// are queued and automatically synced when connectivity is restored
actor OfflineWriteQueue {

    // MARK: - Singleton

    static let shared = OfflineWriteQueue()

    // MARK: - Queued Write Model

    /// Represents a write operation that was queued while offline
    struct QueuedWrite: Codable, Identifiable {
        let id: UUID
        let type: WriteType
        let payload: Data
        let timestamp: Date

        init(id: UUID = UUID(), type: WriteType, payload: Data, timestamp: Date = Date()) {
            self.id = id
            self.type = type
            self.payload = payload
            self.timestamp = timestamp
        }
    }

    /// Types of write operations that can be queued
    enum WriteType: String, Codable {
        case rpeRating = "rpe_rating"
        case manualActivity = "manual_activity"
        case settingsChange = "settings_change"
        case wellnessEntry = "wellness_entry"
    }

    // MARK: - Private Properties

    /// In-memory queue of pending writes
    private var queuedWrites: [QueuedWrite] = []

    /// UserDefaults key for persisting queue
    private let queueKey = "com.veloready.offlineWriteQueue"

    /// Maximum age for queued writes (7 days)
    private let maxWriteAge: TimeInterval = 7 * 24 * 60 * 60

    /// Flag to prevent concurrent sync operations
    private var isSyncing = false

    // MARK: - Initialization

    private init() {
        Logger.debug("📦 [OfflineQueue] Initializing offline write queue")
        loadQueue()
        cleanupStaleWrites()
    }

    // MARK: - Public Methods

    /// Enqueue a write operation for later sync
    /// - Parameter write: The write operation to queue
    func enqueue(_ write: QueuedWrite) {
        queuedWrites.append(write)
        persistQueue()

        Logger.info("📦 [OfflineQueue] Enqueued \(write.type.rawValue) write (id: \(write.id))")
        Logger.debug("📦 [OfflineQueue] Queue size: \(queuedWrites.count)")
    }

    /// Enqueue a write with payload encoding
    /// - Parameters:
    ///   - type: Type of write operation
    ///   - payload: Encodable payload to queue
    func enqueue<T: Encodable>(type: WriteType, payload: T) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let write = QueuedWrite(type: type, payload: data)
        enqueue(write)
    }

    /// Sync all queued writes when online
    /// - Returns: Number of writes successfully synced
    @discardableResult
    func syncWhenOnline() async -> Int {
        // Prevent concurrent sync operations
        guard !isSyncing else {
            Logger.debug("📦 [OfflineQueue] Sync already in progress, skipping")
            return 0
        }

        // Check network connectivity
        let isConnected = await MainActor.run {
            NetworkMonitor.shared.isConnected
        }

        guard isConnected else {
            Logger.debug("📦 [OfflineQueue] Device is offline, skipping sync")
            return 0
        }

        guard !queuedWrites.isEmpty else {
            Logger.debug("📦 [OfflineQueue] Queue is empty, nothing to sync")
            return 0
        }

        isSyncing = true
        defer { isSyncing = false }

        Logger.info("📦 [OfflineQueue] Starting sync of \(queuedWrites.count) queued writes")

        var successCount = 0
        var failedWrites: [QueuedWrite] = []

        // Process each write sequentially
        for write in queuedWrites {
            do {
                try await executeWrite(write)
                successCount += 1
                Logger.info("✅ [OfflineQueue] Synced \(write.type.rawValue) (id: \(write.id))")
            } catch {
                Logger.error("❌ [OfflineQueue] Failed to sync \(write.type.rawValue) (id: \(write.id)): \(error)")
                failedWrites.append(write)
            }
        }

        // Update queue to only contain failed writes
        queuedWrites = failedWrites
        persistQueue()

        Logger.info("📦 [OfflineQueue] Sync complete: \(successCount) succeeded, \(failedWrites.count) failed")

        return successCount
    }

    /// Get current queue size
    var count: Int {
        queuedWrites.count
    }

    /// Get all queued writes (for debugging/UI)
    var allWrites: [QueuedWrite] {
        queuedWrites
    }

    /// Clear all queued writes (for testing/debugging)
    func clearQueue() {
        queuedWrites.removeAll()
        persistQueue()
        Logger.debug("📦 [OfflineQueue] Queue cleared")
    }

    // MARK: - Private Methods

    /// Execute a queued write operation
    /// - Parameter write: The write to execute
    private func executeWrite(_ write: QueuedWrite) async throws {
        Logger.debug("📦 [OfflineQueue] Executing \(write.type.rawValue) write")

        switch write.type {
        case .rpeRating:
            try await executeRPERating(write)

        case .manualActivity:
            try await executeManualActivity(write)

        case .settingsChange:
            try await executeSettingsChange(write)

        case .wellnessEntry:
            try await executeWellnessEntry(write)
        }
    }

    /// Execute an RPE rating write
    private func executeRPERating(_ write: QueuedWrite) async throws {
        struct RPEPayload: Codable {
            let activityId: String
            let rpeScore: Int
            let source: String
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(RPEPayload.self, from: write.payload)

        // TODO: Call actual RPE submission API
        // For now, simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        Logger.debug("📦 [OfflineQueue] Submitted RPE \(payload.rpeScore) for activity \(payload.activityId)")
    }

    /// Execute a manual activity write
    private func executeManualActivity(_ write: QueuedWrite) async throws {
        struct ActivityPayload: Codable {
            let name: String
            let type: String
            let startDate: Date
            let duration: TimeInterval?
            let distance: Double?
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ActivityPayload.self, from: write.payload)

        // TODO: Call actual activity creation API
        // For now, simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        Logger.debug("📦 [OfflineQueue] Created manual activity: \(payload.name)")
    }

    /// Execute a settings change write
    private func executeSettingsChange(_ write: QueuedWrite) async throws {
        struct SettingsPayload: Codable {
            let key: String
            let value: String
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(SettingsPayload.self, from: write.payload)

        // TODO: Call actual settings update API
        // For now, simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        Logger.debug("📦 [OfflineQueue] Updated setting: \(payload.key) = \(payload.value)")
    }

    /// Execute a wellness entry write
    private func executeWellnessEntry(_ write: QueuedWrite) async throws {
        struct WellnessPayload: Codable {
            let date: Date
            let sleepQuality: Int?
            let fatigueLevel: Int?
            let mood: Int?
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(WellnessPayload.self, from: write.payload)

        // TODO: Call actual wellness submission API
        // For now, simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        Logger.debug("📦 [OfflineQueue] Submitted wellness entry for \(payload.date)")
    }

    /// Load queue from UserDefaults
    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            Logger.debug("📦 [OfflineQueue] No persisted queue found")
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            queuedWrites = try decoder.decode([QueuedWrite].self, from: data)
            Logger.info("📦 [OfflineQueue] Loaded \(queuedWrites.count) writes from disk")
        } catch {
            Logger.error("❌ [OfflineQueue] Failed to load queue: \(error)")
            queuedWrites = []
        }
    }

    /// Persist queue to UserDefaults
    private func persistQueue() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(queuedWrites)
            UserDefaults.standard.set(data, forKey: queueKey)
            Logger.debug("📦 [OfflineQueue] Persisted \(queuedWrites.count) writes to disk")
        } catch {
            Logger.error("❌ [OfflineQueue] Failed to persist queue: \(error)")
        }
    }

    /// Remove writes older than maxWriteAge
    private func cleanupStaleWrites() {
        let now = Date()
        let originalCount = queuedWrites.count

        queuedWrites.removeAll { write in
            let age = now.timeIntervalSince(write.timestamp)
            return age > maxWriteAge
        }

        let removedCount = originalCount - queuedWrites.count
        if removedCount > 0 {
            Logger.info("📦 [OfflineQueue] Removed \(removedCount) stale writes (older than 7 days)")
            persistQueue()
        }
    }
}

// MARK: - Error Types

enum OfflineQueueError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case syncFailed(String)
    case notOnline

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode write payload"
        case .decodingFailed:
            return "Failed to decode write payload"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .notOnline:
            return "Device is not online"
        }
    }
}
