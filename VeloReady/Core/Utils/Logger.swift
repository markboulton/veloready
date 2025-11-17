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
    
    // MARK: - File Logging
    
    private static let logFileURL: URL? = {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("veloready_debug.log")
    }()
    
    private static let logQueue = DispatchQueue(label: "com.veloready.logger", qos: .utility)
    private static let maxLogFileSize: Int = 5 * 1024 * 1024 // 5MB
    
    /// Write log message to file (DEBUG builds only)
    private static func writeToFile(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled, let logFileURL = logFileURL else { return }
        
        logQueue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let logLine = "[\(timestamp)] \(message)\n"
            
            // Check file size and rotate if needed
            if let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
               let fileSize = attributes[.size] as? Int,
               fileSize > maxLogFileSize {
                // Rotate log: delete old file and start fresh
                try? FileManager.default.removeItem(at: logFileURL)
            }
            
            // Append to file
            if let data = logLine.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        try? fileHandle.close()
                    }
                } else {
                    try? data.write(to: logFileURL)
                }
            }
        }
        #endif
    }
    
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
    
    /// Log trace information (DEBUG builds only, requires manual flag AND debug toggle)
    /// Use for extremely verbose logging like view body evaluations
    private static var isTraceLoggingEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "com.veloready.traceLoggingEnabled")
        #else
        return false
        #endif
    }
    
    /// Enable/disable trace logging (most verbose level)
    static func setTraceLogging(_ enabled: Bool) {
        #if DEBUG
        UserDefaults.standard.set(enabled, forKey: "com.veloready.traceLoggingEnabled")
        Logger.debug("🔧 Trace logging \(enabled ? "ENABLED" : "DISABLED")")
        #endif
    }
    
    /// Log trace information (DEBUG builds only, requires manual flag)
    /// Use this for extremely verbose logging that would normally flood the console
    static func trace(_ message: String, category: Category = .performance) {
        #if DEBUG
        guard isDebugLoggingEnabled && isTraceLoggingEnabled else { return }
        let logMessage = "🔬 [TRACE][\(category.rawValue)] \(message)"
        print(logMessage)
        writeToFile(logMessage)
        #endif
    }
    
    /// Log debug information (DEBUG builds only, respects debug toggle)
    static func debug(_ message: String, category: Category = .performance) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        let logMessage = "🔍 [\(category.rawValue)] \(message)"
        print(logMessage)
        writeToFile(logMessage)
        #endif
    }
    
    /// Log information (always shown, uses os_log in production)
    static func info(_ message: String, category: Category = .performance) {
        #if DEBUG
        let logMessage = "ℹ️ [\(category.rawValue)] \(message)"
        print(logMessage)
        writeToFile(logMessage)
        #else
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        logger.info("\(message, privacy: .public)")
        #endif
    }
    
    /// Log warnings (always shown)
    static func warning(_ message: String, category: Category = .performance) {
        #if DEBUG
        let logMessage = "⚠️ [\(category.rawValue)] \(message)"
        print(logMessage)
        writeToFile(logMessage)
        #else
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        logger.warning("\(message, privacy: .public)")
        #endif
    }
    
    /// Log errors (always shown)
    static func error(_ message: String, error: Error? = nil, category: Category = .performance) {
        #if DEBUG
        let logMessage: String
        if let error = error {
            logMessage = "❌ [\(category.rawValue)] \(message): \(error.localizedDescription)"
        } else {
            logMessage = "❌ [\(category.rawValue)] \(message)"
        }
        print(logMessage)
        writeToFile(logMessage)
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
        let logMessage: String
        if let duration = duration {
            logMessage = "⚡ [Performance] \(message) (\(String(format: "%.2f", duration))s)"
        } else {
            logMessage = "⚡ [Performance] \(message)"
        }
        print(logMessage)
        writeToFile(logMessage)
        #endif
    }
    
    /// Log network activity (DEBUG only, respects debug toggle)
    static func network(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        let logMessage = "🌐 [Network] \(message)"
        print(logMessage)
        writeToFile(logMessage)
        #endif
    }
    
    /// Log data operations (DEBUG only, respects debug toggle)
    static func data(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        let logMessage = "📊 [Data] \(message)"
        print(logMessage)
        writeToFile(logMessage)
        #endif
    }
    
    /// Log health/fitness data (DEBUG only, respects debug toggle)
    static func health(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        let logMessage = "💓 [Health] \(message)"
        print(logMessage)
        writeToFile(logMessage)
        #endif
    }
    
    /// Log cache operations (DEBUG only, respects debug toggle)
    static func cache(_ message: String) {
        #if DEBUG
        guard isDebugLoggingEnabled else { return }
        let logMessage = "💾 [Cache] \(message)"
        print(logMessage)
        writeToFile(logMessage)
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
        output += "Debug Build Information:\n"
        output += "Debug logging enabled: \(isDebugLoggingEnabled)\n"
        
        if isDebugLoggingEnabled, let logFileURL = logFileURL {
            output += "Log file location: \(logFileURL.path)\n\n"
            
            // Read log file
            if let logContents = try? String(contentsOf: logFileURL, encoding: .utf8) {
                let lines = logContents.components(separatedBy: "\n")
                output += "Recent Logs (\(lines.count) lines):\n"
                output += "\n"
                // Include last 500 lines to keep file size reasonable
                let recentLines = lines.suffix(500)
                output += recentLines.joined(separator: "\n")
            } else {
                output += "No log file found or unable to read\n"
            }
        } else {
            output += "Note: Enable debug logging in Settings → Debug to generate logs\n"
        }
        #else
        // In production, try to fetch recent logs from OSLog
        output += "Recent System Logs:\n"
        output += fetchRecentOSLogs()
        #endif
        
        output += "\n\n=========================\n"
        output += "End of logs\n"
        
        return output
    }
    
    /// Clear the debug log file
    static func clearLogFile() {
        #if DEBUG
        guard let logFileURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: logFileURL)
        Logger.info("Log file cleared")
        #endif
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
