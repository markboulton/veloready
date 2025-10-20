import Foundation

/// Content strings for reusable components
enum ComponentContent {
    
    // MARK: - Loading Spinner
    enum Loading {
        static let defaultMessage = "Loading..."
        static let loadingData = "Loading your data..."
        static let loadingActivity = "Loading latest activity..."
        static let loadingHealthData = "Loading health data..."
        static let syncing = "Syncing..."
    }
    
    // MARK: - Empty States
    enum EmptyState {
        // Generic
        static let noData = "Not enough data"
        static let noDataMessage = "Check back after a few days"
        static let connectButton = "Connect Data Source"
        static let availableSources = "Available Sources:"
        
        // Activities
        static let noActivities = "No Activities Yet"
        static let noActivitiesMessage = "Connect a data source to view your rides and track your progress"
        static let addActivity = "Add Activity"
        
        // Health Data
        static let healthDataUnavailable = "Health data unavailable"
        static let healthDataMessage = "Grant access to Apple Health to see your recovery metrics"
        static let grantAccess = "Grant Access"
        
        // Wellness
        static let noWellnessData = "No Wellness Data"
        static let noWellnessDataMessage = "Connect Apple Health or another source to track sleep, HRV, and recovery"
        
        // Training Zones
        static let noTrainingZones = "No Training Zones"
        static let noTrainingZonesMessage = "Connect a training platform to sync your power and heart rate zones"
        
        // Metrics
        static let noMetrics = "No Performance Metrics"
        static let noMetricsMessage = "Connect a data source to see detailed performance analytics"
        
        // Sleep
        static let noSleepData = "No sleep data"
        static let noSleepDataMessage = "Wear your Apple Watch while sleeping to track sleep quality"
        
        // Recovery
        static let noRecoveryData = "No recovery data"
        static let noRecoveryDataMessage = "Complete your first workout to see recovery metrics"
        
        // Trends
        static let notEnoughTrendData = "Not enough data"
        static let notEnoughTrendDataMessage = "Check back after a few days to see your trends"
    }
    
    // MARK: - Buttons
    enum Button {
        static let save = "Save"
        static let cancel = "Cancel"
        static let delete = "Delete"
        static let edit = "Edit"
        static let done = "Done"
        static let close = "Close"
        static let confirm = "Confirm"
        static let retry = "Retry"
        static let refresh = "Refresh"
        static let loadMore = "Load More"
        static let viewAll = "View All"
        static let viewDetails = "View Details"
        static let getStarted = "Get Started"
        static let learnMore = "Learn More"
    }
    
    // MARK: - Badges
    enum Badge {
        static let pro = "PRO"
        static let new = "NEW"
        static let beta = "BETA"
        static let comingSoon = "COMING SOON"
        static let bestValue = "BEST VALUE"
        static let popular = "POPULAR"
        static let recommended = "RECOMMENDED"
        
        // Status
        static let ready = "Ready"
        static let excellent = "Excellent"
        static let good = "Good"
        static let fair = "Fair"
        static let poor = "Poor"
        static let high = "High"
        static let moderate = "Moderate"
        static let low = "Low"
    }
    
    // MARK: - Errors
    enum Error {
        static let genericTitle = "Something went wrong"
        static let genericMessage = "Please try again later"
        static let networkTitle = "Connection Error"
        static let networkMessage = "Please check your internet connection"
        static let permissionTitle = "Permission Required"
        static let permissionMessage = "This feature requires additional permissions"
    }
}
