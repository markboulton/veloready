import Foundation

/// Result of wellness calculation
struct WellnessFoundation: Identifiable {
    let id = UUID()
    let sleepQuality: Double
    let recoveryCapacity: Double
    let hrvStatus: Double
    let stressLevel: Double
    let consistency: Double
    let nutrition: Double
    let overallScore: Double
}

/// Service for calculating comprehensive wellness scores
///
/// Wellness is calculated using a 6-factor weighted formula:
///
/// **With Sleep Data:**
/// - Sleep Quality (25%): Average sleep score + consistency
/// - Recovery Capacity (25%): Average recovery - low recovery day penalty
/// - HRV Status (20%): Trend + stability
/// - Stress Level (15%): Inverted RHR elevation + recovery stress
/// - Consistency (10%): Sleep schedule regularity
/// - Nutrition (5%): Inferred from recovery patterns
///
/// **Without Sleep Data (Rebalanced):**
/// - Recovery Capacity (33.3%)
/// - HRV Status (26.7%)
/// - Stress Level (20%)
/// - Consistency (13.3%)
/// - Nutrition (6.7%)
///
/// Scores range from 0-100, where higher indicates better wellness.
@MainActor
final class WellnessCalculationService {
    static let shared = WellnessCalculationService()

    // MARK: - Weight Constants (With Sleep)

    private let sleepWeight: Double = 0.25
    private let recoveryWeight: Double = 0.25
    private let hrvWeight: Double = 0.20
    private let stressWeight: Double = 0.15
    private let consistencyWeight: Double = 0.10
    private let nutritionWeight: Double = 0.05

    // MARK: - Weight Constants (Without Sleep - Rebalanced)

    private let recoveryWeightNoSleep: Double = 0.333
    private let hrvWeightNoSleep: Double = 0.267
    private let stressWeightNoSleep: Double = 0.20
    private let consistencyWeightNoSleep: Double = 0.133
    private let nutritionWeightNoSleep: Double = 0.067

    // MARK: - Calculation Constants

    private let lowRecoveryThreshold: Double = 60.0
    private let lowRecoveryPenalty: Double = 3.0
    private let sleepAvgWeight: Double = 0.7
    private let sleepConsistencyWeight: Double = 0.3
    private let nutritionMultiplier: Double = 1.1
    private let sleepConsistencyStdDevFactor: Double = 30.0

    // MARK: - Public API

    /// Calculate wellness foundation from daily scores
    /// - Parameter last7Days: Array of daily scores from the last 7 days
    /// - Returns: Wellness foundation with all component scores and overall score
    func calculateWellness(from last7Days: [DailyScores]) -> WellnessFoundation? {
        guard !last7Days.isEmpty else {
            Logger.warning("️ [WellnessCalculationService] No data for wellness foundation")
            return nil
        }

        // Sleep Quality: avg sleep score + consistency
        let sleepScores = last7Days.compactMap { $0.sleepScore > 0 ? $0.sleepScore : nil }
        let avgSleepScore = sleepScores.isEmpty ? 0 : sleepScores.reduce(0, +) / Double(sleepScores.count)
        let sleepConsistency = calculateSleepConsistency(days: last7Days)
        let sleepQuality = (avgSleepScore * sleepAvgWeight + sleepConsistency * sleepConsistencyWeight)

        // Recovery Capacity: avg recovery - recovery debt penalty
        let recoveryScores = last7Days.compactMap { $0.recoveryScore > 0 ? $0.recoveryScore : nil }
        let avgRecovery = recoveryScores.isEmpty ? 0 : recoveryScores.reduce(0, +) / Double(recoveryScores.count)
        let lowRecoveryDays = recoveryScores.filter { $0 < lowRecoveryThreshold }.count
        let recoveryCapacity = max(0, avgRecovery - Double(lowRecoveryDays) * lowRecoveryPenalty)

        // HRV Status: trend + stability
        let hrvValues = last7Days.compactMap { $0.physio?.hrv ?? 0 > 0 ? $0.physio?.hrv : nil }
        let hrvStatus = calculateHRVStatus(values: hrvValues)

        // Stress Level: inferred from RHR elevation + low recovery days
        let rhrValues = last7Days.compactMap { $0.physio?.rhr ?? 0 > 0 ? $0.physio?.rhr : nil }
        let stressLevel = calculateStressLevel(rhrValues: rhrValues, lowRecoveryDays: lowRecoveryDays)

        // Consistency: sleep + training schedule regularity
        let consistency = sleepConsistency

        // Nutrition: inferred from recovery pattern + workout completion
        // High recovery + completed workouts = good nutrition
        let nutrition = min(100, avgRecovery * nutritionMultiplier)

        // Check if sleep data is available
        let hasSleepData = !sleepScores.isEmpty

        // Overall: weighted average - rebalance when sleep unavailable
        let overall: Double
        if hasSleepData {
            // Normal weights (with sleep)
            overall = (sleepQuality * sleepWeight +
                      recoveryCapacity * recoveryWeight +
                      hrvStatus * hrvWeight +
                      (100 - stressLevel) * stressWeight +
                      consistency * consistencyWeight +
                      nutrition * nutritionWeight)
        } else {
            // Rebalanced weights (without sleep)
            overall = (recoveryCapacity * recoveryWeightNoSleep +
                      hrvStatus * hrvWeightNoSleep +
                      (100 - stressLevel) * stressWeightNoSleep +
                      consistency * consistencyWeightNoSleep +
                      nutrition * nutritionWeightNoSleep)
            Logger.debug("💤 [WellnessCalculationService] NO SLEEP MODE: Using rebalanced weights")
        }

        Logger.debug("💚 [WellnessCalculationService] Wellness Foundation: \(Int(overall))/100")

        return WellnessFoundation(
            sleepQuality: sleepQuality,
            recoveryCapacity: recoveryCapacity,
            hrvStatus: hrvStatus,
            stressLevel: stressLevel,
            consistency: consistency,
            nutrition: nutrition,
            overallScore: overall
        )
    }

    // MARK: - Private Helpers

    /// Calculate sleep consistency from sleep durations
    /// Lower standard deviation = higher consistency score
    private func calculateSleepConsistency(days: [DailyScores]) -> Double {
        let sleepDurations = days.compactMap { day -> Double? in
            guard let duration = day.physio?.sleepDuration, duration > 0 else { return nil }
            return duration
        }
        guard sleepDurations.count >= 3 else { return 0 }

        let avg = sleepDurations.reduce(0, +) / Double(sleepDurations.count)
        let varianceSum = sleepDurations.map { pow($0 - avg, 2) }.reduce(0, +)
        let variance = varianceSum / Double(sleepDurations.count)
        let stdDev = sqrt(variance)

        // Lower std dev = higher consistency
        // 1 hour std dev = 70/100, 0.5 hour = 85/100
        let consistencyScore = max(0, min(100, 100 - (stdDev / 3600) * sleepConsistencyStdDevFactor))
        return consistencyScore
    }

    /// Calculate HRV status from recent trend
    /// Rising HRV = good, falling HRV = poor
    private func calculateHRVStatus(values: [Double]) -> Double {
        guard values.count >= 3 else { return 50 }

        let avg = values.reduce(0, +) / Double(values.count)
        let recent = Array(values.suffix(3))
        let recentAvg = recent.reduce(0, +) / Double(recent.count)

        // Compare recent to overall average
        let change = ((recentAvg - avg) / avg) * 100

        // Rising HRV = good (up to 100), falling = poor (down to 0)
        return min(100, max(0, 70 + change))
    }

    /// Calculate stress level from RHR elevation and recovery pattern
    /// Higher RHR + more low recovery days = higher stress
    private func calculateStressLevel(rhrValues: [Double], lowRecoveryDays: Int) -> Double {
        guard !rhrValues.isEmpty else { return 50 }

        let avg = rhrValues.reduce(0, +) / Double(rhrValues.count)
        let recent = Array(rhrValues.suffix(3))
        let recentAvg = recent.reduce(0, +) / Double(recent.count)

        // Elevated RHR = stress
        let rhrElevation = max(0, ((recentAvg - avg) / avg) * 100)

        // Low recovery days = stress
        let recoveryStress = Double(lowRecoveryDays) * 10

        return min(100, rhrElevation * 2 + recoveryStress)
    }
}
