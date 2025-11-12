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
            .navigationTitle(TodayContent.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: Icons.Status.successFill)
                    .foregroundColor(Color.semantic.success)
                Text(DebugContent.Today.debugMode)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                Text(DebugContent.Today.usingRealData)
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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(DebugContent.Today.recentActivities)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(DebugContent.Today.activityData)
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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(CommonContent.Sections.healthData)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(CommonContent.Debug.healthDataDisplayed)
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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(CommonContent.Sections.wellnessData)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(CommonContent.Debug.wellnessDataDisplayed)
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
    let activity: MockActivity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(activity.name ?? "Unnamed Activity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.type ?? "Unknown Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xs) {
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
            
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
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
