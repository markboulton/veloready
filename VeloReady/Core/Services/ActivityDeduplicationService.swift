import Foundation

/// Service for deduplicating activities from multiple sources
/// Handles merging Intervals.icu, Strava, and Apple Health activities intelligently
@MainActor
class ActivityDeduplicationService {
    static let shared = ActivityDeduplicationService()
    
    private init() {}
    
    /// Deduplicate and merge activities from multiple sources
    /// - Parameters:
    ///   - intervalsActivities: Activities from Intervals.icu
    ///   - stravaActivities: Activities from Strava
    ///   - appleHealthActivities: Activities from Apple Health
    /// - Returns: Unified, deduplicated list of activities
    func deduplicateActivities(
        intervalsActivities: [UnifiedActivity],
        stravaActivities: [UnifiedActivity],
        appleHealthActivities: [UnifiedActivity]
    ) -> [UnifiedActivity] {
        print("🔍 [Deduplication] Starting with:")
        print("   Intervals.icu: \(intervalsActivities.count)")
        print("   Strava: \(stravaActivities.count)")
        print("   Apple Health: \(appleHealthActivities.count)")
        
        var result: [UnifiedActivity] = []
        var processedActivities: Set<String> = []
        
        // PRIORITY 1: Intervals.icu activities (most complete data)
        // These are kept as-is since they often include computed metrics (TSS, IF, etc.)
        for activity in intervalsActivities {
            result.append(activity)
            processedActivities.insert(activity.id)
            
            // Track all similar activities to prevent duplicates
            let matchingStrava = findMatchingActivities(activity, in: stravaActivities)
            let matchingHealth = findMatchingActivities(activity, in: appleHealthActivities)
            
            matchingStrava.forEach { processedActivities.insert($0.id) }
            matchingHealth.forEach { processedActivities.insert($0.id) }
            
            if !matchingStrava.isEmpty || !matchingHealth.isEmpty {
                print("🔗 [Deduplication] Intervals activity '\(activity.name)' matched:")
                print("     Strava: \(matchingStrava.count), Health: \(matchingHealth.count)")
            }
        }
        
        // PRIORITY 2: Strava activities (power + HR data, but no TSS/IF)
        // Only add if not already in Intervals.icu
        for activity in stravaActivities where !processedActivities.contains(activity.id) {
            let matchingHealth = findMatchingActivities(activity, in: appleHealthActivities)
            matchingHealth.forEach { processedActivities.insert($0.id) }
            
            result.append(activity)
            processedActivities.insert(activity.id)
            
            if !matchingHealth.isEmpty {
                print("🔗 [Deduplication] Strava activity '\(activity.name)' matched:")
                print("     Health: \(matchingHealth.count)")
            }
        }
        
        // PRIORITY 3: Apple Health workouts (basic data only)
        // Only add if not already in Intervals.icu or Strava
        for activity in appleHealthActivities where !processedActivities.contains(activity.id) {
            result.append(activity)
            processedActivities.insert(activity.id)
        }
        
        // Sort by date (newest first)
        result.sort { $0.startDate > $1.startDate }
        
        print("✅ [Deduplication] Result: \(result.count) unique activities")
        print("   Removed \(intervalsActivities.count + stravaActivities.count + appleHealthActivities.count - result.count) duplicates")
        
        return result
    }
    
    // MARK: - Private Helpers
    
    /// Find activities that match the given activity (likely the same workout)
    private func findMatchingActivities(_ target: UnifiedActivity, in activities: [UnifiedActivity]) -> [UnifiedActivity] {
        return activities.filter { candidate in
            areActivitiesDuplicates(target, candidate)
        }
    }
    
    /// Determine if two activities are likely duplicates
    /// Uses multiple heuristics: time, duration, distance, type
    private func areActivitiesDuplicates(_ a: UnifiedActivity, _ b: UnifiedActivity) -> Bool {
        // Same source = can't be duplicate
        if a.source == b.source {
            return false
        }
        
        // Check if start times are within 2 hours of each other
        // (increased to handle timezone issues - Intervals stores local time, Strava stores UTC)
        let timeDifference = abs(a.startDate.timeIntervalSince(b.startDate))
        
        guard timeDifference < 7200 else { // 2 hours (to handle timezone differences)
            return false
        }
        
        // Different types = probably not duplicate
        // BUT allow Other to match any type (Intervals often marks Strava activities as Other)
        if a.type != b.type {
            // Allow "Other" to match anything
            if a.type != .other && b.type != .other {
                return false
            }
        }
        
        // If both have duration, check if they're similar (within 10%)
        if let durationA = a.duration, let durationB = b.duration {
            let durationDiff = abs(durationA - durationB)
            let avgDuration = (durationA + durationB) / 2
            if avgDuration > 0 && (durationDiff / avgDuration) > 0.10 {
                return false
            }
        }
        
        // If both have distance, check if they're similar (within 10%)
        if let distanceA = a.distance, let distanceB = b.distance {
            let distanceDiff = abs(distanceA - distanceB)
            let avgDistance = (distanceA + distanceB) / 2
            if avgDistance > 0 && (distanceDiff / avgDistance) > 0.10 {
                return false
            }
        }
        
        // All checks passed - likely a duplicate
        #if DEBUG
        print("🔗 [Deduplication] Match found:")
        print("   A: \(a.name) (\(a.source.displayName)) - \(a.type.rawValue)")
        print("   B: \(b.name) (\(b.source.displayName)) - \(b.type.rawValue)")
        print("   Time diff: \(Int(timeDifference))s")
        #endif
        
        return true
    }
    
    /// Get the "best" activity from a set of duplicates
    /// Prioritizes Intervals.icu > Strava > Apple Health
    func selectBestActivity(from duplicates: [UnifiedActivity]) -> UnifiedActivity? {
        guard !duplicates.isEmpty else { return nil }
        
        // Prefer Intervals.icu (has TSS, IF, and other computed metrics)
        if let intervalsActivity = duplicates.first(where: { $0.source == .intervalsICU }) {
            return intervalsActivity
        }
        
        // Next prefer Strava (has power, HR, and detailed metrics)
        if let stravaActivity = duplicates.first(where: { $0.source == .strava }) {
            return stravaActivity
        }
        
        // Fall back to Apple Health
        return duplicates.first(where: { $0.source == .appleHealth })
    }
    
    /// Merge data from multiple sources for the same activity
    /// Takes the best data from each source
    func mergeActivities(_ activities: [UnifiedActivity]) -> UnifiedActivity? {
        guard let primary = selectBestActivity(from: activities) else {
            return nil
        }
        
        // TODO: Future enhancement - merge partial data
        // For now, just return the best activity
        // In the future, could merge:
        // - Use Intervals TSS if available, otherwise calculate from Strava power
        // - Use Strava detailed HR zones if Intervals doesn't have them
        // - etc.
        
        return primary
    }
}

// MARK: - Data Source Priority

extension ActivityDeduplicationService {
    /// Determine which source should be primary for a given data type
    enum DataPriority {
        case power
        case heartRate
        case metrics // TSS, IF, etc.
        case wellness
        
        /// Get the preferred source for this data type
        func preferredSource(from sources: [UnifiedActivity.ActivitySource]) -> UnifiedActivity.ActivitySource? {
            switch self {
            case .power:
                // Intervals.icu has better power analysis
                if sources.contains(.intervalsICU) { return .intervalsICU }
                if sources.contains(.strava) { return .strava }
                return nil
                
            case .heartRate:
                // Strava often has more detailed HR data
                if sources.contains(.strava) { return .strava }
                if sources.contains(.intervalsICU) { return .intervalsICU }
                if sources.contains(.appleHealth) { return .appleHealth }
                return nil
                
            case .metrics:
                // Only Intervals.icu provides TSS, IF, CTL, ATL
                if sources.contains(.intervalsICU) { return .intervalsICU }
                return nil
                
            case .wellness:
                // Apple Health is best for wellness data
                if sources.contains(.appleHealth) { return .appleHealth }
                if sources.contains(.intervalsICU) { return .intervalsICU }
                return nil
            }
        }
    }
}
