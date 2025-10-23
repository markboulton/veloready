import SwiftUI
import HealthKit

#if DEBUG
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
                // Component Gallery
                componentGallerySection
                
                // Monitoring Dashboards
                monitoringDashboardsSection
                
                // Debug Logging Toggle
                loggingSection
                
                // 1. Auth Status
                authStatusSection
                
                // 2. API Debug Inspector
                apiDebugSection
                
                // 2.5. Activity Card Examples
                activityCardsSection
                
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
                    Logger.debug("🔄 Posted notification to refresh data after Intervals.icu connection")
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
    
    // MARK: - Component Gallery Section
    
    private var componentGallerySection: some View {
        Section {
            NavigationLink(destination: CardGalleryDebugView()) {
                HStack {
                    Image(systemName: Icons.System.grid2x2)
                        .foregroundColor(ColorScale.purpleAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Card Component Gallery")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Preview all 16 V2 cards with dummy data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("UI Components", systemImage: "paintbrush.fill")
        } footer: {
            Text("Visual showcase of all atomic card components organized by category. Use this to understand which card to use for your use case.")
        }
    }
    
    // MARK: - Logging Section
    
    private var loggingSection: some View {
        Section {
            Toggle(DebugSettingsContent.Logging.enableDebug, isOn: Binding(
                get: { Logger.isDebugLoggingEnabled },
                set: { Logger.isDebugLoggingEnabled = $0 }
            ))
            
            if Logger.isDebugLoggingEnabled {
                HStack {
                    Image(systemName: Icons.Status.successFill)
                        .foregroundColor(Color.semantic.success)
                        .font(.caption)
                    Text(DebugSettingsContent.Logging.verboseEnabled)
                        .font(.caption)
                        .foregroundColor(Color.semantic.success)
                }
            } else {
                HStack {
                    Image(systemName: Icons.Status.errorFill)
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(DebugSettingsContent.Logging.disabled)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label(DebugSettingsContent.Logging.title, systemImage: Icons.System.magnifyingGlass)
        } footer: {
            Text(DebugSettingsContent.Logging.footer)
        }
    }
    
    // MARK: - API Debug Section
    
    private var apiDebugSection: some View {
        Section {
            NavigationLink(destination: IntervalsAPIDebugView().environmentObject(IntervalsAPIClient.shared)) {
                HStack {
                    Image(systemName: Icons.System.bug)
                        .foregroundColor(Color.semantic.warning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DebugSettingsContent.API.inspector)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(DebugSettingsContent.API.inspectorDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label(DebugSettingsContent.API.title, systemImage: Icons.System.network)
        } footer: {
            Text(DebugSettingsContent.API.footer)
        }
    }
    
    // MARK: - Auth Status Section
    
    private var authStatusSection: some View {
        Section {
            // HealthKit Status
            HStack {
                Image(systemName: Icons.Health.heartFill)
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
                Image(systemName: Icons.Activity.cycling)
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
                Image(systemName: Icons.DataSource.strava)
                    .foregroundColor(stravaAuthService.connectionState.isConnected ? Color.semantic.success : Color.semantic.warning)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(TrendsContent.Labels.strava)
                        .font(.body)
                    
                    Text(stravaStateDescription)
                        .font(.caption)
                        .foregroundColor(stravaAuthService.connectionState.isConnected ? Color.semantic.success : .secondary)
                }
                
                Spacer()
                
                if stravaAuthService.connectionState.isConnected {
                    Badge(DebugSettingsContent.Strava.connected, variant: .success, size: .small)
                } else {
                    Badge(DebugSettingsContent.Strava.notConnected, variant: .warning, size: .small)
                }
            }
            
            if case .connected(let athleteId) = stravaAuthService.connectionState, let id = athleteId {
                HStack {
                    Text(DebugSettingsContent.Strava.athleteID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(id)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.authStatus, systemImage: Icons.System.shield)
        }
    }
    
    // MARK: - Activity Cards Section
    
    private var activityCardsSection: some View {
        Section {
            NavigationLink(destination: ActivityCardGalleryView()) {
                HStack {
                    Image(systemName: Icons.System.grid2x2)
                        .foregroundColor(Color.button.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Activity Card Gallery")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("View all activity card variations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("UI Components", systemImage: Icons.System.eye)
        } footer: {
            Text("Preview activity card designs for rides, strength, and walking workouts")
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
                    Image(systemName: Icons.Status.successFill)
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
                    Image(systemName: Icons.System.chart)
                        .foregroundColor(Color.button.primary)
                        .font(.caption)
                    Text(DebugSettingsContent.TestingFeatures.mockDataEnabled)
                        .font(.caption)
                        .foregroundColor(Color.button.primary)
                }
            }
            
            // Wellness Warning Toggle
            Toggle(DebugSettingsContent.TestingFeatures.showWellnessWarning, isOn: $config.showWellnessWarningForTesting)
            
            if config.showWellnessWarningForTesting {
                HStack {
                    Image(systemName: Icons.Status.warningFill)
                        .foregroundColor(ColorScale.amberAccent)
                        .font(.caption)
                    Text(DebugSettingsContent.TestingFeatures.wellnessWarningEnabled)
                        .font(.caption)
                        .foregroundColor(ColorScale.amberAccent)
                }
            }
            
            // Illness Indicator Toggle
            Toggle(DebugSettingsContent.TestingFeatures.showIllnessIndicator, isOn: $config.showIllnessIndicatorForTesting)
            
            if config.showIllnessIndicatorForTesting {
                HStack {
                    Image(systemName: Icons.Status.warningFill)
                        .foregroundColor(ColorScale.redAccent)
                        .font(.caption)
                    Text(DebugSettingsContent.TestingFeatures.illnessIndicatorEnabled)
                        .font(.caption)
                        .foregroundColor(ColorScale.redAccent)
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
            Label(DebugSettingsContent.SectionHeaders.testingFeatures, systemImage: Icons.System.hammer)
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
                    Image(systemName: Icons.System.storage)
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
                        Image(systemName: Icons.Document.trash)
                        Text(DebugSettingsContent.Cache.clearIntervalsCache)
                    }
                }
                .buttonStyle(.bordered)
                .tint(Color.button.danger)
                
                if cacheCleared {
                    HStack {
                        Image(systemName: Icons.Status.successFill)
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
                    Image(systemName: Icons.System.database)
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
                        Image(systemName: Icons.Document.trash)
                        Text(DebugSettingsContent.Cache.clearCoreData)
                    }
                }
                .buttonStyle(.bordered)
                .tint(Color.button.danger)
                
                if coreDataCleared {
                    HStack {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(Color.semantic.success)
                        Text(DebugSettingsContent.Cache.coreDataCleared)
                            .font(.caption)
                            .foregroundColor(Color.semantic.success)
                    }
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.cacheManagement, systemImage: Icons.System.storageBadge)
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
                    Image(systemName: Icons.Arrow.clockwise)
                    Text(DebugSettingsContent.AIBrief.refresh)
                }
            }
            .buttonStyle(.bordered)
            .disabled(aiBriefService.isLoading)
            
            NavigationLink(destination: AIBriefSecretConfigView()) {
                HStack {
                    Image(systemName: Icons.Document.key)
                        .foregroundColor(Color.semantic.warning)
                    Text(DebugSettingsContent.AIBrief.configureSecret)
                }
            }
        } header: {
            Label(DebugSettingsContent.SectionHeaders.aiBrief, systemImage: Icons.System.sparkles)
        } footer: {
            Text(DebugSettingsContent.SectionFooters.aiBrief)
        }
    }
    
    // MARK: - AI Ride Summary Section
    
    private var rideSummarySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(DebugSettingsContent.RideSummary.status)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if rideSummaryService.isLoading {
                        Text(DebugSettingsContent.RideSummary.loading)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let error = rideSummaryService.error {
                        Text("\(DebugSettingsContent.RideSummary.error) \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(Color.text.error)
                    } else if rideSummaryService.currentSummary != nil {
                        Text(DebugSettingsContent.RideSummary.loaded)
                            .font(.caption)
                            .foregroundColor(Color.text.success)
                    } else {
                        Text(DebugSettingsContent.RideSummary.notLoaded)
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
                    Image(systemName: Icons.Document.trash)
                    Text(DebugSettingsContent.RideSummary.clearCache)
                }
            }
            .buttonStyle(.bordered)
            
            // Copy last response JSON (debug)
            if let lastResponse = rideSummaryService.cache?.lastResponseJSON {
                Button(action: {
                    UIPasteboard.general.string = lastResponse
                }) {
                    HStack {
                        Image(systemName: Icons.Document.copy)
                        Text(DebugSettingsContent.RideSummary.copyResponse)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            NavigationLink(destination: RideSummarySecretConfigView()) {
                HStack {
                    Image(systemName: Icons.Document.key)
                        .foregroundColor(Color.semantic.warning)
                    Text(DebugSettingsContent.RideSummary.configureSecret)
                }
            }
            
            // Override X-User (for testing)
            NavigationLink(destination: RideSummaryUserOverrideView()) {
                HStack {
                    Image(systemName: Icons.System.person)
                        .foregroundColor(Color.button.primary)
                    Text(DebugSettingsContent.RideSummary.overrideUser)
                }
            }
        } header: {
            Label(DebugSettingsContent.RideSummary.title, systemImage: Icons.System.brain)
        } footer: {
            Text(DebugSettingsContent.RideSummary.footer)
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
                        Image(systemName: Icons.Health.heart)
                    }
                    Text(DebugSettingsContent.ScoreRecalc.forceRecalcRecovery)
                    Spacer()
                    if refreshSuccess && !isRefreshingRecovery {
                        Image(systemName: Icons.Status.successFill)
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
                        Image(systemName: Icons.Health.calories)
                    }
                    Text(DebugSettingsContent.ScoreRecalc.forceRecalcStrain)
                    Spacer()
                    if refreshSuccess && !isRefreshingStrain {
                        Image(systemName: Icons.Status.successFill)
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
                        Image(systemName: Icons.Health.sleepFill)
                    }
                    Text(DebugSettingsContent.ScoreRecalc.forceRecalcSleep)
                    Spacer()
                    if refreshSuccess && !isRefreshingSleep {
                        Image(systemName: Icons.Status.successFill)
                            .foregroundColor(Color.semantic.success)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(ColorPalette.purple)
            .disabled(isRefreshingSleep)
            
            // Info about what this does
            VStack(alignment: .leading, spacing: 4) {
                Text(DebugSettingsContent.ScoreRecalc.info)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DebugSettingsContent.ScoreRecalc.usefulFor)
                    .font(.caption)
                    .foregroundColor(Color.button.primary)
            }
            
            Divider()
            
            // Onboarding controls
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(DebugSettingsContent.ScoreRecalc.onboardingStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(OnboardingManager.shared.hasCompletedOnboarding ? DebugSettingsContent.ScoreRecalc.completed : DebugSettingsContent.ScoreRecalc.notCompleted)
                        .font(.caption)
                        .foregroundColor(OnboardingManager.shared.hasCompletedOnboarding ? Color.text.success : .secondary)
                }
                
                Spacer()
                
                if OnboardingManager.shared.hasCompletedOnboarding {
                    Badge(DebugSettingsContent.ScoreRecalc.done, variant: .success, size: .small)
                }
            }
            
            Button(action: {
                OnboardingManager.shared.resetOnboarding()
            }) {
                HStack {
                    Image(systemName: Icons.Arrow.counterclockwise)
                    Text(DebugSettingsContent.ScoreRecalc.resetOnboarding)
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.button.primary)
        } header: {
            Label(DebugSettingsContent.ScoreRecalc.title, systemImage: Icons.Arrow.triangleCirclePath)
        } footer: {
            Text(DebugSettingsContent.ScoreRecalc.footer)
        }
    }
    
    // MARK: - OAuth Actions Section
    
    private var oauthActionsSection: some View {
        Section {
            // Intervals.icu OAuth
            Group {
                Text(DebugSettingsContent.OAuth.intervalsICU)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if oauthManager.isAuthenticated {
                    Button(action: {
                        Task {
                            await oauthManager.signOut()
                            
                            // Trigger a data refresh to switch to HealthKit-only mode
                            await MainActor.run {
                                NotificationCenter.default.post(name: .refreshDataAfterIntervalsConnection, object: nil)
                                Logger.debug("🔄 Posted notification to refresh data after Intervals.icu disconnection")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: Icons.Arrow.rectanglePortrait)
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
                            Image(systemName: Icons.Arrow.rightCircleFill)
                                .foregroundColor(Color.button.primary)
                            Text(DebugSettingsContent.OAuth.connectIntervals)
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
                Text(DebugSettingsContent.Strava.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if stravaAuthService.connectionState.isConnected {
                    Button(action: {
                        stravaAuthService.disconnect()
                    }) {
                        HStack {
                            Image(systemName: Icons.Arrow.rectanglePortrait)
                                .foregroundColor(Color.button.danger)
                            Text(DebugSettingsContent.Strava.signOut)
                                .foregroundColor(Color.button.danger)
                        }
                    }
                    
                    HStack {
                        Text(TrendsContent.Labels.status)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Badge("Connected", variant: .success)
                    }
                    
                    if case .connected(let athleteId) = stravaAuthService.connectionState, let id = athleteId {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(TrendsContent.Labels.athleteID)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(id)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Text(TrendsContent.Labels.status)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Badge(stravaStateDescription, variant: stravaAuthService.connectionState.isLoading ? .warning : .neutral)
                    }
                    
                    Button(action: {
                        stravaAuthService.startAuth()
                    }) {
                        HStack {
                            Image(systemName: Icons.Arrow.rightCircleFill)
                                .foregroundColor(Color(red: 252/255, green: 76/255, blue: 2/255))
                            Text(TrendsContent.Labels.connectToStrava)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(red: 252/255, green: 76/255, blue: 2/255))
                    .disabled(stravaAuthService.connectionState.isLoading)
                    
                    if case .error(let message) = stravaAuthService.connectionState {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(TrendsContent.Labels.error)
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
            Label(DebugSettingsContent.SectionHeaders.oauthActions, systemImage: Icons.System.keyHorizontal)
        } footer: {
            Text(SettingsContent.OAuthActions.oauthActionsFooter)
        }
    }
    
    // MARK: - Monitoring Dashboards Section
    
    private var monitoringDashboardsSection: some View {
        Section {
            NavigationLink(destination: ServiceHealthDashboard()) {
                HStack {
                    Image(systemName: Icons.System.heartTextSquare)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SettingsContent.MonitoringDashboards.serviceHealth)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(SettingsContent.MonitoringDashboards.serviceHealthDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: TelemetryDashboard()) {
                HStack {
                    Image(systemName: Icons.System.chart)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SettingsContent.MonitoringDashboards.componentTelemetry)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(SettingsContent.MonitoringDashboards.componentTelemetryDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: SportPreferencesDebugView()) {
                HStack {
                    Image(systemName: Icons.DataSource.strava)
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SettingsContent.MonitoringDashboards.sportPreferences)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(SettingsContent.MonitoringDashboards.sportPreferencesDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: CacheStatsView()) {
                HStack {
                    Image(systemName: Icons.System.chartDoc)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SettingsContent.MonitoringDashboards.cacheStatistics)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(SettingsContent.MonitoringDashboards.cacheStatisticsDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: MLDebugView()) {
                HStack {
                    Image(systemName: Icons.System.brain)
                        .foregroundColor(.pink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SettingsContent.MonitoringDashboards.mlInfrastructure)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(SettingsContent.MonitoringDashboards.mlInfrastructureDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: AppGroupDebugView()) {
                HStack {
                    Image(systemName: Icons.System.grid2x2)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SettingsContent.MonitoringDashboards.appGroupTest)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(SettingsContent.MonitoringDashboards.appGroupTestDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: StandardCardDebugView()) {
                HStack {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("StandardCard Component")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Preview all card variations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label(SettingsContent.MonitoringDashboards.header, systemImage: Icons.System.gaugeBadge)
        } footer: {
            Text(SettingsContent.MonitoringDashboards.footer)
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
            Logger.debug("🗑️ Cleared Intervals.icu cache from Debug Settings")
            
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
            Logger.error("Error clearing Core Data: \(error)")
        }
    }
}

#Preview {
    DebugSettingsView()
}
#endif
