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
        Section(DebugContent.TelemetryExtended.summary) {
            let totalUsage = stats.reduce(0) { $0 + $1.usageCount }
            let activeComponents = stats.count
            let totalComponents = ComponentTelemetry.Component.allCases.count
            
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(totalUsage)")
                        .font(.metric)
                    Text(DebugContent.TelemetryExtended.totalUses)
                        .captionStyle()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("\(activeComponents)/\(totalComponents)")
                        .font(.metric)
                    Text(DebugContent.TelemetryExtended.activeComponents)
                        .captionStyle()
                }
            }
        }
    }
    
    private var topComponentsSection: some View {
        Section(DebugContent.TelemetryExtended.top5MostUsed) {
            if stats.isEmpty {
                Text(DebugContent.TelemetryExtended.noUsageData)
                    .captionStyle()
            } else {
                ForEach(ComponentTelemetry.shared.topComponents(5)) { stat in
                    ComponentRow(stat: stat)
                }
            }
        }
    }
    
    private var allComponentsSection: some View {
        Section(DebugContent.TelemetryExtended.allComponents) {
            ForEach(stats) { stat in
                ComponentRow(stat: stat)
            }
        }
    }
    
    private var actionsSection: some View {
        Section(DebugContent.TelemetryExtended.actions) {
            Button(action: {
                showingAllComponents.toggle()
            }) {
                Label(
                    showingAllComponents ? DebugContent.TelemetryExtended.hideAllComponents : DebugContent.TelemetryExtended.showAllComponents,
                    systemImage: showingAllComponents ? "chevron.up" : "chevron.down"
                )
            }
            
            Button(action: {
                refreshStats()
            }) {
                Label(DebugContent.TelemetryExtended.refresh, systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                ComponentTelemetry.shared.reset()
                refreshStats()
            }) {
                Label(DebugContent.TelemetryExtended.resetTelemetry, systemImage: "trash")
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
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(stat.component.rawValue)
                    .font(.body)
                
                Spacer()
                
                Text("\(stat.usageCount)")
                    .font(.heading)
                    .foregroundColor(.primary)
            }
            
            if let avgPerDay = stat.averageUsagePerDay {
                Text(String(format: DebugContent.TelemetryExtended.usesPerDayFormat, avgPerDay))
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
