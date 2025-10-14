import SwiftUI

/// Latest ride panel showing the most recent activity
struct LatestRidePanel: View {
    let activity: IntervalsActivity
    
    var body: some View {
        NavigationLink(destination: RideDetailSheet(activity: activity)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bicycle")
                        .foregroundColor(.primary)
                        .font(.title2)
                    
                    Text(LatestRideContent.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                        .font(.caption)
                }
        
        // Activity name
        Text(activity.name ?? LatestRideContent.unnamedActivity)
            .font(.title2)
            .fontWeight(.bold)
        
        // Date and time
        if let startDate = parseActivityDate(activity.startDateLocal) {
            Text(formatActivityDate(startDate))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        
        // Stats row - all metrics in one consistent row
        HStack(alignment: .top, spacing: 20) {
                if let duration = activity.duration {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDuration(duration))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(LatestRideContent.Metrics.duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let distance = activity.distance {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(String(format: "%.1f", distance / 1000.0)) km")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(LatestRideContent.Metrics.distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let power = activity.normalizedPower {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(power)) W")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("NP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let tss = activity.tss {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(tss))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("TSS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func parseActivityDate(_ dateString: String) -> Date? {
        // Try ISO8601 first (with timezone)
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try local format without timezone (2025-10-02T06:11:37)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localFormatter.timeZone = TimeZone.current
        return localFormatter.date(from: dateString)
    }
    
    private func formatActivityDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    LatestRidePanel(activity: IntervalsActivity(
        id: "1",
        name: "2 x 10 min Threshold",
        description: "Threshold intervals",
        startDateLocal: "2025-10-03T18:30:00",
        type: "cycling",
        duration: 1200, // 20 minutes
        distance: 12.5,
        elevationGain: 150,
        averagePower: 280,
        normalizedPower: 290,
        averageHeartRate: 165,
        maxHeartRate: 175,
        averageCadence: 95,
        averageSpeed: 25.5,
        maxSpeed: 35.2,
        calories: 450,
        fileType: "fit",
        tss: 85.0,
        intensityFactor: 0.85,
        atl: 75.0,
        ctl: 85.0,
        icuZoneTimes: [120, 600, 360, 120, 0, 0, 0], // Power zones in seconds
        icuHrZoneTimes: [180, 720, 240, 60, 0, 0, 0] // HR zones in seconds
    ))
    .padding()
}
