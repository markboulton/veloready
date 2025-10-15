import Foundation

/// Tests for SportPreferences model
/// Run these tests manually in a debug environment
class SportPreferencesTests {
    
    static func runAllTests() {
        print("🧪 Running SportPreferences Tests...")
        
        testDefaultPreferences()
        testInitWithPrimarySport()
        testInitWithOrderedSports()
        testRankingOperations()
        testConvenienceAccessors()
        testUserSettingsIntegration()
        
        print("✅ All SportPreferences tests passed!")
    }
    
    // MARK: - Test Cases
    
    private static func testDefaultPreferences() {
        print("Testing default preferences...")
        
        let prefs = SportPreferences.default
        
        assert(prefs.primarySport == .cycling, "Default primary sport should be cycling")
        assert(prefs.rankings[.cycling] == 1, "Cycling should be ranked 1")
        assert(prefs.rankings[.strength] == 2, "Strength should be ranked 2")
        assert(prefs.rankings[.general] == 3, "General should be ranked 3")
        
        print("✓ Default preferences test passed")
    }
    
    private static func testInitWithPrimarySport() {
        print("Testing init with primary sport...")
        
        let prefs = SportPreferences(primarySport: .strength)
        
        assert(prefs.primarySport == .strength, "Primary sport should be strength")
        assert(prefs.rankings[.strength] == 1, "Strength should be ranked 1")
        assert(prefs.rankings[.cycling] == nil, "Cycling should be unranked")
        
        print("✓ Init with primary sport test passed")
    }
    
    private static func testInitWithOrderedSports() {
        print("Testing init with ordered sports...")
        
        let prefs = SportPreferences(orderedSports: [.general, .cycling, .strength])
        
        assert(prefs.primarySport == .general, "Primary sport should be general")
        assert(prefs.rankings[.general] == 1, "General should be ranked 1")
        assert(prefs.rankings[.cycling] == 2, "Cycling should be ranked 2")
        assert(prefs.rankings[.strength] == 3, "Strength should be ranked 3")
        
        print("✓ Init with ordered sports test passed")
    }
    
    private static func testRankingOperations() {
        print("Testing ranking operations...")
        
        var prefs = SportPreferences()
        
        // Set ranking
        prefs.setRanking(1, for: .strength)
        assert(prefs.rankings[.strength] == 1, "Strength should be ranked 1")
        
        // Check if ranked
        assert(prefs.isRanked(.strength), "Strength should be ranked")
        assert(!prefs.isRanked(.general), "General should not be ranked initially")
        
        // Get ranking
        assert(prefs.ranking(for: .strength) == 1, "Strength ranking should be 1")
        assert(prefs.ranking(for: .general) == nil, "General ranking should be nil")
        
        // Remove ranking
        prefs.removeRanking(for: .strength)
        assert(!prefs.isRanked(.strength), "Strength should no longer be ranked")
        
        print("✓ Ranking operations test passed")
    }
    
    private static func testConvenienceAccessors() {
        print("Testing convenience accessors...")
        
        let prefs = SportPreferences(orderedSports: [.cycling, .strength, .general])
        
        assert(prefs.primarySport == .cycling, "Primary sport should be cycling")
        assert(prefs.secondarySport == .strength, "Secondary sport should be strength")
        assert(prefs.tertiarySport == .general, "Tertiary sport should be general")
        
        let ordered = prefs.orderedSports
        assert(ordered.count == 3, "Should have 3 sports")
        assert(ordered[0] == .cycling, "First should be cycling")
        assert(ordered[1] == .strength, "Second should be strength")
        assert(ordered[2] == .general, "Third should be general")
        
        print("✓ Convenience accessors test passed")
    }
    
    private static func testUserSettingsIntegration() {
        print("Testing UserSettings integration...")
        
        // Note: This test needs to run in MainActor context
        // We'll just verify the types are compatible
        
        let prefs = SportPreferences(primarySport: .strength)
        
        // Verify it's Codable
        if let encoded = try? JSONEncoder().encode(prefs) {
            if let decoded = try? JSONDecoder().decode(SportPreferences.self, from: encoded) {
                assert(decoded.primarySport == .strength, "Decoded primary sport should match")
                print("✓ Codable encoding/decoding works")
            } else {
                fatalError("Failed to decode SportPreferences")
            }
        } else {
            fatalError("Failed to encode SportPreferences")
        }
        
        // Verify it's Equatable
        let prefs2 = SportPreferences(primarySport: .strength)
        assert(prefs == prefs2, "Equal preferences should be equal")
        
        let prefs3 = SportPreferences(primarySport: .cycling)
        assert(prefs != prefs3, "Different preferences should not be equal")
        
        print("✓ UserSettings integration test passed")
    }
}

// MARK: - Test Runner Helper
extension SportPreferencesTests {
    /// Call this from a debug view or breakpoint
    static func quickTest() {
        runAllTests()
    }
}
