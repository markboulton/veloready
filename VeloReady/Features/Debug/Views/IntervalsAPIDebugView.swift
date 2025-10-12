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
                    Text("Intervals.icu API Inspector")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Inspect raw API responses to debug missing data")
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
                        Image(systemName: "arrow.clockwise")
                        Text("Fetch Fresh Data")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView("Fetching data...")
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
        .navigationTitle("API Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Athlete Profile Section
    
    private var athleteProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Athlete Profile")
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
                    Text("Basic Information")
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
            Text("No athlete data loaded")
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
        Text("Power Zones")
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.top, 4)
        
        if let powerZones = athlete.powerZones {
            DebugFieldRow(label: "FTP", value: "\(powerZones.ftp ?? 0) W")
            DebugFieldRow(label: "Zone Boundaries", value: "\(powerZones.zones?.count ?? 0)")
            
            if let zones = powerZones.zones {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, boundary in
                    HStack {
                        Text("Boundary \(index + 1)")
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
            Text("❌ Power zones are NIL")
                .font(.caption)
                .foregroundColor(ColorScale.redAccent)
        }
    }
    
    @ViewBuilder
    private func heartRateZonesSection(athlete: IntervalsAthlete) -> some View {
        Text("Heart Rate Zones")
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.top, 4)
        
        if let hrZones = athlete.heartRateZones {
            DebugFieldRow(label: "Max HR", value: "\(hrZones.maxHr ?? 0) bpm")
            DebugFieldRow(label: "Zone Boundaries", value: "\(hrZones.zones?.count ?? 0)")
            
            if let zones = hrZones.zones {
                ForEach(Array(zones.enumerated()), id: \.offset) { index, boundary in
                    HStack {
                        Text("Boundary \(index + 1)")
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
            Text("❌ Heart rate zones are NIL")
                .font(.caption)
                .foregroundColor(ColorScale.redAccent)
        }
    }
    
    // MARK: - Activities Section
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activities (5)")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if !viewModel.activities.isEmpty {
                ForEach(viewModel.activities.prefix(5)) { activity in
                    ActivityDebugCard(activity: activity)
                        .padding(.horizontal)
                }
            } else if !viewModel.isLoading {
                Text("No activities loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Raw JSON Section
    
    private var rawJSONSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raw JSON Responses")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if let athleteJSON = viewModel.athleteRawJSON {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Athlete Profile JSON")
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
                    Text("Activities JSON (first 1000 chars)")
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
        
        print("🔍 ========== INTERVALS API DEBUG: FETCHING DATA ==========")
        
        // Fetch athlete data
        do {
            print("🔍 Fetching athlete profile...")
            let athlete = try await fetchAthleteWithRawJSON(apiClient: apiClient)
            self.athleteData = athlete
            
            print("🔍 ========== ATHLETE DATA RECEIVED ==========")
            print("🔍 BASIC INFORMATION:")
            print("🔍   ID: \(athlete.id)")
            print("🔍   Name: \(athlete.name ?? "❌ nil")")
            print("🔍   Email: \(athlete.email ?? "❌ nil")")
            print("🔍   Profile Picture: \(athlete.profileMedium ?? "❌ nil")")
            print("🔍   Sex: \(athlete.sex ?? "❌ nil")")
            print("🔍   City: \(athlete.city ?? "❌ nil")")
            print("🔍   State: \(athlete.state ?? "❌ nil")")
            print("🔍   Country: \(athlete.country ?? "❌ nil")")
            print("🔍   Timezone: \(athlete.timezone ?? "❌ nil")")
            print("🔍   Bio: \(athlete.bio ?? "❌ nil")")
            print("🔍   Website: \(athlete.website ?? "❌ nil")")
            print("🔍")
            print("🔍 POWER ZONES: \(athlete.powerZones != nil ? "✅ Present" : "❌ NIL")")
            if let powerZones = athlete.powerZones {
                print("🔍   - FTP: \(powerZones.ftp ?? 0) W")
                print("🔍   - Zone boundaries: \(powerZones.zones?.count ?? 0)")
                if let zones = powerZones.zones {
                    print("🔍   - Boundaries: \(zones.map { Int($0) })")
                }
            }
            print("🔍")
            print("🔍 HEART RATE ZONES: \(athlete.heartRateZones != nil ? "✅ Present" : "❌ NIL")")
            if let hrZones = athlete.heartRateZones {
                print("🔍   - Max HR: \(hrZones.maxHr ?? 0) bpm")
                print("🔍   - Zone boundaries: \(hrZones.zones?.count ?? 0)")
                if let zones = hrZones.zones {
                    print("🔍   - Boundaries: \(zones.map { Int($0) })")
                }
            }
            print("🔍 ================================================")
            
        } catch {
            print("🔍 ❌ Failed to fetch athlete: \(error)")
        }
        
        // Fetch activities
        do {
            print("🔍 Fetching recent activities...")
            let activities = try await fetchActivitiesWithRawJSON(apiClient: apiClient)
            self.activities = activities
            
            print("🔍 ========== ACTIVITIES DATA RECEIVED ==========")
            print("🔍 Total activities: \(activities.count)")
            
            for (index, activity) in activities.prefix(5).enumerated() {
                print("🔍 Activity \(index + 1): \(activity.name ?? "Unnamed")")
                print("🔍   - ID: \(activity.id)")
                print("🔍   - Type: \(activity.type ?? "nil")")
                print("🔍   - Duration: \(activity.duration != nil ? "\(activity.duration!)s" : "NIL ❌")")
                print("🔍   - Distance: \(activity.distance != nil ? "\(activity.distance!)m" : "NIL ❌")")
                print("🔍   - Avg Power: \(activity.averagePower != nil ? "\(activity.averagePower!)W" : "NIL ❌")")
                print("🔍   - Norm Power: \(activity.normalizedPower != nil ? "\(activity.normalizedPower!)W" : "NIL ❌")")
                print("🔍   - Avg HR: \(activity.averageHeartRate != nil ? "\(activity.averageHeartRate!)bpm" : "NIL ❌")")
                print("🔍   - Max HR: \(activity.maxHeartRate != nil ? "\(activity.maxHeartRate!)bpm" : "NIL ❌")")
                print("🔍   - Avg Speed: \(activity.averageSpeed != nil ? "\(activity.averageSpeed!)km/h" : "NIL ❌")")
                print("🔍   - Avg Cadence: \(activity.averageCadence != nil ? "\(activity.averageCadence!)rpm" : "NIL ❌")")
                print("🔍   - Elevation: \(activity.elevationGain != nil ? "\(activity.elevationGain!)m" : "NIL ❌")")
                print("🔍   - TSS: \(activity.tss != nil ? "\(activity.tss!)" : "NIL ❌")")
                print("🔍   - IF: \(activity.intensityFactor != nil ? "\(activity.intensityFactor!)" : "NIL ❌")")
                print("🔍   ")
                print("🔍   ATHLETE DATA (at time of activity):")
                print("🔍   - FTP: \(activity.icuFtp != nil ? "\(Int(activity.icuFtp!))W ✅" : "NIL ❌")")
                print("🔍   - Power Zones: \(activity.icuPowerZones != nil ? "\(activity.icuPowerZones!.map { Int($0) }) ✅" : "NIL ❌")")
                print("🔍   - HR Zones: \(activity.icuHrZones != nil ? "\(activity.icuHrZones!.map { Int($0) }) ✅" : "NIL ❌")")
                print("🔍   - LTHR: \(activity.lthr != nil ? "\(Int(activity.lthr!))bpm ✅" : "NIL ❌")")
                print("🔍   - Resting HR: \(activity.icuRestingHr != nil ? "\(Int(activity.icuRestingHr!))bpm ✅" : "NIL ❌")")
                print("🔍   - Weight: \(activity.icuWeight != nil ? "\(activity.icuWeight!)kg ✅" : "NIL ❌")")
                print("🔍   - Max HR: \(activity.athleteMaxHr != nil ? "\(Int(activity.athleteMaxHr!))bpm ✅" : "NIL ❌")")
                print("🔍   ---")
            }
            print("🔍 ================================================")
            
        } catch {
            print("🔍 ❌ Failed to fetch activities: \(error)")
        }
        
        isLoading = false
    }
    
    private func fetchAthleteWithRawJSON(apiClient: IntervalsAPIClient) async throws -> IntervalsAthlete {
        // Use athlete ID 0 which returns current authenticated user
        // Use /profile endpoint to get zones and detailed metrics
        let url = URL(string: "https://intervals.icu/api/v1/athlete/0/profile")!
        var request = URLRequest(url: url)
        request.setValue(apiClient.getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        print("🔍 Fetching from URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Store raw JSON and print FULL response
        if let jsonString = String(data: data, encoding: .utf8) {
            self.athleteRawJSON = jsonString
            print("🔍 ========== FULL ATHLETE PROFILE JSON ==========")
            print(jsonString)
            print("🔍 ================================================")
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
        
        print("🔍 Fetching from URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 HTTP Status: \(httpResponse.statusCode)")
        }
        
        // Store raw JSON and print FULL response
        if let jsonString = String(data: data, encoding: .utf8) {
            self.activitiesRawJSON = jsonString
            print("🔍 ========== FULL ACTIVITIES JSON ==========")
            print(jsonString)
            print("🔍 ==========================================")
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
