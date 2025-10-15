import Foundation
import CoreData

/// Helper for debugging Core Data cache contents
@MainActor
class CacheDebugHelper {
    static let shared = CacheDebugHelper()
    private let persistence = PersistenceController.shared
    
    /// Print all cached data to console
    func printCacheContents() {
        print("\n" + String(repeating: "=", count: 60))
        Logger.data("CORE DATA CACHE CONTENTS")
        print(String(repeating: "=", count: 60))
        
        // Fetch all DailyScores
        let request = DailyScores.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let allScores = persistence.fetch(request)
        
        Logger.debug("Total cached days: \(allScores.count)")
        print("")
        
        if allScores.isEmpty {
            Logger.warning("️ Cache is EMPTY - no data saved yet")
        } else {
            for (index, scores) in allScores.enumerated() {
                Logger.debug("Day \(index + 1): \(formatDate(scores.date ?? Date()))")
                Logger.debug("  Recovery: \(Int(scores.recoveryScore)) (\(scores.recoveryBand ?? "unknown"))")
                Logger.debug("  Sleep Score: \(Int(scores.sleepScore))")
                Logger.debug("  Strain Score: \(Int(scores.strainScore))")
                Logger.debug("  Effort Target: \(Int(scores.effortTarget))")
                
                if let physio = scores.physio {
                    Logger.debug("  Physio:")
                    Logger.debug("    HRV: \(String(format: "%.1f", physio.hrv))ms (baseline: \(String(format: "%.1f", physio.hrvBaseline))ms)")
                    Logger.debug("    RHR: \(String(format: "%.0f", physio.rhr))bpm (baseline: \(String(format: "%.0f", physio.rhrBaseline))bpm)")
                    Logger.debug("    Sleep: \(String(format: "%.1f", physio.sleepDuration/3600))h (baseline: \(String(format: "%.1f", physio.sleepBaseline/3600))h)")
                }
                
                if let aiBrief = scores.aiBriefText {
                    Logger.debug("  AI Brief: \(aiBrief)")
                }
                
                if let load = scores.load {
                    Logger.debug("  Load:")
                    Logger.debug("    CTL: \(String(format: "%.1f", load.ctl))")
                    Logger.debug("    ATL: \(String(format: "%.1f", load.atl))")
                    Logger.debug("    TSB: \(String(format: "%.1f", load.tsb))")
                    Logger.debug("    TSS: \(String(format: "%.0f", load.tss))")
                    Logger.debug("    eFTP: \(String(format: "%.0f", load.eftp))")
                    if let workoutName = load.workoutName {
                        Logger.debug("    Workout: \(workoutName)")
                    }
                }
                
                Logger.debug("  Last Updated: \(formatTime(scores.lastUpdated ?? Date()))")
                print("")
            }
        }
        
        print(String(repeating: "=", count: 60))
        
        // Print AI Brief cache info
        Logger.debug("\n🤖 AI BRIEF CACHE")
        print(String(repeating: "=", count: 60))
        print(AIBriefService.shared.getDebugInfo())
        print(String(repeating: "=", count: 60))
        print("")
    }
    
    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        let scoresRequest = DailyScores.fetchRequest()
        let physioRequest = DailyPhysio.fetchRequest()
        let loadRequest = DailyLoad.fetchRequest()
        
        let scoresCount = persistence.fetch(scoresRequest).count
        let physioCount = persistence.fetch(physioRequest).count
        let loadCount = persistence.fetch(loadRequest).count
        
        // Get oldest and newest dates
        let sortedScores = DailyScores.fetchRequest()
        sortedScores.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let allScores = persistence.fetch(sortedScores)
        
        let oldestDate = allScores.first?.date
        let newestDate = allScores.last?.date
        
        return CacheStats(
            totalDays: scoresCount,
            physioRecords: physioCount,
            loadRecords: loadCount,
            oldestDate: oldestDate,
            newestDate: newestDate
        )
    }
    
    /// Clear all cached data (for testing)
    func clearCache() {
        persistence.deleteAll(DailyScores.self)
        persistence.deleteAll(DailyPhysio.self)
        persistence.deleteAll(DailyLoad.self)
        Logger.debug("🗑️ Core Data cache cleared")
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Cache Stats

struct CacheStats {
    let totalDays: Int
    let physioRecords: Int
    let loadRecords: Int
    let oldestDate: Date?
    let newestDate: Date?
    
    var summary: String {
        var lines = [String]()
        lines.append("📊 Cache Statistics:")
        lines.append("  Total Days: \(totalDays)")
        lines.append("  Physio Records: \(physioRecords)")
        lines.append("  Load Records: \(loadRecords)")
        
        if let oldest = oldestDate, let newest = newestDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            lines.append("  Date Range: \(formatter.string(from: oldest)) to \(formatter.string(from: newest))")
        }
        
        return lines.joined(separator: "\n")
    }
}
