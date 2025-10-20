import Foundation

/// User's sport preferences and rankings
struct SportPreferences: Codable, Equatable {
    
    // MARK: - Sport Types
    
    enum Sport: String, Codable, CaseIterable, Identifiable {
        case cycling
        case strength
        case general
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .cycling:
                return "Cycling"
            case .strength:
                return "Strength Training"
            case .general:
                return "General Activity"
            }
        }
        
        var description: String {
            switch self {
            case .cycling:
                return CommonContent.Sports.cyclingDescription
            case .strength:
                return "Weight training, resistance exercises, functional fitness"
            case .general:
                return "Walking, running, hiking, and other activities"
            }
        }
        
        var icon: String {
            switch self {
            case .cycling:
                return "figure.outdoor.cycle"
            case .strength:
                return "dumbbell.fill"
            case .general:
                return "figure.walk"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Rankings of sports (1 = primary, 2 = secondary, 3 = tertiary)
    var rankings: [Sport: Int]
    
    /// Primary sport (convenience accessor)
    var primarySport: Sport {
        rankings.first(where: { $0.value == 1 })?.key ?? .cycling
    }
    
    /// Secondary sport (convenience accessor)
    var secondarySport: Sport? {
        rankings.first(where: { $0.value == 2 })?.key
    }
    
    /// Tertiary sport (convenience accessor)
    var tertiarySport: Sport? {
        rankings.first(where: { $0.value == 3 })?.key
    }
    
    /// Ordered list of sports by ranking
    var orderedSports: [Sport] {
        rankings.sorted { $0.value < $1.value }.map { $0.key }
    }
    
    // MARK: - Initialization
    
    init(rankings: [Sport: Int] = [.cycling: 1, .strength: 2, .general: 3]) {
        self.rankings = rankings
    }
    
    /// Initialize with primary sport only (other sports unranked)
    init(primarySport: Sport) {
        self.rankings = [primarySport: 1]
    }
    
    /// Initialize from ordered array (first = primary, second = secondary, etc.)
    init(orderedSports: [Sport]) {
        var rankings: [Sport: Int] = [:]
        for (index, sport) in orderedSports.enumerated() {
            rankings[sport] = index + 1
        }
        self.rankings = rankings
    }
    
    // MARK: - Helpers
    
    /// Get ranking for a specific sport (nil if unranked)
    func ranking(for sport: Sport) -> Int? {
        rankings[sport]
    }
    
    /// Check if a sport is ranked
    func isRanked(_ sport: Sport) -> Bool {
        rankings[sport] != nil
    }
    
    /// Update ranking for a sport
    mutating func setRanking(_ ranking: Int, for sport: Sport) {
        rankings[sport] = ranking
    }
    
    /// Remove ranking for a sport
    mutating func removeRanking(for sport: Sport) {
        rankings.removeValue(forKey: sport)
    }
    
    /// Default preferences (cycling primary)
    static let `default` = SportPreferences(
        rankings: [.cycling: 1, .strength: 2, .general: 3]
    )
}

// MARK: - CustomStringConvertible

extension SportPreferences: CustomStringConvertible {
    var description: String {
        let ranked = orderedSports.map { "\($0.displayName) (#\(rankings[$0] ?? 0))" }
        return "SportPreferences: \(ranked.joined(separator: ", "))"
    }
}
