import SwiftUI

struct DebugTodayView: View {
    @StateObject private var mockHealthData = MockHealthData()
    @StateObject private var mockIntervalsData = MockIntervalsData()
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Header
                    statusHeader
                    
                    // Recent Activities
                    recentActivitiesSection
                    
                    // Health Data
                    healthDataSection
                    
                    // Wellness Data
                    wellnessDataSection
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.semantic.success)
                Text("Debug Mode Active")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                Text("Using Real Data from HealthKit and Intervals.icu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Activities Section
    
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activities")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Activity data displayed in main Today view")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Health Data Section
    
    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Health data displayed in main Today view")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Wellness Data Section
    
    private var wellnessDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wellness Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Wellness data displayed in main Today view")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct ActivityRowView: View {
    let activity: MockIntervalsActivity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name ?? "Unnamed Activity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.type ?? "Unknown Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(activity.duration ?? 0, specifier: "%.0f") min")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let distance = activity.distance {
                    Text("\(distance, specifier: "%.1f") km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct HealthDataRowView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct DebugTodayView_Previews: PreviewProvider {
    static var previews: some View {
        DebugTodayView()
    }
}
