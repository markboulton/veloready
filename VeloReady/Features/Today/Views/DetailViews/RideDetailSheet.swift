import SwiftUI
import Charts

/// Detailed ride analysis sheet showing comprehensive ride data, charts, and zone analysis
struct RideDetailSheet: View {
    let activity: IntervalsActivity
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RideDetailViewModel()
    @EnvironmentObject private var apiClient: IntervalsAPIClient
    @EnvironmentObject private var athleteZoneService: AthleteZoneService
    @StateObject private var profileManager = AthleteProfileManager.shared
    
    var body: some View {
        
        return WorkoutDetailView(
            activity: activity,
            viewModel: viewModel,
            ftp: profileManager.profile.ftp,
            maxHR: profileManager.profile.maxHR
        )
        .task {
            Logger.debug("🏁 RideDetailSheet: .task triggered - loading activity data")
            // Load activity data when view appears
            await viewModel.loadActivityData(
                activity: activity,
                apiClient: apiClient,
                profileManager: AthleteProfileManager.shared
            )
            
            Logger.debug("🏁 RideDetailSheet: Activity data loaded, checking athlete data")
            // Fetch athlete data if needed
            if athleteZoneService.shouldRefreshAthleteData {
                Logger.debug("🏁 RideDetailSheet: Fetching athlete data")
                await athleteZoneService.fetchAthleteData()
            } else {
                Logger.debug("🏁 RideDetailSheet: Athlete data is fresh, skipping fetch")
            }
            Logger.debug("🏁 RideDetailSheet: .task complete")
        }
    }
    
    // MARK: - Header Section
    
    private var rideHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Type
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(activity.name ?? "Unnamed Activity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    if let type = activity.type {
                        Text(type.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.button.primary)
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
            }
            
            // Date and Time
            if let startDate = parseActivityDate(activity.startDateLocal) {
                Text(formatActivityDate(startDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Key Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                RideMetricCard(
                    title: "Duration",
                    value: formatDuration(activity.duration ?? 0)
                )
                
                RideMetricCard(
                    title: "Distance",
                    value: formatDistance(activity.distance ?? 0)
                )
                
                RideMetricCard(
                    title: "Intensity",
                    value: activity.intensityFactor != nil ? formatIntensity(activity.intensityFactor!) : "N/A"
                )
                .opacity(activity.intensityFactor != nil ? 1.0 : 0.5)
                
                RideMetricCard(
                    title: "Load",
                    value: activity.tss != nil ? formatLoad(activity.tss!) : "N/A"
                )
                .opacity(activity.tss != nil ? 1.0 : 0.5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - HR Zone Chart Section
    
    private var hrZoneChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heart Rate Zones")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Real HR Zone Chart
            VStack(spacing: 12) {
                Text("HR Zone Distribution")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Real HR Zone Chart - Chronological time-based visualization like Strava/TrainingPeaks
                if let zoneTimes = activity.icuHrZoneTimes,
                   let totalDuration = activity.duration,
                   totalDuration > 0 {
                    
                    // Debug: Print zone data
                    let _ = print("🔍 HR Zone Data: \(zoneTimes), Total Duration: \(totalDuration)")
                    let _ = print("🔍 Activity ID: \(activity.id), Name: \(activity.name ?? "Unknown")")
                    
                    // Create chronological chart showing ride duration from start to finish
                    let chartWidth: CGFloat = UIScreen.main.bounds.width - 40 // Full width minus padding
                    
                    VStack(spacing: 8) {
                        // Main chart - horizontal bars showing chronological zone distribution
                        HStack(spacing: 0) {
                            ForEach(0..<min(5, zoneTimes.count), id: \.self) { zoneIndex in
                                let timeInZone = zoneTimes[zoneIndex]
                                let percentage = totalDuration > 0 ? timeInZone / totalDuration : 0
                                let width = max(CGFloat(percentage) * chartWidth, 0.5) // Minimum 0.5pt for visibility
                                
                                Rectangle()
                                    .fill(hrZoneColors[zoneIndex])
                                    .frame(width: width, height: 20)
                            }
                        }
                        .cornerRadius(2)
                        
                        // Zone legend with time spent (chronological order)
                        HStack(spacing: 12) {
                            ForEach(0..<min(5, zoneTimes.count), id: \.self) { zoneIndex in
                                let timeInZone = zoneTimes[zoneIndex]
                                if timeInZone > 0 {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(hrZoneColors[zoneIndex])
                                            .frame(width: 10, height: 10)
                                        Text("Z\(zoneIndex + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(Int(timeInZone/60))m")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Fallback: Show mock data for testing
                    let mockZoneTimes: [Double] = [180, 720, 240, 60, 0] // Mock HR zones in seconds
                    let mockDuration: Double = 1200 // 20 minutes
                    let chartWidth: CGFloat = UIScreen.main.bounds.width - 40
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            ForEach(0..<5, id: \.self) { zoneIndex in
                                let timeInZone = mockZoneTimes[zoneIndex]
                                let percentage = mockDuration > 0 ? timeInZone / mockDuration : 0
                                let width = max(CGFloat(percentage) * chartWidth, 0.5)
                                
                                Rectangle()
                                    .fill(hrZoneColors[zoneIndex])
                                    .frame(width: width, height: 20)
                            }
                        }
                        .cornerRadius(2)
                        .overlay(
                            Text("Mock HR Data")
                                .font(.caption2)
                                .foregroundColor(Color.development.mockDataIndicator)
                                .padding(2)
                                .background(Color.development.mockDataIndicator)
                                .cornerRadius(2),
                            alignment: .topTrailing
                        )
                        
                        HStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { zoneIndex in
                                let timeInZone = mockZoneTimes[zoneIndex]
                                if timeInZone > 0 {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(hrZoneColors[zoneIndex])
                                            .frame(width: 10, height: 10)
                                        Text("Z\(zoneIndex + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(Int(timeInZone/60))m")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Power Zone Chart Section
    
    private var powerZoneChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Power Zones")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Real Power Zone Chart based on actual data
            VStack(spacing: 12) {
                Text("Power Zone Distribution")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Real Power Zone Chart - Chronological time-based visualization like Strava/TrainingPeaks
                if let zoneTimes = activity.icuZoneTimes,
                   let totalDuration = activity.duration,
                   totalDuration > 0 {
                    
                    // Debug: Print zone data
                    let _ = print("🔍 Power Zone Data: \(zoneTimes), Total Duration: \(totalDuration)")
                    let _ = print("🔍 Activity ID: \(activity.id), Name: \(activity.name ?? "Unknown")")
                    
                    // Create chronological chart showing ride duration from start to finish
                    let chartWidth: CGFloat = UIScreen.main.bounds.width - 40 // Full width minus padding
                    
                    VStack(spacing: 8) {
                        // Main chart - horizontal bars showing chronological zone distribution
                        HStack(spacing: 0) {
                            ForEach(0..<min(5, zoneTimes.count), id: \.self) { zoneIndex in
                                let timeInZone = zoneTimes[zoneIndex]
                                let percentage = totalDuration > 0 ? timeInZone / totalDuration : 0
                                let width = max(CGFloat(percentage) * chartWidth, 0.5) // Minimum 0.5pt for visibility
                                
                                Rectangle()
                                    .fill(powerZoneColors[zoneIndex % powerZoneColors.count])
                                    .frame(width: width, height: 20)
                            }
                        }
                        .cornerRadius(2)
                        
                        // Zone legend with time spent (chronological order)
                        HStack(spacing: 12) {
                            ForEach(0..<min(5, zoneTimes.count), id: \.self) { zoneIndex in
                                let timeInZone = zoneTimes[zoneIndex]
                                if timeInZone > 0 {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(powerZoneColors[zoneIndex % powerZoneColors.count])
                                            .frame(width: 10, height: 10)
                                        Text("Z\(zoneIndex + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(Int(timeInZone/60))m")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Fallback: Show mock data for testing
                    let mockZoneTimes: [Double] = [120, 600, 360, 120, 0] // Mock power zones in seconds
                    let mockDuration: Double = 1200 // 20 minutes
                    let chartWidth: CGFloat = UIScreen.main.bounds.width - 40
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            ForEach(0..<5, id: \.self) { zoneIndex in
                                let timeInZone = mockZoneTimes[zoneIndex]
                                let percentage = mockDuration > 0 ? timeInZone / mockDuration : 0
                                let width = max(CGFloat(percentage) * chartWidth, 0.5)
                                
                                Rectangle()
                                    .fill(powerZoneColors[zoneIndex])
                                    .frame(width: width, height: 20)
                            }
                        }
                        .cornerRadius(2)
                        .overlay(
                            Text("Mock Power Data")
                                .font(.caption2)
                                .foregroundColor(Color.development.mockDataIndicator)
                                .padding(2)
                                .background(Color.development.mockDataIndicator)
                                .cornerRadius(2),
                            alignment: .topTrailing
                        )
                        
                        HStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { zoneIndex in
                                let timeInZone = mockZoneTimes[zoneIndex]
                                if timeInZone > 0 {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(powerZoneColors[zoneIndex])
                                            .frame(width: 10, height: 10)
                                        Text("Z\(zoneIndex + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(Int(timeInZone/60))m")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Time in Zone Tables Section
    
    private var timeInZoneTablesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time in Zones")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Heart Rate Zones Table
                timeInZoneTable(
                    title: "Heart Rate Zones",
                    zones: hrZoneData,
                    colorScheme: hrZoneColors
                )
                
                // Power Zones Table
                timeInZoneTable(
                    title: "Power Zones",
                    zones: powerZoneData,
                    colorScheme: powerZoneColors
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func timeInZoneTable(title: String, zones: [ZoneData], colorScheme: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                    HStack {
                        // Zone indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorScheme[index])
                                .frame(width: 16, height: 16)
                            
                            Text(zone.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Time and percentage
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(zone.time)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(zone.percentage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if index < zones.count - 1 {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Data Models
    
    private struct ZoneData {
        let name: String
        let time: String
        let percentage: String
    }
    
    // MARK: - Real Zone Data Processing
    
    private var hrZoneData: [ZoneData] {
        guard let zoneTimes = activity.icuHrZoneTimes,
              let totalDuration = activity.duration,
              totalDuration > 0 else {
            return defaultHrZoneData
        }
        
        return processZoneData(zoneTimes: zoneTimes, totalDuration: totalDuration, zoneType: .heartRate)
    }
    
    private var powerZoneData: [ZoneData] {
        guard let zoneTimes = activity.icuZoneTimes,
              let totalDuration = activity.duration,
              totalDuration > 0 else {
            return defaultPowerZoneData
        }
        
        return processZoneData(zoneTimes: zoneTimes, totalDuration: totalDuration, zoneType: .power)
    }
    
    private var defaultHrZoneData: [ZoneData] {
        [
            ZoneData(name: "Zone 1 (Recovery)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 2 (Endurance)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 3 (Tempo)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 4 (Threshold)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 5 (VO2 Max)", time: "0:00", percentage: "0%")
        ]
    }
    
    private var defaultPowerZoneData: [ZoneData] {
        [
            ZoneData(name: "Zone 1 (Active Recovery)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 2 (Endurance)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 3 (Tempo)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 4 (Threshold)", time: "0:00", percentage: "0%"),
            ZoneData(name: "Zone 5 (VO2 Max)", time: "0:00", percentage: "0%")
        ]
    }
    
    private enum ZoneType {
        case heartRate, power
    }
    
    private func processZoneData(zoneTimes: [Double], totalDuration: TimeInterval, zoneType: ZoneType) -> [ZoneData] {
        let zoneNames = zoneType == .heartRate ? hrZoneNames : powerZoneNames
        var processedZones: [ZoneData] = []
        
        // Process up to 5 zones (standard zones)
        for i in 0..<min(5, zoneTimes.count) {
            let timeInSeconds = zoneTimes[i]
            let percentage = totalDuration > 0 ? (timeInSeconds / totalDuration) * 100 : 0
            
            let zoneData = ZoneData(
                name: zoneNames[i],
                time: formatTimeFromSeconds(timeInSeconds),
                percentage: String(format: "%.0f%%", percentage)
            )
            processedZones.append(zoneData)
        }
        
        return processedZones
    }
    
    private var hrZoneNames: [String] {
        ["Zone 1 (Recovery)", "Zone 2 (Endurance)", "Zone 3 (Tempo)", "Zone 4 (Threshold)", "Zone 5 (VO2 Max)"]
    }
    
    private var powerZoneNames: [String] {
        ["Zone 1 (Active Recovery)", "Zone 2 (Endurance)", "Zone 3 (Tempo)", "Zone 4 (Threshold)", "Zone 5 (VO2 Max)"]
    }
    
    private func formatTimeFromSeconds(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private var hrZoneColors: [Color] {
        // Use canonical color token for all zones
        return Array(repeating: Color.workout.heartRate, count: 7)
    }
    
    private var powerZoneColors: [Color] {
        // Use canonical color token for all zones
        return Array(repeating: Color.workout.power, count: 7)
    }
    
    // MARK: - Helper Functions
    
    private func hrZoneColor(for index: Int) -> Color {
        return hrZoneColors[index % hrZoneColors.count]
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
        formatter.dateStyle = .full
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
    
    private func formatDistance(_ distance: Double) -> String {
        // Distance from Intervals.icu is in meters, convert to km
        return String(format: "%.1f km", distance / 1000.0)
    }
    
    private func formatIntensity(_ intensity: Double) -> String {
        return String(format: "%.2f", intensity)
    }
    
    private func formatLoad(_ load: Double) -> String {
        return String(format: "%.0f", load)
    }
}

// MARK: - Ride Metric Card

struct RideMetricCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    RideDetailSheet(activity: IntervalsActivity(
        id: "1",
        name: "2 x 10 min Threshold Intervals",
        description: "Threshold intervals with recovery",
        startDateLocal: "2025-10-03T18:30:00",
        type: "cycling",
        duration: 2400, // 40 minutes
        distance: 15.2,
        elevationGain: 180,
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
        icuZoneTimes: [180, 1200, 720, 360, 120, 0, 0], // Power zones in seconds
        icuHrZoneTimes: [300, 1080, 720, 360, 60, 0, 0] // HR zones in seconds
    ))
    .environmentObject(IntervalsAPIClient.shared)
    .environmentObject(AthleteZoneService())
}
