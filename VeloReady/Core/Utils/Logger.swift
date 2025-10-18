import Foundation
import os.log
import OSLog
import UIKit

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
    
    // MARK: - Log Export
    
    /// Export recent logs for feedback/debugging
    /// Returns formatted log string with timestamp and device info
    static func exportLogs() -> String {
        var output = "VeloReady Diagnostic Logs\n"
        output += "Generated: \(Date())\n"
        output += "=========================\n\n"
        
        // Device info
        output += "Device Information:\n"
        output += "  Model: \(UIDevice.current.model)\n"
        output += "  iOS: \(UIDevice.current.systemVersion)\n"
        output += "  App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        output += "  Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n"
        output += "  Environment: \(DebugFlags.buildEnvironment)\n"
        output += "\n"
        
        #if DEBUG
        output += "Note: Debug build - logs are printed to console, not stored\n"
        output += "Enable debug logging in Settings → Advanced to see detailed logs\n"
        output += "Debug logging enabled: \(isDebugLoggingEnabled)\n"
        #else
        // In production, try to fetch recent logs from OSLog
        output += "Recent System Logs:\n"
        output += fetchRecentOSLogs()
        #endif
        
        output += "\n=========================\n"
        output += "End of logs\n"
        
        return output
    }
    
    #if !DEBUG
    /// Fetch recent logs from OSLog (production only)
    private static func fetchRecentOSLogs() -> String {
        do {
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)
            let oneHourAgo = Date().addingTimeInterval(-3600)
            let position = logStore.position(date: oneHourAgo)
            
            var logs = ""
            var count = 0
            let maxLogs = 500 // Limit to prevent huge files
            
            let entries = try logStore.getEntries(at: position)
            for entry in entries {
                guard count < maxLogs else { break }
                
                if let logEntry = entry as? OSLogEntryLog,
                   logEntry.subsystem == subsystem {
                    let timestamp = logEntry.date.formatted(date: .omitted, time: .standard)
                    logs += "[\(timestamp)] [\(logEntry.category)] \(logEntry.composedMessage)\n"
                    count += 1
                }
            }
            
            if count == 0 {
                logs = "No recent logs found (last hour)\n"
            } else {
                logs = "Found \(count) log entries (last hour):\n\n" + logs
            }
            
            return logs
        } catch {
            return "Failed to fetch logs: \(error.localizedDescription)\n"
        }
    }
    #endif
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
