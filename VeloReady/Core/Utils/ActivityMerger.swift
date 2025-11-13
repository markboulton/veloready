import Foundation

/// Merges activities from multiple sources (Strava, Intervals.icu, Wahoo, etc.) with deduplication
enum ActivityMerger {
    
    /// Merge Strava and other source activities, deduplicating by time/distance match
    /// Strava activities take priority for duplicates (more granular data)
    static func merge(
        strava: [StravaActivity],
        intervals: [Activity]
    ) -> [Activity] {
        Logger.debug("🔀 Merging activities: \(strava.count) Strava + \(intervals.count) other sources")
        
        // Convert Strava to unified format
        var merged = ActivityConverter.stravaToActivity(strava)
        Logger.debug("🔀 Converted \(merged.count) Strava activities to unified format")
        
        // Add activities from other sources that aren't duplicates
        var addedCount = 0
        for sourceActivity in intervals {
            if !isDuplicate(sourceActivity, in: merged) {
                merged.append(sourceActivity)
                addedCount += 1
            }
        }
        
        Logger.debug("🔀 Added \(addedCount) unique activities from other sources")
        Logger.debug("🔀 Total merged: \(merged.count) activities")
        
        // Sort by date (newest first)
        return merged.sorted { $0.startDateLocal > $1.startDateLocal }
    }
    
    /// Check if activity is a duplicate based on start time and distance
    /// Uses 5-minute time window and 1% distance tolerance
    private static func isDuplicate(
        _ activity: Activity,
        in activities: [Activity]
    ) -> Bool {
        // Parse dates from ISO8601 strings
        guard let activityDate = parseDate(activity.startDateLocal) else {
            return false
        }
        
        return activities.contains { existing in
            guard let existingDate = parseDate(existing.startDateLocal) else {
                return false
            }
            
            // Match by start time (within 5 minutes)
            let timeDiff = abs(existingDate.timeIntervalSince(activityDate))
            let timeMatch = timeDiff < 300 // 5 minutes
            
            // Match by distance (within 1% or both nil)
            var distanceMatch = false
            if let existingDist = existing.distance, let activityDist = activity.distance {
                let distDiff = abs(existingDist - activityDist)
                let tolerance = activityDist * 0.01 // 1%
                distanceMatch = distDiff < tolerance
            } else if existing.distance == nil && activity.distance == nil {
                distanceMatch = true // Both have no distance
            }
            
            // Match by duration (within 5% or both nil)
            var durationMatch = false
            if let existingDur = existing.duration, let activityDur = activity.duration {
                let durDiff = abs(existingDur - activityDur)
                let tolerance = activityDur * 0.05 // 5%
                durationMatch = durDiff < tolerance
            } else if existing.duration == nil && activity.duration == nil {
                durationMatch = true // Both have no duration
            }
            
            // Consider duplicate if time + (distance OR duration) match
            return timeMatch && (distanceMatch || durationMatch)
        }
    }
    
    /// Merge with detailed logging for debugging
    static func mergeWithLogging(
        strava: [StravaActivity],
        intervals: [Activity]
    ) -> [Activity] {
        Logger.info("🔀 ========== MERGING ACTIVITIES FROM MULTIPLE SOURCES ==========")
        Logger.info("🔀 Strava activities: \(strava.count)")
        Logger.info("🔀 Activities from other sources: \(intervals.count)")
        
        let merged = merge(strava: strava, intervals: intervals)
        
        Logger.info("🔀 Merged result: \(merged.count) unique activities")
        Logger.info("🔀 Deduplication removed \(strava.count + intervals.count - merged.count) duplicates")
        Logger.info("🔀 ================================================================")
        
        return merged
    }
    
    // MARK: - Helper Functions
    
    /// Parse ISO8601 date string to Date
    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
