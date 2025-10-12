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
        print("📊 CORE DATA CACHE CONTENTS")
        print(String(repeating: "=", count: 60))
        
        // Fetch all DailyScores
        let request = DailyScores.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let allScores = persistence.fetch(request)
        
        print("Total cached days: \(allScores.count)")
        print("")
        
        if allScores.isEmpty {
            print("⚠️ Cache is EMPTY - no data saved yet")
        } else {
            for (index, scores) in allScores.enumerated() {
                print("Day \(index + 1): \(formatDate(scores.date))")
                print("  Recovery: \(Int(scores.recoveryScore)) (\(scores.recoveryBand ?? "unknown"))")
                print("  Sleep Score: \(Int(scores.sleepScore))")
                print("  Strain Score: \(Int(scores.strainScore))")
                print("  Effort Target: \(Int(scores.effortTarget))")
                
                if let physio = scores.physio {
                    print("  Physio:")
                    print("    HRV: \(String(format: "%.1f", physio.hrv))ms (baseline: \(String(format: "%.1f", physio.hrvBaseline))ms)")
                    print("    RHR: \(String(format: "%.0f", physio.rhr))bpm (baseline: \(String(format: "%.0f", physio.rhrBaseline))bpm)")
                    print("    Sleep: \(String(format: "%.1f", physio.sleepDuration/3600))h (baseline: \(String(format: "%.1f", physio.sleepBaseline/3600))h)")
                }
                
                if let aiBrief = scores.aiBriefText {
                    print("  AI Brief: \(aiBrief)")
                }
                
                if let load = scores.load {
                    print("  Load:")
                    print("    CTL: \(String(format: "%.1f", load.ctl))")
                    print("    ATL: \(String(format: "%.1f", load.atl))")
                    print("    TSB: \(String(format: "%.1f", load.tsb))")
                    print("    TSS: \(String(format: "%.0f", load.tss))")
                    print("    eFTP: \(String(format: "%.0f", load.eftp))")
                    if let workoutName = load.workoutName {
                        print("    Workout: \(workoutName)")
                    }
                }
                
                print("  Last Updated: \(formatTime(scores.lastUpdated))")
                print("")
            }
        }
        
        print(String(repeating: "=", count: 60))
        
        // Print AI Brief cache info
        print("\n🤖 AI BRIEF CACHE")
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
        print("🗑️ Core Data cache cleared")
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
