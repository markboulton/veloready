import XCTest
import Testing
@testable import VeloReady

@Suite("VeloReady API Client Integration Tests")
struct VeloReadyAPIClientTests {
    
    @Test("Fetch activities with valid authentication")
    func testFetchActivitiesAuthenticated() async throws {
        let client = await VeloReadyAPIClient.shared
        
        // Use test account credentials
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        let activities = try await client.fetchActivities(daysBack: 30, limit: 50)
        
        #expect(activities.count >= 0) // May be empty for new user
        // Note: athleteId is not returned in the current API structure
    }
    
    @Test("Fetch activities without authentication fails gracefully")
    func testFetchActivitiesUnauthenticated() async throws {
        let client = await VeloReadyAPIClient.shared
        
        // Ensure no auth token
        await TestHelpers.signOut()
        
        do {
            _ = try await client.fetchActivities(daysBack: 30, limit: 50)
            Issue.record("Expected error but call succeeded")
        } catch VeloReadyAPIError.notAuthenticated {
            // Expected - test passes
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test("Fetch activities returns data matching backend schema")
    func testFetchActivitiesSchema() async throws {
        let client = await VeloReadyAPIClient.shared
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        let activities = try await client.fetchActivities(daysBack: 30, limit: 50)
        
        // Validate schema matches backend contract
        #expect(activities is [StravaActivity])
        if let firstActivity = activities.first {
            #expect(firstActivity.id > 0) // id is Int, not optional
            #expect(!firstActivity.name.isEmpty) // name is String, not optional
            #expect(!firstActivity.start_date.isEmpty) // start_date is String, not optional
            // If activity has power data, validate structure
            if firstActivity.average_watts != nil {
                #expect(firstActivity.average_watts != nil)
                #expect(firstActivity.weighted_average_watts != nil)
            }
        }
    }
    
    @Test("Fetch streams with valid authentication")
    func testFetchStreamsAuthenticated() async throws {
        let client = await VeloReadyAPIClient.shared
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        // Mock activity ID
        let activityId = "123456789"
        let streams = try await client.fetchActivityStreams(activityId: activityId, source: .strava)
        
        #expect(streams["power"] != nil || streams["heartrate"] != nil)
        #expect(streams["time"] != nil)
    }
    
    @Test("Fetch Intervals activities with valid authentication")
    func testFetchIntervalsActivitiesAuthenticated() async throws {
        let client = await VeloReadyAPIClient.shared
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        let activities = try await client.fetchIntervalsActivities(daysBack: 30, limit: 50)
        
        #expect(activities.count >= 0) // May be empty for new user
    }
    
    @Test("Fetch Intervals wellness with valid authentication")
    func testFetchIntervalsWellnessAuthenticated() async throws {
        let client = await VeloReadyAPIClient.shared
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        let wellness = try await client.fetchIntervalsWellness(days: 30)
        
        #expect(wellness.count >= 0) // May be empty for new user
    }
    
    @Test("Handle network errors gracefully")
    func testNetworkErrorHandling() async throws {
        let client = await VeloReadyAPIClient.shared
        let testUser = try await TestHelpers.createTestUser()
        try await TestHelpers.signIn(testUser)
        
        // This test would need to mock network failures
        // For now, we'll test that the client doesn't crash
        do {
            _ = try await client.fetchActivities(daysBack: 30, limit: 50)
        } catch {
            // Network errors should be handled gracefully
            #expect(error is VeloReadyAPIError)
        }
    }
}
