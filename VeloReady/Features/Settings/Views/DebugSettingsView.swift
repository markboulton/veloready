import SwiftUI
import HealthKit

/// Comprehensive debug and testing settings view
struct DebugSettingsView: View {
    @ObservedObject private var oauthManager = IntervalsOAuthManager.shared
    @ObservedObject private var stravaAuthService = StravaAuthService.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var config = ProFeatureConfig.shared
    @ObservedObject private var aiBriefService = AIBriefService.shared
    @ObservedObject private var rideSummaryService = RideSummaryService.shared
    
    @State private var showingClearCacheAlert = false
    @State private var showingClearCoreDataAlert = false
    @State private var cacheCleared = false
    @State private var coreDataCleared = false
    @State private var isRefreshingRecovery = false
    @State private var isRefreshingStrain = false
    @State private var isRefreshingSleep = false
    @State private var refreshSuccess = false
    @State private var showingIntervalsLogin = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
                // Monitoring Dashboards
                monitoringDashboardsSection
                
                // Debug Logging Toggle
                loggingSection
                
                // 1. Auth Status
                authStatusSection
                
                // 2. API Debug Inspector
                apiDebugSection
                
                // 3. Pro Toggle, Mock Data, Subscription Status
                testingFeaturesSection
                
                // 4. Cache Section
                cacheSection
                
                // 5. AI Daily Brief
                aiBriefSection
                
                // 6. AI Ride Summary
                rideSummarySection
                
                // 7. Onboarding Testing
                onboardingSection
                
                // 8. OAuth Actions
                oauthActionsSection
        }
        .navigationTitle(DebugSettingsContent.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingIntervalsLogin) {
            IntervalsLoginView {
                showingIntervalsLogin = false
                
                // Trigger a data refresh across the app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .refreshDataAfterIntervalsConnection, object: nil)
                    print("🔄 Posted notification to refresh data after Intervals.icu connection")
                }
            }
        }
        .alert(DebugSettingsContent.Alerts.clearIntervalsCacheTitle, isPresented: $showingClearCacheAlert) {
                Button(DebugSettingsContent.Alerts.cancel, role: .cancel) { }
                Button(DebugSettingsContent.Alerts.clear, role: .destructive) {
                    clearIntervalsCache()
                }
            } message: {
                Text(DebugSettingsContent.Alerts.clearIntervalsCacheMessage)
            }
            .alert(DebugSettingsContent.Alerts.clearCoreDataTitle, isPresented: $showingClearCoreDataAlert) {
                Button(DebugSettingsContent.Alerts.cancel, role: .cancel) { }
                Button(DebugSettingsContent.Alerts.clear, role: .destructive) {
                    clearCoreData()
                }
            } message: {
                Text(DebugSettingsContent.Alerts.clearCoreDataMessage)
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
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.semantic.success)
                        .font(.caption)
                    Text("Verbose logging enabled")
                        .font(.caption)
                        .foregroundColor(Color.semantic.success)
                }
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Logging disabled (optimal performance)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("Debug Logging", systemImage: "doc.text.magnifyingglass")
        } footer: {
            Text("Enable verbose logging for debugging. Logs are DEBUG-only and never shipped to production. Toggle OFF for best performance during normal testing.")
        }
    }
    
    // MARK: - API Debug Section
    
    private var apiDebugSection: some View {
        Section {
            NavigationLink(destination: IntervalsAPIDebugView().environmentObject(IntervalsAPIClient.shared)) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(Color.semantic.warning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Data Inspector")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Debug missing activity & athlete data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("API Debugging", systemImage: "network")
        } footer: {
            Text("Inspect raw API responses to identify missing fields and data inconsistencies")
        }
    }
    
    // MARK: - Auth Status Section
    
    private var authStatusSection: some View {
        Section {
            // HealthKit Status
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(healthKitManager.isAuthorized ? Color.semantic.success : Color.semantic.warning)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(DebugSettingsContent.AuthStatus.healthKit)
                        .font(.body)
                    
                    Text(healthKitManager.isAuthorized ? DebugSettingsContent.AuthStatus.authorized : DebugSettingsContent.AuthStatus.notAuthorized)
                        .font(.caption)
                        .foregroundColor(healthKitManager.isAuthorized ? Color.semantic.success : .secondary)
                }
                
                Spacer()
                
                if !healthKitManager.isAuthorized {
                    Button(DebugSettingsContent.AuthStatus.authorize) {
                        Task {
                            await healthKitManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            // Intervals.icu Status
            HStack {
                Image(systemName: "bicycle")
                    .foregroundColor(oauthManager.isAuthenticated ? Color.semantic.success : Color.semantic.warning)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(DebugSettingsContent.AuthStatus.intervalsICU)
                        .font(.body)
                    
                    Text(oauthManager.isAuthenticated ? DebugSettingsContent.AuthStatus.connected : DebugSettingsContent.AuthStatus.notConnected)
                        .font(.caption)
                        .foregroundColor(oauthManager.isAuthenticated ? Color.semantic.success : .secondary)
                }
                
                Spacer()
                
                if oauthManager.isAuthenticated {
                    Badge(DebugSettingsContent.AuthStatus.connected, variant: .success, size: .small)
                } else {
                    Badge(DebugSettingsContent.AuthStatus.disconnected, variant: .warning, size: .small)
                }
            }
            
            if oauthManager.isAuthenticated, let user = oauthManager.user {
                HStack {
                    Text(DebugSettingsContent.AuthStatus.athlete)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(user.name)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // Strava Status
            HStack {
                Image(systemName: "figure.outdoor.cycle")
                    .foregroundColor(stravaAuthService.connectionState.isConnected ? Color.semantic.success : Color.semantic.warning)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strava")
                        .font(.body)
                    
                    Text(stravaStateDescription)
                        .font(.caption)
                        .foregroundColor(stravaAuthService.connectionState.isConnected ? Color.semantic.success : .secondary)
                }
                
                Spacer()
                
                if stravaAuthService.connectionState.isConnected {
                    Badge("Connected", variant: .success, size: .small)
                } else {
                    Badge("Not Connected", variant: .warning, size: .small)
                }
            }
            
            if case .connected(let athleteId) = stravaAuthService.connectionState, let id = athleteId {
                HStack {
                    Text("Athlete ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(id)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.authStatus, systemImage: "checkmark.shield")
        }
    }
    
    // MARK: - Testing Features Section
    
    private var testingFeaturesSection: some View {
        Section {
            // Pro Features Toggle
            Toggle(DebugSettingsContent.TestingFeatures.enablePro, isOn: $config.bypassSubscriptionForTesting)
                .onChange(of: config.bypassSubscriptionForTesting) { _, newValue in
                    if newValue {
                        config.enableProForTesting()
                    } else {
                        config.disableProForTesting()
                    }
                }
            
            if config.bypassSubscriptionForTesting {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.semantic.success)
                        .font(.caption)
                    Text(DebugSettingsContent.TestingFeatures.allProUnlocked)
                        .font(.caption)
                        .foregroundColor(Color.semantic.success)
                }
            }
            
            // Mock Data Toggle
            Toggle(DebugSettingsContent.TestingFeatures.showMockData, isOn: $config.showMockDataForTesting)
            
            if config.showMockDataForTesting {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color.button.primary)
                        .font(.caption)
                    Text(DebugSettingsContent.TestingFeatures.mockDataEnabled)
                        .font(.caption)
                        .foregroundColor(Color.button.primary)
                }
            }
            
            // Wellness Warning Toggle
            Toggle("Show Wellness Warning", isOn: $config.showWellnessWarningForTesting)
            
            if config.showWellnessWarningForTesting {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Mock wellness warning enabled")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Subscription Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(DebugSettingsContent.TestingFeatures.subscriptionStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Badge(
                        config.hasProAccess ? DebugSettingsContent.TestingFeatures.pro : DebugSettingsContent.TestingFeatures.free,
                        variant: config.hasProAccess ? .pro : .neutral
                    )
                }
                
                if config.isInTrialPeriod {
                    HStack {
                        Text(DebugSettingsContent.TestingFeatures.trialDaysRemaining)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(config.trialDaysRemaining)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.testingFeatures, systemImage: "hammer")
        } footer: {
            Text(DebugSettingsContent.SectionFooters.testingFeatures)
        }
    }
    
    // MARK: - Cache Section
    
    private var cacheSection: some View {
        Section {
            // Intervals Cache (UserDefaults)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "externaldrive")
                        .foregroundColor(Color.button.primary)
                    Text(DebugSettingsContent.Cache.intervalsCache)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Text(DebugSettingsContent.Cache.intervalsCacheDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingClearCacheAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text(DebugSettingsContent.Cache.clearIntervalsCache)
                    }
                }
                .buttonStyle(.bordered)
                .tint(Color.button.danger)
                
                if cacheCleared {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.semantic.success)
                        Text(DebugSettingsContent.Cache.cacheCleared)
                            .font(.caption)
                            .foregroundColor(Color.semantic.success)
                    }
                }
            }
            
            // Core Data Cache
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cylinder")
                        .foregroundColor(ColorPalette.purple)
                    Text(DebugSettingsContent.Cache.coreDataCache)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Text(DebugSettingsContent.Cache.coreDataCacheDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingClearCoreDataAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text(DebugSettingsContent.Cache.clearCoreData)
                    }
                }
                .buttonStyle(.bordered)
                .tint(Color.button.danger)
                
                if coreDataCleared {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.semantic.success)
                        Text(DebugSettingsContent.Cache.coreDataCleared)
                            .font(.caption)
                            .foregroundColor(Color.semantic.success)
                    }
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.cacheManagement, systemImage: "externaldrive.badge.xmark")
        } footer: {
            Text(DebugSettingsContent.SectionFooters.cacheManagement)
        }
    }
    
    // MARK: - AI Brief Section
    
    private var aiBriefSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(DebugSettingsContent.AIBrief.status)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if aiBriefService.isLoading {
                        Text(DebugSettingsContent.AIBrief.loading)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let error = aiBriefService.error {
                        Text("\(DebugSettingsContent.AIBrief.error) \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(Color.text.error)
                    } else if aiBriefService.briefText != nil {
                        Text(DebugSettingsContent.AIBrief.loaded)
                            .font(.caption)
                            .foregroundColor(Color.text.success)
                    } else {
                        Text(DebugSettingsContent.AIBrief.notLoaded)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if aiBriefService.isCached {
                    Badge(DebugSettingsContent.AIBrief.cached, variant: .info, size: .small)
                }
            }
            
            Button(action: {
                Task {
                    await aiBriefService.refresh()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(DebugSettingsContent.AIBrief.refresh)
                }
            }
            .buttonStyle(.bordered)
            .disabled(aiBriefService.isLoading)
            
            NavigationLink(destination: AIBriefSecretConfigView()) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(Color.semantic.warning)
                    Text(DebugSettingsContent.AIBrief.configureSecret)
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.aiBrief, systemImage: "sparkles")
        } footer: {
            Text(DebugSettingsContent.SectionFooters.aiBrief)
        }
    }
    
    // MARK: - AI Ride Summary Section
    
    private var rideSummarySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ride Summary Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if rideSummaryService.isLoading {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let error = rideSummaryService.error {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(Color.text.error)
                    } else if rideSummaryService.currentSummary != nil {
                        Text("Summary loaded")
                            .font(.caption)
                            .foregroundColor(Color.text.success)
                    } else {
                        Text("Not loaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Clear cache button
            Button(action: {
                rideSummaryService.clearCache()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Ride Summary Cache")
                }
            }
            .buttonStyle(.bordered)
            
            // Copy last response JSON (debug)
            if let lastResponse = rideSummaryService.cache?.lastResponseJSON {
                Button(action: {
                    UIPasteboard.general.string = lastResponse
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Last Response JSON")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            NavigationLink(destination: RideSummarySecretConfigView()) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(Color.semantic.warning)
                    Text("Configure HMAC Secret")
                }
            }
            
            // Override X-User (for testing)
            NavigationLink(destination: RideSummaryUserOverrideView()) {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(Color.button.primary)
                    Text("Override User ID")
                }
            }
        } header: {
            Label("AI Ride Summary", systemImage: "brain.head.profile")
        } footer: {
            Text("Test AI ride summary endpoint. PRO feature. Uses same HMAC secret as Daily Brief.")
        }
    }
    
    // MARK: - Score Refresh Section
    
    private var onboardingSection: some View {
        Section {
            // Force Recalculate Recovery
            Button(action: {
                Task {
                    isRefreshingRecovery = true
                    await RecoveryScoreService.shared.forceRefreshRecoveryScoreIgnoringDailyLimit()
                    refreshSuccess = true
                    isRefreshingRecovery = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        refreshSuccess = false
                    }
                }
            }) {
                HStack {
                    if isRefreshingRecovery {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "heart.fill")
                    }
                    Text("Force Recalculate Recovery")
                    Spacer()
                    if refreshSuccess && !isRefreshingRecovery {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.semantic.success)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.semantic.warning)
            .disabled(isRefreshingRecovery)
            
            // Force Recalculate Strain
            Button(action: {
                Task {
                    isRefreshingStrain = true
                    await StrainScoreService.shared.calculateStrainScore()
                    refreshSuccess = true
                    isRefreshingStrain = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        refreshSuccess = false
                    }
                }
            }) {
                HStack {
                    if isRefreshingStrain {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "flame.fill")
                    }
                    Text("Force Recalculate Strain/Load")
                    Spacer()
                    if refreshSuccess && !isRefreshingStrain {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.semantic.success)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.button.primary)
            .disabled(isRefreshingStrain)
            
            // Force Recalculate Sleep
            Button(action: {
                Task {
                    isRefreshingSleep = true
                    await SleepScoreService.shared.calculateSleepScore()
                    refreshSuccess = true
                    isRefreshingSleep = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        refreshSuccess = false
                    }
                }
            }) {
                HStack {
                    if isRefreshingSleep {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "moon.fill")
                    }
                    Text("Force Recalculate Sleep")
                    Spacer()
                    if refreshSuccess && !isRefreshingSleep {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.semantic.success)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(ColorPalette.purple)
            .disabled(isRefreshingSleep)
            
            // Info about what this does
            VStack(alignment: .leading, spacing: 4) {
                Text("These buttons ignore the daily calculation limit and force immediate recalculation using the latest HealthKit data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Useful for testing HealthKit-only mode without Intervals.icu connection.")
                    .font(.caption)
                    .foregroundColor(Color.button.primary)
            }
            
            Divider()
            
            // Onboarding controls
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Onboarding Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(OnboardingManager.shared.hasCompletedOnboarding ? "Completed" : "Not Completed")
                        .font(.caption)
                        .foregroundColor(OnboardingManager.shared.hasCompletedOnboarding ? Color.text.success : .secondary)
                }
                
                Spacer()
                
                if OnboardingManager.shared.hasCompletedOnboarding {
                    Badge("Done", variant: .success, size: .small)
                }
            }
            
            Button(action: {
                OnboardingManager.shared.resetOnboarding()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Onboarding")
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.button.primary)
        } header: {
            Label("Score Recalculation & Testing", systemImage: "arrow.triangle.2.circlepath")
        } footer: {
            Text("Force recalculation bypasses the once-per-day limit. Perfect for testing HealthKit-only mode and algorithm changes.")
        }
    }
    
    // MARK: - OAuth Actions Section
    
    private var oauthActionsSection: some View {
        Section {
            // Intervals.icu OAuth
            Group {
                Text("Intervals.icu")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if oauthManager.isAuthenticated {
                    Button(action: {
                        Task {
                            await oauthManager.signOut()
                            
                            // Trigger a data refresh to switch to HealthKit-only mode
                            await MainActor.run {
                                NotificationCenter.default.post(name: .refreshDataAfterIntervalsConnection, object: nil)
                                print("🔄 Posted notification to refresh data after Intervals.icu disconnection")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Color.button.danger)
                            Text(DebugSettingsContent.OAuth.signOut)
                                .foregroundColor(Color.button.danger)
                        }
                    }
                    
                    HStack {
                        Text(DebugSettingsContent.OAuth.status)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Badge(DebugSettingsContent.AuthStatus.connected, variant: .success)
                    }
                } else {
                    HStack {
                        Text(DebugSettingsContent.OAuth.status)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Badge(DebugSettingsContent.AuthStatus.disconnected, variant: .warning)
                    }
                    
                    Button(action: {
                        showingIntervalsLogin = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(Color.button.primary)
                            Text("Connect to Intervals.icu")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.button.primary)
                }
                
                if let accessToken = oauthManager.accessToken {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DebugSettingsContent.OAuth.accessToken)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(accessToken.prefix(20)))...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Strava OAuth
            Group {
                Text("Strava")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if stravaAuthService.connectionState.isConnected {
                    Button(action: {
                        stravaAuthService.disconnect()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Color.button.danger)
                            Text("Sign Out from Strava")
                                .foregroundColor(Color.button.danger)
                        }
                    }
                    
                    HStack {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Badge("Connected", variant: .success)
                    }
                    
                    if case .connected(let athleteId) = stravaAuthService.connectionState, let id = athleteId {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Athlete ID")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(id)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Badge(stravaStateDescription, variant: stravaAuthService.connectionState.isLoading ? .warning : .neutral)
                    }
                    
                    Button(action: {
                        stravaAuthService.startAuth()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(Color(red: 252/255, green: 76/255, blue: 2/255))
                            Text("Connect to Strava")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(red: 252/255, green: 76/255, blue: 2/255))
                    .disabled(stravaAuthService.connectionState.isLoading)
                    
                    if case .error(let message) = stravaAuthService.connectionState {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Error")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.oauthActions, systemImage: "key.horizontal")
        } footer: {
            Text("Connect or disconnect from Intervals.icu and Strava for testing")
        }
    }
    
    // MARK: - Monitoring Dashboards Section
    
    private var monitoringDashboardsSection: some View {
        Section {
            NavigationLink(destination: ServiceHealthDashboard()) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Service Health")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Monitor service status and connections")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: TelemetryDashboard()) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Component Telemetry")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Track component usage statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("Monitoring", systemImage: "gauge.with.dots.needle.67percent")
        } footer: {
            Text("Real-time monitoring of app services and component usage")
        }
    }
    
    // MARK: - Helper Computed Properties
    
    private var stravaStateDescription: String {
        switch stravaAuthService.connectionState {
        case .disconnected:
            return "Not Connected"
        case .connecting:
            return "Connecting..."
        case .pending(let status):
            return status
        case .connected:
            return "Connected"
        case .error:
            return "Error"
        }
    }
    
    // MARK: - Helper Functions
    
    private func clearIntervalsCache() {
        // Use IntervalsCache to clear all cached data properly
        Task {
            IntervalsCache.shared.clearCache()
            print("🗑️ Cleared Intervals.icu cache from Debug Settings")
            
            await MainActor.run {
                cacheCleared = true
                
                // Reset after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    cacheCleared = false
                }
            }
        }
    }
    
    private func clearCoreData() {
        // Clear Core Data
        let context = PersistenceController.shared.container.viewContext
        
        // Delete all DailyScores entities
        let fetchRequest = DailyScores.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            try context.save()
            
            coreDataCleared = true
            
            // Reset after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                coreDataCleared = false
            }
        } catch {
            print("❌ Error clearing Core Data: \(error)")
        }
    }
}

#Preview {
    DebugSettingsView()
}
