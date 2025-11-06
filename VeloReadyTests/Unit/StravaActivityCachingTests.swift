import Foundation
import Testing
@testable import VeloReady

/// Critical regression test for Strava activities caching bug
/// Tests that [StravaActivity] arrays can be saved and loaded from Core Data
/// This was broken after cache v2 migration - activities would fetch but not persist
@Suite("Strava Activity Caching - Regression Test")
struct StravaActivityCachingTests {
    
    @Test("CRITICAL: Strava activities persist to Core Data and can be retrieved")
    func testStravaActivitiesPersistToCoreData() async throws {
        let persistence = await CachePersistenceLayer.shared
        let key = "strava:activities:7:test:\(UUID().uuidString)"
        
        // Manually create simple Strava activity data (using raw JSON encoding)
        // This simulates what happens when backend returns Strava activities
        let activitiesJSON = """
        [
            {
                "id": 123,
                "name": "Morning Ride",
                "distance": 50000,
                "moving_time": 3600,
                "elapsed_time": 3800,
                "total_elevation_gain": 500,
                "type": "Ride",
                "sport_type": "Ride",
                "start_date": "2025-11-06T08:00:00Z",
                "start_date_local": "2025-11-06T09:00:00Z",
                "timezone": "(GMT+00:00) UTC",
                "average_speed": 13.9,
                "max_speed": 25.0,
                "average_watts": 200,
                "weighted_average_watts": 210,
                "kilojoules": 720,
                "average_cadence": 85,
                "average_heartrate": 145,
                "max_heartrate": 175,
                "has_heartrate": true,
                "elev_high": 150,
                "elev_low": 50,
                "calories": 650,
                "start_latlng": [51.5074, -0.1278],
                "external_id": "ext123",
                "upload_id_str": "upload123",
                "upload_id": 123
            }
        ]
        """.data(using: .utf8)!
        
        // Decode it into [StravaActivity]
        let activities = try JSONDecoder().decode([StravaActivity].self, from: activitiesJSON)
        
        #expect(activities.count == 1, "Should decode 1 activity")
        #expect(activities[0].id == 123)
        #expect(activities[0].name == "Morning Ride")
        
        // THE CRITICAL TEST: Save to Core Data
        await persistence.saveToCoreData(key: key, value: activities, ttl: 3600)
        
        // THE CRITICAL TEST: Load back from Core Data
        let loaded = await persistence.loadFromCoreData(key: key, as: [StravaActivity].self)
        
        #expect(loaded != nil, "CRITICAL: [StravaActivity] must persist to Core Data")
        #expect(loaded?.value.count == 1, "Should load 1 activity from Core Data")
        #expect(loaded?.value[0].id == 123, "Should preserve activity ID")
        #expect(loaded?.value[0].name == "Morning Ride", "Should preserve activity name")
    }
    
    @Test("CRITICAL: Strava activities survive cache restart simulation")
    func testStravaActivitiesSurviveRestart() async throws {
        let cache = await UnifiedCacheManager.shared
        let key = "strava:activities:restart:test:\(UUID().uuidString)"
        
        // Create test data via JSON (easier than constructor)
        let activitiesJSON = """
        [
            {
                "id": 456,
                "name": "Test Ride",
                "distance": 40000,
                "moving_time": 2700,
                "elapsed_time": 2800,
                "total_elevation_gain": 300,
                "type": "Ride",
                "sport_type": "Ride",
                "start_date": "2025-11-06T10:00:00Z",
                "start_date_local": "2025-11-06T11:00:00Z",
                "timezone": "(GMT+00:00) UTC",
                "average_speed": 14.8,
                "max_speed": 26.0,
                "average_watts": 205,
                "weighted_average_watts": 215,
                "kilojoules": 553.5,
                "average_cadence": 88,
                "average_heartrate": 148,
                "max_heartrate": 172,
                "has_heartrate": true,
                "elev_high": 200,
                "elev_low": 100,
                "calories": 500,
                "start_latlng": [51.5074, -0.1278],
                "external_id": "ext456",
                "upload_id_str": "upload456",
                "upload_id": 456
            }
        ]
        """.data(using: .utf8)!
        
        let activities = try JSONDecoder().decode([StravaActivity].self, from: activitiesJSON)
        
        // 1. Cache the activities (simulates first app launch)
        var fetchCount = 0
        let cached = try await cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return activities
        }
        
        #expect(fetchCount == 1, "Should fetch from API once")
        #expect(cached.count == 1)
        
        // 2. Verify it persisted to Core Data
        let persistence = await CachePersistenceLayer.shared
        let persisted = await persistence.loadFromCoreData(key: key, as: [StravaActivity].self)
        #expect(persisted != nil, "Must persist for app restart")
        
        // 3. Try to fetch again (simulates second app launch - should use cache)
        let recached = try await cache.fetch(key: key, ttl: 3600) {
            fetchCount += 1
            return activities
        }
        
        #expect(fetchCount == 1, "Should NOT fetch from API again (cached)")
        #expect(recached.count == 1)
        #expect(recached[0].id == 456)
    }
    
    @Test("CRITICAL: Type-erased loading works for [StravaActivity]")
    func testTypeErasedStravaActivityLoading() async throws {
        let persistence = await CachePersistenceLayer.shared
        let key = "strava:activities:type_erased:test:\(UUID().uuidString)"
        
        // Create activity
        let activitiesJSON = """
        [
            {
                "id": 789,
                "name": "Type Erased Test",
                "distance": 30000,
                "moving_time": 1800,
                "elapsed_time": 1900,
                "total_elevation_gain": 200,
                "type": "Ride",
                "sport_type": "Ride",
                "start_date": "2025-11-06T12:00:00Z",
                "start_date_local": "2025-11-06T13:00:00Z",
                "timezone": "(GMT+00:00) UTC",
                "average_speed": 16.7,
                "max_speed": 30.0,
                "average_watts": 220,
                "weighted_average_watts": 230,
                "kilojoules": 396,
                "average_cadence": 90,
                "average_heartrate": 150,
                "max_heartrate": 170,
                "has_heartrate": true,
                "elev_high": 150,
                "elev_low": 50,
                "calories": 400,
                "start_latlng": [51.5074, -0.1278],
                "external_id": "ext789",
                "upload_id_str": "upload789",
                "upload_id": 789
            }
        ]
        """.data(using: .utf8)!
        
        let activities = try JSONDecoder().decode([StravaActivity].self, from: activitiesJSON)
        
        // Save to Core Data
        await persistence.saveToCoreData(key: key, value: activities, ttl: 3600)
        
        // THE BUG: loadFromCoreData would return nil for [StravaActivity]
        // because loadFromCoreDataErased didn't support it
        let loaded = await persistence.loadFromCoreData(key: key, as: [StravaActivity].self)
        
        #expect(loaded != nil, "CRITICAL: Type-erased loading must support [StravaActivity]")
        #expect(loaded?.value.count == 1)
        #expect(loaded?.value[0].id == 789)
        #expect(loaded?.value[0].name == "Type Erased Test")
    }
    
    @Test("Empty Strava activities array is handled correctly")
    func testEmptyStravaActivities() async throws {
        let persistence = await CachePersistenceLayer.shared
        let key = "strava:activities:empty:test:\(UUID().uuidString)"
        
        // Empty array (user has no activities)
        let activities: [StravaActivity] = []
        
        await persistence.saveToCoreData(key: key, value: activities, ttl: 3600)
        
        let loaded = await persistence.loadFromCoreData(key: key, as: [StravaActivity].self)
        #expect(loaded != nil, "Empty array should still persist")
        #expect(loaded?.value.isEmpty == true)
    }
}
