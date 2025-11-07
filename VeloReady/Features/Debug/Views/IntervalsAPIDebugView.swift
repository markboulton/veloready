import SwiftUI

/// Debug view to inspect raw Intervals.icu API data
struct IntervalsAPIDebugView: View {
    @StateObject private var viewModel = IntervalsAPIDebugViewModel()
    @EnvironmentObject private var apiClient: IntervalsAPIClient
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(DebugContent.IntervalsAPI.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(DebugContent.IntervalsAPI.inspectResponses)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Fetch Button
                Button(action: {
                    Task {
                        await viewModel.fetchDebugData(apiClient: apiClient)
                    }
                }) {
                    HStack {
                        Image(systemName: Icons.Arrow.clockwise)
                        Text(DebugContent.IntervalsAPI.fetchFresh)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView(DebugContent.IntervalsAPI.fetching)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                // Athlete Profile Section
                athleteProfileSection
                
                // Activities Section
                activitiesSection
                
                // Raw JSON Section
                rawJSONSection
            }
            .padding(.bottom)
        }
        .background(Color.background.primary)
        .navigationTitle(DebugContent.Navigation.apiDebug)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Athlete Profile Section
    
    private var athleteProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DebugContent.IntervalsAPI.athleteProfile)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            athleteProfileContent
        }
    }
    
    @ViewBuilder
    private var athleteProfileContent: some View {
        if let athlete = viewModel.athleteData {
            VStack(alignment: .leading, spacing: 12) {
                // Basic Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(DebugContent.IntervalsAPI.basicInfo)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    DebugFieldRow(label: "ID", value: athlete.id)
                    DebugFieldRow(label: "Name", value: formatOptionalString(athlete.name))
                    DebugFieldRow(label: "Email", value: formatOptionalString(athlete.email))
                    DebugFieldRow(label: "Profile Picture URL", value: formatOptionalString(athlete.profileMedium))
                    DebugFieldRow(label: "Sex", value: formatOptionalString(athlete.sex))
                    DebugFieldRow(label: "City", value: formatOptionalString(athlete.city))
                    DebugFieldRow(label: "State", value: formatOptionalString(athlete.state))
                    DebugFieldRow(label: "Country", value: formatOptionalString(athlete.country))
                    DebugFieldRow(label: "Timezone", value: formatOptionalString(athlete.timezone))
                    DebugFieldRow(label: "Bio", value: formatOptionalString(athlete.bio))
                    DebugFieldRow(label: "Website", value: formatOptionalString(athlete.website))
                }
                
                Divider()
                
                powerZonesSection(athlete: athlete)
                
                Divider()
                
                heartRateZonesSection(athlete: athlete)
            }
            .padding()
            .background(Color.background.secondary)
            .cornerRadius(12)
            .padding(.horizontal)
        } else if !viewModel.isLoading {
            Text(DebugContent.IntervalsAPI.noAthleteData)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    private func formatOptionalString(_ value: String?) -> String {
        if let value = value, !value.isEmpty {
            return "✅ \(value)"
        } else {
            return "❌ nil"
        }
    }
    
    @ViewBuilder
    private func powerZonesSection(athlete: IntervalsAthlete) -> some View {
        Text(DebugContent.IntervalsAPI.powerZones)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.top, 4)
        
        if let powerZones = athlete.powerZones {
            DebugFieldRow(label: "FTP", value: "\(powerZones.ftp ?? 0) W")
            DebugFieldRow(label: "Zone Boundaries", value: "\(powerZones.zones?.count ?? 0)")
            
            if let zones = powerZones.zones {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, boundary in
                    HStack {
                        Text("\(DebugContent.IntervalsAPI.boundary) \(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(boundary)) W")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.leading, 16)
                }
            }
        } else {
            Text(DebugContent.IntervalsAPI.powerZonesNil)
                .font(.caption)
                .foregroundColor(ColorScale.redAccent)
        }
    }
    
    @ViewBuilder
    private func heartRateZonesSection(athlete: IntervalsAthlete) -> some View {
        Text(DebugContent.IntervalsAPI.heartRateZones)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.top, 4)
        
        if let hrZones = athlete.heartRateZones {
            DebugFieldRow(label: "Max HR", value: "\(hrZones.maxHr ?? 0) bpm")
            DebugFieldRow(label: "Zone Boundaries", value: "\(hrZones.zones?.count ?? 0)")
            
            if let zones = hrZones.zones {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, boundary in
                    HStack {
                        Text("\(DebugContent.IntervalsAPI.boundary) \(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(boundary)) bpm")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.leading, 16)
                }
            }
        } else {
            Text(DebugContent.IntervalsAPI.hrZonesNil)
                .font(.caption)
                .foregroundColor(ColorScale.redAccent)
        }
    }
    
    // MARK: - Activities Section
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DebugContent.IntervalsAPI.recentActivities)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if !viewModel.activities.isEmpty {
                ForEach(viewModel.activities.prefix(5)) { activity in
                    ActivityDebugCard(activity: activity)
                        .padding(.horizontal)
                }
            } else if !viewModel.isLoading {
                Text(DebugContent.IntervalsAPI.noActivities)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Raw JSON Section
    
    private var rawJSONSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DebugContent.IntervalsAPI.rawJSON)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if let athleteJSON = viewModel.athleteRawJSON {
                VStack(alignment: .leading, spacing: 8) {
                    Text(DebugContent.IntervalsAPI.athleteProfileJSON)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(athleteJSON)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            
            if let activitiesJSON = viewModel.activitiesRawJSON {
                VStack(alignment: .leading, spacing: 8) {
                    Text(DebugContent.IntervalsAPI.activitiesJSON)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(String(activitiesJSON.prefix(1000)))
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Activity Debug Card

struct ActivityDebugCard: View {
    let activity: IntervalsActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(activity.name ?? "Unnamed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(activity.type ?? "Unknown")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.button.primary.opacity(0.2))
                    .cornerRadius(6)
            }
            
            // Date
            Text(activity.startDateLocal)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MetricDebugRow(label: "Duration", value: formatOptional(activity.duration, suffix: "s"))
                MetricDebugRow(label: "Distance", value: formatOptional(activity.distance, suffix: "m"))
                MetricDebugRow(label: "Avg Power", value: formatOptional(activity.averagePower, suffix: "W"))
                MetricDebugRow(label: "Norm Power", value: formatOptional(activity.normalizedPower, suffix: "W"))
                MetricDebugRow(label: "Avg HR", value: formatOptional(activity.averageHeartRate, suffix: "bpm"))
                MetricDebugRow(label: "Max HR", value: formatOptional(activity.maxHeartRate, suffix: "bpm"))
                MetricDebugRow(label: "Avg Speed", value: formatOptional(activity.averageSpeed, suffix: "km/h"))
                MetricDebugRow(label: "Max Speed", value: formatOptional(activity.maxSpeed, suffix: "km/h"))
                MetricDebugRow(label: "Avg Cadence", value: formatOptional(activity.averageCadence, suffix: "rpm"))
                MetricDebugRow(label: "Elevation", value: formatOptional(activity.elevationGain, suffix: "m"))
                MetricDebugRow(label: "TSS", value: formatOptional(activity.tss, suffix: ""))
                MetricDebugRow(label: "IF", value: formatOptional(activity.intensityFactor, suffix: ""))
            }
        }
        .padding()
        .background(Color.background.secondary)
        .cornerRadius(12)
    }
    
    private func formatOptional(_ value: Double?, suffix: String) -> String {
        guard let value = value else { return "❌ nil" }
        if value == 0 { return "⚠️ 0" }
        return "✅ \(String(format: "%.1f", value))\(suffix)"
    }
}

// MARK: - Helper Views

struct DebugFieldRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct MetricDebugRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - View Model

@MainActor
class IntervalsAPIDebugViewModel: ObservableObject {
    @Published var athleteData: IntervalsAthlete?
    @Published var activities: [IntervalsActivity] = []
    @Published var isLoading = false
    @Published var athleteRawJSON: String?
    @Published var activitiesRawJSON: String?
    
    func fetchDebugData(apiClient: IntervalsAPIClient) async {
        isLoading = true
        
        Logger.debug("🔍 ========== INTERVALS API DEBUG: FETCHING DATA ==========")
        
        // Fetch athlete data
        do {
            Logger.debug("🔍 Fetching athlete profile...")
            let athlete = try await fetchAthleteWithRawJSON(apiClient: apiClient)
            self.athleteData = athlete
            
            Logger.debug("🔍 ========== ATHLETE DATA RECEIVED ==========")
            Logger.debug("🔍 BASIC INFORMATION:")
            Logger.debug("🔍   ID: \(athlete.id)")
            Logger.debug("🔍   Name: \(athlete.name ?? "❌ nil")")
            Logger.debug("🔍   Email: \(athlete.email ?? "❌ nil")")
            Logger.debug("🔍   Profile Picture: \(athlete.profileMedium ?? "❌ nil")")
            Logger.debug("🔍   Sex: \(athlete.sex ?? "❌ nil")")
            Logger.debug("🔍   City: \(athlete.city ?? "❌ nil")")
            Logger.debug("🔍   State: \(athlete.state ?? "❌ nil")")
            Logger.debug("🔍   Country: \(athlete.country ?? "❌ nil")")
            Logger.debug("🔍   Timezone: \(athlete.timezone ?? "❌ nil")")
            Logger.debug("🔍   Bio: \(athlete.bio ?? "❌ nil")")
            Logger.debug("🔍   Website: \(athlete.website ?? "❌ nil")")
            Logger.debug("🔍")
            Logger.debug("🔍 POWER ZONES: \(athlete.powerZones != nil ? "✅ Present" : "❌ NIL")")
            if let powerZones = athlete.powerZones {
                Logger.debug("🔍   - FTP: \(powerZones.ftp ?? 0) W")
                Logger.debug("🔍   - Zone boundaries: \(powerZones.zones?.count ?? 0)")
                if let zones = powerZones.zones {
                    Logger.debug("🔍   - Boundaries: \(zones.map { Int($0) })")
                }
            }
            Logger.debug("🔍")
            Logger.debug("🔍 HEART RATE ZONES: \(athlete.heartRateZones != nil ? "✅ Present" : "❌ NIL")")
            if let hrZones = athlete.heartRateZones {
                Logger.debug("🔍   - Max HR: \(hrZones.maxHr ?? 0) bpm")
                Logger.debug("🔍   - Zone boundaries: \(hrZones.zones?.count ?? 0)")
                if let zones = hrZones.zones {
                    Logger.debug("🔍   - Boundaries: \(zones.map { Int($0) })")
                }
            }
            Logger.debug("🔍 ================================================")
            
        } catch {
            Logger.debug("🔍 ❌ Failed to fetch athlete: \(error)")
        }
        
        // Fetch activities
        do {
            Logger.debug("🔍 Fetching recent activities...")
            let activities = try await fetchActivitiesWithRawJSON(apiClient: apiClient)
            self.activities = activities
            
            Logger.debug("🔍 ========== ACTIVITIES DATA RECEIVED ==========")
            Logger.debug("🔍 Total activities: \(activities.count)")
            
            for (index, activity) in activities.prefix(5).enumerated() {
                Logger.debug("🔍 Activity \(index + 1): \(activity.name ?? "Unnamed")")
                Logger.debug("🔍   - ID: \(activity.id)")
                Logger.debug("🔍   - Type: \(activity.type ?? "nil")")
                Logger.debug("🔍   - Duration: \(activity.duration != nil ? "\(activity.duration!)s" : "NIL ❌")")
                Logger.debug("🔍   - Distance: \(activity.distance != nil ? "\(activity.distance!)m" : "NIL ❌")")
                Logger.debug("🔍   - Avg Power: \(activity.averagePower != nil ? "\(activity.averagePower!)W" : "NIL ❌")")
                Logger.debug("🔍   - Norm Power: \(activity.normalizedPower != nil ? "\(activity.normalizedPower!)W" : "NIL ❌")")
                Logger.debug("🔍   - Avg HR: \(activity.averageHeartRate != nil ? "\(activity.averageHeartRate!)bpm" : "NIL ❌")")
                Logger.debug("🔍   - Max HR: \(activity.maxHeartRate != nil ? "\(activity.maxHeartRate!)bpm" : "NIL ❌")")
                Logger.debug("🔍   - Avg Speed: \(activity.averageSpeed != nil ? "\(activity.averageSpeed!)km/h" : "NIL ❌")")
                Logger.debug("🔍   - Avg Cadence: \(activity.averageCadence != nil ? "\(activity.averageCadence!)rpm" : "NIL ❌")")
                Logger.debug("🔍   - Elevation: \(activity.elevationGain != nil ? "\(activity.elevationGain!)m" : "NIL ❌")")
                Logger.debug("🔍   - TSS: \(activity.tss != nil ? "\(activity.tss!)" : "NIL ❌")")
                Logger.debug("🔍   - IF: \(activity.intensityFactor != nil ? "\(activity.intensityFactor!)" : "NIL ❌")")
                Logger.debug("🔍   ")
                Logger.debug("🔍   ATHLETE DATA (at time of activity):")
                Logger.debug("🔍   - FTP: \(activity.icuFtp != nil ? "\(Int(activity.icuFtp!))W ✅" : "NIL ❌")")
                Logger.debug("🔍   - Power Zones: \(activity.icuPowerZones != nil ? "\(activity.icuPowerZones!.map { Int($0) }) ✅" : "NIL ❌")")
                Logger.debug("🔍   - HR Zones: \(activity.icuHrZones != nil ? "\(activity.icuHrZones!.map { Int($0) }) ✅" : "NIL ❌")")
                Logger.debug("🔍   - LTHR: \(activity.lthr != nil ? "\(Int(activity.lthr!))bpm ✅" : "NIL ❌")")
                Logger.debug("🔍   - Resting HR: \(activity.icuRestingHr != nil ? "\(Int(activity.icuRestingHr!))bpm ✅" : "NIL ❌")")
                Logger.debug("🔍   - Weight: \(activity.icuWeight != nil ? "\(activity.icuWeight!)kg ✅" : "NIL ❌")")
                Logger.debug("🔍   - Max HR: \(activity.athleteMaxHr != nil ? "\(Int(activity.athleteMaxHr!))bpm ✅" : "NIL ❌")")
                Logger.debug("🔍   ---")
            }
            Logger.debug("🔍 ================================================")
            
        } catch {
            Logger.debug("🔍 ❌ Failed to fetch activities: \(error)")
        }
        
        isLoading = false
    }
    
    private func fetchAthleteWithRawJSON(apiClient: IntervalsAPIClient) async throws -> IntervalsAthlete {
        // Use athlete ID 0 which returns current authenticated user
        // Use /profile endpoint to get zones and detailed metrics
        let url = URL(string: "https://intervals.icu/api/v1/athlete/0/profile")!
        var request = URLRequest(url: url)
        request.setValue(apiClient.getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        Logger.debug("🔍 Fetching from URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            Logger.debug("🔍 HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Store raw JSON and print FULL response
        if let jsonString = String(data: data, encoding: .utf8) {
            self.athleteRawJSON = jsonString
            Logger.debug("🔍 ========== FULL ATHLETE PROFILE JSON ==========")
            print(jsonString)
            Logger.debug("🔍 ================================================")
        }
        
        // The /profile endpoint returns a wrapper object with athlete nested inside
        let profile = try JSONDecoder().decode(IntervalsAthleteProfile.self, from: data)
        return profile.athlete
    }
    
    private func fetchActivitiesWithRawJSON(apiClient: IntervalsAPIClient) async throws -> [IntervalsActivity] {
        // Use athlete ID 0 which returns current authenticated user
        // Add oldest parameter (30 days back)
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let oldestDate = dateFormatter.string(from: thirtyDaysAgo)
        
        let url = URL(string: "https://intervals.icu/api/v1/athlete/0/activities?limit=5&oldest=\(oldestDate)")!
        var request = URLRequest(url: url)
        request.setValue(apiClient.getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        Logger.debug("🔍 Fetching from URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            Logger.debug("🔍 HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Store raw JSON and print FULL response
        if let jsonString = String(data: data, encoding: .utf8) {
            self.activitiesRawJSON = jsonString
            Logger.debug("🔍 ========== FULL ACTIVITIES JSON ==========")
            print(jsonString)
            Logger.debug("🔍 ==========================================")
        }
        
        let activities = try JSONDecoder().decode([IntervalsActivity].self, from: data)
        return activities
    }
}

#Preview {
    NavigationStack {
        IntervalsAPIDebugView()
            .environmentObject(IntervalsAPIClient.shared)
    }
}
