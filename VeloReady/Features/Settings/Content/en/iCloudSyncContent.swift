import Foundation

/// Content for iCloud sync feature
enum iCloudSyncContent {
    static let title = "iCloud Sync"
    
    enum Status {
        static let available = "Available"
        static let notAvailable = "Not Available"
        static let syncing = "Syncing..."
        static let lastSync = "Last Sync"
    }
    
    enum Actions {
        static let syncNow = "Sync Now"
        static let restore = "Restore from iCloud"
        static let syncing = "Syncing..."
    }
    
    enum Sections {
        static let status = "Status"
        static let actions = "Actions"
        static let whatsSynced = "What's Synced"
    }
    
    enum Footer {
        static let status = "iCloud automatically syncs your settings, workout data, and strength exercise logs across all your devices."
        static let actions = "Manually sync your data to iCloud or restore from your iCloud backup."
        static let whatsSynced = "All data is encrypted and stored securely in your private iCloud account."
    }
    
    enum SyncedData {
        static let userSettings = "User Settings"
        static let userSettingsDesc = "Sleep targets, zones, display preferences"
        
        static let strengthData = "Strength Exercise Data"
        static let strengthDataDesc = "RPE ratings and muscle group selections"
        
        static let workoutMetadata = "Workout Metadata"
        static let workoutMetadataDesc = "Exercise tracking and recovery data"
        
        static let dailyScores = "Daily Scores"
        static let dailyScoresDesc = "Recovery, sleep, and strain scores"
    }
    
    enum Alerts {
        static let restoreTitle = "Restore from iCloud"
        static let restoreMessage = "This will replace your current local data with data from iCloud. Your current data will be overwritten. Are you sure?"
        static let restoreConfirm = "Restore"
        static let cancel = "Cancel"
        
        static let successTitle = "Restore Successful"
        static let successMessage = "Your data has been successfully restored from iCloud."
        
        static let errorTitle = "Restore Failed"
        static let errorMessage = "Failed to restore data from iCloud. Please try again."
        
        static let ok = "OK"
    }
    
    enum NotAvailable {
        static let title = "iCloud Not Available"
        static let instructions = "To enable iCloud sync:"
        static let step1 = "1. Open Settings app"
        static let step2 = "2. Tap your name at the top"
        static let step3 = "3. Tap iCloud"
        static let step4 = "4. Enable iCloud Drive"
        static let step5 = "5. Ensure VeloReady has iCloud access"
    }
    
    enum Errors {
        static let notAvailable = "iCloud is not available. Please check your iCloud settings."
        static let syncFailed = "Sync failed. Please try again."
        static let quotaExceeded = "iCloud storage quota exceeded. Please upgrade your iCloud storage plan."
        static let networkError = "Network error. Please check your internet connection."
    }
}
