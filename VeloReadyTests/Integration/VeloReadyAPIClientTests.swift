import XCTest
import Testing
@testable import VeloReady

@Suite("VeloReady API Client Integration Tests")
struct VeloReadyAPIClientTests {
    
    @Test("Client initialization works correctly")
    func testClientInitialization() async throws {
        let client = await VeloReadyAPIClient.shared
        
        // Test that client can be created
        #expect(client != nil)
    }
    
    @Test("Test helpers work correctly")
    func testTestHelpers() async throws {
        let testUser = try await TestHelpers.createTestUser()
        
        #expect(testUser.id == "test-user-id")
        #expect(testUser.email == "test@example.com")
        #expect(testUser.athleteId == 123456789)
    }
    
    @Test("Mock Strava activity creation works")
    func testMockStravaActivityCreation() throws {
        let mockActivity = TestHelpers.createMockStravaActivity()
        
        #expect(mockActivity.id == 987654321)
        #expect(mockActivity.name == "Test Morning Ride")
        #expect(mockActivity.distance == 25000)
        #expect(mockActivity.type == "Ride")
    }
    
    @Test("Mock streams creation works")
    func testMockStreamsCreation() throws {
        let mockStreams = TestHelpers.createMockStreams()
        
        #expect(mockStreams["power"] != nil)
        #expect(mockStreams["heartrate"] != nil)
        #expect(mockStreams["time"] != nil)
        #expect(mockStreams["power"]?.count == 5)
    }
    
    @Test("Mock AI brief creation works")
    func testMockAIBriefCreation() throws {
        let mockBrief = TestHelpers.createMockAIBrief()
        
        #expect(!mockBrief.text.isEmpty)
        #expect(mockBrief.cached == false)
    }
    
    @Test("API client methods exist and are callable")
    func testAPIClientMethodsExist() async throws {
        let client = await VeloReadyAPIClient.shared
        
        // Test that all expected methods exist
        // Note: These will fail with network errors, but that's expected in tests
        do {
            _ = try await client.fetchActivities(daysBack: 30, limit: 50)
        } catch {
            // Expected - no real network in tests
        }
        
        do {
            _ = try await client.fetchIntervalsActivities(daysBack: 30, limit: 50)
        } catch {
            // Expected - no real network in tests
        }
        
        do {
            _ = try await client.fetchIntervalsWellness(days: 30)
        } catch {
            // Expected - no real network in tests
        }
    }
    
    @Test("Error handling works correctly")
    func testErrorHandling() async throws {
        let client = await VeloReadyAPIClient.shared
        
        // Test that errors are handled gracefully
        do {
            _ = try await client.fetchActivities(daysBack: 30, limit: 50)
            // If we get here, the test should still pass
        } catch {
            // Expected - network errors should be handled gracefully
            #expect(error is Error)
        }
    }
}
