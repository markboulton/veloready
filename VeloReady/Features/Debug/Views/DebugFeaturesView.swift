import SwiftUI

#if DEBUG
/// Debug view for Pro features and testing toggles
struct DebugFeaturesView: View {
    @ObservedObject private var config = ProFeatureConfig.shared
    @State private var isSyncingSubscription = false
    @State private var subscriptionSyncSuccess: Bool?
    
    var body: some View {
        Form {
            proFeaturesSection
            mockDataSection
            simulationSection
            subscriptionSection
        }
        .navigationTitle("Features")
    }
    
    // MARK: - Pro Features Section
    
    private var proFeaturesSection: some View {
        Section {
            Toggle("Enable Pro Features", isOn: $config.bypassSubscriptionForTesting)
                .onChange(of: config.bypassSubscriptionForTesting) { _, newValue in
                    if newValue {
                        config.enableProForTesting()
                    } else {
                        config.disableProForTesting()
                    }
                }
            
            if config.bypassSubscriptionForTesting {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Status.successFill)
                        .foregroundColor(ColorScale.greenAccent)
                    VRText("All Pro features unlocked", style: .caption, color: ColorScale.greenAccent)
                }
            }
        } header: {
            Label("Pro Features", systemImage: Icons.System.star)
        } footer: {
            VRText(
                "Enable Pro features for testing without a subscription. DEBUG builds only.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Mock Data Section
    
    private var mockDataSection: some View {
        Section {
            Toggle("Show Mock Data (Trends)", isOn: $config.showMockDataForTesting)
            
            if config.showMockDataForTesting {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.System.chart)
                        .foregroundColor(ColorScale.blueAccent)
                    VRText("Mock data enabled for charts", style: .caption, color: ColorScale.blueAccent)
                }
            }
        } header: {
            Label("Mock Data", systemImage: Icons.System.chart)
        } footer: {
            VRText(
                "Display mock trend data for testing UI without real data.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Simulation Section
    
    private var simulationSection: some View {
        Section {
            // Wellness Warning Toggle
            Toggle("Show Wellness Warning", isOn: $config.showWellnessWarningForTesting)
            
            if config.showWellnessWarningForTesting {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Status.warningFill)
                        .foregroundColor(ColorScale.amberAccent)
                    VRText("Mock wellness warning enabled", style: .caption, color: ColorScale.amberAccent)
                }
            }
            
            // Illness Indicator Toggle
            Toggle("Show Illness Indicator", isOn: $config.showIllnessIndicatorForTesting)
            
            if config.showIllnessIndicatorForTesting {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Status.warningFill)
                        .foregroundColor(ColorScale.redAccent)
                    VRText("Mock illness indicator enabled", style: .caption, color: ColorScale.redAccent)
                }
            }
            
            // No Sleep Data Toggle
            Toggle("Simulate No Sleep Data", isOn: $config.simulateNoSleepData)
                .onChange(of: config.simulateNoSleepData) { _, newValue in
                    // Always reinstate the banner when toggling
                    // When ON: show "no sleep data" banner
                    // When OFF: show banner if sleep data is actually missing
                    
                    // Reset both dismissal flags to ensure banner shows
                    UserDefaults.standard.set(false, forKey: "missingSleepBannerDismissed")
                    UserDefaults.standard.set(0, forKey: "sleepDataWarningDismissedAt")
                    
                    // Force refresh of HealthWarningsCardViewModel to pick up the change
                    NotificationCenter.default.post(name: .refreshHealthWarnings, object: nil)
                    
                    Logger.debug("🔄 [DEBUG] Sleep simulation toggled - banner reinstated")
                }
            
            if config.simulateNoSleepData {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Health.sleepFill)
                        .foregroundColor(ColorScale.purpleAccent)
                    VRText("Sleep data missing simulation enabled", style: .caption, color: ColorScale.purpleAccent)
                }
            }
            
            // Stress Alert Toggle
            Toggle("Show Stress Alert", isOn: $config.showStressAlertForTesting)
                .onChange(of: config.showStressAlertForTesting) { _, newValue in
                    if newValue {
                        StressAnalysisService.shared.enableMockAlert()
                    } else {
                        StressAnalysisService.shared.disableMockAlert()
                    }
                    Logger.debug("🔄 [DEBUG] Stress alert simulation toggled: \(newValue)")
                }
            
            if config.showStressAlertForTesting {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.Status.warningFill)
                        .foregroundColor(ColorScale.amberAccent)
                    VRText("Mock stress alert enabled", style: .caption, color: ColorScale.amberAccent)
                }
            }
            
            // No Network Toggle
            Toggle("Simulate No Network", isOn: $config.simulateNoNetwork)
            
            if config.simulateNoNetwork {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: Icons.System.network)
                        .foregroundColor(Color.secondary)
                    VRText("Network offline simulation enabled", style: .caption, color: .secondary)
                }
            }
        } header: {
            Label("Simulations", systemImage: Icons.Navigation.settings)
        } footer: {
            VRText(
                "Simulate various app states to test error handling and edge cases.",
                style: .caption,
                color: .secondary
            )
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section {
            HStack {
                VRText("Subscription Status", style: .body)
                Spacer()
                VRBadge(
                    config.hasProAccess ? "PRO" : "FREE",
                    style: config.hasProAccess ? .success : .neutral
                )
            }
            
            if config.trialDaysRemaining > 0 {
                HStack {
                    VRText("Trial Days Remaining:", style: .caption, color: .secondary)
                    Spacer()
                    VRText("\(config.trialDaysRemaining) days", style: .caption)
                        .fontWeight(.medium)
                }
            }
            
        } header: {
            Label("Subscription", systemImage: Icons.System.star)
        } footer: {
            VRText(
                "View current subscription status and sync with backend.",
                style: .caption,
                color: .secondary
            )
        }
    }
}

#Preview {
    NavigationStack {
        DebugFeaturesView()
    }
}
#endif
