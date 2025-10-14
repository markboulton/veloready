import SwiftUI

/// Shared activity row view used in both Today and Activities list
struct SharedActivityRowView: View {
    let activity: UnifiedActivity
    
    var body: some View {
        HStack(spacing: 0) {
            // Activity Details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(formatDate(activity.startDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let duration = activity.duration {
                        Text("•").foregroundColor(.secondary)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let distance = activity.distance {
                        Text("•").foregroundColor(.secondary)
                        Text(formatDistance(distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Show chevron for all tappable activities
            if activity.intervalsActivity != nil || activity.stravaActivity != nil || activity.healthKitWorkout != nil {
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.1f km", km)
    }
}
