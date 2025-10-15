import Foundation
import os.log

/// Centralized logging utility with DEBUG-conditional output
/// Uses os_log for production builds (efficient, privacy-aware)
/// Uses print() for DEBUG builds (easier to read during development)
enum Logger {
    
    // MARK: - Debug Toggle
    
    private static let debugLoggingKey = "com.veloready.debugLoggingEnabled"
    
    /// Enable/disable verbose debug logging at runtime
    /// Persists across app launches
    static var isDebugLoggingEnabled: Bool {
        get {
            #if DEBUG
            return UserDefaults.standard.bool(forKey: debugLoggingKey)
            #else
            return false // Always disabled in production
            #endif
        }
        set {
            #if DEBUG
            UserDefaults.standard.set(newValue, forKey: debugLoggingKey)
            Logger.debug("🔧 Debug logging \(newValue ? "ENABLED" : "DISABLED")")
            #endif
        }
    }
    
    // MARK: - Log Categories
    
    private static let subsystem = "com.veloready"
    
    enum Category: String {
        case performance = "Performance"
        case network = "Network"
        case data = "Data"
        case ui = "UI"
        case health = "Health"
        case location = "Location"
        case cache = "Cache"
        case sync = "Sync"
    }
    
    // MARK: - Logging Methods
    
    /// Log debug information (DEBUG builds only, respects debug toggle)
    static func debug(_ message: String, category: Category = .performance) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        print("🔍 [\(category.rawValue)] \(message)")
        #endif
    }
    
    /// Log information (always shown, uses os_log in production)
    static func info(_ message: String, category: Category = .performance) {
        #if DEBUG
        print("ℹ️ [\(category.rawValue)] \(message)")
        #else
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        logger.info("\(message, privacy: .public)")
        #endif
    }
    
    /// Log warnings (always shown)
    static func warning(_ message: String, category: Category = .performance) {
        #if DEBUG
        print("⚠️ [\(category.rawValue)] \(message)")
        #else
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        logger.warning("\(message, privacy: .public)")
        #endif
    }
    
    /// Log errors (always shown)
    static func error(_ message: String, error: Error? = nil, category: Category = .performance) {
        #if DEBUG
        if let error = error {
            print("❌ [\(category.rawValue)] \(message): \(error.localizedDescription)")
        } else {
            print("❌ [\(category.rawValue)] \(message)")
        }
        #else
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        if let error = error {
            logger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("\(message, privacy: .public)")
        }
        #endif
    }
    
    /// Log performance metrics (DEBUG only, with timing, respects debug toggle)
    static func performance(_ message: String, duration: TimeInterval? = nil) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        if let duration = duration {
            print("⚡ [Performance] \(message) (\(String(format: "%.2f", duration))s)")
        } else {
            print("⚡ [Performance] \(message)")
        }
        #endif
    }
    
    /// Log network activity (DEBUG only, respects debug toggle)
    static func network(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        print("🌐 [Network] \(message)")
        #endif
    }
    
    /// Log data operations (DEBUG only, respects debug toggle)
    static func data(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        print("📊 [Data] \(message)")
        #endif
    }
    
    /// Log health/fitness data (DEBUG only, respects debug toggle)
    static func health(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        print("💓 [Health] \(message)")
        #endif
    }
    
    /// Log cache operations (DEBUG only, respects debug toggle)
    static func cache(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        print("💾 [Cache] \(message)")
        #endif
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Measure and log the execution time of a closure
    static func measure<T>(_ label: String, _ closure: () throws -> T) rethrows -> T {
        #if DEBUG
        guard isDebugLoggingEnabled else { return try closure() }
        let start = Date()
        defer {
            let duration = Date().timeIntervalSince(start)
            performance(label, duration: duration)
        }
        #endif
        return try closure()
    }
    
    /// Measure and log the execution time of an async closure
    static func measureAsync<T>(_ label: String, _ closure: () async throws -> T) async rethrows -> T {
        #if DEBUG
        guard isDebugLoggingEnabled else { return try await closure() }
        let start = Date()
        defer {
            let duration = Date().timeIntervalSince(start)
            performance(label, duration: duration)
        }
        #endif
        return try await closure()
    }
}
