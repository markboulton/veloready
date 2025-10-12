import Foundation

/// Centralized content strings for the paywall and subscription flow
/// Edit these strings to change the paywall copy
enum PaywallContent {
    
    // MARK: - Header
    static let headline = "Unlock Your Full Potential"  /// Main headline on paywall
    static let subheadline = "Get advanced analytics, AI coaching, and unlimited insights"  /// Subheadline describing the offering
    
    // MARK: - Trial Banner
    static let trialBannerText = "Start your 14-day free trial"     /// Trial banner text
    
    // MARK: - Plan Selector
    static let bestValueBadge = "BEST VALUE"    /// Badge text for best value plan
    
    // MARK: - Features Section
    static let featuresTitle = "What's Included"    /// Section title for features list
    
    // MARK: - CTA Button
    static let ctaButtonTrial = "Continue"  /// Button text when user is in trial
    static let ctaButtonStartTrial = "Start Free Trial"     /// Button text when starting new trial
    
    // MARK: - Fine Print
    static let trialDays = 14   /// Trial duration in days
    
    /// Price disclaimer text (dynamic price inserted)
    static func priceDisclaimer(price: String, period: String) -> String {
        "Free for \(trialDays) days, then \(price)/\(period)"
    }
    static let cancellationPolicy = "Cancel anytime. Auto-renews unless cancelled 24 hours before period ends."     /// Cancellation policy
    static let termsButton = "Terms"    /// Terms button text
   static let privacyButton = "Privacy"    /// Privacy button text
    
    /// Restore purchases button text
    static let restoreButton = "Restore"
    
    // MARK: - Error Messages
    static let productUnavailableError = "Product not available. Please try again."     /// Error when product is not available
    static let errorAlertTitle = "Subscription Error"       /// Error alert title
    static let errorAlertOK = "OK"      /// Error alert OK button
    
    // MARK: - Navigation
    static let navigationTitle = "RideReady Pro"    /// Navigation bar title
    static let closeButton = "Close"    /// Close button text
    
    // MARK: - Subscription Plans
    
    enum Plans {
        /// Monthly plan title
        static let monthlyTitle = "Monthly"
        
        /// Monthly plan subtitle
        static let monthlySubtitle = "Billed monthly"
        
        /// Yearly plan title
        static let yearlyTitle = "Yearly"
        
        /// Yearly plan subtitle (dynamic savings inserted)
        static func yearlySubtitle(savingsPercent: Int) -> String {
            "Save \(savingsPercent)% • Billed annually"
        }
        
        /// Period label for monthly
        static let monthlyPeriod = "month"
        
        /// Period label for yearly
        static let yearlyPeriod = "month"
    }
}
