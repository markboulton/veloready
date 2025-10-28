import Foundation
@testable import VeloReady

struct TestUser {
    let id: String
    let email: String
    let athleteId: Int
    let accessToken: String
    let refreshToken: String
}

class TestHelpers {
    static let shared = TestHelpers()
    
    private init() {}
    
    func createTestUser() async throws -> TestUser {
        // In a real test environment, you'd create a test user in Supabase
        // For now, return a mock user
        return TestUser(
            id: "test-user-id",
            email: "test@example.com",
            athleteId: 123456789,
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token"
        )
    }
    
    func signIn(_ user: TestUser) async throws {
        // Mock authentication - in real tests, you'd authenticate with Supabase
        // For now, we'll just set up the client state
        // This would need to be implemented based on your actual auth flow
    }
    
    func signOut() async {
        // Mock sign out
        // This would need to be implemented based on your actual auth flow
    }
    
    func createMockStravaActivity() -> StravaActivity {
        let formatter = ISO8601DateFormatter()
        let now = Date()
        let startDateString = formatter.string(from: now)
        
        return StravaActivity(
            id: 987654321,
            name: "Test Morning Ride",
            distance: 25000,
            moving_time: 3600,
            elapsed_time: 3600,
            total_elevation_gain: 300,
            type: "Ride",
            sport_type: "Ride",
            start_date: startDateString,
            start_date_local: startDateString,
            timezone: "America/New_York",
            average_speed: 6.94,
            max_speed: 12.5,
            average_watts: 200,
            weighted_average_watts: 210,
            kilojoules: 720,
            average_heartrate: 150,
            max_heartrate: 175,
            average_cadence: 85,
            has_heartrate: true,
            elev_high: 1000,
            elev_low: 700,
            calories: 500,
            start_latlng: [40.7128, -74.0060],
            external_id: "test-external-id",
            upload_id: 12345,
            upload_id_str: "12345"
        )
    }
    
    func createMockStreams() -> [String: [Double]] {
        return [
            "power": [200, 210, 195, 205, 200],
            "heartrate": [150, 155, 148, 152, 150],
            "time": [0, 1, 2, 3, 4]
        ]
    }
    
    func createMockAIBrief() -> AIBriefResponse {
        return AIBriefResponse(
            text: "Great recovery! Ready for 50 TSS Z2 ride today.",
            cached: false
        )
    }
}

// Extension to make TestHelpers accessible from tests
extension TestHelpers {
    static func createTestUser() async throws -> TestUser {
        return try await shared.createTestUser()
    }
    
    static func signIn(_ user: TestUser) async throws {
        try await shared.signIn(user)
    }
    
    static func signOut() async {
        await shared.signOut()
    }
}
