import Foundation

/// Configuration for Pro (VeloReady+) features
/// Centralized feature flagging system for Free vs Pro tiers
@MainActor
class ProFeatureConfig: ObservableObject {
    static let shared = ProFeatureConfig()
    
    // MARK: - Subscription State
    
    // CRITICAL: Initialize with cached values to prevent flash during app startup
    // These values must be read synchronously BEFORE any views are created
    @Published var isProUser: Bool = UserDefaults.standard.bool(forKey: "isProUser")
    @Published var isInTrialPeriod: Bool = UserDefaults.standard.bool(forKey: "isInTrialPeriod")
    @Published var trialDaysRemaining: Int = UserDefaults.standard.integer(forKey: "trialDaysRemaining")
    
    // For development/testing: bypass subscription check
    #if DEBUG
    @Published var bypassSubscriptionForTesting: Bool = UserDefaults.standard.bool(forKey: "bypassProForTesting")
    #else
    @Published var bypassSubscriptionForTesting: Bool = false
    #endif
    
    // For development/testing: show mock data for features requiring historical data
    @Published var showMockDataForTesting: Bool = UserDefaults.standard.bool(forKey: "showMockDataForTesting") {
        didSet { UserDefaults.standard.set(showMockDataForTesting, forKey: "showMockDataForTesting") }
    }
    
    // For development/testing: force wellness warning to show
    @Published var showWellnessWarningForTesting: Bool = UserDefaults.standard.bool(forKey: "showWellnessWarningForTesting") {
        didSet { UserDefaults.standard.set(showWellnessWarningForTesting, forKey: "showWellnessWarningForTesting") }
    }
    
    // For development/testing: force illness indicator to show
    @Published var showIllnessIndicatorForTesting: Bool = UserDefaults.standard.bool(forKey: "showIllnessIndicatorForTesting") {
        didSet { UserDefaults.standard.set(showIllnessIndicatorForTesting, forKey: "showIllnessIndicatorForTesting") }
    }
    
    // For development/testing: simulate no sleep data
    @Published var simulateNoSleepData: Bool = UserDefaults.standard.bool(forKey: "simulateNoSleepData") {
        didSet { UserDefaults.standard.set(simulateNoSleepData, forKey: "simulateNoSleepData") }
    }
    
    // For development/testing: simulate no network connection
    @Published var simulateNoNetwork: Bool = UserDefaults.standard.bool(forKey: "simulateNoNetwork") {
        didSet { UserDefaults.standard.set(simulateNoNetwork, forKey: "simulateNoNetwork") }
    }
    
    private init() {
        // Load subscription state from UserDefaults or RevenueCat
        loadSubscriptionState()
        
        #if DEBUG
        // Default to Pro enabled in DEBUG builds for testing
        if !UserDefaults.standard.bool(forKey: "hasSetProTestingPreference") {
            bypassSubscriptionForTesting = true
            UserDefaults.standard.set(true, forKey: "bypassProForTesting")
            UserDefaults.standard.set(true, forKey: "hasSetProTestingPreference")
            Logger.debug("🎯 DEBUG: Pro features enabled by default for testing")
        }
        #endif
    }
    
    // MARK: - Feature Access Checks
    
    var hasProAccess: Bool {
        return isProUser || isInTrialPeriod || bypassSubscriptionForTesting
    }
    
    // MARK: - Account Sync Features
    
    var canConnectStrava: Bool { hasProAccess }
    var canConnectTrainingPeaks: Bool { hasProAccess }
    var canConnectGarmin: Bool { hasProAccess }
    var canConnectWahoo: Bool { hasProAccess }
    
    // MARK: - Dashboard Features
    
    var canViewWeeklyTrends: Bool { hasProAccess }
    var canViewMonthlyTrends: Bool { hasProAccess }
    
    // MARK: - AI Features
    
    var canUseAIWeeklySummary: Bool { hasProAccess }
    var canUseAIMonthlySummary: Bool { hasProAccess }
    var canUseAIInsightFeed: Bool { hasProAccess }
    
    // MARK: - Recovery Features
    
    var canUseAdvancedRecovery: Bool { hasProAccess }
    var canUseReadinessForecast: Bool { hasProAccess }
    
    // MARK: - Chart Features
    
    var canViewHRVTrends: Bool { hasProAccess }
    var canViewFatigueTrends: Bool { hasProAccess }
    var canViewFormChart: Bool { hasProAccess }
    var canViewVO2Trends: Bool { hasProAccess }
    
    // MARK: - Load/Strain Features
    
    var canView7DayLoad: Bool { hasProAccess }
    var canView28DayLoad: Bool { hasProAccess }
    
    // MARK: - Sleep Features
    
    var canUseAISleepSummary: Bool { hasProAccess }
    var canViewSleepEfficiency: Bool { hasProAccess }
    
    // MARK: - Activity History Limits
    
    /// Number of days of activity history to fetch
    var activityHistoryDays: Int {
        return hasProAccess ? 90 : 30
    }
    
    /// Maximum number of activities to fetch per request
    var activityFetchLimit: Int {
        return hasProAccess ? 300 : 100
    }
    
    /// Description of activity history limit for UI
    var activityHistoryDescription: String {
        return hasProAccess 
            ? "Access up to 90 days of activity history"
            : "Access up to 30 days of activity history"
    }
    var canViewSleepDebt: Bool { hasProAccess }
    
    // MARK: - Training Features
    
    var canUseTrainingFocus: Bool { hasProAccess }
    
    // MARK: - Adaptive Zone Features (PRO Only)
    
    /// Can compute FTP from performance data (PRO feature)
    /// FREE users must use manual FTP or Strava/Intervals.icu FTP
    var canUseAdaptiveFTP: Bool { hasProAccess }
    
    /// Can compute power zones from performance data (PRO feature)
    /// FREE users get Coggan default zones based on FTP
    var canUseAdaptivePowerZones: Bool { hasProAccess }
    
    /// Can compute HR zones from performance data (PRO feature)
    /// FREE users get Coggan default zones based on Max HR
    var canUseAdaptiveHRZones: Bool { hasProAccess }
    
    // MARK: - Map Features
    
    var canUseMapOverlays: Bool { hasProAccess }
    var canUseHRGradient: Bool { hasProAccess }
    var canUsePowerGradient: Bool { hasProAccess }
    
    // MARK: - Insights Features
    
    var canViewCorrelations: Bool { hasProAccess }
    
    // MARK: - Data Features
    
    var canUseCloudBackup: Bool { hasProAccess }
    var canExportCSV: Bool { hasProAccess }
    var canExportJSON: Bool { hasProAccess }
    
    // MARK: - UI Features
    
    var canUseCustomThemes: Bool { hasProAccess }
    var canUseDarkModeCustomization: Bool { hasProAccess }
    
    // MARK: - Support Features
    
    var canUsePrioritySupport: Bool { hasProAccess }
    
    // MARK: - Subscription Management
    
    func loadSubscriptionState() {
        // Values are already loaded inline during property initialization to prevent flash
        // This method can be called to reload if needed (e.g., after purchase)
        isProUser = UserDefaults.standard.bool(forKey: "isProUser")
        isInTrialPeriod = UserDefaults.standard.bool(forKey: "isInTrialPeriod")
        trialDaysRemaining = UserDefaults.standard.integer(forKey: "trialDaysRemaining")
        
        #if DEBUG
        // In debug builds, check for testing bypass
        bypassSubscriptionForTesting = UserDefaults.standard.bool(forKey: "bypassProForTesting")
        #endif
    }
    
    func saveSubscriptionState() {
        UserDefaults.standard.set(isProUser, forKey: "isProUser")
        UserDefaults.standard.set(isInTrialPeriod, forKey: "isInTrialPeriod")
        UserDefaults.standard.set(trialDaysRemaining, forKey: "trialDaysRemaining")
    }
    
    // MARK: - Testing Helpers
    
    #if DEBUG
    func enableProForTesting() {
        bypassSubscriptionForTesting = true
        UserDefaults.standard.set(true, forKey: "bypassProForTesting")
        objectWillChange.send()
    }
    
    func disableProForTesting() {
        bypassSubscriptionForTesting = false
        UserDefaults.standard.set(false, forKey: "bypassProForTesting")
        objectWillChange.send()
    }
    
    func simulateTrial(daysRemaining: Int = 14) {
        isInTrialPeriod = true
        trialDaysRemaining = daysRemaining
        saveSubscriptionState()
        objectWillChange.send()
    }
    
    func endTrial() {
        isInTrialPeriod = false
        trialDaysRemaining = 0
        saveSubscriptionState()
        objectWillChange.send()
    }
    #endif
    
    // MARK: - Feature Lists
    
    /// Get list of all VeloReady Pro features for display in paywall
    var proFeaturesList: [ProFeature] {
        return [
            ProFeature(
                icon: "link",
                title: "Multi-Service Sync",
                description: "Connect Strava, TrainingPeaks, Garmin, and Wahoo",
                category: .sync
            ),
            ProFeature(
                icon: "chart.line.uptrend.xyaxis",
                title: "Trend Dashboards",
                description: "Weekly and monthly performance trends",
                category: .dashboard
            ),
            ProFeature(
                icon: "brain.head.profile",
                title: "AI Coaching",
                description: "Weekly and monthly AI summaries",
                category: .ai
            ),
            ProFeature(
                icon: "lightbulb.fill",
                title: "AI Insights Feed",
                description: "Contextual tips and recommendations",
                category: .ai
            ),
            ProFeature(
                icon: "heart.text.square",
                title: "Advanced Recovery",
                description: "HR trends and readiness forecasting",
                category: .recovery
            ),
            ProFeature(
                icon: "chart.xyaxis.line",
                title: "Fitness-Fatigue Chart",
                description: "Track your training form over time",
                category: .charts
            ),
            ProFeature(
                icon: "waveform.path.ecg",
                title: "HRV & VO₂ Trends",
                description: "Long-term health metric tracking",
                category: .charts
            ),
            ProFeature(
                icon: "figure.run",
                title: "7 & 28-Day Load",
                description: "Rolling training load analysis",
                category: .load
            ),
            ProFeature(
                icon: "bed.double.fill",
                title: "AI Sleep Analysis",
                description: "Sleep efficiency, debt, and recommendations",
                category: .sleep
            ),
            ProFeature(
                icon: "target",
                title: "Training Focus",
                description: "7-day workout recommendations",
                category: .training
            ),
            ProFeature(
                icon: "map.fill",
                title: "Map Overlays",
                description: "HR and power gradient visualization",
                category: .maps
            ),
            ProFeature(
                icon: "chart.dots.scatter",
                title: "Correlation Insights",
                description: "Recovery-sleep relationship analysis",
                category: .insights
            ),
            ProFeature(
                icon: "icloud.fill",
                title: "Cloud Backup",
                description: "Secure data backup to cloud",
                category: .data
            ),
            ProFeature(
                icon: "square.and.arrow.up",
                title: "Data Export",
                description: "Export to CSV and JSON",
                category: .data
            ),
            ProFeature(
                icon: "paintpalette.fill",
                title: "Custom Themes",
                description: "Dark mode and gradient customization",
                category: .ui
            ),
            ProFeature(
                icon: "person.fill.questionmark",
                title: "Priority Support",
                description: "Fast response to your questions",
                category: .support
            )
        ]
    }
}

// MARK: - Pro Feature Model

struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let category: ProFeatureCategory
}

enum ProFeatureCategory {
    case sync
    case dashboard
    case ai
    case recovery
    case charts
    case load
    case sleep
    case training
    case maps
    case insights
    case data
    case ui
    case support
}
 