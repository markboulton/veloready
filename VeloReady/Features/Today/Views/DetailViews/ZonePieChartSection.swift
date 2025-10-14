import SwiftUI
import Charts

/// Zone analysis pie charts for heart rate and power with free/pro versions
struct ZonePieChartSection: View {
    let activity: IntervalsActivity
    @StateObject private var profileManager = AthleteProfileManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @ObservedObject private var proConfig = ProFeatureConfig.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Heart Rate Zone Pie Chart
            heartRateZoneChart
            
            // Power Zone Pie Chart - only show if activity has power data
            if activity.icuZoneTimes != nil || (activity.averagePower ?? 0) > 0 {
                powerZoneChart
            }
            
            // Single Upgrade CTA (only show if not Pro)
            if !proConfig.hasProAccess {
                ProUpgradeCard(
                    content: .adaptiveZones,
                    showBenefits: true,
                    learnMore: .adaptiveZones
                )
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Heart Rate Zone Chart
    
    private var heartRateZoneChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(proConfig.hasProAccess ? "Adaptive HR Zones" : "Heart Rate Zones")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if proConfig.hasProAccess {
                // Pro version: Adaptive zones
                adaptiveHRZoneChart
            } else {
                // Free version: Intervals.icu zones (NO upgrade CTA here)
                freeHRZoneChart
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }
    
    private var adaptiveHRZoneChart: some View {
        VStack(spacing: 16) {
            // Pie chart
            if let zoneTimes = activity.icuHrZoneTimes,
               let totalDuration = activity.duration,
               totalDuration > 0 {
                
                Chart {
                    ForEach(Array(zip(zoneTimes.indices, zoneTimes)), id: \.0) { index, time in
                        if index < 7 && time > 0 {
                            SectorMark(
                                angle: .value("Time", time),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(hrZoneColor(index))
                            .opacity(hrZoneOpacity(index))
                        }
                    }
                }
                .frame(height: 200)
                
                // Zone legend with values
                VStack(spacing: 8) {
                    if let hrZones = profileManager.profile.hrZones {
                        ForEach(Array(hrZones.enumerated()), id: \.offset) { index, boundary in
                            if index < hrZones.count - 1 {
                                let nextBoundary = hrZones[index + 1]
                                let timeInZone = zoneTimes.count > index ? zoneTimes[index] : 0
                                
                                if timeInZone > 0 {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(hrZoneColor(index))
                                            .opacity(hrZoneOpacity(index))
                                            .frame(width: 16, height: 16)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Zone \(index + 1)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(hrZoneName(index))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 90, alignment: .leading)
                                        
                                        Text("\(Int(boundary)) - \(Int(nextBoundary)) bpm")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        Text(formatTime(timeInZone))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No heart rate data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
    }
    
    private var freeHRZoneChart: some View {
        VStack(spacing: 16) {
            // Pie chart with user-configured zones from Settings
            if let zoneTimes = activity.icuHrZoneTimes,
               let totalDuration = activity.duration,
               totalDuration > 0 {
                
                Chart {
                    ForEach(Array(zip(zoneTimes.indices, zoneTimes)), id: \.0) { index, time in
                        if index < 7 && time > 0 {
                            SectorMark(
                                angle: .value("Time", time),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(hrZoneColor(index))
                            .opacity(hrZoneOpacity(index))
                        }
                    }
                }
                .frame(height: 200)
                
                // Basic zone legend (no specific boundaries, just zones)
                VStack(spacing: 8) {
                    ForEach(0..<min(7, zoneTimes.count), id: \.self) { index in
                        let timeInZone = zoneTimes[index]
                        
                        if timeInZone > 0 {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(hrZoneColor(index))
                                    .opacity(hrZoneOpacity(index))
                                    .frame(width: 16, height: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Zone \(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(hrZoneName(index))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 90, alignment: .leading)
                                
                                Text(freeHRZoneBoundary(index))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 100, alignment: .leading)
                                
                                Spacer()
                                
                                Text(formatTime(timeInZone))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            
            // No upgrade CTA here - moved to bottom of section
        }
    }
    
    // MARK: - Power Zone Chart
    
    private var powerZoneChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(proConfig.hasProAccess ? "Adaptive Power Zones" : "Power Zones")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if proConfig.hasProAccess {
                // Pro version: Adaptive zones
                adaptivePowerZoneChart
            } else {
                // Free version: Intervals.icu zones (NO upgrade CTA here)
                freePowerZoneChart
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }
    
    private var adaptivePowerZoneChart: some View {
        VStack(spacing: 16) {
            
            // Pie chart
            if let zoneTimes = activity.icuZoneTimes,
               let totalDuration = activity.duration,
               totalDuration > 0 {
                
                Chart {
                    ForEach(Array(zip(zoneTimes.indices, zoneTimes)), id: \.0) { index, time in
                        if index < 7 && time > 0 {
                            SectorMark(
                                angle: .value("Time", time),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(powerZoneColor(index))
                            .opacity(powerZoneOpacity(index))
                        }
                    }
                }
                .frame(height: 200)
                
                // Zone legend with adaptive values
                VStack(spacing: 8) {
                    if let powerZones = profileManager.profile.powerZones {
                        ForEach(Array(powerZones.enumerated()), id: \.offset) { index, boundary in
                            if index < powerZones.count - 1 {
                                let nextBoundary = powerZones[index + 1]
                                let timeInZone = zoneTimes.count > index ? zoneTimes[index] : 0
                                
                                if timeInZone > 0 {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(powerZoneColor(index))
                                            .opacity(powerZoneOpacity(index))
                                            .frame(width: 16, height: 16)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Zone \(index + 1)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(powerZoneName(index))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 110, alignment: .leading)
                                        
                                        Text("\(Int(boundary)) - \(Int(nextBoundary)) W")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        Text(formatTime(timeInZone))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No power data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
    }
    
    private var freePowerZoneChart: some View {
        VStack(spacing: 16) {
            
            // Pie chart with user-configured zones from Settings
            if let zoneTimes = activity.icuZoneTimes,
               let totalDuration = activity.duration,
               totalDuration > 0 {
                
                Chart {
                    ForEach(Array(zip(zoneTimes.indices, zoneTimes)), id: \.0) { index, time in
                        if index < 7 && time > 0 {
                            SectorMark(
                                angle: .value("Time", time),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(powerZoneColor(index))
                            .opacity(powerZoneOpacity(index))
                        }
                    }
                }
                .frame(height: 200)
                
                // Basic zone legend (no specific boundaries, just zones)
                VStack(spacing: 8) {
                    ForEach(0..<min(7, zoneTimes.count), id: \.self) { index in
                        let timeInZone = zoneTimes[index]
                        
                        if timeInZone > 0 {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(powerZoneColor(index))
                                    .opacity(powerZoneOpacity(index))
                                    .frame(width: 16, height: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Zone \(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(powerZoneName(index))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 110, alignment: .leading)
                                
                                Text(freePowerZoneBoundary(index))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 100, alignment: .leading)
                                
                                Spacer()
                                
                                Text(formatTime(timeInZone))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            
            // No upgrade CTA here - moved to bottom of section
        }
    }
    
    // MARK: - Helper Functions
    
    private func hrZoneColor(_ index: Int) -> Color {
        // Use canonical color token for heart rate
        return Color.workout.heartRate
    }
    
    private func hrZoneOpacity(_ index: Int) -> Double {
        // Opacity gradient from Zone 1 to Zone 7 - using higher values for better visibility
        let opacities: [Double] = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]
        return opacities[min(index, opacities.count - 1)]
    }
    
    private func powerZoneColor(_ index: Int) -> Color {
        // Use canonical color token for power
        return Color.workout.power
    }
    
    private func powerZoneOpacity(_ index: Int) -> Double {
        // Opacity gradient from Zone 1 to Zone 7 - using higher values for better visibility
        let opacities: [Double] = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]
        return opacities[min(index, opacities.count - 1)]
    }
    
    private func hrZoneName(_ index: Int) -> String {
        let names = ["Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Max"]
        return names[index % names.count]
    }
    
    private func powerZoneName(_ index: Int) -> String {
        let names = ["Active Recovery", "Endurance", "Tempo", "Threshold", "VO2 Max", "Anaerobic", "Neuromuscular"]
        return names[index % names.count]
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    // MARK: - FREE User Zone Boundaries (from UserSettings)
    
    private func freeHRZoneBoundary(_ index: Int) -> String {
        switch index {
        case 0: return "≤ \(userSettings.hrZone1Max) bpm"
        case 1: return "\(userSettings.hrZone1Max + 1) - \(userSettings.hrZone2Max) bpm"
        case 2: return "\(userSettings.hrZone2Max + 1) - \(userSettings.hrZone3Max) bpm"
        case 3: return "\(userSettings.hrZone3Max + 1) - \(userSettings.hrZone4Max) bpm"
        case 4: return "\(userSettings.hrZone4Max + 1) - \(userSettings.hrZone5Max) bpm"
        case 5: return "> \(userSettings.hrZone5Max) bpm"
        default: return hrZoneName(index)
        }
    }
    
    private func freePowerZoneBoundary(_ index: Int) -> String {
        switch index {
        case 0: return "≤ \(userSettings.powerZone1Max) W"
        case 1: return "\(userSettings.powerZone1Max + 1) - \(userSettings.powerZone2Max) W"
        case 2: return "\(userSettings.powerZone2Max + 1) - \(userSettings.powerZone3Max) W"
        case 3: return "\(userSettings.powerZone3Max + 1) - \(userSettings.powerZone4Max) W"
        case 4: return "\(userSettings.powerZone4Max + 1) - \(userSettings.powerZone5Max) W"
        case 5: return "> \(userSettings.powerZone5Max) W"
        default: return powerZoneName(index)
        }
    }
}

#Preview {
    ScrollView {
        ZonePieChartSection(activity: IntervalsActivity(
            id: "1",
            name: "Test Ride",
            description: nil,
            startDateLocal: "2025-10-08T10:00:00",
            type: "cycling",
            duration: 3600,
            distance: 30000,
            elevationGain: 200,
            averagePower: 200,
            normalizedPower: 210,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averageCadence: 90,
            averageSpeed: 30,
            maxSpeed: 45,
            calories: 800,
            fileType: "fit",
            tss: 75,
            intensityFactor: 0.8,
            atl: 50,
            ctl: 60,
            icuZoneTimes: [300, 1200, 900, 450, 150, 0, 0],
            icuHrZoneTimes: [450, 1350, 900, 300, 0, 0, 0]
        ))
    }
    .padding()
}
