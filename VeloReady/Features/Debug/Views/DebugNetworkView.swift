import SwiftUI

#if DEBUG
/// Debug view for API debugging and network logging
struct DebugNetworkView: View {
    @ObservedObject private var aiBriefService = AIBriefService.shared
    @ObservedObject private var rideSummaryService = RideSummaryService.shared
    
    var body: some View {
        Form {
            loggingSection
            apiDebugSection
            aiBriefSection
            rideSummarySection
        }
        .navigationTitle("Network")
    }
    
    // MARK: - Logging Section
    
    private var loggingSection: some View {
        Section {
            Toggle("Enable Debug Logging", isOn: Binding(
                get: { Logger.isDebugLoggingEnabled },
                set: { Logger.isDebugLoggingEnabled = $0 }
            ))
            
            if Logger.isDebugLoggingEnabled {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Status.successFill)
                        .foregroundColor(ColorScale.greenAccent)
                    VRText("Verbose logging enabled", style: .caption, color: ColorScale.greenAccent)
                }
            } else {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Status.errorFill)
                        .foregroundColor(.secondary)
                    VRText("Logging disabled (optimal performance)", style: .caption, color: .secondary)
                }
            }
        } header: {
            Label("Debug Logging", systemImage: Icons.System.magnifyingGlass)
        } footer: {
            VRText(
                "Enable verbose logging for debugging. Logs are DEBUG-only and never shipped to production. Toggle OFF for best performance during normal testing.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - API Debug Section
    
    private var apiDebugSection: some View {
        Section {
            NavigationLink(destination: IntervalsAPIDebugView().environmentObject(IntervalsAPIClient.shared)) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: Icons.System.bug)
                        .foregroundColor(ColorScale.amberAccent)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        VRText("API Data Inspector", style: .body)
                        VRText("Debug missing activity & athlete data", style: .caption, color: .secondary)
                    }
                }
            }
        } header: {
            Label("API Debugging", systemImage: Icons.System.network)
        } footer: {
            VRText(
                "Inspect raw API responses to identify missing fields and data inconsistencies",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - AI Brief Section
    
    private var aiBriefSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("AI Brief Status", style: .body)
                    
                    if aiBriefService.isLoading {
                        VRText("Loading...", style: .caption, color: .secondary)
                    } else if let error = aiBriefService.error {
                        VRText("Error: \(String(describing: error))", style: .caption, color: ColorScale.redAccent)
                    } else if aiBriefService.briefText != nil {
                        VRText("Loaded", style: .caption, color: ColorScale.greenAccent)
                    } else {
                        VRText("Not loaded", style: .caption, color: .secondary)
                    }
                }
                
                Spacer()
                
                if aiBriefService.isCached {
                    VRBadge("Cached", style: .neutral)
                }
            }
            
            Button(action: {
                Task {
                    await aiBriefService.fetchBrief(bypassCache: true)
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Arrow.counterclockwise)
                    VRText("Refresh AI Brief", style: .body)
                }
            }
            .buttonStyle(.bordered)
            .disabled(aiBriefService.isLoading)
            
            NavigationLink("Configure AI Secret") {
                AIBriefSecretConfigView()
            }
        } header: {
            Label("AI Daily Brief", systemImage: Icons.System.sparkles)
        } footer: {
            VRText(
                "Manage AI brief configuration and refresh status. PRO feature.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Ride Summary Section
    
    private var rideSummarySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    VRText("Ride Summary Status", style: .body)
                    
                    if rideSummaryService.isLoading {
                        VRText("Loading...", style: .caption, color: .secondary)
                    } else if let error = rideSummaryService.error {
                        VRText("Error: \\(error)", style: .caption, color: ColorScale.redAccent)
                    } else if rideSummaryService.currentSummary != nil {
                        VRText("Summary loaded", style: .caption, color: ColorScale.greenAccent)
                    } else {
                        VRText("Not loaded", style: .caption, color: .secondary)
                    }
                }
                
                Spacer()
            }
            
            NavigationLink("Configure HMAC Secret") {
                AIBriefSecretConfigView()
            }
        } header: {
            Label("AI Ride Summary", systemImage: Icons.Activity.cycling)
        } footer: {
            VRText(
                "Test AI ride summary endpoint. PRO feature. Uses same HMAC secret as Daily Brief.",
                style: .caption,
                color: .secondary
            )
        }
    }
}

#Preview {
    NavigationStack {
        DebugNetworkView()
    }
}
#endif
