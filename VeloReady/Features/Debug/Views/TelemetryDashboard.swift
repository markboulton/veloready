import SwiftUI

/// Debug dashboard showing component usage telemetry
/// Helps track which components are used and adoption rates
struct TelemetryDashboard: View {
    @State private var stats: [ComponentStats] = []
    @State private var showingAllComponents = false
    
    var body: some View {
        NavigationView {
            List {
                // Summary
                summarySection
                
                // Top Components
                topComponentsSection
                
                // All Components
                if showingAllComponents {
                    allComponentsSection
                }
                
                // Actions
                actionsSection
            }
            .navigationTitle(DebugContent.Navigation.componentTelemetry)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                refreshStats()
            }
        }
    }
    
    // MARK: - Sections
    
    private var summarySection: some View {
        Section("Summary") {
            let totalUsage = stats.reduce(0) { $0 + $1.usageCount }
            let activeComponents = stats.count
            let totalComponents = ComponentTelemetry.Component.allCases.count
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalUsage)")
                        .font(.metric)
                    Text("Total Uses")
                        .captionStyle()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(activeComponents)/\(totalComponents)")
                        .font(.metric)
                    Text("Active Components")
                        .captionStyle()
                }
            }
        }
    }
    
    private var topComponentsSection: some View {
        Section("Top 5 Most Used") {
            if stats.isEmpty {
                Text("No usage data yet")
                    .captionStyle()
            } else {
                ForEach(ComponentTelemetry.shared.topComponents(5)) { stat in
                    ComponentRow(stat: stat)
                }
            }
        }
    }
    
    private var allComponentsSection: some View {
        Section("All Components") {
            ForEach(stats) { stat in
                ComponentRow(stat: stat)
            }
        }
    }
    
    private var actionsSection: some View {
        Section("Actions") {
            Button(action: {
                showingAllComponents.toggle()
            }) {
                Label(
                    showingAllComponents ? "Hide All Components" : "Show All Components",
                    systemImage: showingAllComponents ? "chevron.up" : "chevron.down"
                )
            }
            
            Button(action: {
                refreshStats()
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                ComponentTelemetry.shared.reset()
                refreshStats()
            }) {
                Label("Reset Telemetry", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func refreshStats() {
        stats = ComponentTelemetry.shared.allStats()
    }
}

// MARK: - Component Row

private struct ComponentRow: View {
    let stat: ComponentStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stat.component.rawValue)
                    .font(.body)
                
                Spacer()
                
                Text("\(stat.usageCount)")
                    .font(.heading)
                    .foregroundColor(.primary)
            }
            
            if let avgPerDay = stat.averageUsagePerDay {
                Text(String(format: "%.1f uses/day", avgPerDay))
                    .captionStyle()
            }
        }
    }
}

#Preview {
    // Populate some sample data
    let telemetry = ComponentTelemetry.shared
    telemetry.track(.sectionHeader)
    telemetry.track(.sectionHeader)
    telemetry.track(.metricDisplay)
    telemetry.track(.loadingStateView)
    
    return TelemetryDashboard()
}
