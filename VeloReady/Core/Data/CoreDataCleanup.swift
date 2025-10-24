import Foundation
import CoreData

/// Utility for cleaning up duplicate and invalid Core Data entries
@MainActor
final class CoreDataCleanup {
    private let persistence = PersistenceController.shared
    
    /// Remove duplicate DailyScores entries for the same date
    /// Keeps the most recent entry (by lastUpdated) and deletes others
    func removeDuplicateDailyScores() async {
        Logger.debug("🧹 [CLEANUP] Starting duplicate DailyScores removal...")
        
        let context = persistence.newBackgroundContext()
        
        await context.perform {
            // Fetch all DailyScores
            let request = DailyScores.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            
            guard let allScores = try? context.fetch(request) else {
                Logger.error("❌ [CLEANUP] Failed to fetch DailyScores")
                return
            }
            
            Logger.debug("🧹 [CLEANUP] Found \(allScores.count) total DailyScores entries")
            
            // Group by date
            var scoresByDate: [Date: [DailyScores]] = [:]
            for score in allScores {
                guard let date = score.date else { continue }
                let startOfDay = Calendar.current.startOfDay(for: date)
                scoresByDate[startOfDay, default: []].append(score)
            }
            
            var deletedCount = 0
            var keptCount = 0
            
            // For each date, keep only the most recent entry
            for (date, scores) in scoresByDate {
                if scores.count > 1 {
                    // Sort by lastUpdated (most recent first)
                    let sorted = scores.sorted { (s1, s2) in
                        guard let d1 = s1.lastUpdated, let d2 = s2.lastUpdated else {
                            return false
                        }
                        return d1 > d2
                    }
                    
                    // Keep the first (most recent), delete the rest
                    let toKeep = sorted.first!
                    let toDelete = sorted.dropFirst()
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM dd, yyyy HH:mm"
                    
                    Logger.debug("🧹 [CLEANUP] Date \(formatter.string(from: date)): Found \(scores.count) duplicates")
                    Logger.debug("   ✅ Keeping: lastUpdated=\(formatter.string(from: toKeep.lastUpdated ?? date))")
                    
                    for duplicate in toDelete {
                        Logger.debug("   🗑️ Deleting: lastUpdated=\(formatter.string(from: duplicate.lastUpdated ?? date))")
                        context.delete(duplicate)
                        deletedCount += 1
                    }
                    
                    keptCount += 1
                } else {
                    keptCount += 1
                }
            }
            
            // Save changes
            if context.hasChanges {
                do {
                    try context.save()
                    Logger.debug("✅ [CLEANUP] Removed \(deletedCount) duplicate DailyScores entries")
                    Logger.debug("✅ [CLEANUP] Kept \(keptCount) unique entries")
                } catch {
                    Logger.error("❌ [CLEANUP] Failed to save: \(error)")
                }
            } else {
                Logger.debug("✅ [CLEANUP] No duplicates found")
            }
        }
    }
    
    /// Remove DailyScores entries with all zero values (invalid data)
    func removeEmptyDailyScores() async {
        Logger.debug("🧹 [CLEANUP] Starting empty DailyScores removal...")
        
        let context = persistence.newBackgroundContext()
        
        await context.perform {
            // Fetch all DailyScores
            let request = DailyScores.fetchRequest()
            
            guard let allScores = try? context.fetch(request) else {
                Logger.error("❌ [CLEANUP] Failed to fetch DailyScores")
                return
            }
            
            var deletedCount = 0
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
            
            for score in allScores {
                // Check if this is an empty/invalid entry
                let isEmpty = score.recoveryScore == 0 &&
                             score.sleepScore == 0 &&
                             score.strainScore == 0 &&
                             (score.physio?.hrv ?? 0) == 0 &&
                             (score.physio?.rhr ?? 0) == 0 &&
                             (score.load?.ctl ?? 0) == 0 &&
                             (score.load?.atl ?? 0) == 0
                
                if isEmpty {
                    if let date = score.date {
                        Logger.debug("🗑️ [CLEANUP] Deleting empty entry: \(formatter.string(from: date))")
                    }
                    context.delete(score)
                    deletedCount += 1
                }
            }
            
            // Save changes
            if context.hasChanges {
                do {
                    try context.save()
                    Logger.debug("✅ [CLEANUP] Removed \(deletedCount) empty DailyScores entries")
                } catch {
                    Logger.error("❌ [CLEANUP] Failed to save: \(error)")
                }
            } else {
                Logger.debug("✅ [CLEANUP] No empty entries found")
            }
        }
    }
    
    /// Run full cleanup: remove duplicates and empty entries
    func runFullCleanup() async {
        Logger.debug("🧹 [CLEANUP] ========== STARTING FULL CLEANUP ==========")
        await removeDuplicateDailyScores()
        await removeEmptyDailyScores()
        Logger.debug("✅ [CLEANUP] ========== CLEANUP COMPLETE ==========")
    }
}
