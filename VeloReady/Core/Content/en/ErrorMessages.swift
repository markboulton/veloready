import Foundation

/// Centralized error messages for the app
enum ErrorMessages {
    // MARK: - Network
    static let networkUnavailable = "No internet connection"  /// Network unavailable error
    static let requestFailed = "Request failed. Please try again."  /// Generic request error
    static let timeout = "Request timed out"  /// Timeout error
    
    // MARK: - Authentication
    static let authFailed = "Authentication failed"  /// Auth error
    static let tokenExpired = "Session expired. Please log in again."  /// Token expired
    static let unauthorized = "Unauthorized access"  /// Unauthorized error
    
    // MARK: - Data
    static let dataLoadFailed = "Failed to load data"  /// Data loading error
    static let dataSaveFailed = "Failed to save data"  /// Data saving error
    static let dataNotFound = "Data not found"  /// Data not found error
    static let invalidData = "Invalid data format"  /// Invalid data error
    
    // MARK: - Health Kit
    static let healthKitUnavailable = "Health data is not available"  /// HealthKit unavailable
    static let healthKitPermissionDenied = "Health data access denied"  /// Permission denied
    static let healthKitReadFailed = "Failed to read health data"  /// Read failed
    
    // MARK: - API
    static let apiError = "API error occurred"  /// Generic API error
    static let serverError = "Server error. Please try again later."  /// Server error
    static let rateLimitExceeded = "Too many requests. Please wait."  /// Rate limit error
    
    // MARK: - Sync
    static let syncFailed = "Sync failed"  /// Sync error
    static let conflictDetected = "Data conflict detected"  /// Conflict error
    
    // MARK: - Generic
    static let unknownError = "An unknown error occurred"  /// Unknown error
    static let tryAgain = "Please try again"  /// Try again message
}
