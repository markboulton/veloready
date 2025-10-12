import Foundation

/// Content strings for Onboarding feature
enum OnboardingContent {
    // MARK: - Health Permissions
    enum HealthPermissions {
        static let title = "Health Data Access"  /// Health permissions title
        static let description = "RideReady needs access to your health data to calculate recovery scores and track your training."  /// Description
        static let grantAccess = "Grant Access"  /// Grant access button
        static let required = "Required Permissions"  /// Required section title
        static let optional = "Optional Permissions"  /// Optional section title
        static let heartRate = "Heart Rate"  /// Heart rate permission
        static let heartRateVariability = "Heart Rate Variability"  /// HRV permission
        static let restingHeartRate = "Resting Heart Rate"  /// RHR permission
        static let sleepAnalysis = "Sleep Analysis"  /// Sleep permission
        static let workouts = "Workouts"  /// Workouts permission
        static let activeEnergy = "Active Energy"  /// Active energy permission
    }
    
    // MARK: - Intervals OAuth
    enum IntervalsOAuth {
        static let title = "Connect Intervals.icu"  /// Intervals title
        static let description = "Connect your Intervals.icu account to sync workouts and training data."  /// Description
        static let connectButton = "Connect Intervals.icu"  /// Connect button
        static let skipButton = "Skip for Now"  /// Skip button
        static let connecting = "Connecting..."  /// Connecting state
        static let success = "Connected Successfully"  /// Success message
        static let failed = "Connection Failed"  /// Failed message
        static let retry = "Retry Connection"  /// Retry button
    }
    
    // MARK: - Welcome
    enum Welcome {
        static let title = "Welcome to RideReady"  /// Welcome title
        static let subtitle = "Your Personal Cycling Performance Tracker"  /// Subtitle
        static let getStarted = "Get Started"  /// Get started button
        static let feature1Title = "Track Recovery"  /// Feature 1 title
        static let feature1Description = "Monitor your recovery with HRV, sleep, and training load"  /// Feature 1 description
        static let feature2Title = "Analyze Performance"  /// Feature 2 title
        static let feature2Description = "Detailed workout analysis with power, heart rate, and more"  /// Feature 2 description
        static let feature3Title = "AI Coaching"  /// Feature 3 title
        static let feature3Description = "Get personalized insights and training recommendations"  /// Feature 3 description
    }
}
