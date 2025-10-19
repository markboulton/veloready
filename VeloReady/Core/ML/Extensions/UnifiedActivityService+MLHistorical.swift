import Foundation

/// Extension to UnifiedActivityService for ML historical data fetching
extension UnifiedActivityService {
    
    /// Fetch activities for a specific date range (for ML training data)
    /// - Parameters:
    ///   - startDate: Start date for activities
    ///   - endDate: End date for activities
    /// - Returns: Array of unified activities within the date range
    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [UnifiedActivity] {
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 90
        
        Logger.debug("📊 [ML] Fetching activities from \(startDate) to \(endDate) (\(daysDiff) days)")
        
        // Fetch activities using existing method
        let activities = try await fetchRecentActivities(limit: 1000, daysBack: daysDiff + 1)
        
        // Filter to date range
        let filtered = activities.filter { activity in
            guard let activityDate = parseDate(from: activity.startDateLocal) else { return false }
            return activityDate >= startDate && activityDate <= endDate
        }
        
        Logger.debug("📊 [ML] Found \(filtered.count) activities in date range")
        
        // Convert to unified activities
        return filtered.map { UnifiedActivity(from: $0) }
    }
    
    /// Parse activity date string
    private func parseDate(from dateString: String) -> Date? {
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
}
