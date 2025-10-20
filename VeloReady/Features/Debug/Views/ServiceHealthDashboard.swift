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
        Section(DebugContent.ServiceHealthExtended.overallStatus) {
            HStack {
                Image(systemName: health.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(health.isHealthy ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(health.isHealthy ? DebugContent.ServiceHealthExtended.healthy : DebugContent.ServiceHealthExtended.issuesDetected)
                        .font(.heading)
                    
                    Text("\(health.connectedDataSources)/3 " + DebugContent.ServiceHealthExtended.dataSourcesConnected)
                        .captionStyle()
                }
                
                Spacer()
            }
        }
    }
    
    private var dataSourcesSection: some View {
        Section(DebugContent.ServiceHealthExtended.dataSources) {
            StatRow(
                label: DebugContent.ServiceHealthExtended.healthKit,
                value: health.healthKitAuthorized ? DebugContent.ServiceHealthExtended.connected : DebugContent.ServiceHealthExtended.notConnected,
                valueColor: health.healthKitAuthorized ? .green : .red,
                icon: "heart.fill"
            )
            
            StatRow(
                label: DebugContent.ServiceHealthExtended.intervalsIcu,
                value: health.intervalsConnected ? DebugContent.ServiceHealthExtended.connected : DebugContent.ServiceHealthExtended.notConnected,
                valueColor: health.intervalsConnected ? .green : .gray,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            StatRow(
                label: DebugContent.ServiceHealthExtended.strava,
                value: health.stravaConnected ? DebugContent.ServiceHealthExtended.connected : DebugContent.ServiceHealthExtended.notConnected,
                valueColor: health.stravaConnected ? .green : .gray,
                icon: "figure.outdoor.cycle"
            )
        }
    }
    
    private var viewModelsSection: some View {
        Section(DebugContent.ServiceHealthExtended.registeredViewModels) {
            let viewModels = ServiceContainer.shared.registeredViewModels
            
            if viewModels.isEmpty {
                Text(DebugContent.ServiceHealthExtended.noViewModels)
                    .captionStyle()
            } else {
                ForEach(viewModels, id: \.self) { key in
                    HStack {
                        Image(systemName: Icons.System.docText)
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
        Section(DebugContent.ServiceHealthExtended.actions) {
            Button(action: {
                ServiceContainer.shared.clearAllCaches()
            }) {
                Label(DebugContent.ServiceHealthExtended.clearAllCaches, systemImage: "trash")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                Task {
                    await ServiceContainer.shared.warmUp()
                }
            }) {
                Label(DebugContent.ServiceHealthExtended.warmUpServices, systemImage: "flame")
                    .foregroundColor(.orange)
            }
            
            Button(action: {
                health = ServiceContainer.shared.healthCheck()
            }) {
                Label(DebugContent.ServiceHealthExtended.refreshStatus, systemImage: "arrow.clockwise")
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
