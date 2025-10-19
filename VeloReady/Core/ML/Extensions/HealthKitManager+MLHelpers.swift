import Foundation
import HealthKit

/// Extension to HealthKitManager for ML-specific helper methods
extension HealthKitManager {
    
    // MARK: - ML Historical Data Helpers
    
    /// Fetch step count for a specific date range (returns total)
    func fetchStepCount(from startDate: Date, to endDate: Date) async -> Double {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    Logger.error("[ML] Failed to fetch steps: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let sum = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            
            HKHealthStore().execute(query)
        }
    }
    
    /// Fetch active calories for a specific date range (returns total)
    func fetchActiveCalories(from startDate: Date, to endDate: Date) async -> Double {
        guard let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    Logger.error("[ML] Failed to fetch calories: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: sum)
            }
            
            HKHealthStore().execute(query)
        }
    }
    
    // Note: fetchWorkouts(from:to:activityTypes:) already exists in TrainingLoadCalculator.swift
}
