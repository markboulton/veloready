import SwiftUI

#if DEBUG
/// Simplified debug settings for alpha testers
/// Only shows relevant testing options without overwhelming technical details
struct AlphaTesterSettingsView: View {
    @ObservedObject private var config = ProFeatureConfig.shared
    @State private var showingClearCacheAlert = false
    @State private var cacheCleared = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // Debug Logging
            loggingSection
            
            // Pro Features Testing
            proTestingSection
            
            // Cache Management
            cacheSection
            
            // Feedback
            feedbackSection
        }
        .navigationTitle("Alpha Testing")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Cache?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear cached activity data. The app will re-fetch data from Intervals.icu on next load.")
        }
    }
    
    // MARK: - Logging Section
    
    private var loggingSection: some View {
        Section {
            Toggle("Enable Debug Logging", isOn: Binding(
                get: { Logger.isDebugLoggingEnabled },
                set: { Logger.isDebugLoggingEnabled = $0 }
            ))
            
            if Logger.isDebugLoggingEnabled {
                HStack {
                    Image(systemName: Icons.Status.successFill)
                        .foregroundColor(Color.semantic.success)
                    Text("Logs are being recorded")
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                }
            }
        } header: {
            Text("Logging")
        } footer: {
            Text("Enable this to record detailed logs for bug reports. Logs will be included when you submit feedback.")
        }
    }
    
    // MARK: - Pro Testing Section
    
    private var proTestingSection: some View {
        Section {
            Toggle("Test Pro Features", isOn: $config.bypassSubscriptionForTesting)
            
            if config.bypassSubscriptionForTesting {
                HStack {
                    Image(systemName: Icons.Status.successFill)
                        .foregroundColor(ColorScale.blueAccent)
                    Text("Pro features unlocked")
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                }
            }
        } header: {
            Text("Pro Features")
        } footer: {
            Text("Enable this to test Pro features like VeloAI, training load charts, and advanced analytics without a subscription.")
        }
    }
    
    // MARK: - Cache Section
    
    private var cacheSection: some View {
        Section {
            Button(action: {
                showingClearCacheAlert = true
            }) {
                HStack {
                    Image(systemName: Icons.Document.trash)
                        .foregroundColor(Color.semantic.error)
                    Text("Clear Activity Cache")
                        .foregroundColor(Color.semantic.error)
                }
            }
            
            if cacheCleared {
                HStack {
                    Image(systemName: Icons.Status.successFill)
                        .foregroundColor(Color.semantic.success)
                    Text("Cache cleared successfully")
                        .font(.caption)
                        .foregroundColor(Color.text.secondary)
                }
            }
        } header: {
            Text("Cache Management")
        } footer: {
            Text("Clear this if you're seeing stale or incorrect activity data. The app will re-fetch everything from Intervals.icu.")
        }
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Thank you for alpha testing!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("When reporting bugs:")
                    .font(.caption)
                    .foregroundColor(Color.text.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 4) {
                        Text("•")
                        Text("Enable debug logging above")
                    }
                    HStack(alignment: .top, spacing: 4) {
                        Text("•")
                        Text("Reproduce the issue")
                    }
                    HStack(alignment: .top, spacing: 4) {
                        Text("•")
                        Text("Use the feedback button in Settings")
                    }
                    HStack(alignment: .top, spacing: 4) {
                        Text("•")
                        Text("Logs will be automatically included")
                    }
                }
                .font(.caption)
                .foregroundColor(Color.text.tertiary)
            }
        } header: {
            Text("Feedback")
        }
    }
    
    // MARK: - Actions
    
    private func clearCache() {
        // IntervalsCache deleted - use CacheOrchestrator
        Task { await CacheOrchestrator.shared.invalidate(matching: "intervals:.*") }
        cacheCleared = true
        
        // Reset after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            cacheCleared = false
        }
        
        Logger.info("🗑️ Activity cache cleared by alpha tester")
    }
}

#Preview {
    NavigationStack {
        AlphaTesterSettingsView()
    }
}
#endif
