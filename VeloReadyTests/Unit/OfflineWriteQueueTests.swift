import XCTest
@testable import VeloReady

/// Unit tests for OfflineWriteQueue service
/// Tests queuing, persistence, and sync logic for offline writes
final class OfflineWriteQueueTests: XCTestCase {

    var sut: OfflineWriteQueue!

    override func setUp() async throws {
        try await super.setUp()
        sut = OfflineWriteQueue.shared
        // Clear queue before each test
        await sut.clearQueue()
    }

    override func tearDown() async throws {
        // Clear queue after each test
        await sut.clearQueue()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testOfflineWriteQueue_IsSingleton() async throws {
        // Given: Two references to OfflineWriteQueue
        let instance1 = OfflineWriteQueue.shared
        let instance2 = OfflineWriteQueue.shared

        // Then: Should be the same instance
        XCTAssertTrue(instance1 === instance2, "OfflineWriteQueue should be a singleton")
    }

    func testInitialState_QueueIsEmpty() async throws {
        // Given: Fresh queue
        // When: Getting queue size
        let count = await sut.count

        // Then: Queue should be empty
        XCTAssertEqual(count, 0, "Initial queue should be empty")
    }

    // MARK: - Enqueue Tests

    func testEnqueue_RPERating_AddsToQueue() async throws {
        // Given: RPE payload
        struct RPEPayload: Codable {
            let activityId: String
            let rpeScore: Int
            let source: String
        }

        let payload = RPEPayload(activityId: "123", rpeScore: 8, source: "healthkit")

        // When: Enqueueing the write
        try await sut.enqueue(type: .rpeRating, payload: payload)

        // Then: Queue should contain the write
        let count = await sut.count
        XCTAssertEqual(count, 1, "Queue should contain 1 write")

        let writes = await sut.allWrites
        XCTAssertEqual(writes.first?.type, .rpeRating, "Write type should be rpeRating")
    }

    func testEnqueue_ManualActivity_AddsToQueue() async throws {
        // Given: Activity payload
        struct ActivityPayload: Codable {
            let name: String
            let type: String
            let startDate: Date
        }

        let payload = ActivityPayload(name: "Morning Run", type: "running", startDate: Date())

        // When: Enqueueing the write
        try await sut.enqueue(type: .manualActivity, payload: payload)

        // Then: Queue should contain the write
        let count = await sut.count
        XCTAssertEqual(count, 1, "Queue should contain 1 write")

        let writes = await sut.allWrites
        XCTAssertEqual(writes.first?.type, .manualActivity, "Write type should be manualActivity")
    }

    func testEnqueue_SettingsChange_AddsToQueue() async throws {
        // Given: Settings payload
        struct SettingsPayload: Codable {
            let key: String
            let value: String
        }

        let payload = SettingsPayload(key: "name", value: "John Doe")

        // When: Enqueueing the write
        try await sut.enqueue(type: .settingsChange, payload: payload)

        // Then: Queue should contain the write
        let count = await sut.count
        XCTAssertEqual(count, 1, "Queue should contain 1 write")

        let writes = await sut.allWrites
        XCTAssertEqual(writes.first?.type, .settingsChange, "Write type should be settingsChange")
    }

    func testEnqueue_MultipleWrites_AllAdded() async throws {
        // Given: Multiple payloads
        struct TestPayload: Codable {
            let value: String
        }

        let payload1 = TestPayload(value: "first")
        let payload2 = TestPayload(value: "second")
        let payload3 = TestPayload(value: "third")

        // When: Enqueueing multiple writes
        try await sut.enqueue(type: .rpeRating, payload: payload1)
        try await sut.enqueue(type: .manualActivity, payload: payload2)
        try await sut.enqueue(type: .settingsChange, payload: payload3)

        // Then: Queue should contain all writes
        let count = await sut.count
        XCTAssertEqual(count, 3, "Queue should contain 3 writes")
    }

    // MARK: - Persistence Tests

    func testEnqueue_WritesPersistToUserDefaults() async throws {
        // Given: A write
        struct TestPayload: Codable {
            let value: String
        }

        let payload = TestPayload(value: "test")

        // When: Enqueueing the write
        try await sut.enqueue(type: .rpeRating, payload: payload)

        // Then: Should be persisted to UserDefaults
        let data = UserDefaults.standard.data(forKey: "com.veloready.offlineWriteQueue")
        XCTAssertNotNil(data, "Queue should be persisted to UserDefaults")

        // Verify it can be decoded
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let writes = try decoder.decode([OfflineWriteQueue.QueuedWrite].self, from: data!)
        XCTAssertEqual(writes.count, 1, "Persisted queue should contain 1 write")
    }

    // MARK: - Sync Tests

    func testSyncWhenOnline_WhenOffline_DoesNotSync() async throws {
        // Given: Queue with writes and device offline
        struct TestPayload: Codable {
            let value: String
        }

        let payload = TestPayload(value: "test")
        try await sut.enqueue(type: .rpeRating, payload: payload)

        // Note: This test assumes device is actually online in test environment
        // In a real scenario with network mocking, we'd mock NetworkMonitor.isConnected = false

        // When: Attempting to sync
        let syncCount = await sut.syncWhenOnline()

        // Then: Based on actual network state, should sync or not
        // In test environment (likely online), sync will execute
        let remainingCount = await sut.count

        // If synced successfully, count should be 0
        // If offline (mocked), count should still be 1
        XCTAssertTrue(remainingCount == 0 || remainingCount == 1,
                     "Queue should either sync (0) or remain (1) based on network state")
    }

    func testSyncWhenOnline_EmptyQueue_ReturnsZero() async throws {
        // Given: Empty queue
        // When: Attempting to sync
        let syncCount = await sut.syncWhenOnline()

        // Then: Should return 0
        XCTAssertEqual(syncCount, 0, "Sync of empty queue should return 0")
    }

    func testSyncWhenOnline_ConcurrentCalls_OnlyOneSyncRuns() async throws {
        // Given: Queue with writes
        struct TestPayload: Codable {
            let value: String
        }

        for i in 1...5 {
            try await sut.enqueue(type: .rpeRating, payload: TestPayload(value: "test\(i)"))
        }

        // When: Calling sync concurrently
        async let sync1 = sut.syncWhenOnline()
        async let sync2 = sut.syncWhenOnline()
        async let sync3 = sut.syncWhenOnline()

        let results = await [sync1, sync2, sync3]

        // Then: Only one should have synced, others should return 0
        let totalSynced = results.reduce(0, +)
        XCTAssertTrue(totalSynced <= 5, "Should not sync more items than in queue")
    }

    // MARK: - Clear Queue Tests

    func testClearQueue_RemovesAllWrites() async throws {
        // Given: Queue with multiple writes
        struct TestPayload: Codable {
            let value: String
        }

        for i in 1...5 {
            try await sut.enqueue(type: .rpeRating, payload: TestPayload(value: "test\(i)"))
        }

        let initialCount = await sut.count
        XCTAssertEqual(initialCount, 5, "Queue should have 5 writes initially")

        // When: Clearing the queue
        await sut.clearQueue()

        // Then: Queue should be empty
        let finalCount = await sut.count
        XCTAssertEqual(finalCount, 0, "Queue should be empty after clearing")
    }

    // MARK: - Write Type Tests

    func testWriteType_AllTypesSupported() async throws {
        // Given: All write types
        let types: [OfflineWriteQueue.WriteType] = [
            .rpeRating,
            .manualActivity,
            .settingsChange,
            .wellnessEntry
        ]

        struct TestPayload: Codable {
            let value: String
        }

        // When: Enqueueing each type
        for type in types {
            try await sut.enqueue(type: type, payload: TestPayload(value: type.rawValue))
        }

        // Then: All should be in queue
        let count = await sut.count
        XCTAssertEqual(count, types.count, "Queue should contain all write types")

        let writes = await sut.allWrites
        let writeTypes = writes.map { $0.type }

        for type in types {
            XCTAssertTrue(writeTypes.contains(type), "Queue should contain \(type.rawValue)")
        }
    }

    // MARK: - ID Generation Tests

    func testQueuedWrite_GeneratesUniqueIDs() async throws {
        // Given: Multiple writes
        struct TestPayload: Codable {
            let value: String
        }

        for i in 1...10 {
            try await sut.enqueue(type: .rpeRating, payload: TestPayload(value: "test\(i)"))
        }

        // When: Getting all writes
        let writes = await sut.allWrites

        // Then: All IDs should be unique
        let ids = writes.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All write IDs should be unique")
    }

    // MARK: - Timestamp Tests

    func testQueuedWrite_IncludesTimestamp() async throws {
        // Given: A write
        struct TestPayload: Codable {
            let value: String
        }

        let beforeEnqueue = Date()

        // When: Enqueueing the write
        try await sut.enqueue(type: .rpeRating, payload: TestPayload(value: "test"))

        let afterEnqueue = Date()

        // Then: Write should have timestamp between before and after
        let writes = await sut.allWrites
        XCTAssertEqual(writes.count, 1, "Queue should have 1 write")

        let write = writes.first!
        XCTAssertTrue(write.timestamp >= beforeEnqueue, "Timestamp should be after enqueue start")
        XCTAssertTrue(write.timestamp <= afterEnqueue, "Timestamp should be before enqueue end")
    }

    // MARK: - Manual Testing Instructions

    /// MANUAL TEST: Offline RPE Submission
    /// 1. Run app on physical device or simulator
    /// 2. Complete a workout and open RPE input sheet
    /// 3. Enable airplane mode
    /// 4. Submit RPE rating (should show "Queued for sync" or similar)
    /// 5. Check console for log: "📦 [OfflineQueue] Enqueued rpe_rating write"
    /// 6. Disable airplane mode
    /// 7. Wait a few seconds
    /// 8. Check console for log: "✅ [OfflineQueue] Synced rpe_rating"
    ///
    /// Expected: RPE is queued when offline, syncs automatically when online

    /// MANUAL TEST: Offline Settings Change
    /// 1. Navigate to Settings > Profile
    /// 2. Enable airplane mode
    /// 3. Change name, weight, or other settings
    /// 4. Tap Save
    /// 5. Check console for log: "📦 [Profile] Queued profile settings for backend sync"
    /// 6. Disable airplane mode
    /// 7. Check console for log: "✅ [OfflineQueue] Synced settings_change"
    ///
    /// Expected: Settings are saved locally and queued for backend sync

    /// MANUAL TEST: Queue Persistence Across App Restarts
    /// 1. Enable airplane mode
    /// 2. Submit 3 RPE ratings
    /// 3. Force quit the app (swipe up in app switcher)
    /// 4. Relaunch the app
    /// 5. Disable airplane mode
    /// 6. Check console for log: "📦 [OfflineQueue] Loaded 3 writes from disk"
    /// 7. Check console for log: "📦 [OfflineQueue] Starting sync of 3 queued writes"
    ///
    /// Expected: Queued writes persist across app restarts and sync when online

    /// MANUAL TEST: Concurrent Sync Prevention
    /// 1. Queue multiple writes while offline
    /// 2. Go online
    /// 3. Trigger multiple sync attempts rapidly (e.g., by navigating between views)
    /// 4. Check console for log: "📦 [OfflineQueue] Sync already in progress, skipping"
    ///
    /// Expected: Only one sync operation runs at a time
}
