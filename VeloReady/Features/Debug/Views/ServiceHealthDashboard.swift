import SwiftUI

/// Debug view showing service health and status
/// Provides visibility into ServiceContainer state
struct ServiceHealthDashboard: View {
    @State private var health: ServiceHealth = ServiceContainer.shared.healthCheck()
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            List {
                // Overall Health
                overallHealthSection
                
                // Data Sources
                dataSourcesSection
                
                // Registered ViewModels
                viewModelsSection
                
                // Actions
                actionsSection
            }
            .navigationTitle(DebugContent.Navigation.serviceHealth)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                startRefresh()
            }
            .onDisappear {
                stopRefresh()
            }
        }
    }
    
    // MARK: - Sections
    
    private var overallHealthSection: some View {
        Section("Overall Status") {
            HStack {
                Image(systemName: health.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(health.isHealthy ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(health.isHealthy ? "Healthy" : "Issues Detected")
                        .font(.heading)
                    
                    Text("\(health.connectedDataSources)/3 data sources connected")
                        .captionStyle()
                }
                
                Spacer()
            }
        }
    }
    
    private var dataSourcesSection: some View {
        Section("Data Sources") {
            StatRow(
                label: "HealthKit",
                value: health.healthKitAuthorized ? "Connected" : "Not Connected",
                valueColor: health.healthKitAuthorized ? .green : .red,
                icon: "heart.fill"
            )
            
            StatRow(
                label: "Intervals.icu",
                value: health.intervalsConnected ? "Connected" : "Not Connected",
                valueColor: health.intervalsConnected ? .green : .gray,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            StatRow(
                label: "Strava",
                value: health.stravaConnected ? "Connected" : "Not Connected",
                valueColor: health.stravaConnected ? .green : .gray,
                icon: "figure.outdoor.cycle"
            )
        }
    }
    
    private var viewModelsSection: some View {
        Section("Registered ViewModels") {
            let viewModels = ServiceContainer.shared.registeredViewModels
            
            if viewModels.isEmpty {
                Text("No ViewModels registered")
                    .captionStyle()
            } else {
                ForEach(viewModels, id: \.self) { key in
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text(key)
                            .font(.body)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        Section("Actions") {
            Button(action: {
                ServiceContainer.shared.clearAllCaches()
            }) {
                Label("Clear All Caches", systemImage: "trash")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                Task {
                    await ServiceContainer.shared.warmUp()
                }
            }) {
                Label("Warm Up Services", systemImage: "flame")
                    .foregroundColor(.orange)
            }
            
            Button(action: {
                health = ServiceContainer.shared.healthCheck()
            }) {
                Label("Refresh Status", systemImage: "arrow.clockwise")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func startRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            health = ServiceContainer.shared.healthCheck()
        }
    }
    
    private func stopRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

#Preview {
    ServiceHealthDashboard()
}
