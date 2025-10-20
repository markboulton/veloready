import Foundation

/// Content strings for Onboarding feature
enum OnboardingContent {
    
    // MARK: - Corporate Network
    enum CorporateNetwork {
        static let issueDetected = "Corporate Network Issue Detected"
        static let httpsInterception = "Your corporate network is intercepting HTTPS traffic with Netskope certificates. This prevents OAuth from working."
        static let workaroundOptions = "Workaround Options:"
        static let instructions = "Instructions"
        static let noInstructions = "No instructions available"
        
        static let personalHotspot = "Personal Hotspot"
        static let usePersonalHotspot = "Use Personal Hotspot"
        static let hotspotBypass = "This bypasses your corporate network entirely:"
        static let hotspotStep1 = "1. Enable Personal Hotspot on your phone"
        static let hotspotStep2 = "2. Connect your Mac to the hotspot"
        static let hotspotStep3 = "3. Run the app - OAuth should work normally"
        static let hotspotStep4 = "4. Switch back to corporate network after testing"
        static let hotspotPros = "✅ Pros: Completely bypasses corporate network"
        static let hotspotCons = "❌ Cons: Uses cellular data"
        
        static let vpnConnection = "VPN Connection"
        static let useVPN = "Use VPN Connection"
        static let vpnBypass = "Connect to a VPN to bypass corporate network:"
        static let vpnStep1 = "1. Install a VPN client (NordVPN, ExpressVPN, etc.)"
        static let vpnStep2 = "2. Connect to a server outside your corporate network"
        static let vpnStep3 = "3. Run the app - OAuth should work normally"
        static let vpnStep4 = "4. Disconnect VPN after testing"
        static let vpnPros = "✅ Pros: Bypasses corporate network, keeps internet"
        static let vpnCons = "❌ Cons: Requires VPN subscription"
        
        static let differentNetwork = "Different Network"
        static let useDifferentNetwork = "Use Different Network"
        static let networkWithout = "Connect to a network without corporate security:"
        static let networkStep1 = "1. Go to a coffee shop, library, or home network"
        static let networkStep2 = "2. Connect to their WiFi"
        static let networkStep3 = "3. Run the app - OAuth should work normally"
        static let networkStep4 = "4. Return to corporate network after testing"
        static let networkPros = "✅ Pros: No additional setup required"
        static let networkCons = "❌ Cons: Requires physical location change"
        
        static let certificateBypass = "Certificate Bypass"
        static let certificateAdvanced = "Certificate Bypass (Advanced)"
        static let certificateConfigure = "Configure the app to accept corporate certificates:"
        static let certificateStep1 = "1. This requires modifying the app's SSL handling"
        static let certificateStep2 = "2. Accept corporate certificates for intervals.icu"
        static let certificateStep3 = "3. May require IT approval for security reasons"
        static let certificateStep4 = "4. Not recommended for production apps"
        static let certificateWarning = "⚠️ Warning: This reduces security and may violate corporate policy"
    }
    
    // MARK: - Certificate Bypass
    enum CertificateBypass {
        static let devOnly = "Development Only"
        static let securityWarning = "This bypass reduces security and should only be used for development on corporate networks."
        static let title = "Certificate Bypass"
        static let acceptCerts = "Accept Corporate Certificates"
        static let certsAccepted = "✅ Corporate certificates will be accepted for intervals.icu"
        static let standardValidation = "❌ Standard certificate validation will be used"
        static let howItWorks = "How it works:"
        static let step1 = "1. When enabled, the app accepts corporate certificates"
        static let step2 = "2. This allows OAuth to work on corporate networks"
        static let step3 = "3. Only applies to intervals.icu domain"
        static let step4 = "4. Automatically disabled in production builds"
        static let alertTitle = "Security Warning"
        static let enableAnyway = "Enable Anyway"
        static let alertMessage = "This bypass reduces security by accepting corporate certificates. Only use this for development on corporate networks."
    }
    
    // MARK: - OAuth Debug
    enum OAuthDebug {
        static let title = "OAuth Debug Information"  /// OAuth debug title
        static let configuration = "OAuth Configuration"  /// Configuration section
        static let testURL = "Test OAuth URL"  /// Test URL button
        static let openSafari = "Open in Safari"  /// Open Safari button
        static let testComponents = "Test URL Components"  /// Test components section
        static let failedURL = "Failed to generate OAuth URL"  /// Failed URL message
        static let debugInfo = "Debug Information"  /// Debug info section
        static let noDebugInfo = "No debug info yet"  /// No debug info message
        static let testAPI = "Test API Connection"  /// Test API button
        static let oauthStatus = "OAuth Status"  /// OAuth status section
        static let oauthTests = "OAuth Tests"  /// OAuth tests section
        static let testResults = "Test Results"  /// Test results section
        static let clientID = "Client ID: 108"  /// Client ID
        static let redirectURI = "Redirect URI: veloready://oauth/callback"  /// Redirect URI
        static let scopes = "Scopes: ACTIVITY WELLNESS CALENDAR"  /// Scopes
        static let user = "User"  /// User label
        static let error = "Error"  /// Error label
    }
    
    // MARK: - Health Permissions
    enum HealthPermissions {
        static let title = "Health Data Access"  /// Health permissions title
        static let description = "VeloReady needs access to your health data to calculate recovery scores and track your training."  /// Description
        static let grantAccess = "Grant Access"  /// Grant access button
        static let continueButton = "Continue"  /// Continue button
        static let skipForNow = "Skip for Now"  /// Skip button
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
    
    // MARK: - Screen 1: Value Proposition
    enum ValueProp {
        static let title = "Welcome to VeloReady"  /// Main title
        static let subtitle = "Your intelligent training companion"  /// Subtitle
        static let continueButton = "Get Started"  /// Continue button
        
        // Benefits
        static let benefit1Icon = "chart.line.uptrend.xyaxis"  /// Progress tracking icon
        static let benefit1Title = "Track Your Progress"  /// Progress title
        static let benefit1Description = "Monitor recovery, sleep, and training load in one place"  /// Progress description
        
        static let benefit2Icon = "brain.head.profile"  /// AI insights icon
        static let benefit2Title = "AI-Powered Insights"  /// AI title
        static let benefit2Description = "Get personalized coaching based on your data"  /// AI description
        
        static let benefit3Icon = "figure.outdoor.cycle"  /// Cycling icon
        static let benefit3Title = "Cycling Focused"  /// Cycling title
        static let benefit3Description = "Built specifically for cyclists and their training needs"  /// Cycling description
        
        static let benefit4Icon = "heart.text.square"  /// Recovery icon
        static let benefit4Title = "Smart Recovery"  /// Recovery title
        static let benefit4Description = "Know when to push hard and when to rest"  /// Recovery description
        
        static let benefit5Icon = "bolt.fill"  /// Training load icon
        static let benefit5Title = "Training Load Balance"  /// Load title
        static let benefit5Description = "Avoid overtraining with intelligent TSB tracking"  /// Load description
    }
    
    // MARK: - Screen 2: What VeloReady Does  
    enum WhatVeloReady {
        static let title = "What VeloReady Does"  /// Main title
        static let subtitle = "Built for athletes who value data-driven training"  /// Subtitle
        static let continueButton = "Continue"  /// Continue button
        static let privacyNote = "Your data is private and never leaves your device"  /// Privacy note
        
        // Feature 1: Riding First
        static let feature1Icon = "figure.outdoor.cycle"  /// Riding icon
        static let feature1Title = "Riding First"  /// Riding title
        static let feature1Description = "Track power, heart rate, and training load. Connect with Strava, Intervals.icu, or Wahoo for seamless data sync."  /// Riding description
        
        // Feature 2: Intelligence Layer
        static let feature2Icon = "brain.filled.head.profile"  /// AI icon
        static let feature2Title = "Intelligence Layer"  /// AI title
        static let feature2Description = "AI analyzes your data to provide daily coaching insights, workout recommendations, and recovery guidance."  /// AI description
        
        // Feature 3: General Health
        static let feature3Icon = "heart.circle.fill"  /// Health icon
        static let feature3Title = "General Health"  /// Health title
        static let feature3Description = "Monitor HRV, resting heart rate, sleep quality, and overall wellness metrics from Apple Health."  /// Health description
        
        // Feature 4: Recovery Focus
        static let feature4Icon = "bed.double.fill"  /// Recovery icon
        static let feature4Title = "Recovery Focus"  /// Recovery title
        static let feature4Description = "Balance training stress with recovery. Know when to push hard and when to back off to avoid burnout."  /// Recovery description
    }
    
    // MARK: - Screen 3: Apple Health
    enum AppleHealth {
        static let title = "Apple Health"  /// Main title (short version)
        static let fullTitle = "Connect Apple Health"  /// Full title
        static let subtitle = "VeloReady uses Apple Health to monitor your recovery and training metrics"  /// Subtitle
        static let description = "VeloReady needs access to Apple Health to track your recovery metrics"  /// Description
        static let allowButton = "Allow Access"  /// Allow button
        static let continueButton = "Continue"  /// Continue button
        static let wellAccess = "We'll access:"  /// We'll access label
        static let connected = "Apple Health Connected"  /// Connected message
        static let doLater = "I'll Do This Later"  /// Skip button
        
        // Required section
        static let requiredTitle = "Required"  /// Required section title
        static let requiredItem1Icon = "heart.fill"  /// HRV icon
        static let requiredItem1Title = "Heart Rate Variability"  /// HRV title
        static let requiredItem1Description = "Tracks your recovery status"  /// HRV description
        
        static let requiredItem2Icon = "waveform.path.ecg"  /// RHR icon
        static let requiredItem2Title = "Resting Heart Rate"  /// RHR title
        static let requiredItem2Description = "Monitors baseline fitness"  /// RHR description
        
        static let requiredItem3Icon = "bed.double.fill"  /// Sleep icon
        static let requiredItem3Title = "Sleep Analysis"  /// Sleep title
        static let requiredItem3Description = "Tracks sleep duration and quality"  /// Sleep description
        
        // Optional section
        static let optionalTitle = "Optional"  /// Optional section title
        static let optionalItem1Icon = "figure.run"  /// Workouts icon
        static let optionalItem1Title = "Workouts"  /// Workouts title
        static let optionalItem1Description = "Syncs your training activities"  /// Workouts description
        
        static let optionalItem2Icon = "flame.fill"  /// Energy icon
        static let optionalItem2Title = "Active Energy"  /// Energy title
        static let optionalItem2Description = "Tracks calories burned"  /// Energy description
    }
    
    // MARK: - Screen 4: Data Sources
    enum DataSources {
        static let title = "Connect Data Sources"  /// Main title
        static let subtitleCycling = "Connect to Strava, Intervals.icu, or Wahoo to sync your rides and track your progress. This step is optional."  /// Cycling subtitle
        static let subtitleNonCycling = "We'll use Apple Health to track your activities and health metrics"  /// Non-cycling subtitle
        static let continueButton = "Continue"  /// Continue button
        static let optionalNote = "Optional: Connect your training platform"  /// Optional note
        static let allSetTitle = "You're all set!"  /// All set title
        static let allSetMessage = "We'll track your activities through Apple Health"  /// All set message
        
        // Strava
        static let stravaConnect = "Connect with Strava"  /// Strava connect button
        static let stravaConnecting = "Connecting..."  /// Strava connecting state
        static let stravaDisconnect = "Disconnect from Strava"  /// Strava disconnect button
        static let stravaError = "Error"  /// Strava error prefix
        
        // Intervals.icu
        static let intervalsConnect = "Connect with Intervals.icu"  /// Intervals connect button
        static let intervalsDisconnect = "Disconnect from Intervals.icu"  /// Intervals disconnect button
        
        // Wahoo
        static let wahooComingSoon = "Wahoo (Coming Soon)"  /// Wahoo button
    }
    
    // MARK: - Screen 5: Profile Setup
    enum ProfileSetup {
        static let title = "Set Up Your Profile"  /// Main title
        static let subtitleConnected = "Your profile information has been pulled from your connected accounts"  /// Connected subtitle
        static let subtitleHealthKit = "We'll use Apple Health to track your metrics"  /// HealthKit subtitle
        static let continueButton = "Continue"  /// Continue button
        
        // Name section
        static let nameLabel = "Name"  /// Name field label
        static let nameLoading = "Loading..."  /// Name loading state
        
        // Units section
        static let unitsLabel = "Units"  /// Units field label
        static let units = "Units"  /// Units label (short)
        static let metricOption = "Metric"  /// Metric option
        static let imperialOption = "Imperial"  /// Imperial option
        static let metricDistance = "Kilometers"  /// Metric distance
        static let metricWeight = "Kilograms"  /// Metric weight
        static let imperialDistance = "Miles"  /// Imperial distance
        static let imperialWeight = "Pounds"  /// Imperial weight
    }
    
    // MARK: - Screen 6: Subscription
    enum Subscription {
        static let title = "Unlock Pro Features"  /// Main title
        static let subtitle = "Get the most out of your training with advanced analytics and AI coaching"  /// Subtitle
        static let continueButton = "Start Free Trial"  /// Continue button
        static let skipButton = "Skip for Now"  /// Skip button
        static let restoreButton = "Restore Purchase"  /// Restore button
        
        // Features
        static let feature1Icon = "chart.xyaxis.line"  /// Advanced analytics icon
        static let feature1Title = "Advanced Analytics"  /// Analytics title
        static let feature1Description = "Deep dive into your training data with comprehensive charts and trends"  /// Analytics description
        
        static let feature2Icon = "brain.head.profile"  /// AI coaching icon
        static let feature2Title = "AI Coaching"  /// AI title
        static let feature2Description = "Get personalized daily briefs and ride summaries powered by GPT-4"  /// AI description
        
        static let feature3Icon = "arrow.triangle.2.circlepath"  /// Unlimited sync icon
        static let feature3Title = "Unlimited Syncing"  /// Sync title
        static let feature3Description = "Connect all your platforms: Strava, Intervals.icu, and Wahoo"  /// Sync description
        
        static let feature4Icon = "bell.badge.fill"  /// Smart notifications icon
        static let feature4Title = "Smart Notifications"  /// Notifications title
        static let feature4Description = "Get timely reminders and insights to optimize your training"  /// Notifications description
        
        // Plan
        static let planAnnualTitle = "Annual Plan"  /// Annual plan title
        static let planAnnualPrice = "$49.99/year"  /// Annual plan price
        static let planAnnualSavings = "Save 30%"  /// Annual plan savings
        static let planMonthlyTitle = "Monthly Plan"  /// Monthly plan title
        static let planMonthlyPrice = "$5.99/month"  /// Monthly plan price
        
        // Fine print
        static let finePrint = "7-day free trial. Cancel anytime. Payment charged to Apple ID at confirmation of purchase. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period."  /// Fine print
    }
    
    // MARK: - Complete Step
    enum Complete {
        static let title = "All Set!"  /// Complete title
        static let subtitle = "You're ready to start tracking your rides"  /// Complete subtitle
        static let continueButton = "Start Using VeloReady"  /// Start button
    }
    
    // MARK: - Intervals Login
    enum IntervalsLogin {
        static let title = "Welcome to VeloReady"  /// Login title
        static let subtitle = "Connect your intervals.icu account to access your training data and get personalized recommendations."  /// Login subtitle
        static let whatYouGet = "What you'll get:"  /// What you get label
        static let dataPrivate = "Your data stays private and secure"  /// Privacy message
        static let connectButton = "Connect to intervals.icu"  /// Connect button
        static let authenticationError = "Authentication Error"  /// Authentication error alert title
        static let ok = "OK"  /// OK button
    }
    
    // MARK: - Network Debug
    enum NetworkDebug {
        static let title = "Network Debug"  /// Network debug title
        static let networkStatus = "Network Status"  /// Network status section
        static let networkTests = "Network Tests"  /// Network tests section
        static let testResults = "Test Results"  /// Test results section
    }
    
    // MARK: - OAuth Web View
    enum OAuthWebView {
        static let navigationTitle = "Connect to intervals.icu"  /// OAuth web view navigation title
        static let cancel = "Cancel"  /// Cancel button
        static let networkError = "Network Error"  /// Network error alert title
        static let ok = "OK"  /// OK button
    }
    
    // MARK: - Preferences Step
    enum Preferences {
        static let title = "Set Up Your Profile"  /// Main title
        static let subtitle = "Customize your experience"  /// Subtitle
        static let continueButton = "Continue"  /// Continue button
        
        // Units Section
        static let unitsTitle = "Units"  /// Units section title
        
        // Activity Types Section
        static let activitiesTitle = "Activities to Track"  /// Activities section title
        static let activitiesSubtitle = "Select which activities you want to see in your feed"  /// Activities subtitle
        
        // Notifications Section
        static let notificationsTitle = "Notifications"  /// Notifications section title
        static let recoveryReminders = "Recovery Reminders"  /// Recovery reminders toggle
        static let recoveryRemindersDescription = "Get notified about your daily recovery score"  /// Recovery reminders description
    }
}
